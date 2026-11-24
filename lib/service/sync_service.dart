import '../database/helper/record_helper.dart';
import '../database/model/reading_record.dart';
import 'remote_records.dart';

/// Um único envio por vez; repetir set/delete com o mesmo UUID é idempotente.
/// A Future do Firestore só conclui depois do reconhecimento do servidor.
class SyncService {
  SyncService({required this.local, required this.remote});
  final RecordHelper local;
  final RemoteRecords remote;
  Future<void>? _running;
  bool _again = false;
  bool _stopped = false;

  Future<void> synchronize(
    String userId, {
    required bool Function() connected,
    required Future<void> Function(ReadingRecord) onAcknowledged,
  }) {
    if (_stopped) return Future.value();
    if (_running != null) {
      _again = true;
      return _running!;
    }
    _running = _drain(userId, connected, onAcknowledged).whenComplete(() {
      _running = null;
    });
    return _running!;
  }

  Future<void> _drain(
    String userId,
    bool Function() connected,
    Future<void> Function(ReadingRecord) onAcknowledged,
  ) async {
    do {
      _again = false;
      if (_stopped || !connected()) return;
      final batch = await local.pending(userId);
      for (final queued in batch) {
        if (_stopped || !connected()) return;
        // Outra alteração pode ter ocorrido enquanto um registro anterior
        // aguardava o servidor. Envia a versão mais recente desta linha.
        final record = await local.find(userId, queued.id);
        if (record == null) continue;
        if (record.isDeleted) {
          await remote.delete(record).timeout(const Duration(seconds: 15));
        } else {
          await remote.save(record).timeout(const Duration(seconds: 15));
        }
        // Em caso de timeout/erro, esta linha não é executada: a fila é mantida.
        await local.acknowledge(record);
        if (!_stopped) await onAcknowledged(record);
      }
      // Inclui alterações realizadas enquanto o servidor respondia.
      if (!_stopped && connected()) {
        _again = _again || (await local.pending(userId)).isNotEmpty;
      }
    } while (_again && !_stopped);
  }

  void stop() => _stopped = true;
}
