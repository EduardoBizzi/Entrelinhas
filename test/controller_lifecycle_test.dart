import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:entrelinhas/controller/library_controller.dart';
import 'package:entrelinhas/database/helper/record_helper.dart';
import 'package:entrelinhas/database/model/reading_record.dart';
import 'package:entrelinhas/service/connectivity_service.dart';
import 'package:entrelinhas/service/remote_records.dart';
import 'package:entrelinhas/utils/app_exception.dart';

class _Local extends RecordHelper {
  _Local(String file)
    : super(factory: databaseFactoryFfiNoIsolate, databasePath: file);
  int failures = 0;

  @override
  Future<List<ReadingRecord>> pending(String userId) async {
    if (failures > 0) {
      failures--;
      throw const AppException('Falha temporária ao abrir a biblioteca.');
    }
    return super.pending(userId);
  }
}

class _Network extends ConnectivityService {
  Object? failure;
  Completer<bool>? waiting;
  int checks = 0;

  @override
  Future<bool> check() async {
    checks++;
    if (failure != null) throw failure!;
    return waiting == null ? false : await waiting!.future;
  }

  @override
  Stream<bool> get changes => const Stream.empty();
}

class _Remote implements RemoteRecords {
  @override
  Stream<RemoteSnapshot> watch(String userId) => const Stream.empty();
  @override
  Future<void> save(ReadingRecord record) async => fail('Rede indisponível.');
  @override
  Future<void> delete(ReadingRecord record) async => fail('Rede indisponível.');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  late Directory directory;
  late _Local local;
  late _Network network;
  late LibraryController controller;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('biblioteca_controller_');
    local = _Local(path.join(directory.path, 'records.db'));
    network = _Network();
    controller = LibraryController(
      userId: 'alice',
      local: local,
      remote: _Remote(),
      connectivity: network,
    );
    await local.save(
      ReadingRecord.create('alice').copyWith(title: 'Livro local'),
    );
  });

  tearDown(() async {
    controller.dispose();
    await local.close();
    await directory.delete(recursive: true);
  });

  Future<void> idle() async {
    for (
      var attempt = 0;
      attempt < 100 && controller.synchronizing;
      attempt++
    ) {
      await Future<void>.delayed(Duration.zero);
    }
    expect(controller.synchronizing, isFalse);
  }

  test(
    'tentar novamente recupera leitura SQLite sem precisar de internet',
    () async {
      local.failures = 2; // Inicialização e primeira tentativa automática.
      await controller.start();
      await idle();
      expect(controller.localError, contains('Falha temporária'));
      expect(controller.records, isEmpty);

      await controller.synchronize();

      expect(controller.localError, isNull);
      expect(controller.records.single.title, 'Livro local');
      expect(controller.pendingCount, 1);
      expect(await local.pending('alice'), hasLength(1));
    },
  );

  test(
    'erro de conectividade preserva livros e não acusa falha no SQLite',
    () async {
      network.failure = const AppException('Falha ao consultar a rede.');
      await controller.start();
      await idle();

      expect(controller.localError, isNull);
      expect(controller.cloudError, 'Falha ao consultar a rede.');
      expect(controller.records.single.title, 'Livro local');
      expect(controller.pendingCount, 1);
    },
  );

  test(
    'chamadas simultâneas aguardam apenas uma verificação de rede',
    () async {
      network.waiting = Completer<bool>();
      final first = controller.synchronize();
      final second = controller.synchronize();
      await Future<void>.delayed(Duration.zero);
      expect(controller.synchronizing, isTrue);
      expect(network.checks, 1);

      network.waiting!.complete(false);
      await Future.wait([first, second]);

      expect(controller.synchronizing, isFalse);
      expect(controller.pendingCount, 1);
      expect(controller.cloudError, isNull);
    },
  );
}
