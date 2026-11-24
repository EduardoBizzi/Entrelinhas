import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:entrelinhas/service/open_library_service.dart';
import 'package:entrelinhas/utils/app_exception.dart';

void check(bool value, String message) {
  if (!value) throw StateError(message);
}

Future<void> fails(
  Future<Object?> Function() action,
  bool Function(Object) matches,
) async {
  Object? failure;
  try {
    await action();
  } catch (error) {
    failure = error;
  }
  check(
    failure != null && matches(failure),
    'Erro não foi propagado corretamente.',
  );
}

Future<void> main() async {
  var calls = 0;
  final service = OpenLibraryService(
    client: MockClient((request) async {
      calls++;
      check(
        request.url.scheme == 'https' && request.url.host == 'openlibrary.org',
        'Endpoint incorreto.',
      );
      check(
        request.url.queryParameters['q'] == 'ação & leitura',
        'Busca não codificada.',
      );
      check(request.url.queryParameters['page'] == '2', 'Paginação incorreta.');
      return http.Response.bytes(
        utf8.encode(
          jsonEncode({
            'numFound': 20,
            'docs': [
              {
                'key': '/works/OL1W',
                'title': 'Ação',
                'author_name': ['Autora'],
                'cover_i': 42,
              },
              {'title': 'Sem campos opcionais'},
            ],
          }),
        ),
        200,
      );
    }),
  );
  try {
    final result = await service.search(' ação & leitura ', page: 2);
    check(
      result.total == 20 &&
          result.books.length == 2 &&
          result.books.first.title == 'Ação',
      'Falha no JSON/UTF-8.',
    );
    check(
      result.books.first.coverUrl ==
          'https://covers.openlibrary.org/b/id/42-M.jpg',
      'URL da capa incorreta.',
    );
    check(
      result.books.last.author == 'Autor não informado' &&
          result.books.last.coverUrl == null,
      'Campos opcionais não tratados.',
    );
    stdout.writeln(
      'PASSOU: HTTPS, codificação da consulta, paginação, JSON/UTF-8 e campos opcionais',
    );
    await fails(() => service.search(' '), (error) => error is AppException);
    check(calls == 1, 'Buscou mesmo com termo vazio.');
    stdout.writeln('PASSOU: busca vazia não dispara HTTP');
  } finally {
    service.close();
  }
  for (final status in [429, 500]) {
    final failed = OpenLibraryService(
      client: MockClient((_) async => http.Response('{}', status)),
    );
    try {
      await fails(
        () => failed.search('Dart'),
        (error) => error is AppException,
      );
    } finally {
      failed.close();
    }
  }
  stdout.writeln('PASSOU: erros HTTP 429/500 não viram resultados vazios');
  for (final body in ['não-json', '[]', '{"docs":{}}']) {
    final malformed = OpenLibraryService(
      client: MockClient((_) async => http.Response(body, 200)),
    );
    try {
      await fails(
        () => malformed.search('Dart'),
        (error) => error is FormatException,
      );
    } finally {
      malformed.close();
    }
  }
  stdout.writeln('PASSOU: JSON inválido e esquema inesperado são rejeitados');
  final offline = OpenLibraryService(
    client: MockClient((_) async => throw const SocketException('offline')),
  );
  try {
    await fails(
      () => offline.search('Dart'),
      (error) => error is SocketException,
    );
  } finally {
    offline.close();
  }
  stdout.writeln('PASSOU: falha de conexão é propagada à interface');
  stdout.writeln(
    '5 cenários aprovados com HTTP controlado. API na internet exige validação separada.',
  );
}
