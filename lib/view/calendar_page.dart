import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../controller/library_controller.dart';
import '../database/model/reading_record.dart';
import '../widgets/empty_state.dart';
import '../widgets/record_card.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({
    super.key,
    required this.controller,
    required this.onCreate,
    required this.onOpen,
    this.onSelected,
  });
  final LibraryController controller;
  final ValueChanged<DateTime> onCreate;
  final ValueChanged<ReadingRecord> onOpen;
  final ValueChanged<DateTime>? onSelected;
  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  List<ReadingRecord> _events(DateTime day) => widget.controller.records
      .where((record) => isSameDay(record.eventAt, day))
      .toList();

  @override
  Widget build(BuildContext context) {
    final events = _events(_selectedDay);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      children: [
        const Text(
          'Tempo para ler',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: -.7,
          ),
        ),
        const SizedBox(height: 6),
        const Text('Escolha uma data e planeje sua próxima leitura.'),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: TableCalendar<ReadingRecord>(
              locale: 'pt_BR',
              firstDay: DateTime(2000),
              lastDay: DateTime(2100, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: CalendarFormat.month,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selected, focused) {
                setState(() {
                  _selectedDay = selected;
                  _focusedDay = focused;
                });
                widget.onSelected?.call(selected);
              },
              onPageChanged: (focused) => setState(() => _focusedDay = focused),
              eventLoader: _events,
              startingDayOfWeek: StartingDayOfWeek.monday,
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
              ),
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                selectedDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                todayDecoration: const BoxDecoration(
                  color: Color(0xFFA0B6A3),
                  shape: BoxShape.circle,
                ),
                markerDecoration: const BoxDecoration(
                  color: Color(0xFFB97B3F),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 22),
        Text(
          DateFormat("d 'de' MMMM", 'pt_BR').format(_selectedDay),
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        FilledButton.tonalIcon(
          onPressed: () => widget.onCreate(_selectedDay),
          icon: const Icon(Icons.add),
          label: const Text('Agendar leitura nesta data'),
        ),
        const SizedBox(height: 18),
        if (events.isEmpty)
          const EmptyState(
            icon: Icons.event_available_outlined,
            title: 'Um espaço na sua agenda',
            message: 'Nenhuma leitura agendada para esta data.',
          )
        else
          for (final record in events)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: RecordCard(
                record: record,
                onTap: () => widget.onOpen(record),
              ),
            ),
      ],
    );
  }
}
