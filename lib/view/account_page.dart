import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../controller/library_controller.dart';
import '../service/auth_service.dart';
import '../utils/error_message.dart';
import '../widgets/brand_mark.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({
    super.key,
    required this.user,
    required this.auth,
    required this.controller,
  });
  final User user;
  final AuthService auth;
  final LibraryController controller;
  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  bool _busy = false;
  Future<void> _logout() async {
    if (widget.controller.pendingCount > 0) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Sair com alterações pendentes?'),
          content: const Text(
            'As alterações continuarão guardadas neste aparelho e serão enviadas quando você entrar novamente nesta mesma conta. Não desinstale nem limpe os dados do aplicativo antes de sincronizar.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Continuar aqui'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Sair da conta'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }
    setState(() => _busy = true);
    try {
      await widget.auth.logout();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage(error))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 80),
      children: [
        const Text(
          'Sua conta',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 26,
                  child: Text(
                    (widget.user.displayName?.trim().isNotEmpty == true
                            ? widget.user.displayName!
                            : widget.user.email ?? 'L')[0]
                        .toUpperCase(),
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  widget.user.displayName ?? 'Leitor',
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(widget.user.email ?? ''),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Sua biblioteca acompanha você',
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 14),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.cloud_upload_outlined),
                title: Text(
                  '${controller.pendingCount} alterações aguardando envio',
                ),
                subtitle: Text(
                  '${controller.pendingDeletions} exclusões pendentes • gravadas neste aparelho',
                ),
              ),
              ListTile(
                leading: const Icon(Icons.cloud_done_outlined),
                title: const Text('Última sincronização nesta sessão'),
                subtitle: Text(
                  controller.lastSync == null
                      ? 'Nenhum envio confirmado nesta sessão.'
                      : DateFormat(
                          'dd/MM/yyyy HH:mm:ss',
                        ).format(controller.lastSync!),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: controller.synchronizing
                        ? null
                        : controller.synchronize,
                    icon: const Icon(Icons.sync),
                    label: Text(
                      controller.synchronizing
                          ? 'Sincronizando...'
                          : 'Sincronizar agora',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Você pode cadastrar, editar e excluir sem internet. Livros já consultados continuam na última cópia disponível; as alterações pendentes ficam guardadas até o servidor confirmar o envio.',
        ),
        const SizedBox(height: 12),
        const Text(
          'A busca na Open Library e o primeiro acesso à conta precisam de internet. As fotos escolhidas ficam somente neste aparelho, uma por livro.',
        ),
        const SizedBox(height: 28),
        OutlinedButton.icon(
          onPressed: _busy ? null : _logout,
          icon: const Icon(Icons.logout),
          label: Text(_busy ? 'Saindo...' : 'Encerrar sessão'),
        ),
        const SizedBox(height: 32),
        const Row(
          children: [
            BrandMark(size: 38),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Entrelinhas 1.0\nBiblioteca pessoal e agenda de leitura',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
