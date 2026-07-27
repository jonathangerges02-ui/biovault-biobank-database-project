$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Set-Location $projectRoot

pandoc report_source.md `
    --from markdown+raw_tex `
    --resource-path=. `
    --toc `
    --toc-depth=3 `
    --number-sections `
    --syntax-highlighting=tango `
    --metadata lang=en-US `
    --output report.docx

pandoc report_source.md `
    --from markdown+raw_tex `
    --resource-path=. `
    --toc `
    --toc-depth=3 `
    --number-sections `
    --syntax-highlighting=tango `
    --pdf-engine=xelatex `
    --variable mainfont=Arial `
    --variable sansfont=Arial `
    --variable monofont=Consolas `
    --variable papersize=a4 `
    --variable geometry:margin=0.72in `
    --variable colorlinks=true `
    --variable linkcolor=blue `
    --variable urlcolor=blue `
    --metadata lang=en-US `
    --output report.pdf

Write-Host 'Generated report.docx and report.pdf.'
