import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:entrelinhas/service/auth_service.dart';
import 'package:entrelinhas/theme/app_theme.dart';
import 'package:entrelinhas/view/login_page.dart';

class FakeAuth extends AuthService {
  int logins = 0;
  int registrations = 0;
  String? recoveryEmail;
  Object? failure;
  Completer<void>? pendingLogin;
  @override
  Future<void> login(String email, String password) async {
    logins++;
    if (failure != null) throw failure!;
    await pendingLogin?.future;
  }

  @override
  Future<void> register(String name, String email, String password) async {
    registrations++;
  }

  @override
  Future<void> resetPassword(String email) async {
    recoveryEmail = email.trim();
  }
}

void main() {
  late FakeAuth auth;
  setUp(() => auth = FakeAuth());
  Future<void> open(
    WidgetTester tester, {
    Size size = const Size(390, 844),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('pt', 'BR'),
        supportedLocales: const [Locale('pt', 'BR')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: LoginPage(auth: auth),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text));
    await tester.tap(find.text(text));
    await tester.pump();
  }

  Future<void> fillLogin(WidgetTester tester) async {
    await tester.enterText(
      find.byKey(const ValueKey('auth_email')),
      'leitor@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('auth_password')),
      'senha-de-teste',
    );
  }

  testWidgets('não autentica quando os campos são inválidos', (tester) async {
    await open(tester);
    await tapText(tester, 'Entrar na biblioteca');
    expect(find.text('Informe um e-mail válido.'), findsOneWidget);
    expect(find.text('Use pelo menos 6 caracteres.'), findsOneWidget);
    expect(auth.logins, 0);
  });

  testWidgets('cadastro exige confirmação igual à senha', (tester) async {
    await open(tester);
    await tapText(tester, 'Ainda não tem conta? Cadastre-se aqui');
    await tester.enterText(
      find.byKey(const ValueKey('auth_name')),
      'Pessoa de Teste',
    );
    await fillLogin(tester);
    await tester.enterText(
      find.byKey(const ValueKey('auth_confirmation')),
      'outra-senha',
    );
    await tapText(tester, 'Criar minha conta');
    expect(find.text('As senhas precisam ser iguais.'), findsOneWidget);
    expect(auth.registrations, 0);
  });

  testWidgets('login em andamento apresenta loading e impede novo envio', (
    tester,
  ) async {
    auth.pendingLogin = Completer<void>();
    await open(tester);
    await fillLogin(tester);
    await tapText(tester, 'Entrar na biblioteca');
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('auth_submit')))
          .onPressed,
      isNull,
    );
    expect(auth.logins, 1);
    auth.pendingLogin!.complete();
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('erro real de credencial é traduzido para a interface', (
    tester,
  ) async {
    auth.failure = FirebaseAuthException(code: 'invalid-credential');
    await open(tester);
    await fillLogin(tester);
    await tapText(tester, 'Entrar na biblioteca');
    await tester.pumpAndSettle();
    expect(
      find.text('E-mail ou senha inválidos. Confira e tente novamente.'),
      findsOneWidget,
    );
  });

  testWidgets('recuperação envia e-mail e informa o resultado', (tester) async {
    await open(tester);
    await tapText(tester, 'Recuperar senha');
    await tester.enterText(
      find.byKey(const ValueKey('auth_email')),
      'leitor@example.com',
    );
    await tapText(tester, 'Enviar instruções');
    await tester.pumpAndSettle();
    expect(auth.recoveryEmail, 'leitor@example.com');
    expect(
      find.textContaining('receberá as instruções de recuperação'),
      findsOneWidget,
    );
  });

  for (final size in [const Size(320, 568), const Size(1024, 768)]) {
    testWidgets('login sem overflow em ${size.width.toInt()} pixels', (
      tester,
    ) async {
      await open(tester, size: size);
      expect(tester.takeException(), isNull);
      await tapText(tester, 'Ainda não tem conta? Cadastre-se aqui');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
