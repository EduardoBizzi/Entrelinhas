param([string]$ProjectId = 'biblioteca-2b8bf')
$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath (Split-Path -Parent $PSScriptRoot)

# Execute em um terminal com internet e acesso normal ao Android SDK.
# No Console, habilite E-mail/senha e crie o Firestore antes deste passo.
& (Join-Path $PSScriptRoot 'configurar_firebase.ps1') -ProjectId $ProjectId

Write-Host 'Publicando regras e índices do Firestore...'
firebase deploy --only firestore --project $ProjectId
if ($LASTEXITCODE -ne 0) {
  throw "Não foi possível publicar as regras. Confira o banco Firestore em https://console.firebase.google.com/project/$ProjectId/firestore"
}

& (Join-Path $PSScriptRoot 'verificar_e_compilar.ps1')
Write-Host 'APK compilado. Execute o roteiro docs/ROTEIRO_DE_TESTES.md no Android antes de entregar.'
