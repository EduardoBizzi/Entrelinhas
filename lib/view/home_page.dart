import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../controller/library_controller.dart';
import '../database/helper/record_helper.dart';
import '../database/model/reading_record.dart';
import '../service/auth_service.dart';
import '../service/connectivity_service.dart';
import '../service/firestore_service.dart';
import '../service/open_library_service.dart';
import '../service/photo_service.dart';
import '../utils/error_message.dart';
import '../widgets/brand_mark.dart';
import 'account_page.dart';
import 'calendar_page.dart';
import 'explore_page.dart';
import 'library_page.dart';
import 'record_detail_page.dart';
import 'record_form_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.user,
    required this.auth,
    required this.local,
  });
  final User user;
  final AuthService auth;
  final RecordHelper local;
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  late final LibraryController _controller;
  int _tab = 0;
  DateTime _calendarDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = LibraryController(
      userId: widget.user.uid,
      local: widget.local,
      remote: FirestoreService(),
      connectivity: ConnectivityService(),
    );
    unawaited(_controller.start());
    WidgetsBinding.instance.addPostFrameCallback((_) => _recoverPhoto());
  }

  Future<void> _recoverPhoto() async {
    try {
      final recovered = await PhotoService().recover(widget.user.uid);
      if (mounted && recovered != null) {
        await Navigator.push<String>(
          context,
          MaterialPageRoute(
            builder: (_) => RecordFormPage(
              controller: _controller,
              record: recovered.record,
              recoveredImage: recovered.imagePath,
            ),
          ),
        );
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
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_controller.synchronize());
    }
  }

  Future<void> _create({DateTime? date, BookResult? book}) async {
    var record = ReadingRecord.create(widget.user.uid, date: date);
    if (book != null) {
      record = record.copyWith(
        title: book.title,
        author: book.author,
        totalPages: book.pages,
        bookKey: book.key,
        coverUrl: book.coverUrl,
      );
    }
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => RecordFormPage(controller: _controller, record: record),
      ),
    );
    if (result != null && mounted) {
      setState(() => _tab = 0);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Livro salvo na sua biblioteca.')),
      );
    }
  }

  void _open(ReadingRecord record) => Navigator.push<void>(
    context,
    MaterialPageRoute(
      builder: (_) =>
          RecordDetailPage(controller: _controller, recordId: record.id),
    ),
  );

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _controller,
    builder: (context, _) => LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 850;
        final pages = IndexedStack(
          index: _tab,
          children: [
            LibraryPage(
              controller: _controller,
              name:
                  widget.user.displayName ??
                  widget.user.email?.split('@').first ??
                  'Leitor',
              onOpen: _open,
              onCreate: () => _create(),
            ),
            CalendarPage(
              controller: _controller,
              onCreate: (date) => _create(date: date),
              onOpen: _open,
              onSelected: (date) => setState(() => _calendarDay = date),
            ),
            ExplorePage(onAdd: (book) => _create(book: book)),
            AccountPage(
              user: widget.user,
              auth: widget.auth,
              controller: _controller,
            ),
          ],
        );
        return Scaffold(
          appBar: AppBar(
            title: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                BrandMark(size: 32),
                SizedBox(width: 10),
                Text(
                  'entrelinhas',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.8,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Sincronizar biblioteca',
                onPressed: _controller.synchronizing
                    ? null
                    : _controller.synchronize,
                icon: const Icon(Icons.sync),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Column(
            children: [
              _status(),
              if (_controller.cloudError != null ||
                  _controller.localError != null)
                MaterialBanner(
                  content: Text(
                    _controller.localError ?? _controller.cloudError!,
                  ),
                  leading: const Icon(Icons.info_outline),
                  actions: [
                    TextButton(
                      onPressed: _controller.synchronizing
                          ? null
                          : _controller.synchronize,
                      child: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              Expanded(
                child: Row(
                  children: [
                    if (wide)
                      NavigationRail(
                        selectedIndex: _tab,
                        onDestinationSelected: (index) =>
                            setState(() => _tab = index),
                        labelType: NavigationRailLabelType.all,
                        destinations: const [
                          NavigationRailDestination(
                            icon: Icon(Icons.auto_stories_outlined),
                            selectedIcon: Icon(Icons.auto_stories),
                            label: Text('Biblioteca'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.calendar_month_outlined),
                            selectedIcon: Icon(Icons.calendar_month),
                            label: Text('Agenda'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.explore_outlined),
                            selectedIcon: Icon(Icons.explore),
                            label: Text('Explorar'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.person_outline),
                            selectedIcon: Icon(Icons.person),
                            label: Text('Conta'),
                          ),
                        ],
                      ),
                    Expanded(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 900),
                          child: pages,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          floatingActionButton: _tab <= 1
              ? FloatingActionButton.extended(
                  onPressed: () =>
                      _create(date: _tab == 1 ? _calendarDay : null),
                  icon: const Icon(Icons.add),
                  label: Text(_tab == 1 ? 'Agendar leitura' : 'Novo livro'),
                )
              : null,
          bottomNavigationBar: wide
              ? null
              : NavigationBar(
                  selectedIndex: _tab,
                  onDestinationSelected: (index) =>
                      setState(() => _tab = index),
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.auto_stories_outlined),
                      selectedIcon: Icon(Icons.auto_stories),
                      label: 'Biblioteca',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.calendar_month_outlined),
                      selectedIcon: Icon(Icons.calendar_month),
                      label: 'Agenda',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.explore_outlined),
                      selectedIcon: Icon(Icons.explore),
                      label: 'Explorar',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.person_outline),
                      selectedIcon: Icon(Icons.person),
                      label: 'Conta',
                    ),
                  ],
                ),
        );
      },
    ),
  );

  Widget _status() {
    final pending = _controller.pendingCount;
    final message = _controller.synchronizing
        ? 'Sincronizando sua biblioteca...'
        : !_controller.connected
        ? 'Você está offline • $pending alterações aguardando envio'
        : pending > 0
        ? '$pending alterações salvas neste aparelho • aguardando confirmação'
        : _controller.cloudError != null
        ? 'Sua última cópia continua disponível'
        : _controller.fromCache
        ? 'Consultando sua biblioteca na nuvem...'
        : 'Biblioteca atualizada';
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
        color: _controller.connected
            ? const Color(0xFFE8EEE1)
            : const Color(0xFFF3E7D1),
        child: Row(
          children: [
            Icon(
              _controller.connected
                  ? Icons.cloud_outlined
                  : Icons.cloud_off_outlined,
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message, style: const TextStyle(fontSize: 11)),
            ),
          ],
        ),
      ),
    );
  }
}
