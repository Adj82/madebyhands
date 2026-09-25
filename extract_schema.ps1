Add-Type -Assembly "System.IO.Compression.FileSystem"

$path = "C:\Users\KIIT\OneDrive\Desktop\MADEBYHANDS_Shared_Firestore_Schema_v1.docx"

if (-not (Test-Path $path)) {
    Write-Host "File not found at $path"
    exit
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
[System.IO.File]::WriteAllText("C:\madebyhands\shared_schema_extracted.txt", $result)
Write-Host "Shared Schema extracted successfully. Total lines: $($lines.Count), Total chars: $($result.Length)"
