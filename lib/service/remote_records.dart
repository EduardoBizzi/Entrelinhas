import '../database/model/reading_record.dart';

class RemoteSnapshot {
  const RemoteSnapshot(this.records, {required this.fromCache});
  final List<ReadingRecord> records;
  final bool fromCache;
}

abstract class RemoteRecords {
  Stream<RemoteSnapshot> watch(String userId);
  Future<void> save(ReadingRecord record);
  Future<void> delete(ReadingRecord record);
}
