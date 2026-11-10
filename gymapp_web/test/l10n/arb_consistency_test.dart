import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The .arb files are the source of truth for texts (see l10n.yaml).
/// Both languages must define exactly the same messages — otherwise Polish
/// silently falls back to English, or a key exists only in the generated code.
void main() {
  Map<String, dynamic> load(String name) =>
      jsonDecode(File('lib/l10n/$name').readAsStringSync()) as Map<String, dynamic>;

  Set<String> messageKeys(Map<String, dynamic> arb) =>
      arb.keys.where((k) => !k.startsWith('@')).toSet();

  final en = load('app_en.arb');
  final pl = load('app_pl.arb');

  test('pl and en define the same messages', () {
    expect(messageKeys(pl).difference(messageKeys(en)), isEmpty, reason: 'only in app_pl.arb');
    expect(messageKeys(en).difference(messageKeys(pl)), isEmpty, reason: 'missing in app_pl.arb');
  });

  test('placeholders match between languages', () {
    final placeholder = RegExp(r'\{(\w+)\}');
    for (final key in messageKeys(en)) {
      final enNames = placeholder.allMatches(en[key] as String).map((m) => m.group(1)).toSet();
      final plNames = placeholder.allMatches(pl[key] as String).map((m) => m.group(1)).toSet();
      expect(plNames, enNames, reason: key);
    }
  });

  test('generated code contains every arb message', () {
    final generated = File('lib/l10n/app_localizations.dart').readAsStringSync();
    for (final key in messageKeys(en)) {
      expect(generated, contains(' $key'), reason: 'run `flutter gen-l10n` after editing .arb ($key)');
    }
  });
}
