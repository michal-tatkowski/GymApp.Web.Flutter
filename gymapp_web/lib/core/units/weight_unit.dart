import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/settings/presentation/settings_providers.dart' show localeProvider;
import '../storage/secure_storage_keys.dart';

/// Unit the user sees and types. The API always stores kilograms; conversion
/// happens only at the edges (display, input), so switching the unit also
/// converts the whole history and the charts.
enum WeightUnit {
  kg(label: 'kg', step: 2.5, perKg: 1),
  lb(label: 'lb', step: 5, perKg: 2.2046226218);

  const WeightUnit({required this.label, required this.step, required this.perKg});

  final String label;

  /// −/+ step in this unit: the smallest common plate pair (2 × 1.25 kg, 2 × 2.5 lb).
  final double step;
  final double perKg;
}

/// Formats and converts weights for one unit. Every weight on screen goes
/// through here — never append "kg" by hand.
class WeightFormat {
  const WeightFormat(this.unit, {this.language = 'en'});

  final WeightUnit unit;

  /// App language: how big numbers are grouped in [withUnit] ("11,677.5" / "11 677.5").
  final String language;

  static const kg = WeightFormat(WeightUnit.kg);

  String get label => unit.label;
  double get step => unit.step;

  /// kg → number in this unit (lb rounded to 0.1, so 100 kg shows as 220.5 lb).
  double fromKg(double kg) =>
      unit == WeightUnit.kg ? kg : (kg * unit.perKg * 10).roundToDouble() / 10;

  /// Number typed in this unit → kg for the API (0.01 kg precision, like the API).
  double toKg(double value) =>
      unit == WeightUnit.kg ? value : (value / unit.perKg * 100).roundToDouble() / 100;

  /// "100", "102.5", "220.5" — no unit, no grouping (also fills input fields).
  String number(double kg) => formatNumber(fromKg(kg));

  /// "100 kg", "220.5 lb", "11,677.5 kg" (Polish: "11 677.5 kg") — for display only: inputs use [number].
  String withUnit(double kg) => '${grouped(fromKg(kg), language)} ${unit.label}';

  /// Upper limit for a set in this unit (the API allows 1000 kg).
  double get maxSetWeight => fromKg(1000);

  static String formatNumber(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

  /// [formatNumber] with thousands grouped: English from 1,000 ("3,380"), Polish from 10 000 with a
  /// no-break space ("3380", "11 677.5") — the Polish typographic norm.
  static String grouped(double v, String language) {
    final text = formatNumber(v);
    final pl = language == 'pl';
    if (v.abs() < (pl ? 10000 : 1000)) return text;
    final dot = text.indexOf('.');
    final whole = dot < 0 ? text : text.substring(0, dot);
    final sign = whole.startsWith('-') ? '-' : '';
    final digits = whole.substring(sign.length);
    final out = StringBuffer(sign);
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) out.write(pl ? ' ' : ',');
      out.write(digits[i]);
    }
    return '$out${dot < 0 ? '' : text.substring(dot)}';
  }
}

/// Chosen in Settings, persisted. kg until the user picks lb.
final weightUnitProvider = NotifierProvider<WeightUnitNotifier, WeightUnit>(WeightUnitNotifier.new);

/// Shortcut for widgets: `ref.watch(weightFormatProvider).withUnit(volume)`.
final weightFormatProvider = Provider<WeightFormat>(
  (ref) => WeightFormat(ref.watch(weightUnitProvider), language: ref.watch(localeProvider.select((l) => l.languageCode))),
);

class WeightUnitNotifier extends Notifier<WeightUnit> {
  bool _changedByUser = false;

  @override
  WeightUnit build() {
    _restore();
    return WeightUnit.kg;
  }

  Future<void> _restore() async {
    final stored = (await SharedPreferences.getInstance()).getString(StorageKeys.weightUnit);
    if (!ref.mounted || _changedByUser) return;
    state = WeightUnit.values.where((u) => u.name == stored).firstOrNull ?? WeightUnit.kg;
  }

  Future<void> set(WeightUnit unit) async {
    _changedByUser = true;
    state = unit;
    await (await SharedPreferences.getInstance()).setString(StorageKeys.weightUnit, unit.name);
  }
}
