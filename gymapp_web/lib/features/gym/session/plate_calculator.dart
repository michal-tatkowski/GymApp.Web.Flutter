import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/storage/secure_storage_keys.dart';
import '../../../core/units/weight_unit.dart';
import '../../../l10n/app_localizations.dart';

/// Standard plates per unit, heaviest first (one of each per side is assumed unlimited).
const kPlatesKg = [25.0, 20.0, 15.0, 10.0, 5.0, 2.5, 1.25];
const kPlatesLb = [45.0, 35.0, 25.0, 10.0, 5.0, 2.5];

/// Barbells to choose from, in the unit's numbers.
const kBarsKg = [20.0, 15.0, 10.0];
const kBarsLb = [45.0, 35.0, 25.0];

/// Plates for ONE side of the bar, greedy from the heaviest (standard sets make that
/// optimal). Everything in the user's unit. [remainder] = what cannot be loaded.
({List<double> plates, double remainder}) platesPerSide(double total, double bar, WeightUnit unit) {
  final plates = <double>[];
  var left = (total - bar) / 2;
  for (final p in unit == WeightUnit.kg ? kPlatesKg : kPlatesLb) {
    while (left + 1e-9 >= p) {
      plates.add(p);
      left -= p;
    }
  }
  return (plates: plates, remainder: left < 1e-6 ? 0 : double.parse((left * 2).toStringAsFixed(2)));
}

/// Barbell weight in the user's unit; kg and lb remembered separately ("20" / "45").
final barWeightProvider = NotifierProvider<BarWeightNotifier, double>(BarWeightNotifier.new);

class BarWeightNotifier extends Notifier<double> {
  @override
  double build() {
    final unit = ref.watch(weightUnitProvider);
    _restore(unit);
    return _default(unit);
  }

  static double _default(WeightUnit unit) => unit == WeightUnit.kg ? kBarsKg.first : kBarsLb.first;
  static String _key(WeightUnit unit) => '${StorageKeys.barWeight}.${unit.name}';

  Future<void> _restore(WeightUnit unit) async {
    final stored = (await SharedPreferences.getInstance()).getDouble(_key(unit));
    if (stored != null && ref.mounted && ref.read(weightUnitProvider) == unit) state = stored;
  }

  Future<void> set(double value) async {
    state = value;
    await (await SharedPreferences.getInstance()).setDouble(_key(ref.read(weightUnitProvider)), value);
  }
}

Future<void> showPlateCalculator(BuildContext context, double weightKg) => showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => PlateCalculatorSheet(weightKg: weightKg),
    );

/// "On each side: 20 + 10 + 2.5" with a drawing of the loaded bar.
class PlateCalculatorSheet extends ConsumerWidget {
  const PlateCalculatorSheet({super.key, required this.weightKg});

  final double weightKg;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final weights = ref.watch(weightFormatProvider);
    final bar = ref.watch(barWeightProvider);
    final total = weights.fromKg(weightKg);
    final result = platesPerSide(total, bar, weights.unit);
    String n(double v) => WeightFormat.formatNumber(v);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('${t.plateCalculator} · ${weights.withUnit(weightKg)}', style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            if (total < bar)
              Text(t.platesBelowBar, key: const Key('plates.belowBar'))
            else ...[
              _LoadedBar(plates: result.plates, maxPlate: weights.unit == WeightUnit.kg ? kPlatesKg.first : kPlatesLb.first),
              const SizedBox(height: 12),
              Text(t.platesPerSide, style: theme.textTheme.labelLarge),
              Text(
                result.plates.isEmpty ? t.platesJustBar : result.plates.map(n).join(' + '),
                key: const Key('plates.perSide'),
                style: theme.textTheme.headlineSmall,
              ),
              if (result.remainder > 0)
                Text(t.platesRemainder('${n(result.remainder)} ${weights.label}'), style: TextStyle(color: theme.colorScheme.error)),
            ],
            const SizedBox(height: 16),
            Text(t.barWeight, style: theme.textTheme.labelLarge),
            const SizedBox(height: 4),
            SegmentedButton<double>(
              key: const Key('plates.bar'),
              showSelectedIcon: false,
              segments: [
                for (final b in weights.unit == WeightUnit.kg ? kBarsKg : kBarsLb)
                  ButtonSegment(value: b, label: Text('${n(b)} ${weights.label}')),
              ],
              selected: {bar},
              onSelectionChanged: (v) => ref.read(barWeightProvider.notifier).set(v.single),
            ),
          ],
        ),
      ),
    );
  }
}

/// Side view of one half of the bar: plates as bars, taller = heavier.
class _LoadedBar extends StatelessWidget {
  const _LoadedBar({required this.plates, required this.maxPlate});

  final List<double> plates;
  final double maxPlate;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final palette = [colors.primary, colors.tertiary, colors.secondary];
    return ExcludeSemantics(
      child: SizedBox(
        height: 72,
        child: Row(
          children: [
            Container(width: 48, height: 10, color: colors.outline),
            Container(width: 8, height: 26, color: colors.outline), // collar
            for (var i = 0; i < plates.length; i++)
              Container(
                width: 12,
                height: 24 + 48 * (plates[i] / maxPlate),
                margin: const EdgeInsets.only(left: 2),
                decoration: BoxDecoration(color: palette[i % palette.length], borderRadius: BorderRadius.circular(3)),
              ),
            Expanded(child: Container(height: 10, color: colors.outline)),
          ],
        ),
      ),
    );
  }
}
