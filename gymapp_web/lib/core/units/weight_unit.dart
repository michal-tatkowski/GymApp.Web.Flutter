import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  const WeightFormat(this.unit);

  final WeightUnit unit;

  static const kg = WeightFormat(WeightUnit.kg);

  String get label => unit.label;
  double get step => unit.step;

  /// kg → number in this unit (lb rounded to 0.1, so 100 kg shows as 220.5 lb).
  double fromKg(double kg) =>
      unit == WeightUnit.kg ? kg : (kg * unit.perKg * 10).roundToDouble() / 10;

  /// Number typed in this unit → kg for the API (0.01 kg precision, like the API).
  double toKg(double value) =>
      unit == WeightUnit.kg ? value : (value / unit.perKg * 100).roundToDouble() / 100;

  /// "100", "102.5", "220.5" — no unit.
  String number(double kg) => formatNumber(fromKg(kg));

  /// "100 kg", "220.5 lb".
  String withUnit(double kg) => '${number(kg)} ${unit.label}';

  /// Upper limit for a set in this unit (the API allows 1000 kg).
  double get maxSetWeight => fromKg(1000);

  static String formatNumber(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);
}

/// Chosen in Settings, persisted. kg until the user picks lb.
final weightUnitProvider = NotifierProvider<WeightUnitNotifier, WeightUnit>(WeightUnitNotifier.new);

/// Shortcut for widgets: `ref.watch(weightFormatProvider).withUnit(volume)`.
final weightFormatProvider = Provider<WeightFormat>((ref) => WeightFormat(ref.watch(weightUnitProvider)));

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
