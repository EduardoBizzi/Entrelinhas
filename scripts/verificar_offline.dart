// Verificação local sem Flutter engine e sem sockets. Usa SQLite verdadeiro.
import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:entrelinhas/database/helper/record_helper.dart';
import 'package:entrelinhas/database/model/reading_record.dart';
import 'package:entrelinhas/service/remote_records.dart';
import 'package:entrelinhas/service/sync_service.dart';

class _Remote implements RemoteRecords {
  final Map<String, ReadingRecord> documents = {};
  Future<void> Function(ReadingRecord)? duringSend;
  Object? failure;
  int saves = 0;
  int deletions = 0;
  @override
  Stream<RemoteSnapshot> watch(String uid) => const Stream.empty();
  @override
  Future<void> save(ReadingRecord record) async {
    saves++;
    if (failure != null) throw failure!;
    await duringSend?.call(record);
    documents['${record.userId}/${record.id}'] = record;
  }

  @override
  Future<void> delete(ReadingRecord record) async {
    deletions++;
    if (failure != null) throw failure!;
    documents.remove('${record.userId}/${record.id}');
  }
}

void check(bool condition, String message) {
  if (!condition) throw StateError(message);
}

Future<void> main() async {
  sqfliteFfiInit();
  final directory = await Directory.systemTemp.createTemp('entrelinhas_check_');
  final dbPath = path.join(directory.path, 'records.db');
  var local = RecordHelper(
    factory: databaseFactoryFfiNoIsolate,
    databasePath: dbPath,
  );
  final remote = _Remote();
  var sync = SyncService(local: local, remote: remote);
  Future<void> send({bool connected = true}) => sync.synchronize(
    'alice',
    connected: () => connected,
    onAcknowledged: (_) async {},
  );
  try {
    final first = ReadingRecord.create('alice').copyWith(
      title: 'Dom Casmurro',
      author: 'Machado de Assis',
      description: 'Anotações',
      latitude: -25.39,
      longitude: -51.46,
    );
    await local.save(first);
    await local.save(first.copyWith(description: 'Edição offline').changed());
    await local.close();
    local = RecordHelper(
      factory: databaseFactoryFfiNoIsolate,
      databasePath: dbPath,
    );
    sync = SyncService(local: local, remote: remote);
    check(
      (await local.pending('alice')).single.description == 'Edição offline',
      'Não persistiu após reiniciar.',
    );
    stdout.writeln('PASSOU: CRUD local e persistência após reinício');

    await send(connected: false);
    check(
      remote.saves == 0 && (await local.pending('alice')).length == 1,
      'Enviou ou perdeu dados sem conexão.',
    );
    remote.failure = const SocketException('offline');
    try {
      await send();
      throw StateError('Falha não propagada.');
    } on SocketException {
      /* esperado */
    }
    check(
      (await local.pending('alice')).length == 1,
      'Apagou dados sem confirmação.',
    );
    remote.failure = null;
    stdout.writeln('PASSOU: falta de conexão e erro preservam a fila');

    final started = Completer<void>();
    final ack = Completer<void>();
    remote.duringSend = (_) async {
      started.complete();
      await ack.future;
    };
    final sending = send();
    await started.future;
    check((await local.pending('alice')).length == 1, 'Limpou antes do ACK.');
    ack.complete();
    await sending;
    await send();
    check(
      (await local.pending('alice')).isEmpty && remote.documents.length == 1,
      'ACK ou idempotência incorretos.',
    );
    stdout.writeln(
      'PASSOU: confirmação remota, limpeza do SQLite e ausência de duplicação',
    );

    await local.save(first.changed());
    var edited = false;
    remote.duringSend = (record) async {
      if (!edited) {
        edited = true;
        await local.save(record.copyWith(title: 'Nova edição').changed());
      }
    };
    await send();
    check(
      remote.documents.values.single.title == 'Nova edição' &&
          (await local.pending('alice')).isEmpty,
      'Perdeu edição simultânea.',
    );
    stdout.writeln(
      'PASSOU: edição durante envio permanece até seu próprio ACK',
    );

    await local.delete(first);
    await local.close();
    local = RecordHelper(
      factory: databaseFactoryFfiNoIsolate,
      databasePath: dbPath,
    );
    sync = SyncService(local: local, remote: remote);
    check(
      (await local.pending('alice')).single.isDeleted,
      'Perdeu tombstone no reinício.',
    );
    await send();
    check(
      remote.documents.isEmpty &&
          (await local.pending('alice')).isEmpty &&
          remote.deletions == 1,
      'Exclusão não foi replicada.',
    );
    stdout.writeln('PASSOU: exclusão offline, reinício e exclusão remota');

    await local.save(first.changed());
    final bob = ReadingRecord.fromMap({
      ...first.toMap(),
      'userId': 'bob',
      'title': 'Livro do Bob',
    });
    await local.save(bob);
    remote.duringSend = null;
    await Future.wait([send(), send()]);
    check(
      (await local.pending('bob')).single.title == 'Livro do Bob' &&
          (await local.pending('alice')).isEmpty,
      'Misturou as contas.',
    );
    check(
      remote.documents.keys.every((key) => key.startsWith('alice/')),
      'Enviou dados de outra conta.',
    );
    stdout.writeln('PASSOU: isolamento entre contas e chamadas concorrentes');

    await local.save(first.changed());
    remote.duringSend = (record) async => local.delete(record);
    await send();
    check(
      remote.documents.isEmpty && (await local.pending('alice')).isEmpty,
      'Ressuscitou registro excluído durante envio.',
    );
    stdout.writeln('PASSOU: exclusão durante envio sem reaparecimento');
    final queuedFirst = ReadingRecord.create('alice').copyWith(
      title: 'Livro A',
      author: 'Autor',
      description: 'Primeiro da fila',
      updatedAt: DateTime.utc(2026, 1, 1),
    );
    final queuedSecond = ReadingRecord.create('alice').copyWith(
      title: 'Versão antiga',
      author: 'Autor',
      description: 'Segundo da fila',
      updatedAt: DateTime.utc(2026, 1, 2),
    );
    await local.save(queuedFirst);
    await local.save(queuedSecond);
    final previousSaves = remote.saves;
    remote.duringSend = (record) async {
      if (record.id == queuedFirst.id) {
        await local.save(
          queuedSecond.copyWith(title: 'Última versão').changed(),
        );
      }
    };
    await send();
    check(
      remote.saves == previousSaves + 2 &&
          remote.documents['alice/${queuedSecond.id}']!.title ==
              'Última versão',
      'Enviou uma versão que já havia sido substituída na fila.',
    );
    stdout.writeln(
      'PASSOU: fila relê a versão mais recente antes de cada envio',
    );
    stdout.writeln(
      '8 cenários aprovados. Firebase real e UI exigem validação separada.',
    );
  } finally {
    sync.stop();
    await local.close();
    await directory.delete(recursive: true);
  }
}
