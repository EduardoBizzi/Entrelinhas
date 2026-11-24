# Entrelinhas

Aplicativo Android para organizar livros e acompanhar leituras.

Trabalho de Desenvolvimento de Aplicações Mobile da UNICENTRO, desenvolvido por Eduardo Bizzi.

## Funcionalidades

- Cadastro, login e recuperação de senha.
- Cadastro, busca, edição e exclusão de livros.
- Calendário e acompanhamento do progresso de leitura.
- Funcionamento offline e sincronização com o Firebase.
- Fotos pela câmera ou galeria e registro de localização.
- Busca de livros na Open Library.

## Tecnologias

Flutter, Dart, Firebase Authentication, Firestore, SQLite, Geolocator, Table Calendar, Image Picker e Open Library API.

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
