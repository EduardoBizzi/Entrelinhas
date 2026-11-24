import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:entrelinhas/service/open_library_service.dart';
import 'package:entrelinhas/utils/error_message.dart';

void main() {
  test(
    'consulta HTTPS codifica busca e página, converte JSON e campos opcionais',
    () async {
      final service = OpenLibraryService(
        client: MockClient((request) async {
          expect(request.url.scheme, 'https');
          expect(request.url.host, 'openlibrary.org');
          expect(request.url.queryParameters['q'], 'ação & leitura');
          expect(request.url.queryParameters['page'], '2');
          expect(request.url.queryParameters['limit'], '12');
          return http.Response(
            '{"numFound":20,"docs":[{"key":"/works/OL1W","title":"Livro","author_name":["Autora"],"cover_i":42},{"title":"Sem capa"}]}',
            200,
          );
        }),
      );
      final result = await service.search(' ação & leitura ', page: 2);
      expect(result.total, 20);
      expect(
        result.books.first.coverUrl,
        'https://covers.openlibrary.org/b/id/42-M.jpg',
      );
      expect(result.books.last.coverUrl, isNull);
      expect(result.books.last.author, 'Autor não informado');
      service.close();
    },
  );
  test('busca vazia não dispara requisição', () async {
    final service = OpenLibraryService(
      client: MockClient(
        (_) async => fail('Não deveria consultar o servidor.'),
      ),
    );
    await expectLater(service.search('  '), throwsA(isA<AppException>()));
    service.close();
  });
  test(
    'falhas HTTP são apresentadas como erro em vez de resultados vazios',
    () async {
      for (final status in [429, 500]) {
        final service = OpenLibraryService(
          client: MockClient((_) async => http.Response('{}', status)),
        );
        await expectLater(service.search('Dart'), throwsA(isA<AppException>()));
        service.close();
      }
    },
  );
  test('JSON inválido ou esquema inesperado são rejeitados', () async {
    for (final body in ['not-json', '[]', '{"docs":{}}']) {
      final service = OpenLibraryService(
        client: MockClient((_) async => http.Response(body, 200)),
      );
      await expectLater(
        service.search('Dart'),
        throwsA(isA<FormatException>()),
      );
      service.close();
    }
  });
  test('falha de conexão tem mensagem utilizável na interface', () async {
    final service = OpenLibraryService(
      client: MockClient((_) async => throw const SocketException('offline')),
    );
    try {
      await service.search('Dart');
      fail('Deveria falhar.');
    } catch (error) {
      expect(errorMessage(error), 'Sem conexão com a internet.');
    }
    service.close();
  });
}
