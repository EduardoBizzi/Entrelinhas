import 'package:flutter/material.dart';
import '../controller/library_controller.dart';
import '../database/model/reading_record.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/record_card.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({
    super.key,
    required this.controller,
    required this.name,
    required this.onOpen,
    required this.onCreate,
  });
  final LibraryController controller;
  final String name;
  final ValueChanged<ReadingRecord> onOpen;
  final VoidCallback onCreate;
  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  ReadingStatus? _filter;
  String _search = '';
  final _searchController = TextEditingController();
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final all = widget.controller.records;
    final records = all
        .where(
          (record) =>
              (_filter == null || record.status == _filter) &&
              '${record.title} ${record.author}'.toLowerCase().contains(
                _search,
              ),
        )
        .toList();
    return RefreshIndicator(
      onRefresh: widget.controller.synchronize,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.forest,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SEU ESPAÇO DE LEITURA',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .7),
                    fontSize: 10,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Olá, ${widget.name.split(' ').first}.',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Cada livro, uma nova descoberta.',
                  style: TextStyle(color: Color(0xFFE2E7D9)),
                ),
                const SizedBox(height: 22),
                Wrap(
                  spacing: 24,
                  runSpacing: 14,
                  children: [
                    _stat('${all.length}', 'na biblioteca'),
                    _stat(
                      '${all.where((item) => item.status == ReadingStatus.reading).length}',
                      'em leitura',
                    ),
                    _stat(
                      '${all.where((item) => item.status == ReadingStatus.finished).length}',
                      'concluídos',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Minha biblioteca',
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -.5,
                ),
              ),
              IconButton(
                onPressed: widget.onCreate,
                tooltip: 'Cadastrar livro',
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Filtrar por título ou autor',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) =>
                setState(() => _search = value.trim().toLowerCase()),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              ChoiceChip(
                label: const Text('Todos'),
                selected: _filter == null,
                onSelected: (_) => setState(() => _filter = null),
              ),
              for (final status in ReadingStatus.values)
                ChoiceChip(
                  label: Text(status.label),
                  selected: _filter == status,
                  onSelected: (_) => setState(() => _filter = status),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (widget.controller.loading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (records.isEmpty)
            EmptyState(
              icon: Icons.auto_stories_outlined,
              title: all.isEmpty
                  ? 'Sua estante está esperando'
                  : 'Nenhum livro encontrado',
              message: all.isEmpty
                  ? 'Cadastre um livro ou descubra novos títulos na aba Explorar.'
                  : 'Experimente outro filtro ou título.',
              action: all.isEmpty
                  ? FilledButton.icon(
                      onPressed: widget.onCreate,
                      icon: const Icon(Icons.add),
                      label: const Text('Cadastrar primeiro livro'),
                    )
                  : null,
            )
          else
            for (final record in records)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: RecordCard(
                  record: record,
                  onTap: () => widget.onOpen(record),
                ),
              ),
        ],
      ),
    );
  }

  Widget _stat(String value, String label) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        value,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 25,
          fontWeight: FontWeight.w700,
        ),
      ),
      Text(
        label,
        style: const TextStyle(color: Color(0xFFD3DDCF), fontSize: 11),
      ),
    ],
  );
}
