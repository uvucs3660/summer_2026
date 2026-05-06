import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Generates a stable 33-character Canvas-style identifier ("g" + 32 hex)
/// from a slug. Caller is responsible for namespacing slugs (e.g.
/// "assignment:job-pack" vs "page:job-pack") to avoid collisions across kinds.
String imsId(String slug) {
  final digest = md5.convert(utf8.encode(slug));
  return 'g${digest.toString()}';
}
