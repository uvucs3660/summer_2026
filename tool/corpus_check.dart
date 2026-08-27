import 'dart:io';
import 'package:course_builder/src/loaders/deck_loader.dart';

void main() {
  final dir = Directory('content/cs3540/2026/lectures/slides');
  var decks = 0, slides = 0, words = 0, links = 0, unscripted = 0;

  final files = dir.listSync().whereType<File>().where(
      (f) => RegExp(r'w\d\d-.*\.md$').hasMatch(f.path)).toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  for (final f in files) {
    final d = loadDeck(f.path);
    decks++;
    slides += d.slides.length;
    words += d.wordCount;
    for (final s in d.slides) {
      links += s.links.length;
      if (s.script.isEmpty) {
        unscripted++;
        stderr.writeln('${d.id} slide ${s.index}: no script');
      }
    }
  }
  stdout.writeln('decks=$decks slides=$slides words=$words links=$links '
      'unscripted=$unscripted');
  if (unscripted > 0) exit(1);
}
