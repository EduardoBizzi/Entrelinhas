import 'package:flutter_test/flutter_test.dart';
import 'package:entrelinhas/database/model/reading_record.dart';
import 'package:entrelinhas/utils/validators.dart';

void main() {
  test('serialização preserva datas, coordenadas e identificação', () {
    final record =
        ReadingRecord.create(
          'alice',
          date: DateTime(2027, 2, 15, 18, 30),
        ).copyWith(
          title: 'Livro',
          author: 'Autor',
          description: 'Descrição',
          latitude: -25.39,
          longitude: -51.46,
        );
    final restored = ReadingRecord.fromMap(record.toMap());
    expect(restored.id, record.id);
    expect(restored.remoteId, record.id);
    expect(restored.eventAt, record.eventAt);
    expect(restored.latitude, -25.39);
    expect(restored.longitude, -51.46);
    expect(record.toMap().containsKey('photoPath'), isFalse);
    expect(restored.copyWith(clearLocation: true).hasLocation, isFalse);
  });
  test('validadores rejeitam nome incompleto, e-mail e senha inválidos', () {
    expect(Validators.fullName('Eduardo'), isNotNull);
    expect(Validators.fullName('Eduardo Bizzi'), isNull);
    expect(Validators.email('sem-email'), isNotNull);
    expect(Validators.email('eduardo@example.com'), isNull);
    expect(Validators.password('12345'), isNotNull);
    expect(Validators.password('123456'), isNull);
    expect(Validators.requiredText(' '), isNotNull);
  });
}
