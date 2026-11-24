import 'dart:async';
import 'package:flutter/foundation.dart';
import '../database/helper/record_helper.dart';
import '../database/model/reading_record.dart';
import '../service/connectivity_service.dart';
import '../service/remote_records.dart';
import '../service/sync_service.dart';
import '../utils/error_message.dart';

class LibraryController extends ChangeNotifier {
  LibraryController({
    required this.userId,
    required this.local,
    required this.remote,
    required this.connectivity,
  }) : sync = SyncService(local: local, remote: remote);

  final String userId;
  final RecordHelper local;
  final RemoteRecords remote;
  final ConnectivityService connectivity;
  final SyncService sync;
  Map<String, ReadingRecord> _cloud = {};
  List<ReadingRecord> _pending = [];
  StreamSubscription<RemoteSnapshot>? _remoteSubscription;
  StreamSubscription<bool>? _networkSubscription;
  Timer? _retry;
  bool _disposed = false;
  bool loading = true;
  bool connected = false;
  bool synchronizing = false;
  bool fromCache = true;
  String? cloudError;
  String? localError;
  DateTime? lastSync;

  int get pendingCount => _pending.length;
  int get pendingDeletions => _pending.where((item) => item.isDeleted).length;
  List<ReadingRecord> get records => merge(_cloud.values, _pending);

  /// A fila SQLite sempre prevalece sobre o cache remoto, inclusive exclusões.
  static List<ReadingRecord> merge(
    Iterable<ReadingRecord> cloud,
    Iterable<ReadingRecord> pending,
  ) {
    final merged = {for (final record in cloud) record.id: record};
    for (final record in pending) {
      if (record.isDeleted) {
        merged.remove(record.id);
      } else {
        merged[record.id] = record;
      }
    }
    return merged.values.toList()
      ..sort((a, b) => a.eventAt.compareTo(b.eventAt));
  }

  Future<void> start() async {
    try {
      await _loadPending();
    } catch (_) {
      // A mensagem é registrada por _loadPending e pode ser recuperada no retry.
    }
    try {
      connected = await connectivity.check();
    } catch (error) {
      cloudError = errorMessage(error);
    }
    if (_disposed) return;
    loading = false;
    _remoteSubscription = remote
        .watch(userId)
        .listen(
          (snapshot) {
            if (_disposed) return;
            _cloud = {for (final record in snapshot.records) record.id: record};
            fromCache = snapshot.fromCache;
            if (!snapshot.fromCache) cloudError = null;
            _notify();
          },
          onError: (Object error) {
            cloudError = errorMessage(error);
            _notify();
          },
        );
    _networkSubscription = connectivity.changes.listen((available) {
      connected = available;
      _notify();
      if (available) unawaited(synchronize());
    }, onError: (Object _) {});
    // Wi-Fi não comprova internet: só o ACK do Firestore confirma o envio.
    _retry = Timer.periodic(const Duration(seconds: 30), (_) {
      if (connected && pendingCount > 0) unawaited(synchronize());
    });
    _notify();
    unawaited(synchronize());
  }

  Future<void> _loadPending() async {
    try {
      _pending = await local.pending(userId);
      localError = null;
    } catch (error) {
      localError = errorMessage(error);
      rethrow;
    }
  }

  Future<void> save(ReadingRecord record) async {
    if (record.userId != userId) {
      throw const AppException('Este registro pertence a outra conta.');
    }
    await local.save(record.changed());
    await _loadPending();
    _notify();
    unawaited(synchronize());
  }

  Future<void> delete(ReadingRecord record) async {
    if (record.userId != userId) {
      throw const AppException('Este registro pertence a outra conta.');
    }
    await local.delete(record);
    await _loadPending();
    _notify();
    unawaited(synchronize());
  }

  Future<void> synchronize() async {
    if (_disposed || synchronizing) return;
    synchronizing = true;
    _notify();
    try {
      // Recupera também uma leitura SQLite que falhou ao abrir o aplicativo,
      // mesmo sem rede. O botão de tentar novamente deve reparar ambos os casos.
      await _loadPending();
      connected = await connectivity.check();
      if (!connected || _disposed) {
        return;
      }
      await sync.synchronize(
        userId,
        connected: () => connected && !_disposed,
        onAcknowledged: (sent) async {
          if (sent.isDeleted) {
            _cloud.remove(sent.id);
          } else {
            _cloud[sent.id] = sent.copyWith(synced: true);
          }
          await _loadPending();
          lastSync = DateTime.now();
          cloudError = null;
          _notify();
        },
      );
    } catch (error) {
      if (localError == null) cloudError = errorMessage(error);
    } finally {
      synchronizing = false;
      _notify();
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    sync.stop();
    _retry?.cancel();
    unawaited(_remoteSubscription?.cancel());
    unawaited(_networkSubscription?.cancel());
    super.dispose();
  }
}
