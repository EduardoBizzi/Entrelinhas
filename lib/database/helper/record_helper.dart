import 'package:path/path.dart' as path;
import 'package:sqflite_common/sqlite_api.dart';
import '../model/reading_record.dart';

/// SQLite é a fila durável de alterações ainda não confirmadas pelo servidor.
/// Os registros confirmados ficam no Firestore e no cache persistente dele.
class RecordHelper {
  RecordHelper({required this.factory, this.databasePath});

  final DatabaseFactory factory;
  final String? databasePath;
  Future<Database>? _opening;

  Future<Database> get db => _opening ??= _open();

  Future<Database> _open() async {
    try {
      return await factory.openDatabase(
        databasePath ??
            path.join(await factory.getDatabasesPath(), 'entrelinhas.db'),
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, version) async {
            await db.execute('''
              CREATE TABLE pending_records (
                id TEXT NOT NULL, userId TEXT NOT NULL, remoteId TEXT NOT NULL,
                title TEXT NOT NULL, author TEXT NOT NULL,
                description TEXT NOT NULL, eventAt TEXT NOT NULL,
                createdAt TEXT NOT NULL, updatedAt TEXT NOT NULL,
                changeId TEXT NOT NULL, status TEXT NOT NULL,
                pages INTEGER NOT NULL, totalPages INTEGER NOT NULL,
                latitude REAL, longitude REAL, place TEXT NOT NULL,
                bookKey TEXT, coverUrl TEXT, deletedAt TEXT,
                synced INTEGER NOT NULL DEFAULT 0,
                PRIMARY KEY (userId, id)
              )
            ''');
            await db.execute(
              'CREATE INDEX pending_by_user ON pending_records(userId, synced)',
            );
          },
        ),
      );
    } catch (_) {
      _opening = null;
      rethrow;
    }
  }

  Future<void> save(ReadingRecord record) async {
    final database = await db;
    await database.insert(
      'pending_records',
      record.copyWith(synced: false).toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ReadingRecord>> pending(String userId) async {
    final rows = await (await db).query(
      'pending_records',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'updatedAt ASC, id ASC',
    );
    return rows.map(ReadingRecord.fromMap).toList();
  }

  Future<ReadingRecord?> find(String userId, String id) async {
    final rows = await (await db).query(
      'pending_records',
      where: 'userId = ? AND id = ?',
      whereArgs: [userId, id],
    );
    return rows.isEmpty ? null : ReadingRecord.fromMap(rows.first);
  }

  /// A exclusão vira um tombstone: permanece após reiniciar, até o delete remoto.
  Future<void> delete(ReadingRecord record) =>
      save(record.copyWith(deletedAt: DateTime.now().toUtc()).changed());

  /// Só limpa a versão que recebeu confirmação. Uma edição feita enquanto
  /// o envio estava em andamento precisa continuar na fila.
  Future<bool> acknowledge(ReadingRecord sent) async {
    return (await db).transaction((transaction) async {
      final args = [sent.userId, sent.id, sent.changeId];
      final changed = await transaction.update(
        'pending_records',
        {'synced': 1},
        where: 'userId = ? AND id = ? AND changeId = ?',
        whereArgs: args,
      );
      if (changed == 0) return false;
      await transaction.delete(
        'pending_records',
        where: 'userId = ? AND id = ? AND changeId = ? AND synced = 1',
        whereArgs: args,
      );
      return true;
    });
  }

  Future<void> close() async {
    final opening = _opening;
    _opening = null;
    if (opening != null) await (await opening).close();
  }
}
