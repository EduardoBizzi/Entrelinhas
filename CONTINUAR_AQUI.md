# Continuar o projeto Biblioteca

Pasta atual: `C:\Users\Windows 10\Documents\ChatGPT\entrelinhas`.
Destino: somente Android. A pasta atual já possui permissão de escrita.

## Concluído em 12/11/2026

- Dependências reais completas resolvidas; `pubspec.lock` incluído.
- Análise estática sem diagnósticos.
- Oito arquivos de testes presentes; 38 testes aprovados na engine Flutter sem transporte por socket.
- Oito cenários adicionais de SQLite/sincronização e cinco de HTTP aprovados.
- Retry do SQLite offline, classificação de erros de rede e concorrência do controller corrigidos e testados.
- Calendário com `table_calendar` real testado: selecionar data, consultar livros locais, abrir registro, agendar e navegar entre meses.
- Projeto Firebase existente identificado: `biblioteca-2b8bf`. Padrão configurado nos scripts e `.firebaserc`.
- Sequência `scripts/finalizar_android.ps1` preparada para configurar FlutterFire, publicar regras e verificar/compilar após habilitar os serviços no Console.

## Firebase configurado em 23/11/2026

O app Android usa o pacote `br.edu.unicentro.biblioteca` no projeto `biblioteca-2b8bf`. O `google-services.json` foi conferido e incluído em `android/app/`. A CLI FlutterFire gerou `lib/firebase_options.dart`. O método E-mail/senha está habilitado no Console e o Firebase confirmou a publicação das regras e dos índices no banco `(default)`.

## Próximos passos

Abra o emulador `Medium_Phone` no Android Studio e, no PowerShell do Windows, execute da raiz do projeto:

```powershell
flutter run
```

Siga `docs/ROTEIRO_DE_TESTES.md` para testar login, CRUD e sincronização offline no dispositivo. Depois, capture as telas e gere o APK com `flutter build apk --release` antes de validar a instalação e disponibilizar o repositório remoto.

## Limitações desta sessão

O build release parou antes da compilação. O Gradle recebeu `Permission denied: connect` ao tentar baixar a distribuição, e a instalação em cache também falhou porque o Java não tinha acesso de escrita na pasta do plugin do Flutter. O emulador recebeu `Acesso negado` ao criar um arquivo de controle em `.android`. A análise de `lib`, `test` e `scripts` passou, assim como os 38 testes com `flutter test --no-pub` após o ajuste do cabeçalho do login em telas estreitas.

Os resultados e limites completos estão em `docs/VALIDACAO.md`.

Manter SQLite como fila durável e limpar somente a versão confirmada pelo servidor. Preservar as exclusões offline e as edições feitas durante o envio. O projeto tem Android como plataforma de entrega.
