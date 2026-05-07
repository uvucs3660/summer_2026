import 'package:xml/xml.dart';

import '../ims_id.dart';
import '../models/quiz.dart';

/// Emit Canvas's `assessment_meta.xml` for a quiz — the Canvas-specific
/// metadata sidecar that the QTI file alone doesn't capture (description
/// HTML, due_at, allowed_attempts, scoring policy, assignment group).
///
/// Format mirrors the 2025 export's `g<id>/assessment_meta.xml`. Canvas's
/// CC importer reads BOTH this file and the QTI; the QTI carries the
/// questions, this carries the gradebook integration metadata.
String emitQuizMetaXml(Quiz q) {
  final assessmentId = imsId('quiz:${q.slug}');
  final b = XmlBuilder();
  b.processing('xml', 'version="1.0" encoding="UTF-8"');
  b.element('quiz', attributes: {
    'identifier': assessmentId,
  }, namespaces: {
    'http://canvas.instructure.com/xsd/cccv1p0': '',
  }, nest: () {
    b.element('title', nest: q.title);
    if (q.descriptionHtml.isNotEmpty) {
      b.element('description', nest: q.descriptionHtml);
    }
    if (q.dueAt != null) {
      b.element('due_at', nest: q.dueAt!.toIso8601String());
    }
    b.element('shuffle_answers', nest: 'false');
    b.element('scoring_policy', nest: q.scoringPolicy);
    b.element('hide_results', nest: 'false');
    // 'assignment' = a graded quiz that goes in the gradebook (vs.
    // 'survey', 'practice_quiz', 'graded_survey').
    b.element('quiz_type', nest: 'assignment');
    b.element('points_possible', nest: q.pointsPossible.toString());
    b.element('allowed_attempts', nest: q.allowedAttempts.toString());
    b.element('one_question_at_a_time', nest: 'false');
    b.element('cant_go_back', nest: 'false');
    b.element('available', nest: 'true');
    b.element('show_correct_answers', nest: 'true');
    b.element('show_correct_answers_last_attempt', nest: 'false');
    b.element('only_visible_to_overrides', nest: 'false');
    b.element('module_locked', nest: 'false');
    b.element('assignment_group_identifierref',
        nest: imsId('group:${q.groupSlug}'));
    b.element('assignment_overrides');
  });
  return b.buildDocument().toXmlString(pretty: true);
}
