param([switch]$SomenteVerificar)
$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath (Split-Path -Parent $PSScriptRoot)
function Run-Step([string]$Name, [scriptblock]$Command) {
  Write-Host $Name
  & $Command
  if ($LASTEXITCODE -ne 0) { throw "Falha: $Name" }
}
Run-Step 'Obtendo dependências...' { flutter pub get }
Run-Step 'Conferindo formatação...' { dart format --output=none --set-exit-if-changed lib test }
Run-Step 'Analisando código...' { flutter analyze }
Run-Step 'Executando testes...' { flutter test }
if ($SomenteVerificar) {
  Write-Host 'Verificações locais aprovadas. Firebase e roteiro Android exigem validação separada.'
  return
}
if (Select-String -LiteralPath 'lib/firebase_options.dart' -Pattern 'Firebase ainda não configurado' -Quiet) {
  throw 'Verificações locais aprovadas, mas falta configurar o Firebase: .\scripts\configurar_firebase.ps1'
}
Run-Step 'Compilando APK Android...' { flutter build apk --release }
Write-Host 'APK: build/app/outputs/flutter-apk/app-release.apk'
