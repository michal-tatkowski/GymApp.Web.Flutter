import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp_web/features/profile/presentation/widgets/measurements_card.dart';
import 'package:gymapp_web/features/profile/presentation/widgets/progress_photos.dart';
import 'package:gymapp_web/features/settings/settings_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_app.dart';

class FakeMeasurements extends MeasurementsRepository {
  FakeMeasurements(this.items) : super(Dio());

  final List<BodyMeasurement> items;
  final saved = <Map<BodyPart, double>>[];

  @override
  Future<List<BodyMeasurement>> list() async => List.of(items);

  @override
  Future<void> save(DateTime date, Map<BodyPart, double> cm) async {
    saved.add(cm);
    items.add(BodyMeasurement(date: date, cm: cm));
  }
}

class FakePhotoStore implements ProgressPhotoStore {
  final photos = <ProgressPhoto>[];
  bool cleared = false;

  @override
  Future<List<ProgressPhoto>> list() async => List.of(photos);

  @override
  Future<void> add(XFile picked) async => photos.add(ProgressPhoto(path: picked.path, takenAt: DateTime.now()));

  @override
  Future<void> delete(ProgressPhoto photo) async => photos.remove(photo);

  @override
  Future<void> clearAll() async {
    cleared = true;
    photos.clear();
  }
}

void main() {
  final today = DateUtils.dateOnly(DateTime.now());
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('measurements: latest per part with the change since the first; save any subset', (tester) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repo = FakeMeasurements([
      BodyMeasurement(date: today.subtract(const Duration(days: 60)), cm: const {BodyPart.waist: 90, BodyPart.arm: 35}),
      BodyMeasurement(date: today.subtract(const Duration(days: 10)), cm: const {BodyPart.waist: 86.5}),
    ]);
    await pumpScreen(tester, const Scaffold(body: SingleChildScrollView(child: MeasurementsCard())),
        overrides: [measurementsRepositoryProvider.overrideWithValue(repo)]);

    expect(tester.widget<Text>(find.byKey(const Key('measurements.waist'))).data, '86.5 cm');
    expect(find.text('−3.5 cm'), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(const Key('measurements.arm'))).data, '35 cm');

    await tester.tap(find.byKey(const Key('measurements.add')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('measurement.save')));
    await tester.pumpAndSettle();
    expect(find.text('Enter at least one measurement.'), findsOneWidget);
    expect(repo.saved, isEmpty);

    await tester.enterText(find.byKey(const Key('measurement.arm')), '36,5');
    await tester.tap(find.byKey(const Key('measurement.save')));
    await tester.pumpAndSettle();
    expect(repo.saved.single, {BodyPart.arm: 36.5});
    expect(tester.widget<Text>(find.byKey(const Key('measurements.arm'))).data, '36.5 cm');
  });

  testWidgets('photos: added from the picker, compared with the first, cleared on logout', (tester) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final store = FakePhotoStore()
      ..photos.add(ProgressPhoto(path: 'first.jpg', takenAt: today.subtract(const Duration(days: 90))));
    await pumpScreen(
      tester,
      Scaffold(body: ProgressPhotosCard(picker: (_) async => XFile('new.jpg'))),
      overrides: [progressPhotoStoreProvider.overrideWithValue(store)],
    );

    await tester.tap(find.byKey(const Key('photos.add')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose from gallery'));
    await tester.pumpAndSettle();
    expect(store.photos.map((p) => p.path), ['first.jpg', 'new.jpg']);
    expect(find.byKey(const Key('photo.1')), findsOneWidget);

    await tester.tap(find.byKey(const Key('photo.0'))); // newest
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('photo.compare')));
    await tester.pump();
    expect(find.byType(Image), findsNWidgets(2));
  });

  testWidgets('logout deletes the photos on this phone', (tester) async {
    final store = FakePhotoStore()..photos.add(ProgressPhoto(path: 'a.jpg', takenAt: today));
    await pumpScreen(tester, const SettingsScreen(), overrides: [progressPhotoStoreProvider.overrideWithValue(store)]);
    await tester.scrollUntilVisible(find.text('Logout'), 200, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Logout'));
    await tester.pumpAndSettle();
    expect(store.cleared, isTrue);
  });
}
