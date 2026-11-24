"""Empacota o fonte atual, incluindo alterações ainda não commitadas."""
from pathlib import Path
import subprocess
import zipfile

root = Path(__file__).resolve().parents[1]
output = root / "entrega/Entrelinhas_Biblioteca_Android_em_desenvolvimento.zip"
output.parent.mkdir(exist_ok=True)
listing = subprocess.run(
    ['git', 'ls-files', '--cached', '--others', '--exclude-standard', '-z'],
    cwd=root, check=True, capture_output=True,
).stdout.decode('utf-8')
allowed_roots = {'android', 'assets', 'docs', 'lib', 'scripts', 'test'}
allowed_files = {
    '.firebaserc', '.gitignore', '.metadata', 'analysis_options.yaml',
    'CONTINUAR_AQUI.md', 'README.md', 'firebase.json', 'firestore.indexes.json',
    'firestore.rules', 'pubspec.lock', 'pubspec.yaml',
}
sources = []
for name in sorted(set(listing.rstrip('\0').split('\0'))):
    if not name:
        continue
    relative = Path(name)
    if relative.parts[0] not in allowed_roots and name not in allowed_files:
        continue
    if any(part in {'.gradle', '.dart_tool', 'build', '__pycache__'} for part in relative.parts):
        continue
    if relative.name in {'local.properties', 'key.properties', '.env'} or relative.suffix in {'.jks', '.keystore', '.pyc'}:
        continue
    source = root / relative
    if not source.is_file():
        continue
    if not source.resolve().is_relative_to(root.resolve()):
        raise RuntimeError(f'Arquivo fora do projeto: {name}')
    sources.append((source, 'entrelinhas/' + relative.as_posix()))
required = {
    'entrelinhas/pubspec.yaml', 'entrelinhas/pubspec.lock', 'entrelinhas/lib/main.dart',
    'entrelinhas/README.md', 'entrelinhas/docs/REQUISITOS.md',
    'entrelinhas/test/sync_service_test.dart', 'entrelinhas/test/calendar_page_test.dart',
}
if not required.issubset({name for _, name in sources}):
    raise RuntimeError('Arquivo essencial ausente; nenhum ZIP novo foi escrito.')
with zipfile.ZipFile(output, 'w', compression=zipfile.ZIP_DEFLATED) as archive:
    for source, name in sources:
        archive.write(source, name)
with zipfile.ZipFile(output) as archive:
    names = archive.namelist()
    if not required.issubset(names):
        raise RuntimeError("Arquivo essencial ausente no ZIP.")
    forbidden = ("/.tooling/", "/.git/", "/.dart_tool/", "/build/", "firebase-tools.json")
    if any(any(pattern in name for pattern in forbidden) for name in names):
        raise RuntimeError("Arquivo privado ou temporário incluído no ZIP.")
    if any(name.startswith("entrelinhas/ios/") or name.startswith("entrelinhas/web/") or name.startswith("entrelinhas/windows/") for name in names):
        raise RuntimeError("Plataforma extra incluída no ZIP Android.")
    print(f"ZIP conferido: {len(names)} entradas; fonte Android atual, testes e documentação.")
print(output)
