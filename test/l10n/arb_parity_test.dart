import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guarda contra la deriva entre idiomas, que es el modo de falla típico de un
/// proyecto con varios .arb: se agrega una key al template (es) y nadie la
/// traduce, así que en inglés la app cae al español sin que nadie se entere.
/// `flutter gen-l10n` solo emite un warning que es fácil de pasar por alto;
/// esto falla el test.
void main() {
  Map<String, dynamic> readArb(String locale) {
    final file = File('lib/l10n/app_$locale.arb');
    expect(file.existsSync(), isTrue, reason: 'falta ${file.path}');
    return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  }

  // Las keys que empiezan con @ son metadata (@@locale, @miKey con su
  // description/placeholders), no mensajes traducibles.
  Set<String> messageKeys(Map<String, dynamic> arb) =>
      arb.keys.where((k) => !k.startsWith('@')).toSet();

  late Map<String, dynamic> es;
  late Map<String, dynamic> en;

  setUp(() {
    es = readArb('es');
    en = readArb('en');
  });

  test('app_en.arb traduce exactamente las mismas keys que app_es.arb', () {
    final esKeys = messageKeys(es);
    final enKeys = messageKeys(en);

    expect(
      esKeys.difference(enKeys),
      isEmpty,
      reason: 'keys sin traducir en app_en.arb',
    );
    expect(
      enKeys.difference(esKeys),
      isEmpty,
      reason: 'keys en app_en.arb que ya no existen en el template (es)',
    );
  });

  test('cada mensaje del template tiene description', () {
    final sinDescripcion = <String>[];
    for (final key in messageKeys(es)) {
      final meta = es['@$key'];
      if (meta is! Map || (meta['description'] as String?)?.isEmpty != false) {
        sinDescripcion.add(key);
      }
    }
    expect(
      sinDescripcion,
      isEmpty,
      reason:
          'el template es la referencia para traducir: sin description, quien '
          'traduzca no tiene contexto',
    );
  });

  test('los placeholders coinciden entre idiomas', () {
    final placeholder = RegExp(r'\{(\w+)\}');
    for (final key in messageKeys(es)) {
      final esPlaceholders =
          placeholder
              .allMatches(es[key] as String)
              .map((m) => m.group(1))
              .toSet();
      final enPlaceholders =
          placeholder
              .allMatches(en[key] as String)
              .map((m) => m.group(1))
              .toSet();
      expect(
        enPlaceholders,
        esPlaceholders,
        reason: 'los placeholders de "$key" no coinciden entre es y en',
      );
    }
  });

  test('el locale declarado en cada archivo es el correcto', () {
    expect(es['@@locale'], 'es');
    expect(en['@@locale'], 'en');
  });
}
