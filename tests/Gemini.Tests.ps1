BeforeAll {
    . (Join-Path $PSScriptRoot '..\Functions.ps1')
    Mock Write-AiLog {}
}

Describe 'Selección automática de Gemini' {
    BeforeEach {
        $script:GeminiModelCache = $null
    }

    It 'ordena modelos compatibles de todas las páginas y excluye 3.7' {
        $script:catalogCalls = 0
        Mock Invoke-RestMethod {
            $script:catalogCalls++
            if ($script:catalogCalls -eq 1) {
                return [pscustomobject]@{
                    models = @(
                        @{ name = 'models/gemini-3.5-flash'; supportedGenerationMethods = @('generateContent') },
                        @{ name = 'models/gemini-3.7-flash'; supportedGenerationMethods = @('generateContent') },
                        @{ name = 'models/gemini-4-flash-preview'; supportedGenerationMethods = @('generateContent') }
                    )
                    nextPageToken = 'segunda página'
                }
            }
            return [pscustomobject]@{
                models = @(
                    @{ name = 'models/gemini-3.8-flash'; supportedGenerationMethods = @('generateContent') },
                    @{ name = 'models/gemini-3.6-flash'; supportedGenerationMethods = @('generateContent') },
                    @{ name = 'models/gemini-4-flash'; supportedGenerationMethods = @('embedContent') },
                    @{ name = 'models/gemini-3.8-flash-tts'; supportedGenerationMethods = @('generateContent') }
                )
            }
        }

        (Get-GeminiAutoModels -ApiKey 'fake-key') | Should -Be @('gemini-3.8-flash', 'gemini-3.6-flash', 'gemini-3.5-flash')
        (Get-GeminiAutoModels -ApiKey 'fake-key') | Out-Null
        $script:catalogCalls | Should -Be 2
    }

    It 'usa el respaldo fijo cuando falla el catálogo' {
        Mock Invoke-RestMethod { throw 'catálogo caído' }
        (Get-GeminiAutoModels -ApiKey 'fake-key') | Should -Be @('gemini-3.8-flash', 'gemini-3.6-flash', 'gemini-3.5-flash')
    }

    It 'pasa al siguiente modelo tras una respuesta vacía' {
        $script:GeminiModelCache = [pscustomobject]@{
            ApiKey = 'fake-key'; Models = @('gemini-3.8-flash', 'gemini-3.6-flash'); ExpiresAt = (Get-Date).AddHours(1)
        }
        $script:attempts = @()
        $script:bodies = @()
        Mock Invoke-RestMethod {
            $script:attempts += $Uri
            $script:bodies += ($Body | ConvertFrom-Json)
            if ($Uri -match '3\.8') { return @{ candidates = @(@{ content = @{ parts = @(@{ text = '' }) } }) } }
            return @{ candidates = @(@{ content = @{ parts = @(@{ text = 'respuesta' }) } }) }
        }

        Invoke-GeminiGenerateContent -Prompt 'hola' -ApiKey 'fake-key' -ResponseMimeType 'text/plain' | Should -Be 'respuesta'
        $script:attempts.Count | Should -Be 2
        $script:bodies[0].generationConfig.thinkingConfig.thinkingLevel | Should -Be 'low'
        $script:bodies[1].generationConfig.thinkingConfig | Should -BeNullOrEmpty
    }

    It 'respeta la selección manual y no consulta el catálogo' {
        Mock Invoke-RestMethod { return @{ candidates = @(@{ content = @{ parts = @(@{ text = 'ok' }) } }) } }
        Invoke-GeminiGenerateContent -Prompt 'hola' -ApiKey 'fake-key' -Model 'gemini-3.6-flash' -ResponseMimeType 'text/plain' | Should -Be 'ok'
        Assert-MockCalled Invoke-RestMethod -Exactly 1 -ParameterFilter { $Method -eq 'Post' -and $Uri -match 'gemini-3\.6-flash' }
    }

    It 'pasa al siguiente modelo si el JSON es inválido' {
        $script:GeminiModelCache = [pscustomobject]@{
            ApiKey = 'fake-key'; Models = @('gemini-3.8-flash', 'gemini-3.6-flash'); ExpiresAt = (Get-Date).AddHours(1)
        }
        Mock Invoke-RestMethod {
            if ($Uri -match '3\.8') { return @{ candidates = @(@{ content = @{ parts = @(@{ text = '{invalido' }) } }) } }
            return @{ candidates = @(@{ content = @{ parts = @(@{ text = '{"ok":true}' }) } }) }
        }
        Invoke-GeminiGenerateContent -Prompt 'hola' -ApiKey 'fake-key' | Should -Be '{"ok":true}'
        Assert-MockCalled Invoke-RestMethod -Exactly 2 -ParameterFilter { $Method -eq 'Post' }
    }

    It 'continúa tras timeout' {
        $script:GeminiModelCache = [pscustomobject]@{
            ApiKey = 'fake-key'; Models = @('gemini-3.8-flash', 'gemini-3.6-flash'); ExpiresAt = (Get-Date).AddHours(1)
        }
        Mock Invoke-RestMethod {
            if ($Uri -match '3\.8') { throw ([System.Net.WebException]::new('timeout', [System.Net.WebExceptionStatus]::Timeout)) }
            return @{ candidates = @(@{ content = @{ parts = @(@{ text = 'ok' }) } }) }
        }
        Invoke-GeminiGenerateContent -Prompt 'hola' -ApiKey 'fake-key' -ResponseMimeType 'text/plain' | Should -Be 'ok'
        Assert-MockCalled Invoke-RestMethod -Exactly 2 -ParameterFilter { $Method -eq 'Post' }
    }

    It 'se detiene ante un error no recuperable' {
        $script:GeminiModelCache = [pscustomobject]@{
            ApiKey = 'fake-key'; Models = @('gemini-3.8-flash', 'gemini-3.6-flash'); ExpiresAt = (Get-Date).AddHours(1)
        }
        Mock Invoke-RestMethod { throw 'solicitud rechazada' }
        { Invoke-GeminiGenerateContent -Prompt 'hola' -ApiKey 'fake-key' -ResponseMimeType 'text/plain' } | Should -Throw '*Error llamando a Gemini*'
        Assert-MockCalled Invoke-RestMethod -Exactly 1 -ParameterFilter { $Method -eq 'Post' }
    }

    It 'distingue 503 recuperable de 403 no recuperable' {
        $error503 = [pscustomobject]@{ Exception = [pscustomobject]@{ Response = [pscustomobject]@{ StatusCode = 503 } } }
        $error403 = [pscustomobject]@{ Exception = [pscustomobject]@{ Response = [pscustomobject]@{ StatusCode = 403 } } }
        Test-GeminiRecoverableError -ErrorRecord $error503 | Should -BeTrue
        Test-GeminiRecoverableError -ErrorRecord $error403 | Should -BeFalse
    }
}
