import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../controller/library_controller.dart';
import '../database/model/reading_record.dart';
import '../service/photo_service.dart';
import '../utils/error_message.dart';
import '../widgets/book_cover.dart';
import 'record_form_page.dart';

class RecordDetailPage extends StatefulWidget {
  const RecordDetailPage({
    super.key,
    required this.controller,
    required this.recordId,
  });
  final LibraryController controller;
  final String recordId;
  @override
  State<RecordDetailPage> createState() => _RecordDetailPageState();
}

class _RecordDetailPageState extends State<RecordDetailPage> {
  Future<String?>? _photo;
  bool _deleting = false;
  @override
  void initState() {
    super.initState();
    _reloadPhoto();
  }

  void _reloadPhoto() {
    _photo = PhotoService().existing(widget.controller.userId, widget.recordId);
  }

  Future<void> _delete(ReadingRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir da biblioteca?'),
        content: Text(
          '“${record.title}” será removido. Se você estiver offline, a exclusão será enviada quando a conexão voltar.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _deleting = true);
    try {
      await widget.controller.delete(record);
      await PhotoService().remove(record.userId, record.id);
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage(error))));
      }
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  Future<void> _openMap(ReadingRecord record) async {
    final uri = Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': '${record.latitude},${record.longitude}',
    });
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw const AppException('Não foi possível abrir o mapa.');
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage(error))));
      }
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) {
      final matches = widget.controller.records.where(
        (record) => record.id == widget.recordId,
      );
      final record = matches.isEmpty ? null : matches.first;
      if (record == null) {
        return Scaffold(
          appBar: AppBar(title: const Text('Livro')),
          body: const Center(
            child: Text('Este livro foi removido da biblioteca.'),
          ),
        );
      }
      return Scaffold(
        appBar: AppBar(
          title: const Text('Na sua biblioteca'),
          actions: [
            IconButton(
              tooltip: 'Editar livro',
              onPressed: _deleting
                  ? null
                  : () async {
                      final result = await Navigator.push<String>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RecordFormPage(
                            controller: widget.controller,
                            record: record,
                            editing: true,
                          ),
                        ),
                      );
                      if (result != null && context.mounted) {
                        setState(_reloadPhoto);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Livro atualizado.')),
                        );
                      }
                    },
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              tooltip: 'Excluir livro',
              onPressed: _deleting ? null : () => _delete(record),
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
        body: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BookCover(url: record.coverUrl, width: 88, height: 126),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            record.title,
                            style: const TextStyle(
                              fontSize: 26,
                              height: 1.1,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(record.author),
                          const SizedBox(height: 12),
                          Chip(
                            label: Text(record.status.label),
                            avatar: const Icon(
                              Icons.bookmark_outline,
                              size: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.event_outlined),
                    title: const Text('Leitura agendada'),
                    subtitle: Text(
                      DateFormat(
                        "dd 'de' MMMM 'de' yyyy • HH:mm",
                        'pt_BR',
                      ).format(record.eventAt),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                if (record.totalPages > 0) ...[
                  Text(
                    '${record.pages} de ${record.totalPages} páginas • ${(record.pages * 100 / record.totalPages).round()}%',
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: (record.pages / record.totalPages).clamp(0, 1),
                    minHeight: 7,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  const SizedBox(height: 24),
                ],
                const Text(
                  'Entre suas anotações',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                SelectableText(record.description),
                const SizedBox(height: 24),
                if (record.hasLocation) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            record.place.isEmpty
                                ? 'Seu lugar de leitura'
                                : record.place,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SelectableText(
                            'Latitude: ${record.latitude!.toStringAsFixed(6)}\nLongitude: ${record.longitude!.toStringAsFixed(6)}',
                          ),
                          TextButton.icon(
                            onPressed: () => _openMap(record),
                            icon: const Icon(Icons.map_outlined),
                            label: const Text('Abrir no mapa'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ] else if (record.place.isNotEmpty)
                  ListTile(
                    leading: const Icon(Icons.place_outlined),
                    title: Text(record.place),
                  ),
                FutureBuilder<String?>(
                  future: _photo,
                  builder: (context, snapshot) {
                    if (snapshot.data == null) return const SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Seu registro em imagem',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Image.file(
                            File(snapshot.data!),
                            height: 240,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) =>
                                const Text('Foto indisponível neste aparelho.'),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Foto guardada somente neste aparelho.',
                          style: TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 24),
                      ],
                    );
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    record.synced
                        ? Icons.cloud_done_outlined
                        : Icons.cloud_upload_outlined,
                  ),
                  title: Text(
                    record.synced
                        ? 'Sincronizado com sua conta'
                        : 'Alteração salva neste aparelho',
                  ),
                  subtitle: Text(
                    record.synced
                        ? 'Disponível na nuvem e na última cópia deste aparelho.'
                        : 'Será enviada quando o servidor estiver disponível.',
                  ),
                ),
                Text(
                  'Adicionado em ${DateFormat('dd/MM/yyyy HH:mm').format(record.createdAt.toLocal())}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 28),
                OutlinedButton.icon(
                  onPressed: _deleting ? null : () => _delete(record),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Excluir da biblioteca'),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
