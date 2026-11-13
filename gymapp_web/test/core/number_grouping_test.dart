import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp_web/core/units/weight_unit.dart';

void main() {
  test('English groups from 1,000 with commas', () {
    expect(WeightFormat.grouped(999, 'en'), '999');
    expect(WeightFormat.grouped(3380, 'en'), '3,380');
    expect(WeightFormat.grouped(11677.5, 'en'), '11,677.5');
    expect(WeightFormat.grouped(1250000, 'en'), '1,250,000');
    expect(WeightFormat.grouped(-12345, 'en'), '-12,345');
  });

  test('Polish groups from 10 000 with a no-break space', () {
    expect(WeightFormat.grouped(3380, 'pl'), '3380');
    expect(WeightFormat.grouped(11677.5, 'pl'), '11 677.5');
    expect(WeightFormat.grouped(250000, 'pl'), '250 000');
  });

  test('withUnit groups for display, number stays plain for inputs', () {
    const en = WeightFormat(WeightUnit.kg);
    const lb = WeightFormat(WeightUnit.lb, language: 'pl');
    expect(en.withUnit(2400), '2,400 kg');
    expect(en.number(2400), '2400');
    expect(lb.withUnit(10000), '22 046.2 lb');
    expect(lb.number(1000), '2204.6');
  });
}
