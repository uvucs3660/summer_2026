import 'models/assignment.dart';

/// One teaching week, as declared in `course.yaml#schedule.weeks`.
/// The lecture that belongs to one schedule week.
class ScheduleLecture {
  final String slug;
  final String title;
  const ScheduleLecture({required this.slug, required this.title});

  /// The lecture pages title themselves `Week 7 — Contact: …`; the schedule
  /// already says which week it is, so the prefix is dropped from link text.
  String get shortTitle =>
      title.replaceFirst(RegExp(r'^Week\s+\d+\s*[—–-]\s*'), '');
}

class ScheduleWeek {
  final int week;
  final String topic;
  final List<String> meets;

  /// Optional callout — a holiday, a withdrawal deadline.
  final String? note;

  /// When set, this week opens a new act and the heading is emitted first.
  final String? actTitle;

  const ScheduleWeek({
    required this.week,
    required this.topic,
    required this.meets,
    this.note,
    this.actTitle,
  });
}

/// Mountain Time offset from UTC for a 2026 date.
///
/// `course.yaml` stores due dates in UTC. Displaying them raw shows a Friday
/// 23:59 deadline as Saturday, and puts a Sunday deadline in the wrong
/// teaching week. DST ends Sun Nov 1, 2026, so dates from then on are MST.
Duration mountainOffset(DateTime utc) =>
    Duration(hours: (utc.month >= 11) ? 7 : 6);

DateTime toMountain(DateTime utc) => utc.subtract(mountainOffset(utc));

const _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _monthNames = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String formatLocal(DateTime local) =>
    '${_dayNames[local.weekday - 1]} ${_monthNames[local.month - 1]} '
    '${local.day.toString().padLeft(2, '0')}';

/// Which teaching week a local deadline belongs to. Week 1 begins Mon Aug 17,
/// 2026 (the Monday before the first meeting).
int weekOf(DateTime local, DateTime firstMonday, int weekCount) {
  final days = local.difference(firstMonday).inDays;
  final w = (days ~/ 7) + 1;
  return w < 1 ? 1 : (w > weekCount ? weekCount : w);
}

/// Build the course schedule page body from the declared weeks and the real
/// assignment due dates.
///
/// Generated rather than hand-written: a maintained-by-hand schedule drifts
/// from `course.yaml` within a week, and the drift is invisible until a
/// student misses a deadline the page said was later.
String renderScheduleMarkdown({
  required String title,
  required List<ScheduleWeek> weeks,
  required List<Assignment> assignments,
  required DateTime firstMonday,
  String? finalsNote,
  Map<int, ScheduleLecture> lecturesByWeek = const {},
}) {
  final byWeek = <int, List<MapEntry<DateTime, String>>>{};
  for (final a in assignments) {
    if (a.dueAt == null) continue;
    final local = toMountain(a.dueAt!);
    final w = weekOf(local, firstMonday, weeks.length);
    (byWeek[w] ??= []).add(MapEntry(local, a.title));
  }

  final b = StringBuffer()
    ..writeln('# $title')
    ..writeln()
    ..writeln('Generated from the course definition — these are the dates '
        'Canvas enforces.')
    ..writeln()
    ..writeln('All deadlines are **23:59 Mountain Time**. Lateness is measured '
        'by the *commit* timestamp in git, not by when you paste the link '
        'into Canvas.')
    ..writeln();

  for (final w in weeks) {
    if (w.actTitle != null) {
      b
        ..writeln('## ${w.actTitle}')
        ..writeln();
    }
    final heading = w.topic.isEmpty
        ? 'Week ${w.week.toString().padLeft(2, '0')}'
        : 'Week ${w.week.toString().padLeft(2, '0')} — ${w.topic}';
    b
      ..writeln('### $heading')
      ..writeln()
      ..writeln('**Meets:** ${w.meets.isEmpty ? '—' : w.meets.join(' · ')}')
      ..writeln();
    // Emitted as a relative markdown link; the loader's post-pass resolves it
    // to a WIKI_REFERENCE token once every page slug is known.
    final lecture = lecturesByWeek[w.week];
    if (lecture != null) {
      b
        ..writeln(
            '**Lecture:** [${lecture.shortTitle}](${lecture.slug}.md)')
        ..writeln();
    }
    if (w.note != null) {
      b
        ..writeln('> ${w.note}')
        ..writeln();
    }
    final due = byWeek[w.week] ?? [];
    if (due.isNotEmpty) {
      due.sort((x, y) {
        final c = x.key.compareTo(y.key);
        return c != 0 ? c : x.value.compareTo(y.value);
      });
      b
        ..writeln('| Due | Assignment |')
        ..writeln('|---|---|');
      for (final e in due) {
        b.writeln('| ${formatLocal(e.key)} | ${e.value} |');
      }
      b.writeln();
    }
  }

  if (finalsNote != null) {
    b
      ..writeln('## Finals week')
      ..writeln()
      ..writeln(finalsNote)
      ..writeln();
  }
  return b.toString();
}
