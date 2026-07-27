$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$sourcePath = Join-Path $projectRoot 'course/BioVault_Database_Masterclass.md'
$headerPath = Join-Path $projectRoot 'course/pandoc-header.tex'
$docxPath = Join-Path $projectRoot 'course/BioVault_Database_Masterclass.docx'
$pdfPath = Join-Path $projectRoot 'course/BioVault_Database_Masterclass.pdf'

Set-Location $projectRoot

pandoc $sourcePath `
    --from markdown+raw_tex `
    --resource-path=$projectRoot `
    --toc `
    --toc-depth=3 `
    --syntax-highlighting=tango `
    --metadata lang=en-US `
    --metadata title="BioVault Database Masterclass" `
    --output $docxPath
if ($LASTEXITCODE -ne 0) {
    throw "Pandoc failed while generating the DOCX course."
}

pandoc $sourcePath `
    --from markdown+raw_tex `
    --resource-path=$projectRoot `
    --toc `
    --toc-depth=3 `
    --syntax-highlighting=tango `
    --include-in-header=$headerPath `
    --pdf-engine=xelatex `
    --variable mainfont=Arial `
    --variable sansfont=Arial `
    --variable monofont=Consolas `
    --variable papersize=a4 `
    --variable geometry:margin=0.72in `
    --variable colorlinks=true `
    --variable linkcolor=blue `
    --variable urlcolor=teal `
    --metadata lang=en-US `
    --metadata title="BioVault Database Masterclass" `
    --output $pdfPath
if ($LASTEXITCODE -ne 0) {
    throw "Pandoc failed while generating the PDF course."
}

Write-Host 'Generated course/BioVault_Database_Masterclass.docx'
Write-Host 'Generated course/BioVault_Database_Masterclass.pdf'
