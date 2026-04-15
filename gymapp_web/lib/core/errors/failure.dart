/// Domain-level error representation, safe to show to the user.
///
/// Use [Failure] in presentation/state layers — never throw raw [Exception]s
/// out of repositories. Convert low-level exceptions (Dio, Socket, etc.) to
/// [Failure] in the data layer.
sealed class Failure {
  const Failure(this.message);
  final String message;

  @override
  String toString() => '$runtimeType($message)';
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Brak połączenia z internetem.']);
}

class TimeoutFailure extends Failure {
  const TimeoutFailure([super.message = 'Serwer nie odpowiada.']);
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([super.message = 'Sesja wygasła, zaloguj się ponownie.']);
}

class ServerFailure extends Failure {
  const ServerFailure(super.message, {this.statusCode});
  final int? statusCode;
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {this.fieldErrors = const {}});
  final Map<String, String> fieldErrors;
}

class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Wystąpił nieoczekiwany błąd.']);
}
