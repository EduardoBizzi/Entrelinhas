import 'package:flutter_test/flutter_test.dart';
import 'package:entrelinhas/controller/library_controller.dart';
import 'package:entrelinhas/database/model/reading_record.dart';

void main() {
  test('edição SQLite prevalece sobre a última cópia remota', () {
    final remote = ReadingRecord.create(
      'alice',
    ).copyWith(title: 'Antigo', synced: true);
    final local = remote
        .copyWith(title: 'Edição offline', synced: false)
        .changed();
    final merged = LibraryController.merge([remote], [local]);
    expect(merged.single.title, 'Edição offline');
    expect(merged.single.synced, isFalse);
  });
  test('tombstone esconde o registro antes de haver acesso ao servidor', () {
    final remote = ReadingRecord.create(
      'alice',
    ).copyWith(title: 'Livro', synced: true);
    final deletion = remote.copyWith(deletedAt: DateTime.now()).changed();
    expect(LibraryController.merge([remote], [deletion]), isEmpty);
  });
  test('livro criado offline aparece junto dos livros do cache', () {
    final first = ReadingRecord.create(
      'alice',
    ).copyWith(title: 'Na nuvem', synced: true);
    final second = ReadingRecord.create('alice').copyWith(title: 'No aparelho');
    expect(LibraryController.merge([first], [second]), hasLength(2));
  });
}
