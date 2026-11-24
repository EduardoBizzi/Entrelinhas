import 'package:cloud_firestore/cloud_firestore.dart';
import '../database/model/reading_record.dart';
import 'remote_records.dart';

class FirestoreService implements RemoteRecords {
  FirestoreService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _records(String userId) =>
      _firestore.collection('users').doc(userId).collection('registros');

  @override
  Stream<RemoteSnapshot> watch(String userId) => _records(userId)
      .snapshots(includeMetadataChanges: true)
      .map(
        (snapshot) => RemoteSnapshot(
          snapshot.docs
              .map((doc) {
                final data = <String, dynamic>{...doc.data(), 'id': doc.id};
                for (final field in [
                  'eventAt',
                  'createdAt',
                  'updatedAt',
                  'deletedAt',
                ]) {
                  if (data[field] is Timestamp) {
                    data[field] = (data[field] as Timestamp)
                        .toDate()
                        .toUtc()
                        .toIso8601String();
                  }
                }
                return ReadingRecord.fromMap(data);
              })
              .where((record) => record.userId == userId && !record.isDeleted)
              .toList(),
          fromCache: snapshot.metadata.isFromCache,
        ),
      );

  @override
  Future<void> save(ReadingRecord record) =>
      _records(record.userId).doc(record.id).set({
        ...record.toMap(),
        'synced': true,
        'eventAt': Timestamp.fromDate(record.eventAt),
        'createdAt': Timestamp.fromDate(record.createdAt),
        'updatedAt': Timestamp.fromDate(record.updatedAt),
        'deletedAt': record.deletedAt == null
            ? null
            : Timestamp.fromDate(record.deletedAt!),
      });

  @override
  Future<void> delete(ReadingRecord record) =>
      _records(record.userId).doc(record.id).delete();
}
