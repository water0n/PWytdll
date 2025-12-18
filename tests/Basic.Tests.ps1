Describe "YTDLL Basic Tests" {
    It "Should have required modules" {
        $modules = @("Database", "GUI", "Installers", "Queries", "Utilities")
        foreach ($module in $modules) {
            Test-Path "src/modules/$module.psm1" | Should -Be $true
        }
    }
    
    It "Should have main script" {
        Test-Path "src/main.ps1" | Should -Be $true
    }
}
