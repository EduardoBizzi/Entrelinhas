# Registro de validação — 12/11/2026

Projeto atual: `C:\Users\Windows 10\Documents\ChatGPT\entrelinhas`. Tema **Biblioteca**, somente **Android**. A conferência segue as 18 páginas de `Trabalho Final de Mobile.pdf`.

## Confirmado nesta retomada

- Acesso de escrita à pasta atual e conferência do código, Android e documentação.
- Resolução completa com `flutter pub get --offline`, reutilizando pacotes reais instalados. `cloud_firestore`, `geolocator` e `table_calendar` estão disponíveis; o `pubspec.lock` foi gerado pela ferramenta.
- `flutter analyze --no-pub` aprovado sem diagnósticos. Após as correções e inclusão dos testes, `dart analyze lib test scripts` também passou.
- Recuperação dos seis arquivos de testes anteriores, ausentes nesta cópia. Foram acrescentados testes de recuperação do controller e do calendário real.
- Correção do retry: uma falha de leitura SQLite pode ser recuperada mesmo offline; erro de conectividade não é apresentado como falha do banco local; a verificação assíncrona de rede participa do bloqueio de sincronização concorrente.
- Inicialização Firebase repetida evita recriar uma instância já inicializada.
- Projeto `biblioteca-2b8bf` identificado no Firebase Console e definido como padrão dos scripts e do `.firebaserc`. O cadastro Android foi confirmado com o pacote `br.edu.unicentro.biblioteca`; Gradle, MainActivity e script foram alinhados a ele. O arquivo JSON e as opções reais ainda precisam ser obtidos.
- Scripts de configuração e compilação atualizados. `finalizar_android.ps1` reúne FlutterFire, publicação das regras e verificação/compilação, após habilitar os serviços no Console.

## Testes executados

Os **38 testes dos oito arquivos em `test/` passaram**, usando fontes recompilados nesta retomada e a engine Flutter local. O runner utiliza o backend `test_api` sem o transporte de testes por socket, bloqueado nesta sessão. Os corpos de teste, matchers, setup/teardown e `WidgetTester` são os mesmos arquivos do projeto.

| Grupo | Aprovados |
| --- | ---: |
| SQLite e sincronização | 14 |
| Modelo e validadores | 2 |
| API com HTTP controlado | 5 |
| Combinação de cache e pendências | 3 |
| Recuperação do controller e concorrência | 3 |
| Calendário real: registros por dia, seleção, abertura, agendamento e mudança de mês | 2 |
| Autenticação: formulário, erros, carregamento e layouts | 7 |
| Busca: respostas antigas e seleção de resultados | 2 |
| **Total** | **38** |

O log limpo está em `docs/RESULTADOS_TESTES.txt`. O SQLite desses testes é real, por FFI. Firebase e HTTP são controlados; estes resultados não validam login, regras publicadas ou sincronização com o servidor real.

Também passaram os oito cenários de `scripts/verificar_offline.dart` e os cinco cenários HTTP de `scripts/verificar_api.dart`. Incluem persistência após reinício, exclusão offline, ACK antes da limpeza, edição durante envio, isolamento de contas, ausência de duplicações e erros de rede/JSON.

As três imagens do README continuam sendo prévias renderizadas de widgets, não capturas Android. GPS, câmera/galeria, inicialização completa e sessão Firebase precisam ser conferidos no dispositivo.

## Bloqueios concretos

| Operação | Resultado observado |
| --- | --- |
| Firebase CLI com sessão já autenticada | Falha de DNS/rede ao acessar os serviços Google (`ENOTFOUND`). Nenhuma configuração remota foi concluída. |
| `flutter test --no-pub` convencional | O processo de teste não conectou ao runner em `127.0.0.1`, erro de socket 10057. A suíte foi executada pela engine sem esse transporte, conforme explicado acima. |
| `flutter devices` e ADB | O daemon ADB não conseguiu iniciar/conectar; não foi possível acessar o emulador. |
| Compilação Android release via Gradle | O Gradle iniciou o daemon, mas o cliente não conseguiu conectar ao processo local. O build não chegou a compilar o aplicativo. |

A permissão da pasta está funcionando. Os bloqueios acima são de rede/comunicação entre processos, independentes da gravação dos arquivos do projeto.

Existe um `app-debug.apk` anterior em `build/`; ele não foi produzido nem validado nesta retomada e não é uma entrega final. Não foi gerado APK release atualizado.

## Atualização — 23/11/2026

O aplicativo Android `br.edu.unicentro.biblioteca` foi configurado no projeto real `biblioteca-2b8bf`. A CLI FlutterFire gerou `lib/firebase_options.dart`. O ID do app corresponde ao `google-services.json` do módulo Android. O Console exibiu E-mail/senha habilitado e o Firebase CLI confirmou a compilação e a publicação de `firestore.rules` e dos índices no banco `(default)`.

`dart analyze lib test scripts` passou sem diagnósticos. A primeira execução de `flutter test --no-pub` detectou um estouro horizontal no cabeçalho do login a 320 pixels. Após o ajuste, a mesma suíte passou com 38 testes.

A compilação release tentou baixar o Gradle e recebeu `Permission denied: connect`. A execução com o Gradle em cache também falhou porque o Java não tinha acesso de escrita na pasta do plugin do Flutter. O `Medium_Phone` encontrou `Acesso negado` ao criar seu arquivo de controle em `.android`. A execução do app e o teste de login e sincronização no Android seguem pendentes.

## Pendências para entrega

1. Abrir o `Medium_Phone` no Android Studio e iniciar o aplicativo com `flutter run` no PowerShell do Windows.
2. Executar `docs/ROTEIRO_DE_TESTES.md` no Android e conferir os documentos no Firestore e a limpeza da fila SQLite.
3. Gerar o APK com `flutter build apk --release`, testar a instalação, inserir capturas reais e disponibilizar os commits em repositório remoto com acesso ao professor.

**Estado atual:** Firebase configurado, regras publicadas e análise estática aprovada. Teste Android, APK e repositório remoto pendentes.
