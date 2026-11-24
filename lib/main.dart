import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sqflite/sqflite.dart';
import 'database/helper/record_helper.dart';
import 'firebase_options.dart';
import 'service/auth_service.dart';
import 'theme/app_theme.dart';
import 'view/home_page.dart';
import 'view/login_page.dart';
import 'widgets/brand_mark.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const EntrelinhasApp());
}

/// Inicialização real, antes de liberar o acesso às telas.
Future<void> initializeServices() async {
  await initializeDateFormatting('pt_BR');
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );
}

class EntrelinhasApp extends StatelessWidget {
  const EntrelinhasApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Entrelinhas • Biblioteca',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    locale: const Locale('pt', 'BR'),
    supportedLocales: const [Locale('pt', 'BR')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    home: const _BootstrapPage(),
  );
}

class _BootstrapPage extends StatefulWidget {
  const _BootstrapPage();
  @override
  State<_BootstrapPage> createState() => _BootstrapPageState();
}

class _BootstrapPageState extends State<_BootstrapPage> {
  late Future<void> _initialization;
  final _local = RecordHelper(factory: databaseFactory);
  @override
  void initState() {
    super.initState();
    _initialization = initializeServices();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
    future: _initialization,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Scaffold(
          backgroundColor: AppTheme.forest,
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                BrandMark(size: 96),
                SizedBox(height: 24),
                Text(
                  'entrelinhas',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Toda leitura encontra seu lugar.',
                  style: TextStyle(color: Color(0xFFD4DECA)),
                ),
                SizedBox(height: 32),
                CircularProgressIndicator(color: Color(0xFFE2D2A9)),
              ],
            ),
          ),
        );
      }
      if (snapshot.hasError) {
        return Scaffold(
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(28),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const BrandMark(size: 72),
                      const SizedBox(height: 24),
                      const Text(
                        'Vamos conectar sua biblioteca',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Não foi possível inicializar o Firebase. Confira a configuração do projeto seguindo o README e execute novamente. O aplicativo utiliza autenticação e banco de dados reais.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: () => setState(
                          () => _initialization = initializeServices(),
                        ),
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }
      final auth = AuthService();
      return StreamBuilder(
        stream: auth.changes,
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (userSnapshot.hasError) {
            return Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Tentar carregar a sessão novamente'),
                ),
              ),
            );
          }
          final user = userSnapshot.data;
          return user == null
              ? LoginPage(auth: auth)
              : HomePage(
                  key: ValueKey(user.uid),
                  user: user,
                  auth: auth,
                  local: _local,
                );
        },
      );
    },
  );
}
