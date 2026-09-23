Add-Type -Assembly "System.IO.Compression.FileSystem"

$path = "C:\Users\KIIT\OneDrive\Desktop\Madebyhands\Final\MadeByHands_SRS_v1_0_final.docx"
if (-not (Test-Path $path)) {
    $path = "docs\MadeByHands_SRS_v1_0_final.docx"
}

Write-Host "Opening $path..."
$zip = [System.IO.Compression.ZipFile]::OpenRead($path)
$entry = $zip.Entries | Where-Object { $_.FullName -eq 'word/document.xml' }
$stream = $entry.Open()
$reader = New-Object System.IO.StreamReader($stream)
$xmlText = $reader.ReadToEnd()
$reader.Close()
$stream.Close()
$zip.Dispose()

[xml]$doc = $xmlText
$ns = New-Object System.Xml.XmlNamespaceManager($doc.NameTable)
$ns.AddNamespace('w', 'http://schemas.openxmlformats.org/wordprocessingml/2006/main')

$paragraphs = $doc.SelectNodes('//w:p', $ns)
$lines = New-Object System.Collections.Generic.List[string]

foreach ($p in $paragraphs) {
    $texts = $p.SelectNodes('.//w:t', $ns)
    $sb = New-Object System.Text.StringBuilder
    foreach ($t in $texts) {
        [void]$sb.Append($t.InnerText)
    }
    $line = $sb.ToString()
    if ($line.Trim().Length -gt 0) {
        $lines.Add($line)
    }
}

$result = $lines -join "`n"
[System.IO.File]::WriteAllText("C:\madebyhands\srs_extracted.txt", $result)
Write-Host "SRS extracted successfully. Total lines: $($lines.Count), Total chars: $($result.Length)"
