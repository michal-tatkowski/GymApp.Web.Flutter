import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/failure_messages.dart';
import '../../core/units/weight_unit.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/gradient_background.dart';
import '../../l10n/app_localizations.dart';
import '../../routing/app_routes.dart';
import 'presentation/profile_providers.dart';
import 'presentation/widgets/profile_edit_form.dart';
import 'presentation/widgets/profile_view.dart';

/// Profile: read-only view ⇄ edit form. The form owns its fields; this screen
/// only switches modes and saves (see ProfileController.save).
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<ProfileEditFormState>();
  bool _editing = false;
  bool _saving = false;

  Future<void> _refresh() async {
    final t = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(profileControllerProvider.notifier).refresh();
    } catch (e) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(describeError(t, e))));
    }
  }

  Future<void> _save() async {
    final req = _formKey.currentState?.buildRequest();
    if (req == null) return;

    final t = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    final error = await ref.read(profileControllerProvider.notifier).save(req);
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (error == null) _editing = false; // on failure the form keeps what the user typed
    });
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(error == null ? t.profileSaved : describeError(t, error))));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final profileAsync = ref.watch(profileControllerProvider);
    final busy = profileAsync.isLoading || _saving;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.profile),
        actions: [
          if (profileAsync.hasValue && _editing) ...[
            TextButton(
              onPressed: busy ? null : () => setState(() => _editing = false),
              child: Text(t.cancel),
            ),
            TextButton(onPressed: busy ? null : _save, child: Text(t.save)),
          ] else ...[
            if (profileAsync.hasValue)
              IconButton(
                icon: const Icon(Icons.edit),
                tooltip: t.edit,
                onPressed: () => setState(() => _editing = true),
              ),
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: t.settings,
              onPressed: () => context.push(AppRoutes.settings),
            ),
          ],
        ],
      ),
      body: GradientBackground(
        child: SafeArea(
          child: profileAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => ErrorView(
              message: describeError(t, err),
              onRetry: () => ref.read(profileControllerProvider.notifier).load(),
            ),
            data: (profile) => _editing
                ? ProfileEditForm(key: _formKey, initial: profile, enabled: !busy)
                : RefreshIndicator(onRefresh: _refresh, child: ProfileView(profile: profile, weights: ref.watch(weightFormatProvider))),
          ),
        ),
      ),
    );
  }
}
