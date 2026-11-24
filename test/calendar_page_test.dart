import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:entrelinhas/controller/library_controller.dart';
import 'package:entrelinhas/database/helper/record_helper.dart';
import 'package:entrelinhas/database/model/reading_record.dart';
import 'package:entrelinhas/service/connectivity_service.dart';
import 'package:entrelinhas/service/remote_records.dart';
import 'package:entrelinhas/theme/app_theme.dart';
import 'package:entrelinhas/view/calendar_page.dart';

class _Offline extends ConnectivityService {
  @override
  Future<bool> check() async => false;
  @override
  Stream<bool> get changes => const Stream.empty();
}

class _Remote implements RemoteRecords {
  @override
  Stream<RemoteSnapshot> watch(String userId) => const Stream.empty();
  @override
  Future<void> save(ReadingRecord record) async => fail('Sem conexão.');
  @override
  Future<void> delete(ReadingRecord record) async => fail('Sem conexão.');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  late Directory directory;
  late RecordHelper local;
  late LibraryController controller;
  late DateTime today;
  late DateTime scheduled;

  setUp(() async {
    await initializeDateFormatting('pt_BR');
    today = DateTime.now();
    scheduled = DateTime(
      today.year,
      today.month,
      today.day < 27 ? today.day + 1 : 1,
    );
    directory = await Directory.systemTemp.createTemp('biblioteca_calendar_');
    local = RecordHelper(
      factory: databaseFactoryFfiNoIsolate,
      databasePath: path.join(directory.path, 'records.db'),
    );
    await local.save(
      ReadingRecord.create(
        'alice',
        date: today,
      ).copyWith(title: 'Leitura de hoje'),
    );
    await local.save(
      ReadingRecord.create(
        'alice',
        date: scheduled,
      ).copyWith(title: 'Leitura agendada'),
    );
    controller = LibraryController(
      userId: 'alice',
      local: local,
      remote: _Remote(),
      connectivity: _Offline(),
    );
    await controller.start();
    while (controller.synchronizing) {
      await Future<void>.delayed(Duration.zero);
    }
  });

  tearDown(() async {
    controller.dispose();
    await local.close();
    await directory.delete(recursive: true);
  });

  Future<void> open(
    WidgetTester tester, {
    required ValueChanged<DateTime> onCreate,
    required ValueChanged<ReadingRecord> onOpen,
  }) async {
    tester.view.physicalSize = const Size(430, 950);
    tester.view.devicePixelRatio = 1;
    await tester.binding.setSurfaceSize(const Size(430, 950));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('pt', 'BR'),
        supportedLocales: const [Locale('pt', 'BR')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: Scaffold(
          body: CalendarPage(
            controller: controller,
            onCreate: onCreate,
            onOpen: onOpen,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('selecionar data lista livros locais e permite agendar e abrir', (
    tester,
  ) async {
    DateTime? createdAt;
    ReadingRecord? opened;
    await open(
      tester,
      onCreate: (value) => createdAt = value,
      onOpen: (value) => opened = value,
    );
    expect(controller.records, hasLength(2));
    await tester.scrollUntilVisible(
      find.text('Leitura de hoje'),
      200,
      scrollable: find.byType(Scrollable).first,
      maxScrolls: 5,
    );
    expect(find.text('Leitura de hoje'), findsOneWidget);
    expect(find.text('Leitura agendada'), findsNothing);

    await tester.drag(find.byType(ListView), const Offset(0, 800));
    await tester.pumpAndSettle();

    await tester.tap(
      find
          .descendant(
            of: find.byType(TableCalendar<ReadingRecord>),
            matching: find.text('${scheduled.day}'),
          )
          .first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Leitura de hoje'), findsNothing);
    expect(find.text('Leitura agendada'), findsOneWidget);
    final calendar = tester.widget<TableCalendar<ReadingRecord>>(
      find.byType(TableCalendar<ReadingRecord>),
    );
    expect(calendar.eventLoader!(scheduled), hasLength(1));
    await tester.tap(find.text('Agendar leitura nesta data'));
    expect(isSameDay(createdAt, scheduled), isTrue);
    await tester.ensureVisible(find.text('Leitura agendada'));
    await tester.tap(find.text('Leitura agendada'));
    expect(opened?.title, 'Leitura agendada');
    expect(tester.takeException(), isNull);
  });

  testWidgets('navegação mensal mantém seleção e agenda na data escolhida', (
    tester,
  ) async {
    DateTime? createdAt;
    await open(tester, onCreate: (value) => createdAt = value, onOpen: (_) {});
    await tester.tap(
      find.descendant(
        of: find.byType(TableCalendar<ReadingRecord>),
        matching: find.byIcon(Icons.chevron_right),
      ),
    );
    await tester.pumpAndSettle();
    final next = DateTime(today.year, today.month + 1, 1);
    final calendar = tester.widget<TableCalendar<ReadingRecord>>(
      find.byType(TableCalendar<ReadingRecord>),
    );
    expect(calendar.focusedDay.year, next.year);
    expect(calendar.focusedDay.month, next.month);

    await tester.tap(
      find
          .descendant(
            of: find.byType(TableCalendar<ReadingRecord>),
            matching: find.text('1'),
          )
          .first,
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Nenhuma leitura agendada para esta data.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Agendar leitura nesta data'));
    expect(isSameDay(createdAt, next), isTrue);
    expect(tester.takeException(), isNull);
  });
}
