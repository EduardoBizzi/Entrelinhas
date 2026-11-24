import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/app_exception.dart';

class BookResult {
  const BookResult({
    required this.key,
    required this.title,
    required this.author,
    this.coverUrl,
    this.year,
    this.pages = 0,
  });
  final String key;
  final String title;
  final String author;
  final String? coverUrl;
  final int? year;
  final int pages;

  factory BookResult.fromJson(Map<String, dynamic> json) {
    final authors = json['author_name'];
    final cover = json['cover_i'];
    return BookResult(
      key: json['key'] as String? ?? '',
      title: json['title'] as String? ?? 'Livro sem título',
      author: authors is List && authors.isNotEmpty
          ? authors.join(', ')
          : 'Autor não informado',
      coverUrl: cover is num
          ? 'https://covers.openlibrary.org/b/id/${cover.toInt()}-M.jpg'
          : null,
      year: (json['first_publish_year'] as num?)?.toInt(),
      pages: (json['number_of_pages_median'] as num?)?.toInt() ?? 0,
    );
  }
}

class BookSearch {
  const BookSearch(this.books, this.total);
  final List<BookResult> books;
  final int total;
}

/// Adaptação do service OpenLibraryService do primeiro trabalho da disciplina.
class OpenLibraryService {
  OpenLibraryService({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;

  Future<BookSearch> search(String term, {int page = 1}) async {
    if (term.trim().isEmpty) {
      throw const AppException('Digite um livro, autor ou assunto.');
    }
    final response = await _client
        .get(
          Uri.https('openlibrary.org', '/search.json', {
            'q': term.trim(),
            'page': '$page',
            'limit': '12',
            'fields':
                'key,title,author_name,cover_i,first_publish_year,number_of_pages_median',
          }),
          headers: {'Accept': 'application/json'},
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode == 429) {
      throw const AppException(
        'A biblioteca recebeu muitas buscas. Aguarde e tente novamente.',
      );
    }
    if (response.statusCode != 200) {
      throw const AppException(
        'A Open Library está indisponível. Tente novamente mais tarde.',
      );
    }
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    if (data is! Map<String, dynamic> || data['docs'] is! List) {
      throw const FormatException('Resposta inválida da Open Library.');
    }
    final books = (data['docs'] as List)
        .whereType<Map<String, dynamic>>()
        .map(BookResult.fromJson)
        .toList();
    return BookSearch(
      books,
      ((data['numFound'] ?? data['num_found']) as num?)?.toInt() ??
          books.length,
    );
  }

  void close() => _client.close();
}
