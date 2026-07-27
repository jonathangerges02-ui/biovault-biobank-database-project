param(
    [switch]$ReuseExisting
)

$ErrorActionPreference = 'Stop'

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$presentationDir = Join-Path $projectRoot 'presentation'
$audioDir = Join-Path $presentationDir 'audio'
$partsDir = Join-Path $presentationDir 'video_parts'
$renderedDir = Join-Path $presentationDir 'rendered'
$slidesPath = Join-Path $presentationDir 'slides.json'
$outputPath = Join-Path $presentationDir 'BioVault_Presentation_Video.mp4'

New-Item -ItemType Directory -Force -Path $audioDir, $partsDir | Out-Null
$slides = Get-Content -Raw -LiteralPath $slidesPath | ConvertFrom-Json

Add-Type -AssemblyName System.Speech
$synthesizer = New-Object System.Speech.Synthesis.SpeechSynthesizer
$synthesizer.Rate = -1
$synthesizer.Volume = 100

$concatLines = [System.Collections.Generic.List[string]]::new()
$slideNumber = 0

foreach ($slide in $slides) {
    $slideNumber++
    $number = $slideNumber.ToString('00')
    $imagePath = Join-Path $renderedDir "slide_$number.png"
    $audioPath = Join-Path $audioDir "narration_$number.wav"
    $partPath = Join-Path $partsDir "part_$number.mp4"

    if (-not $ReuseExisting -or -not (Test-Path -LiteralPath $audioPath)) {
        Write-Host "Narrating slide $number of $($slides.Count): $($slide.title)"
        $synthesizer.SetOutputToWaveFile($audioPath)
        $synthesizer.Speak([string]$slide.narration)
        $synthesizer.SetOutputToNull()
    } else {
        Write-Host "Reusing narration for slide $number of $($slides.Count): $($slide.title)"
    }

    $actualDurationText = & ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 $audioPath
    $actualDuration = [Math]::Ceiling([double]::Parse(
        $actualDurationText.Trim(),
        [System.Globalization.CultureInfo]::InvariantCulture
    )) + 1
    $duration = [Math]::Max([int]$slide.duration_seconds, [int]$actualDuration)

    if (-not $ReuseExisting -or -not (Test-Path -LiteralPath $partPath)) {
        & ffmpeg -hide_banner -loglevel error -y `
            -loop 1 -framerate 1 -i $imagePath `
            -i $audioPath `
            -filter_complex "[1:a]apad=whole_dur=$duration[a]" `
            -map 0:v -map "[a]" `
            -t $duration `
            -r 25 `
            -c:v libx264 -preset veryfast -tune stillimage -crf 29 `
            -pix_fmt yuv420p `
            -c:a aac -b:a 96k `
            $partPath

        if ($LASTEXITCODE -ne 0) {
            throw "ffmpeg failed while rendering slide $number."
        }
    }

    $portablePartPath = $partPath.Replace('\', '/')
    $concatLines.Add("file '$portablePartPath'")
}

$synthesizer.Dispose()
$concatPath = Join-Path $partsDir 'concat.txt'
$utf8WithoutBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllLines($concatPath, $concatLines, $utf8WithoutBom)

& ffmpeg -hide_banner -loglevel error -y `
    -f concat -safe 0 -i $concatPath `
    -c copy -movflags +faststart `
    $outputPath

if ($LASTEXITCODE -ne 0) {
    throw 'ffmpeg failed while joining the final video.'
}

$durationText = & ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 $outputPath
$sizeMb = [Math]::Round((Get-Item $outputPath).Length / 1MB, 2)
Write-Host "Generated: $outputPath"
Write-Host "Duration: $durationText seconds"
Write-Host "Size: $sizeMb MB"
