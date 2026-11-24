import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:entrelinhas/service/open_library_service.dart';
import 'package:entrelinhas/view/explore_page.dart';

void main() {
  testWidgets('limpar pesquisa ignora uma resposta antiga ainda em andamento', (
    tester,
  ) async {
    final response = Completer<http.Response>();
    final service = OpenLibraryService(
      client: MockClient((_) => response.future),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ExplorePage(service: service, onAdd: (_) {}),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), 'Dart');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.byTooltip('Limpar pesquisa'));
    await tester.pump();
    response.complete(
      http.Response('{"numFound":1,"docs":[{"title":"Resposta antiga"}]}', 200),
    );
    await tester.pumpAndSettle();
    expect(find.text('Resposta antiga'), findsNothing);
    expect(find.text('Uma biblioteca de possibilidades'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('resultado da API pode ser adicionado à biblioteca', (
    tester,
  ) async {
    BookResult? selected;
    final service = OpenLibraryService(
      client: MockClient(
        (_) async => http.Response(
          '{"numFound":1,"docs":[{"key":"/works/OL1W","title":"Livro de teste","author_name":["Autora"]}]}',
          200,
        ),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ExplorePage(service: service, onAdd: (book) => selected = book),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), 'Dart');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Adicionar à biblioteca'));
    await tester.tap(find.text('Adicionar à biblioteca'));
    expect(selected?.title, 'Livro de teste');
    expect(selected?.author, 'Autora');
  });
}
