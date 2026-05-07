import 'assignment.dart';
import 'assignment_group.dart';
import 'late_policy.dart';
import 'module.dart';
import 'rubric.dart';
import 'web_resource.dart';
import 'wiki_page.dart';

class Course {
  final String title;
  final String courseCode;
  final DateTime startAt;
  final DateTime endAt;
  final String gradingScheme; // "letter" | "points"
  final LatePolicy latePolicy;
  final List<AssignmentGroup> assignmentGroups;
  final List<Assignment> assignments;
  final List<WikiPage> wikiPages;
  final List<Module> modules;
  final List<Rubric> rubrics;
  final List<WebResource> webResources;
  final String frontPageSlug;

  const Course({
    required this.title,
    required this.courseCode,
    required this.startAt,
    required this.endAt,
    required this.gradingScheme,
    required this.latePolicy,
    required this.assignmentGroups,
    required this.assignments,
    required this.wikiPages,
    required this.modules,
    required this.rubrics,
    this.webResources = const [],
    required this.frontPageSlug,
  });
}
