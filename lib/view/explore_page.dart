import 'package:flutter/material.dart';
import '../service/open_library_service.dart';
import '../utils/error_message.dart';
import '../widgets/book_cover.dart';
import '../widgets/empty_state.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key, required this.onAdd, this.service});
  final ValueChanged<BookResult> onAdd;
  final OpenLibraryService? service;
  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  final _query = TextEditingController();
  late final OpenLibraryService _service;
  final List<BookResult> _books = [];
  bool _busy = false;
  bool _searched = false;
  String _term = '';
  String? _error;
  int _page = 0;
  int _total = 0;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? OpenLibraryService();
  }

  void _clear() {
    ++_generation;
    setState(() {
      _query.clear();
      _books.clear();
      _term = '';
      _error = null;
      _page = 0;
      _total = 0;
      _busy = false;
      _searched = false;
    });
  }

  Future<void> _search({bool more = false}) async {
    if (_busy && more) return;
    final term = more ? _term : _query.text.trim();
    if (term.isEmpty) {
      setState(() => _error = 'Digite um livro, autor ou assunto.');
      return;
    }
    FocusScope.of(context).unfocus();
    final generation = ++_generation;
    final page = more ? _page + 1 : 1;
    setState(() {
      _busy = true;
      _error = null;
      if (!more) {
        _books.clear();
        _term = term;
      }
    });
    try {
      final result = await _service.search(term, page: page);
      if (!mounted || generation != _generation) return;
      setState(() {
        _books.addAll(result.books);
        _page = page;
        _total = result.total;
        _searched = true;
      });
    } catch (error) {
      if (mounted && generation == _generation) {
        setState(() => _error = errorMessage(error));
      }
    } finally {
      if (mounted && generation == _generation) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _query.dispose();
    _service.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
    children: [
      const Text(
        'Encontre sua\npróxima história.',
        style: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w700,
          height: 1.1,
          letterSpacing: -.8,
        ),
      ),
      const SizedBox(height: 10),
      const Text(
        'Busque na Open Library e leve seus favoritos para a biblioteca.',
      ),
      const SizedBox(height: 22),
      TextField(
        controller: _query,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          labelText: 'Título, autor ou assunto',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: IconButton(
            tooltip: 'Limpar pesquisa',
            onPressed: _clear,
            icon: const Icon(Icons.close),
          ),
        ),
        onSubmitted: (_) => _search(),
      ),
      const SizedBox(height: 12),
      FilledButton.icon(
        onPressed: _busy ? null : () => _search(),
        icon: const Icon(Icons.search),
        label: const Text('Pesquisar livros'),
      ),
      if (_error != null) ...[
        const SizedBox(height: 16),
        Semantics(
          liveRegion: true,
          child: Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
        TextButton(
          onPressed: _busy ? null : () => _search(more: _books.isNotEmpty),
          child: const Text('Tentar novamente'),
        ),
      ],
      const SizedBox(height: 18),
      if (_books.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Text(
            '${_books.length} de $_total resultados',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      for (final book in _books)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BookCover(url: book.coverUrl, width: 62, height: 90),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          book.title,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(book.author),
                        if (book.year != null)
                          Text(
                            'Primeira publicação: ${book.year}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: () => widget.onAdd(book),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Adicionar à biblioteca'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      if (_busy)
        const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        )
      else if (_books.isNotEmpty && _books.length < _total)
        OutlinedButton(
          onPressed: () => _search(more: true),
          child: const Text('Carregar mais livros'),
        ),
      if (!_busy && _books.isEmpty && _error == null)
        EmptyState(
          icon: Icons.travel_explore,
          title: _searched
              ? 'Nenhum resultado por aqui'
              : 'Uma biblioteca de possibilidades',
          message: _searched
              ? 'Tente outro título, autor ou assunto.'
              : 'Digite uma busca para explorar o catálogo. É necessário ter internet para pesquisar.',
        ),
    ],
  );
}
