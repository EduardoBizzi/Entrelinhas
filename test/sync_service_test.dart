import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:entrelinhas/database/helper/record_helper.dart';
import 'package:entrelinhas/database/model/reading_record.dart';
import 'package:entrelinhas/service/remote_records.dart';
import 'package:entrelinhas/service/sync_service.dart';

class FakeRemote implements RemoteRecords {
  final Map<String, ReadingRecord> documents = {};
  int saves = 0;
  int deletes = 0;
  Object? failure;
  Future<void> Function(ReadingRecord)? beforeSave;
  @override
  Stream<RemoteSnapshot> watch(String userId) => const Stream.empty();
  @override
  Future<void> save(ReadingRecord record) async {
    saves++;
    if (failure != null) throw failure!;
    await beforeSave?.call(record);
    documents['${record.userId}/${record.id}'] = record;
  }

  @override
  Future<void> delete(ReadingRecord record) async {
    deletes++;
    if (failure != null) throw failure!;
    documents.remove('${record.userId}/${record.id}');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  late Directory directory;
  late RecordHelper local;
  late FakeRemote remote;
  late SyncService sync;
  ReadingRecord record() => ReadingRecord.create('alice').copyWith(
    title: 'Dom Casmurro',
    author: 'Machado de Assis',
    description: 'Leitura do capítulo inicial.',
  );
  Future<void> runSync({String userId = 'alice', bool connected = true}) =>
      sync.synchronize(
        userId,
        connected: () => connected,
        onAcknowledged: (_) async {},
      );
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('entrelinhas_test_');
    local = RecordHelper(
      factory: databaseFactoryFfi,
      databasePath: path.join(directory.path, 'queue.db'),
    );
    remote = FakeRemote();
    sync = SyncService(local: local, remote: remote);
  });
  tearDown(() async {
    sync.stop();
    await local.close();
    await directory.delete(recursive: true);
  });

  test(
    'SQLite cadastra, consulta, edita e persiste após fechar e reabrir',
    () async {
      final first = record();
      await local.save(first);
      await local.save(
        first.copyWith(description: 'Anotação atualizada').changed(),
      );
      final databasePath = path.join(directory.path, 'queue.db');
      await local.close();
      local = RecordHelper(
        factory: databaseFactoryFfi,
        databasePath: databasePath,
      );
      expect(
        (await local.pending('alice')).single.description,
        'Anotação atualizada',
      );
      expect((await local.find('alice', first.id))!.synced, isFalse);
    },
  );

  test('sem conexão, não envia nem apaga o registro local', () async {
    await local.save(record());
    await runSync(connected: false);
    expect(remote.saves, 0);
    expect(await local.pending('alice'), hasLength(1));
  });

  test('somente o reconhecimento remoto permite limpar o SQLite', () async {
    final first = record();
    await local.save(first);
    final started = Completer<void>();
    final acknowledgement = Completer<void>();
    remote.beforeSave = (_) async {
      started.complete();
      await acknowledgement.future;
    };
    final sending = runSync();
    await started.future;
    expect(await local.pending('alice'), hasLength(1));
    acknowledgement.complete();
    await sending;
    expect(await local.pending('alice'), isEmpty);
    expect(remote.documents.values.single.id, first.id);
  });

  test(
    'falha de rede mantém a fila e nova tentativa não duplica documento',
    () async {
      await local.save(record());
      remote.failure = const SocketException('offline');
      await expectLater(runSync(), throwsA(isA<SocketException>()));
      expect(await local.pending('alice'), hasLength(1));
      remote.failure = null;
      await runSync();
      await runSync();
      expect(remote.documents, hasLength(1));
      expect(await local.pending('alice'), isEmpty);
    },
  );

  test('timeout não produz confirmação nem limpeza local', () async {
    await local.save(record());
    remote.failure = TimeoutException('servidor indisponível');
    await expectLater(runSync(), throwsA(isA<TimeoutException>()));
    expect(await local.pending('alice'), hasLength(1));
  });

  test(
    'edição durante envio não é apagada pelo reconhecimento antigo',
    () async {
      final first = record();
      await local.save(first);
      remote.beforeSave = (sending) async {
        if (remote.saves == 1) {
          await local.save(
            sending.copyWith(title: 'Título atualizado').changed(),
          );
        }
      };
      await runSync();
      expect(remote.saves, 2);
      expect(remote.documents.values.single.title, 'Título atualizado');
      expect(await local.pending('alice'), isEmpty);
    },
  );

  test(
    'exclusão durante envio permanece pendente até o delete remoto',
    () async {
      await local.save(record());
      remote.beforeSave = (sending) async {
        await local.delete(sending);
      };
      await runSync();
      expect(remote.saves, 1);
      expect(remote.deletes, 1);
      expect(remote.documents, isEmpty);
      expect(await local.pending('alice'), isEmpty);
    },
  );

  test(
    'exclusão offline sobrevive a reinício e é replicada na nuvem',
    () async {
      final first = record();
      remote.documents['alice/${first.id}'] = first;
      await local.delete(first);
      await local.close();
      local = RecordHelper(
        factory: databaseFactoryFfi,
        databasePath: path.join(directory.path, 'queue.db'),
      );
      sync = SyncService(local: local, remote: remote);
      expect((await local.pending('alice')).single.isDeleted, isTrue);
      await runSync();
      expect(remote.documents, isEmpty);
      expect(await local.pending('alice'), isEmpty);
    },
  );

  test('criar e excluir antes do envio não faz o livro reaparecer', () async {
    final first = record();
    await local.save(first);
    await local.delete(first);
    await runSync();
    expect(remote.saves, 0);
    expect(remote.deletes, 1);
    expect(remote.documents, isEmpty);
    expect(await local.pending('alice'), isEmpty);
  });

  test(
    'contas distintas não compartilham consultas, envios ou limpeza',
    () async {
      final alice = record();
      final bob = ReadingRecord.fromMap({
        ...alice.toMap(),
        'userId': 'bob',
        'title': 'Livro do Bob',
      });
      await local.save(alice);
      await local.save(bob);
      expect((await local.find('bob', bob.id))!.title, 'Livro do Bob');
      await runSync();
      expect(remote.documents.keys, ['alice/${alice.id}']);
      expect(await local.pending('alice'), isEmpty);
      expect((await local.pending('bob')).single.title, 'Livro do Bob');
      expect(await local.find('charlie', alice.id), isNull);
    },
  );

  test('duas chamadas simultâneas usam um único trabalhador', () async {
    await local.save(record());
    await Future.wait([runSync(), runSync()]);
    expect(remote.saves, 1);
    expect(await local.pending('alice'), isEmpty);
  });

  test(
    'linha editada antes de sua vez envia somente a versão mais recente',
    () async {
      final first = record().copyWith(updatedAt: DateTime.utc(2026, 1, 1));
      final second = record().copyWith(
        title: 'Versão antiga',
        updatedAt: DateTime.utc(2026, 1, 2),
      );
      await local.save(first);
      await local.save(second);
      remote.beforeSave = (sending) async {
        if (sending.id == first.id) {
          await local.save(second.copyWith(title: 'Última versão').changed());
        }
      };
      await runSync();
      expect(remote.saves, 2);
      expect(remote.documents['alice/${second.id}']!.title, 'Última versão');
      expect(await local.pending('alice'), isEmpty);
    },
  );

  test('linha excluída antes de sua vez não é cadastrada na nuvem', () async {
    final first = record().copyWith(updatedAt: DateTime.utc(2026, 1, 1));
    final second = record().copyWith(updatedAt: DateTime.utc(2026, 1, 2));
    await local.save(first);
    await local.save(second);
    remote.beforeSave = (sending) async {
      if (sending.id == first.id) await local.delete(second);
    };
    await runSync();
    expect(remote.saves, 1);
    expect(remote.deletes, 1);
    expect(remote.documents.keys, ['alice/${first.id}']);
    expect(await local.pending('alice'), isEmpty);
  });

  test('changeId distingue alterações mesmo com updatedAt idêntico', () async {
    final first = record();
    final next = first
        .copyWith(title: 'Nova edição')
        .changed()
        .copyWith(updatedAt: first.updatedAt);
    await local.save(first);
    await local.save(next);
    expect(await local.acknowledge(first), isFalse);
    expect((await local.pending('alice')).single.title, 'Nova edição');
  });
}
