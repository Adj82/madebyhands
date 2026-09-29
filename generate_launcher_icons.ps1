Add-Type -AssemblyName System.Drawing

$sourcePath = "C:\Users\KIIT\OneDrive\Desktop\app dev.png"
if (-not (Test-Path $sourcePath)) {
    $sourcePath = "C:\madebyhands\assets\images\logo.png"
}

Write-Host "Source image: $sourcePath"
$srcImage = [System.Drawing.Image]::FromFile($sourcePath)

function Save-ResizedImage($width, $height, $targetPath) {
    $bmp = New-Object System.Drawing.Bitmap($width, $height)
    $graph = [System.Drawing.Graphics]::FromImage($bmp)
    $graph.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graph.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $graph.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $graph.DrawImage($srcImage, 0, 0, $width, $height)
    $graph.Dispose()

    $dir = [System.IO.Path]::GetDirectoryName($targetPath)
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
    $bmp.Save($targetPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    Write-Host "Generated $targetPath ($width x $height)"
}

Save-ResizedImage 48 48 "C:\madebyhands\android\app\src\main\res\mipmap-mdpi\ic_launcher.png"
Save-ResizedImage 72 72 "C:\madebyhands\android\app\src\main\res\mipmap-hdpi\ic_launcher.png"
Save-ResizedImage 96 96 "C:\madebyhands\android\app\src\main\res\mipmap-xhdpi\ic_launcher.png"
Save-ResizedImage 144 144 "C:\madebyhands\android\app\src\main\res\mipmap-xxhdpi\ic_launcher.png"
Save-ResizedImage 192 192 "C:\madebyhands\android\app\src\main\res\mipmap-xxxhdpi\ic_launcher.png"

Save-ResizedImage 16 16 "C:\madebyhands\web\favicon.png"
Save-ResizedImage 192 192 "C:\madebyhands\web\icons\Icon-192.png"
Save-ResizedImage 512 512 "C:\madebyhands\web\icons\Icon-512.png"
Save-ResizedImage 192 192 "C:\madebyhands\web\icons\Icon-maskable-192.png"
Save-ResizedImage 512 512 "C:\madebyhands\web\icons\Icon-maskable-512.png"

$srcImage.Dispose()
Write-Host "All launcher icons generated successfully!"
