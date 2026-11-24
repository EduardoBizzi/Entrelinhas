param([string]$ProjectId = 'biblioteca-2b8bf')
$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath (Split-Path -Parent $PSScriptRoot)
function Run-Step([string]$Name, [scriptblock]$Command) {
  Write-Host $Name
  & $Command
  if ($LASTEXITCODE -ne 0) { throw "Falha: $Name" }
}
foreach ($command in @('flutter','dart','firebase','flutterfire')) {
  if (-not (Get-Command $command -ErrorAction SilentlyContinue)) {
    throw "Comando $command não encontrado. Consulte a instalação no README."
  }
}
Run-Step 'Verificando acesso ao projeto Firebase...' { firebase projects:list }
Run-Step 'Instalando dependências...' { flutter pub get }
Run-Step 'Configurando o aplicativo Android com FlutterFire CLI...' {
  flutterfire configure --project=$ProjectId --platforms=android --android-package-name=br.edu.unicentro.biblioteca --out=lib/firebase_options.dart --yes
}
if (Select-String -LiteralPath 'lib/firebase_options.dart' -Pattern 'Firebase ainda não configurado' -Quiet) {
  throw 'O FlutterFire não gerou a configuração real. Confira o acesso ao projeto Firebase.'
}
Run-Step 'Gerando ícone do aplicativo...' { dart run flutter_launcher_icons }
Run-Step 'Gerando splash nativa...' { dart run flutter_native_splash:create }
Write-Host 'Configuração Android gerada. Habilite E-mail/senha e crie o Firestore no Console conforme README.'
Write-Host "Depois publique as regras: firebase deploy --only firestore --project $ProjectId"
