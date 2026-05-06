class Assignment {
  final String slug;
  final String title;
  final String htmlBody;
  final String groupSlug;
  final num pointsPossible;
  final DateTime? dueAt;
  final List<String> submissionTypes; // e.g. ["online_text_entry","online_url"]
  final String gradingType; // "points" | "percent" | "pass_fail"
  final String? rubricSlug;

  const Assignment({
    required this.slug,
    required this.title,
    required this.htmlBody,
    required this.groupSlug,
    required this.pointsPossible,
    required this.submissionTypes,
    required this.gradingType,
    this.dueAt,
    this.rubricSlug,
  });
}
