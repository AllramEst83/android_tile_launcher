import 'package:android_tile_launcher/messages.dart';
import 'package:android_tile_launcher/model/agenda_format.dart';
import 'package:android_tile_launcher/model/calendar_event.dart';
import 'package:android_tile_launcher/model/clock_format.dart';
import 'package:android_tile_launcher/model/todo_item.dart';

/// What the READY. screen prints, as two runs of lines: the [intro] typed
/// before the loading effect, and the [body] printed after it.
class ReadyScript {
  const ReadyScript({required this.intro, required this.body});

  final List<String> intro;
  final List<String> body;
}

/// The day's summary as the Commodore would print it: the date, the next
/// [maxEvents] events still to come, the open to-dos (at most [maxTodos]
/// listed, the rest counted) and the unread mail.
///
/// [events] is null when the calendar could not be read (no access); [unread]
/// is null when there is no mail account or it could not be asked, in which
/// case the mail line is left out.
ReadyScript readyScript({
  required DateTime now,
  required List<CalendarEvent>? events,
  required List<TodoItem> todos,
  int? unread,
  int maxEvents = 4,
  int maxTodos = 5,
}) {
  final List<String> body = <String>[formatClockDate(now), ''];

  body.add(Messages.readyEvents);
  if (events == null) {
    body.add(' ${Messages.readyNoCalendar}');
  } else {
    final List<CalendarEvent> coming = <CalendarEvent>[
      for (final CalendarEvent e in events)
        if (e.end.isAfter(now)) e,
    ];
    if (coming.isEmpty) {
      body.add(' ${Messages.readyNothingPlanned}');
    } else {
      for (final CalendarEvent e in coming.take(maxEvents)) {
        body.add(' ${formatWhen(e, now)} ${e.title.toUpperCase()}');
      }
      if (coming.length > maxEvents) {
        body.add(' ${Messages.readyMore(coming.length - maxEvents)}');
      }
    }
  }
  body.add('');

  final List<TodoItem> open = <TodoItem>[
    for (final TodoItem t in todos)
      if (!t.done) t,
  ];
  body.add(Messages.readyTodos(open.length));
  if (open.isEmpty) {
    body.add(
      ' ${todos.isEmpty ? Messages.readyNothingToDo : Messages.readyAllDone}',
    );
  } else {
    for (final TodoItem t in open.take(maxTodos)) {
      body.add(' [ ] ${t.title.toUpperCase()}');
    }
    if (open.length > maxTodos) {
      body.add(' ${Messages.readyMore(open.length - maxTodos)}');
    }
  }

  if (unread != null) {
    body
      ..add('')
      ..add(Messages.readyUnread(unread));
  }
  body
    ..add('')
    ..add(Messages.bootReady);

  return ReadyScript(
    intro: <String>[
      Messages.readyLoad,
      Messages.readySearching,
      Messages.bootLoading,
    ],
    body: <String>[Messages.bootReady, Messages.bootRun, '', ...body],
  );
}
