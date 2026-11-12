import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp_web/features/gym/exercises/data/models/exercise.dart';
import 'package:gymapp_web/features/gym/exercises/presentation/exercises_providers.dart';
import 'package:gymapp_web/features/gym/plans/presentation/exercise_picker_sheet.dart';

import '../helpers/test_app.dart';

void main() {
  testWidgets('typing filters the exercises (server-side search)', (tester) async {
    final repo = FakeExerciseRepository(const [
      Exercise(id: 'bench', name: 'Bench press', category: ExerciseCategory.push),
      Exercise(id: 'row', name: 'Barbell row', category: ExerciseCategory.pull),
    ]);
    Exercise? picked;
    await pumpScreen(
      tester,
      Builder(
        builder: (context) => Scaffold(
          body: TextButton(onPressed: () async => picked = await pickExercise(context), child: const Text('open')),
        ),
      ),
      overrides: [exerciseRepositoryProvider.overrideWithValue(repo)],
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Barbell row'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('picker.search')), 'bench');
    await tester.pump(const Duration(milliseconds: 350)); // debounce
    await tester.pumpAndSettle();

    expect(repo.queries.last.search, 'bench');
    expect(find.text('Barbell row'), findsNothing);
    await tester.tap(find.text('Bench press'));
    await tester.pumpAndSettle();
    expect(picked?.id, 'bench');
  });
}
