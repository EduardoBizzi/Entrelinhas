import 'package:flutter/material.dart';
import '../service/auth_service.dart';
import '../theme/app_theme.dart';
import '../utils/error_message.dart';
import '../utils/validators.dart';
import '../widgets/brand_mark.dart';

enum AuthMode { login, register, recover }

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.auth});
  final AuthService auth;
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  AuthMode _mode = AuthMode.login;
  bool _busy = false;
  bool _hidePassword = true;
  String? _message;
  bool _success = false;

  void _changeMode(AuthMode mode) {
    setState(() {
      _mode = mode;
      _message = null;
      _success = false;
      _password.clear();
      _confirmation.clear();
      _form.currentState?.reset();
    });
  }

  Future<void> _submit() async {
    if (_busy || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      switch (_mode) {
        case AuthMode.login:
          await widget.auth.login(_email.text, _password.text);
        case AuthMode.register:
          await widget.auth.register(_name.text, _email.text, _password.text);
        case AuthMode.recover:
          await widget.auth.resetPassword(_email.text);
          if (mounted) {
            setState(() {
              _success = true;
              _message =
                  'Se houver uma conta para este e-mail, você receberá as instruções de recuperação. Confira também o spam.';
            });
          }
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _success = false;
          _message = errorMessage(error);
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    for (final controller in [_name, _email, _password, _confirmation]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = switch (_mode) {
      AuthMode.login => 'Sua próxima página\ncomeça aqui.',
      AuthMode.register => 'Um lugar para\nsuas histórias.',
      AuthMode.recover => 'Vamos recuperar\nseu acesso.',
    };
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: AutofillGroup(
                child: Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Row(
                        children: [
                          BrandMark(size: 48),
                          SizedBox(width: 12),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'entrelinhas',
                                  style: TextStyle(
                                    fontSize: 25,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.forest,
                                    letterSpacing: -.8,
                                  ),
                                ),
                                Text(
                                  'BIBLIOTECA PESSOAL',
                                  style: TextStyle(
                                    fontSize: 10,
                                    letterSpacing: 2.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 34,
                          height: 1.12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.forest,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _mode == AuthMode.recover
                            ? 'Informe o e-mail da sua conta para receber o link de redefinição.'
                            : 'Organize seus livros, reserve tempo para ler e guarde suas descobertas.',
                      ),
                      const SizedBox(height: 28),
                      if (_mode == AuthMode.register) ...[
                        TextFormField(
                          key: const ValueKey('auth_name'),
                          controller: _name,
                          decoration: const InputDecoration(
                            labelText: 'Nome completo',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: Validators.fullName,
                          textCapitalization: TextCapitalization.words,
                          autofillHints: const [AutofillHints.name],
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 14),
                      ],
                      TextFormField(
                        key: const ValueKey('auth_email'),
                        controller: _email,
                        decoration: const InputDecoration(
                          labelText: 'E-mail',
                          prefixIcon: Icon(Icons.alternate_email),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: Validators.email,
                        autofillHints: const [AutofillHints.email],
                        autocorrect: false,
                        textInputAction: _mode == AuthMode.recover
                            ? TextInputAction.done
                            : TextInputAction.next,
                        onFieldSubmitted: (_) {
                          if (_mode == AuthMode.recover) _submit();
                        },
                      ),
                      if (_mode != AuthMode.recover) ...[
                        const SizedBox(height: 14),
                        TextFormField(
                          key: const ValueKey('auth_password'),
                          controller: _password,
                          obscureText: _hidePassword,
                          validator: Validators.password,
                          autofillHints: [
                            _mode == AuthMode.register
                                ? AutofillHints.newPassword
                                : AutofillHints.password,
                          ],
                          decoration: InputDecoration(
                            labelText: 'Senha',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              tooltip: _hidePassword
                                  ? 'Mostrar senha'
                                  : 'Ocultar senha',
                              icon: Icon(
                                _hidePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed: () => setState(
                                () => _hidePassword = !_hidePassword,
                              ),
                            ),
                          ),
                          onFieldSubmitted: (_) {
                            if (_mode == AuthMode.login) _submit();
                          },
                        ),
                      ],
                      if (_mode == AuthMode.register) ...[
                        const SizedBox(height: 14),
                        TextFormField(
                          key: const ValueKey('auth_confirmation'),
                          controller: _confirmation,
                          obscureText: _hidePassword,
                          decoration: const InputDecoration(
                            labelText: 'Confirme a senha',
                            prefixIcon: Icon(Icons.lock_outline),
                          ),
                          validator: (value) => value == _password.text
                              ? null
                              : 'As senhas precisam ser iguais.',
                          onFieldSubmitted: (_) => _submit(),
                        ),
                      ],
                      if (_message != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 18),
                          child: Semantics(
                            liveRegion: true,
                            child: Text(
                              _message!,
                              style: TextStyle(
                                color: _success
                                    ? AppTheme.forest
                                    : Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),
                      FilledButton(
                        key: const ValueKey('auth_submit'),
                        onPressed: _busy ? null : _submit,
                        child: _busy
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(switch (_mode) {
                                AuthMode.login => 'Entrar na biblioteca',
                                AuthMode.register => 'Criar minha conta',
                                AuthMode.recover => 'Enviar instruções',
                              }),
                      ),
                      if (_mode == AuthMode.login) ...[
                        TextButton(
                          onPressed: _busy
                              ? null
                              : () => _changeMode(AuthMode.recover),
                          child: const Text('Recuperar senha'),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: _busy
                              ? null
                              : () => _changeMode(AuthMode.register),
                          child: const Text(
                            'Ainda não tem conta? Cadastre-se aqui',
                          ),
                        ),
                      ] else
                        TextButton(
                          onPressed: _busy
                              ? null
                              : () => _changeMode(AuthMode.login),
                          child: const Text('Voltar para o login'),
                        ),
                      const SizedBox(height: 28),
                      const Text(
                        'Seus livros e anotações, no seu ritmo.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF68746D),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
