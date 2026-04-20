$xaml = Get-Content '.\GUI.ps1' -Raw | Select-String '(?s)<Window.*?</Window>' | % { $_.Matches.Value }
[xml]$x = $xaml

$window = $x.Window
$resources = $window.Resources
$children = @()
foreach ($node in $resources.ChildNodes) {
    if ($node.NodeType -eq [System.Xml.XmlNodeType]::Element) {
        $children += $node
    }
}

Add-Type -AssemblyName PresentationFramework

for ($i = 0; $i -lt $children.Count; $i++) {
    $tempXml = "<Window xmlns='http://schemas.microsoft.com/winfx/2006/xaml/presentation' xmlns:x='http://schemas.microsoft.com/winfx/2006/xaml'><Window.Resources>"
    $tempXml += $children[$i].OuterXml
    $tempXml += "</Window.Resources></Window>"
    
    try {
        $reader = (New-Object System.Xml.XmlNodeReader ([xml]$tempXml))
        $form = [System.Windows.Markup.XamlReader]::Load($reader)
        Write-Host "Child $i parsed OK"
    } catch {
        Write-Host "Child $i FAILED: $($_.Exception.InnerException.Message)"
    }
}
