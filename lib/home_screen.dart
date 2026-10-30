import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:table_calendar/table_calendar.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Calendar display format (month, two weeks, or week)
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  // Local storage for events keyed by normalized date
  Map<DateTime, List<String>> _events = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  // Strips time so dates match consistently as map keys
  DateTime _normalizedDate( DateTime date) {
    return DateTime.utc(date.year, date.month, date.day);
  }

  // Returns event titles for a given date
  List<String> _getEventsForDay(DateTime day) {
    return _events[_normalizedDate(day)] ?? [];
  }

  // Shows a dialog for the user to type an event title
  Future<void> _addEvent() async {
    final titleController = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Event'),
        content: TextField(
          controller: titleController,
          decoration: const InputDecoration(
            hintText: 'Event title',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, titleController.text),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    // Store event in local map if title is not empty
    if (title != null && title.isNotEmpty) {
      setState(() {
        final key = _normalizedDate(_selectedDay!);
        if (_events[key] == null) _events[key] = [];
        _events[key]!.add(title);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Calendar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Interactive monthly calendar grid
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            eventLoader: _getEventsForDay,
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onFormatChanged: (format) {
              setState(() => _calendarFormat = format);
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
          ),
                    const SizedBox(height: 8),
          // Daily event list below the calendar
          Expanded(
            child: _getEventsForDay(_selectedDay!).isEmpty
                ? const Center(child: Text('No events for this day'))
                : ListView.builder(
                    itemCount: _getEventsForDay(_selectedDay!).length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: const Icon(Icons.event),
                        title: Text(_getEventsForDay(_selectedDay!)[index]),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addEvent,
        child: const Icon(Icons.add),
      ),
    );
  }
}
