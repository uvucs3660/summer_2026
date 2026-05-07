import 'package:xml/xml.dart';

import '../ims_id.dart';
import '../models/quiz.dart';

/// Emit a quiz as an IMS QTI 1.2 `questestinterop` document, the format
/// Canvas's CC importer expects. The 2025 export's
/// `non_cc_assessments/*.xml.qti` is the reference: per question, an
/// `<item>` with `<presentation>` (text + choices), `<resprocessing>`
/// (per-choice feedback hooks + correct-answer scoring), then
/// `<itemfeedback>` blocks holding the actual feedback text.
String emitQuizQti(Quiz q) {
  final assessmentId = imsId('quiz:${q.slug}');
  final b = XmlBuilder();
  b.processing('xml', 'version="1.0" encoding="UTF-8"');
  b.element('questestinterop', namespaces: {
    'http://www.imsglobal.org/xsd/ims_qtiasiv1p2': '',
    'http://www.w3.org/2001/XMLSchema-instance': 'xsi',
  }, attributes: {
    'xsi:schemaLocation':
        'http://www.imsglobal.org/xsd/ims_qtiasiv1p2 '
            'http://www.imsglobal.org/xsd/ims_qtiasiv1p2p1.xsd',
  }, nest: () {
    b.element('assessment',
        attributes: {'ident': assessmentId, 'title': q.title},
        nest: () {
      // Quiz-level metadata.
      b.element('qtimetadata', nest: () {
        _qtimd(b, 'cc_maxattempts', q.allowedAttempts.toString());
      });

      b.element('section', attributes: {'ident': 'root_section'}, nest: () {
        for (final question in q.questions) {
          _emitItem(b, question);
        }
      });
    });
  });
  return b.buildDocument().toXmlString(pretty: true);
}

void _qtimd(XmlBuilder b, String label, String entry) {
  b.element('qtimetadatafield', nest: () {
    b.element('fieldlabel', nest: label);
    b.element('fieldentry', nest: entry);
  });
}

void _emitItem(XmlBuilder b, QuizQuestion q) {
  final itemId = imsId('quiz-item:${q.slug}');
  b.element('item',
      attributes: {'ident': itemId, 'title': q.slug}, nest: () {
    // Item metadata.
    b.element('itemmetadata', nest: () {
      b.element('qtimetadata', nest: () {
        _qtimd(b, 'question_type', 'multiple_choice_question');
        _qtimd(b, 'points_possible', q.points.toString());
        _qtimd(
          b,
          'original_answer_ids',
          List<String>.generate(
            q.choices.length,
            (i) => _choiceId(q.slug, i),
          ).join(','),
        );
      });
    });

    // Question text + answer choices.
    b.element('presentation', nest: () {
      b.element('material', nest: () {
        b.element('mattext', attributes: {'texttype': 'text/html'},
            nest: q.textHtml);
      });
      b.element('response_lid',
          attributes: {'ident': 'response1', 'rcardinality': 'Single'},
          nest: () {
        b.element('render_choice', nest: () {
          for (var i = 0; i < q.choices.length; i++) {
            b.element('response_label',
                attributes: {'ident': _choiceId(q.slug, i)},
                nest: () {
              b.element('material', nest: () {
                b.element('mattext',
                    attributes: {'texttype': 'text/plain'},
                    nest: q.choices[i].text);
              });
            });
          }
        });
      });
    });

    // Response processing: a feedback hook per choice + the correct-answer
    // scoring rule. Order matters — Canvas evaluates conditions in source
    // order; the final `continue="No"` rule is the score setter for the
    // correct answer.
    b.element('resprocessing', nest: () {
      b.element('outcomes', nest: () {
        b.element('decvar', attributes: {
          'maxvalue': '100',
          'minvalue': '0',
          'varname': 'SCORE',
          'vartype': 'Decimal',
        });
      });

      // Per-choice feedback display (only emit for choices that have
      // feedback text).
      for (var i = 0; i < q.choices.length; i++) {
        if (q.choices[i].feedback.isEmpty) continue;
        final cid = _choiceId(q.slug, i);
        b.element('respcondition', attributes: {'continue': 'Yes'},
            nest: () {
          b.element('conditionvar', nest: () {
            b.element('varequal',
                attributes: {'respident': 'response1'}, nest: cid);
          });
          b.element('displayfeedback', attributes: {
            'feedbacktype': 'Response',
            'linkrefid': '${cid}_fb',
          });
        });
      }

      // Correct-answer scoring rule.
      final correctChoiceId = _choiceId(q.slug, q.correctIndex);
      b.element('respcondition', attributes: {'continue': 'No'}, nest: () {
        b.element('conditionvar', nest: () {
          b.element('varequal',
              attributes: {'respident': 'response1'},
              nest: correctChoiceId);
        });
        b.element('setvar', attributes: {
          'action': 'Set',
          'varname': 'SCORE',
        }, nest: '100');
      });
    });

    // Itemfeedback blocks holding the actual feedback text.
    for (var i = 0; i < q.choices.length; i++) {
      if (q.choices[i].feedback.isEmpty) continue;
      final cid = _choiceId(q.slug, i);
      b.element('itemfeedback', attributes: {'ident': '${cid}_fb'},
          nest: () {
        b.element('flow_mat', nest: () {
          b.element('material', nest: () {
            b.element('mattext',
                attributes: {'texttype': 'text/html'},
                nest: _composeFeedbackHtml(q.choices[i]));
          });
        });
      });
    }
  });
}

/// Stable choice identifier. The 2025 export uses 5-digit decimal IDs;
/// we use a slug-based form (Canvas accepts either since it just stores
/// them as strings).
String _choiceId(String questionSlug, int index) =>
    'c_${questionSlug}_$index';

/// Compose feedback HTML, optionally appending a "see cheatsheet-X"
/// pointer. The pointer is plain text — Canvas's CC importer flags
/// `$WIKI_REFERENCE$` tokens inside QTI feedback HTML as missing links
/// during import (the resolver runs over wiki pages and assignments
/// but not QTI). Naming the cheat sheet by name is enough; students
/// reach it from the module structure or via the cheat-sheet library
/// page.
String _composeFeedbackHtml(QuizChoice c) {
  final buf = StringBuffer();
  buf.write('<p>${_escapeHtml(c.feedback)}</p>');
  if (c.cheatsheetSlug != null) {
    buf.write(
      '<p><strong>See:</strong> <em>'
      '${_escapeHtml(_displayNameFromSlug(c.cheatsheetSlug!))}</em> '
      'cheat sheet (<code>${_escapeHtml(c.cheatsheetSlug!)}</code>)</p>',
    );
  }
  return buf.toString();
}

String _escapeHtml(String s) => s
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;');

String _displayNameFromSlug(String slug) {
  var s = slug;
  if (s.startsWith('cheatsheet-')) s = s.substring('cheatsheet-'.length);
  const acronyms = {'html', 'css', 'sql', 'pwa', 'mcp', 'eips'};
  return s.split('-').map((part) {
    if (acronyms.contains(part)) return part.toUpperCase();
    if (part.isEmpty) return part;
    return part[0].toUpperCase() + part.substring(1);
  }).join(' ');
}
