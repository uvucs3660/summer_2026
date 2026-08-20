import 'dart:io';
import 'package:course_builder/src/loaders/course_loader.dart';
import 'package:course_builder/src/models/assignment.dart';
import 'package:course_builder/src/schedule.dart';
import 'package:test/test.dart';

void main() {
  group('mountain time', () {
    // course.yaml stores UTC. Rendering it raw shows a Friday 23:59 deadline
    // as Saturday and files a Sunday deadline into the wrong teaching week.
    test('is UTC-6 before the Nov 1 DST change', () {
      expect(mountainOffset(DateTime.parse('2026-10-26T05:59:59')),
          const Duration(hours: 6));
    });

    test('is UTC-7 from November', () {
      expect(mountainOffset(DateTime.parse('2026-11-02T06:59:59')),
          const Duration(hours: 7));
    });

    test('a 23:59 MT deadline renders on its own local day, not the next', () {
      // Fri Aug 21 23:59 MT is stored as Sat Aug 22 05:59 UTC.
      final local = toMountain(DateTime.parse('2026-08-22T05:59:59'));
      expect(formatLocal(local), 'Fri Aug 21');
    });

    test('a November deadline also lands on its own day', () {
      final local = toMountain(DateTime.parse('2026-11-06T06:59:59'));
      expect(formatLocal(local), 'Thu Nov 05');
    });
  });

  group('weekOf', () {
    final firstMonday = DateTime.parse('2026-08-17');
    test('assigns a Sunday deadline to the week it closes', () {
      expect(weekOf(DateTime.parse('2026-08-23'), firstMonday, 16), 1);
      expect(weekOf(DateTime.parse('2026-08-30'), firstMonday, 16), 2);
    });
    test('clamps to the declared week range', () {
      expect(weekOf(DateTime.parse('2026-07-01'), firstMonday, 16), 1);
      expect(weekOf(DateTime.parse('2027-03-01'), firstMonday, 16), 16);
    });
  });

  group('renderScheduleMarkdown', () {
    Assignment a(String title, String iso) => Assignment(
          slug: title.toLowerCase().replaceAll(' ', '-'),
          title: title,
          htmlBody: '',
          groupSlug: 'g',
          pointsPossible: 1,
          submissionTypes: const ['online_url'],
          gradingType: 'points',
          rubricSlug: null,
          dueAt: DateTime.parse(iso),
        );

    final weeks = [
      const ScheduleWeek(
          week: 1, topic: 'Start', meets: ['Thu Aug 20'], actTitle: 'Act I'),
      const ScheduleWeek(week: 2, topic: 'Next', meets: ['Tue Aug 25'],
          note: 'A holiday note.'),
    ];

    test('files each assignment into the week its deadline closes', () {
      final md = renderScheduleMarkdown(
        title: 'Course Schedule',
        weeks: weeks,
        assignments: [a('Early', '2026-08-22T05:59:59'),
                      a('Later', '2026-08-31T05:59:59')],
        firstMonday: DateTime.parse('2026-08-17'),
      );
      final w1 = md.indexOf('Week 01');
      final w2 = md.indexOf('Week 02');
      expect(md.indexOf('Early'), inInclusiveRange(w1, w2));
      expect(md.indexOf('Later'), greaterThan(w2));
    });

    test('emits the act heading and the note', () {
      final md = renderScheduleMarkdown(
        title: 'T', weeks: weeks, assignments: const [],
        firstMonday: DateTime.parse('2026-08-17'));
      expect(md, contains('## Act I'));
      expect(md, contains('> A holiday note.'));
    });

    test('a week with no meetings renders an em dash, not an empty row', () {
      final md = renderScheduleMarkdown(
        title: 'T',
        weeks: [const ScheduleWeek(week: 1, topic: '', meets: [])],
        assignments: const [], firstMonday: DateTime.parse('2026-08-17'));
      expect(md, contains('**Meets:** —'));
    });
  });

  group('the generated page in the real course', () {
    late final course = loadCourse('content/cs3540/2026');

    test('a course-schedule page is emitted', () {
      expect(course.wikiPages.map((p) => p.slug), contains('course-schedule'));
    });

    test('it lists every week declared in course.yaml', () {
      final page =
          course.wikiPages.firstWhere((p) => p.slug == 'course-schedule');
      for (var w = 1; w <= 16; w++) {
        expect(page.htmlBody, contains('Week ${w.toString().padLeft(2, '0')}'),
            reason: 'week $w missing from the schedule');
      }
    });

    test('every dated assignment appears on it', () {
      final page =
          course.wikiPages.firstWhere((p) => p.slug == 'course-schedule');
      final dated = course.assignments.where((a) => a.dueAt != null);
      expect(dated, isNotEmpty);
      for (final a in dated) {
        expect(page.htmlBody, contains(a.title),
            reason: '${a.slug} has a due date but is not on the schedule');
      }
    });

    test('it cannot drift — no authored course-schedule.md exists', () {
      expect(
          File('content/cs3540/2026/pages/course-schedule.md').existsSync(),
          isFalse,
          reason: 'the page is generated; an authored copy would go stale');
    });
  });
}
