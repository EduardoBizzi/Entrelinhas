import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../database/model/reading_record.dart';
import '../utils/error_message.dart';

class RecoveredPhoto {
  const RecoveredPhoto(this.record, this.imagePath);
  final ReadingRecord record;
  final String imagePath;
}

/// Uma foto por registro, apenas neste aparelho. O arquivo sai do cache da
/// câmera e é copiado para Documents; não vira uma URL fictícia no Firestore.
class PhotoService {
  static const maxPhotosPerAccount = 10;
  final ImagePicker _picker = ImagePicker();

  Future<File> _draft(String userId) async => File(
    path.join(
      (await getApplicationDocumentsDirectory()).path,
      'photo_draft_$userId.json',
    ),
  );

  Future<String?> pick(ImageSource source, ReadingRecord draft) async {
    final file = await _draft(draft.userId);
    await file.writeAsString(jsonEncode(draft.toMap()), flush: true);
    try {
      return (await _picker.pickImage(
        source: source,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 75,
        requestFullMetadata: false,
      ))?.path;
    } finally {
      if (await file.exists()) await file.delete();
    }
  }

  Future<File> fileFor(String userId, String recordId) async => File(
    path.join(
      (await getApplicationDocumentsDirectory()).path,
      'record_photos',
      userId,
      '$recordId.jpg',
    ),
  );

  Future<String?> existing(String userId, String recordId) async {
    final file = await fileFor(userId, recordId);
    return await file.exists() ? file.path : null;
  }

  Future<void> persist(String userId, String recordId, String source) async {
    final sourceFile = File(source);
    if (!await sourceFile.exists()) {
      throw const AppException(
        'A foto não está mais disponível. Selecione novamente.',
      );
    }
    if (await sourceFile.length() > 5 * 1024 * 1024) {
      throw const AppException('Escolha uma foto de até 5 MB.');
    }
    final destination = await fileFor(userId, recordId);
    if (path.equals(sourceFile.path, destination.path)) return;
    await destination.parent.create(recursive: true);
    final photos = await destination.parent
        .list()
        .where((entry) => entry is File)
        .toList();
    if (!await destination.exists() && photos.length >= maxPhotosPerAccount) {
      throw const AppException(
        'Limite de 10 fotos nesta conta e neste aparelho. Remova uma foto antes de adicionar outra.',
      );
    }
    await sourceFile.copy(destination.path);
  }

  Future<void> remove(String userId, String recordId) async {
    final file = await fileFor(userId, recordId);
    if (await file.exists()) await file.delete();
  }

  Future<RecoveredPhoto?> recover(String userId) async {
    if (!Platform.isAndroid) return null;
    final draft = await _draft(userId);
    // Não recolhe fotos que foram escolhidas em uma sessão de outro usuário.
    if (!await draft.exists()) return null;
    final result = await _picker.retrieveLostData();
    if (result.exception != null) throw result.exception!;
    if (result.files == null || result.files!.isEmpty) {
      await draft.delete();
      return null;
    }
    final record = ReadingRecord.fromMap(
      Map<String, dynamic>.from(jsonDecode(await draft.readAsString()) as Map),
    );
    await draft.delete();
    if (record.userId != userId) return null;
    return RecoveredPhoto(record, result.files!.first.path);
  }
}
