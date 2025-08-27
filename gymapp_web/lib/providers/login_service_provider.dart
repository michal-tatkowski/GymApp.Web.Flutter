import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymapp_web/features/login/login_api_service.dart';

final loginServiceProvider = Provider<LoginApiService>(
      (ref) => LoginApiService(),
);