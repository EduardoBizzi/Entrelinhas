import 'package:uuid/uuid.dart';

enum ReadingStatus {
  planned('Quero ler'),
  reading('Lendo'),
  finished('Concluído');

  const ReadingStatus(this.label);
  final String label;
}

/// O mesmo UUID é a chave do SQLite e o ID do documento no Firestore.
/// changeId identifica cada alteração, inclusive duas feitas no mesmo instante.
class ReadingRecord {
  ReadingRecord({
    required this.id,
    required this.userId,
    required this.title,
    required this.author,
    required this.description,
    required this.eventAt,
    required this.createdAt,
    required this.updatedAt,
    required this.changeId,
    this.status = ReadingStatus.planned,
    this.pages = 0,
    this.totalPages = 0,
    this.latitude,
    this.longitude,
    this.place = '',
    this.bookKey,
    this.coverUrl,
    this.deletedAt,
    this.synced = false,
  });

  factory ReadingRecord.create(String userId, {DateTime? date}) {
    final now = DateTime.now();
    return ReadingRecord(
      id: const Uuid().v4(),
      userId: userId,
      title: '',
      author: '',
      description: '',
      eventAt: date ?? now,
      createdAt: now.toUtc(),
      updatedAt: now.toUtc(),
      changeId: const Uuid().v4(),
    );
  }

  final String id;
  final String userId;
  final String title;
  final String author;
  final String description;
  final DateTime eventAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String changeId;
  final ReadingStatus status;
  final int pages;
  final int totalPages;
  final double? latitude;
  final double? longitude;
  final String place;
  final String? bookKey;
  final String? coverUrl;
  final DateTime? deletedAt;
  final bool synced;
  String get remoteId => id;
  bool get isDeleted => deletedAt != null;
  bool get hasLocation => latitude != null && longitude != null;

  ReadingRecord copyWith({
    String? title,
    String? author,
    String? description,
    DateTime? eventAt,
    DateTime? updatedAt,
    String? changeId,
    ReadingStatus? status,
    int? pages,
    int? totalPages,
    double? latitude,
    double? longitude,
    String? place,
    String? bookKey,
    String? coverUrl,
    DateTime? deletedAt,
    bool? synced,
    bool clearLocation = false,
  }) => ReadingRecord(
    id: id,
    userId: userId,
    title: title ?? this.title,
    author: author ?? this.author,
    description: description ?? this.description,
    eventAt: eventAt ?? this.eventAt,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    changeId: changeId ?? this.changeId,
    status: status ?? this.status,
    pages: pages ?? this.pages,
    totalPages: totalPages ?? this.totalPages,
    latitude: clearLocation ? null : latitude ?? this.latitude,
    longitude: clearLocation ? null : longitude ?? this.longitude,
    place: place ?? this.place,
    bookKey: bookKey ?? this.bookKey,
    coverUrl: coverUrl ?? this.coverUrl,
    deletedAt: deletedAt ?? this.deletedAt,
    synced: synced ?? this.synced,
  );

  ReadingRecord changed() => copyWith(
    updatedAt: DateTime.now().toUtc(),
    changeId: const Uuid().v4(),
    synced: false,
  );

  Map<String, Object?> toMap() => {
    'id': id,
    'userId': userId,
    'remoteId': remoteId,
    'title': title,
    'author': author,
    'description': description,
    'eventAt': eventAt.toUtc().toIso8601String(),
    'createdAt': createdAt.toUtc().toIso8601String(),
    'updatedAt': updatedAt.toUtc().toIso8601String(),
    'changeId': changeId,
    'status': status.name,
    'pages': pages,
    'totalPages': totalPages,
    'latitude': latitude,
    'longitude': longitude,
    'place': place,
    'bookKey': bookKey,
    'coverUrl': coverUrl,
    'deletedAt': deletedAt?.toUtc().toIso8601String(),
    'synced': synced ? 1 : 0,
  };

  factory ReadingRecord.fromMap(Map<String, dynamic> map) {
    DateTime date(dynamic value) => DateTime.parse(value as String);
    return ReadingRecord(
      id: map['id'] as String,
      userId: map['userId'] as String,
      title: map['title'] as String,
      author: map['author'] as String? ?? '',
      description: map['description'] as String? ?? '',
      eventAt: date(map['eventAt']).toLocal(),
      createdAt: date(map['createdAt']).toUtc(),
      updatedAt: date(map['updatedAt']).toUtc(),
      changeId: map['changeId'] as String,
      status: ReadingStatus.values.firstWhere(
        (status) => status.name == map['status'],
        orElse: () => ReadingStatus.planned,
      ),
      pages: (map['pages'] as num?)?.toInt() ?? 0,
      totalPages: (map['totalPages'] as num?)?.toInt() ?? 0,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      place: map['place'] as String? ?? '',
      bookKey: map['bookKey'] as String?,
      coverUrl: map['coverUrl'] as String?,
      deletedAt: map['deletedAt'] == null ? null : date(map['deletedAt']),
      synced: map['synced'] == true || map['synced'] == 1,
    );
  }
}
