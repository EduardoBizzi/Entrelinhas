# Entrelinhas

Aplicativo Android para organizar livros e acompanhar leituras.

Trabalho de Desenvolvimento de Aplicações Mobile da UNICENTRO, desenvolvido por Eduardo Bizzi e Pedro Castello.

## Funcionalidades

- Cadastro, login e recuperação de senha.
- Cadastro, busca, edição e exclusão de livros.
- Calendário e acompanhamento do progresso de leitura.
- Funcionamento offline e sincronização com o Firebase.
- Fotos pela câmera ou galeria e registro de localização.
- Busca de livros na Open Library.

## Tecnologias e bibliotecas

Desenvolvido em Flutter e Dart, com Firebase, SQLite e Open Library API.

- `firebase_core`, `firebase_auth` e `cloud_firestore` — integração com o Firebase.
- `sqflite`, `sqflite_common` e `path` — banco de dados local.
- `connectivity_plus` — monitoramento da conexão.
- `geolocator` e `url_launcher` — localização e mapas.
- `table_calendar`, `intl` e `flutter_localizations` — calendário, datas e idioma.
- `image_picker` e `path_provider` — fotos e arquivos.
- `http` — consumo da API externa.
- `uuid` — identificação única dos registros.

## Telas principais

Capturas do aplicativo em execução no emulador, com dados de teste.

| Login | Biblioteca | Agenda | Explorar |
| :---: | :---: | :---: | :---: |
| <img src="docs/screenshots/login.png" alt="Tela de login" width="200"> | <img src="docs/screenshots/biblioteca.png" alt="Biblioteca pessoal" width="200"> | <img src="docs/screenshots/agenda.png" alt="Agenda de leitura" width="200"> | <img src="docs/screenshots/explorar.png" alt="Pesquisa de livros" width="200"> |

## Como executar

Instale o Flutter e o SDK Android. Abra um emulador ou conecte um dispositivo Android.

```bash
flutter pub get
flutter run
```

O projeto já contém a configuração do Firebase. Para usar outro projeto, habilite a autenticação por e-mail e senha e crie um banco Firestore no Firebase Console. Com o Firebase CLI e o FlutterFire CLI instalados, execute:

```bash
flutterfire configure --project=ID_DO_PROJETO --platforms=android
firebase deploy --only firestore --project ID_DO_PROJETO
```

Para gerar o APK:

```bash
flutter build apk --release
```

## Estrutura

- `lib/` — código Dart, telas, serviços e dados.
- `android/` — configuração e recursos Android.
- `assets/` — imagem usada no aplicativo.
- `docs/screenshots/` — imagens das telas.
