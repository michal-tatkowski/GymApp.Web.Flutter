import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/jwt_token_service.dart';

final jwtTokenServiceProvider = Provider<JwtTokenService>(
      (ref) => JwtTokenService.instance,
);