import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'jwt_token_provider.dart';
import 'login_service_provider.dart';

final loginStateProvider = StateNotifierProvider<LoginNotifier, bool>(
      (ref) => LoginNotifier(ref),
);

class LoginNotifier extends StateNotifier<bool> {
  final Ref ref;
  LoginNotifier(this.ref) : super(false);

  Future<void> login(String email, String password) async {
    state = true;
    try {
      final success = await ref.read(loginServiceProvider).login(email, password);
      if (success.$1) {
        await ref.read(jwtTokenServiceProvider).saveToken(success.$2);
      } else {
        throw Exception('Niepoprawny login lub hasło.');
      }
    } finally {
      state = false; // stop loading
    }
  }

  Future<void> getUsers() async {
    state = true;
    try {
      await ref.read(loginServiceProvider).getUsers();
    } finally {
      state = false; // stop loading
    }
  }
}
