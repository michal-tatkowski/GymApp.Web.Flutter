import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/errors/exceptions.dart';
import '../../../core/errors/failure.dart';
import '../../../core/errors/failure_messages.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/presentation/auth_providers.dart';
import '../exercises/data/models/exercise.dart';
import '../exercises/presentation/category_ui.dart';
import '../exercises/presentation/exercises_providers.dart';
import '../plans/data/plan_models.dart';
import '../plans/presentation/plan_providers.dart';

/// What a share code points to — exactly one of [plan] / [exercise].
class SharedItem {
  const SharedItem({required this.code, this.plan, this.exercise});

  final String code;
  final WorkoutPlan? plan;
  final Exercise? exercise;

  static SharedItem fromJson(Map<String, dynamic> json, {String? code}) => SharedItem(
        code: code ?? json['code'] as String? ?? '',
        plan: json['plan'] is Map<String, dynamic> ? WorkoutPlan.fromJson(json['plan'] as Map<String, dynamic>) : null,
        exercise: json['exercise'] is Map<String, dynamic> ? Exercise.fromJson(json['exercise'] as Map<String, dynamic>) : null,
      );
}

/// "ABCD2345" → "ABCD-2345" (easier to read out and type).
String formatShareCode(String code) => code.length == 8 ? '${code.substring(0, 4)}-${code.substring(4)}' : code;

/// What the user typed → the API code (letters and digits, upper case).
String normalizeShareCode(String text) => text.toUpperCase().replaceAll(RegExp('[^A-Z0-9]'), '');

class SharingRepository {
  SharingRepository(this._dio);

  final Dio _dio;

  Future<String> sharePlan(String planId) => _code('Plans/$planId/share');
  Future<String> shareExercise(String exerciseId) => _code('Exercise/$exerciseId/share');

  Future<SharedItem> preview(String code) => _guard(() async {
        final res = await _dio.get<dynamic>('Shared/${normalizeShareCode(code)}');
        return SharedItem.fromJson(res.data as Map<String, dynamic>);
      });

  Future<SharedItem> import(String code) => _guard(() async {
        final res = await _dio.post<dynamic>('Shared/${normalizeShareCode(code)}/import');
        return SharedItem.fromJson(res.data as Map<String, dynamic>, code: normalizeShareCode(code));
      });

  Future<String> _code(String path) => _guard(() async {
        final res = await _dio.post<dynamic>(path);
        return (res.data as Map<String, dynamic>)['code'] as String;
      });

  static Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw mapDioErrorToFailure(e);
    } on TypeError {
      throw const ServerFailure();
    }
  }
}

final sharingRepositoryProvider = Provider((ref) => SharingRepository(ref.watch(dioProvider)));

/// Gets the code and shows it: big, copyable, and through the system share sheet.
Future<void> shareItem(BuildContext context, WidgetRef ref, {required String name, String? planId, String? exerciseId}) async {
  final t = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.of(context);
  final String code;
  try {
    final repo = ref.read(sharingRepositoryProvider);
    code = planId != null ? await repo.sharePlan(planId) : await repo.shareExercise(exerciseId!);
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(describeError(t, e))));
    return;
  }
  if (!context.mounted) return;
  final shown = formatShareCode(code);
  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      icon: const Icon(Icons.share_outlined),
      title: Text(t.shareTitle(name)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(t.shareHint, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          SelectableText(
            shown,
            key: const Key('share.code'),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(letterSpacing: 2, fontWeight: FontWeight.w700),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: shown));
            messenger.showSnackBar(SnackBar(content: Text(t.codeCopied)));
          },
          child: Text(t.copy),
        ),
        FilledButton.icon(
          onPressed: () => SharePlus.instance.share(ShareParams(text: t.shareMessage(name, shown))),
          icon: const Icon(Icons.ios_share),
          label: Text(t.share),
        ),
      ],
    ),
  );
}

/// "From a code": type the code, see what it is, add a copy to your plans / exercises.
Future<void> importFromCode(BuildContext context, WidgetRef ref) async {
  final added = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => const _ImportSheet(),
  );
  if (added != null && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(added)));
  }
}

class _ImportSheet extends ConsumerStatefulWidget {
  const _ImportSheet();

  @override
  ConsumerState<_ImportSheet> createState() => _ImportSheetState();
}

class _ImportSheetState extends ConsumerState<_ImportSheet> {
  final _code = TextEditingController();
  SharedItem? _preview;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _look() async {
    if (normalizeShareCode(_code.text).length < 8) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final item = await ref.read(sharingRepositoryProvider).preview(_code.text);
      setState(() => _preview = item);
    } catch (e) {
      if (mounted) setState(() => _error = describeError(AppLocalizations.of(context)!, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _import() async {
    final t = AppLocalizations.of(context)!;
    final navigator = Navigator.of(context);
    setState(() => _busy = true);
    try {
      final item = await ref.read(sharingRepositoryProvider).import(_code.text);
      ref.invalidate(plansProvider);
      ref.invalidate(exercisesProvider);
      navigator.pop(item.plan != null ? t.planImported(item.plan!.name) : t.exerciseImported(item.exercise?.name ?? ''));
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = describeError(t, e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final preview = _preview;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(t.importFromCode, style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          TextField(
            key: const Key('import.code'),
            controller: _code,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(labelText: t.shareCode, hintText: 'ABCD-2345', errorText: _error),
            onChanged: (_) => setState(() => _preview = null),
            onSubmitted: (_) => _look(),
          ),
          const SizedBox(height: 12),
          if (preview == null)
            FilledButton(
              key: const Key('import.look'),
              onPressed: _busy || normalizeShareCode(_code.text).length < 8 ? null : _look,
              child: Text(t.showShared),
            )
          else ...[
            Card(
              key: const Key('import.preview'),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: preview.plan != null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(preview.plan!.name, style: theme.textTheme.titleMedium),
                          const SizedBox(height: 4),
                          for (final i in preview.plan!.items)
                            Text('• ${i.exerciseName} · ${i.target}', style: theme.textTheme.bodyMedium),
                        ],
                      )
                    : ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(categoryIcon(preview.exercise!.category)),
                        title: Text(preview.exercise!.name),
                        subtitle: preview.exercise!.description == null ? null : Text(preview.exercise!.description!),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              key: const Key('import.add'),
              onPressed: _busy ? null : _import,
              icon: const Icon(Icons.download_done),
              label: Text(preview.plan != null ? t.addToMyPlans : t.addToMyExercises),
            ),
          ],
        ],
      ),
    );
  }
}
