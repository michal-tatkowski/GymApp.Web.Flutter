/// Domain-level error representation, safe to show to the user.
///
/// Use [Failure] in presentation/state layers — never throw raw [Exception]s
/// out of repositories. Convert low-level exceptions (Dio, Socket, etc.) to
/// [Failure] in the data layer.
///
/// [serverMessage] is the (already localized, via Accept-Language) message
/// from the API. When it is missing the UI shows a localized default for the
/// failure type — see `describeError` in `failure_messages.dart`.
sealed class Failure {
  const Failure([this.serverMessage]);

  final String? serverMessage;

  @override
  String toString() => '$runtimeType(${serverMessage ?? ''})';
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.serverMessage]);
}

class BadCertificateFailure extends Failure {
  const BadCertificateFailure();
}

class TimeoutFailure extends Failure {
  const TimeoutFailure([super.serverMessage]);
}

class CancelledFailure extends Failure {
  const CancelledFailure();
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([super.serverMessage]);
}

class ServerFailure extends Failure {
  const ServerFailure([super.serverMessage, this.statusCode]);
  final int? statusCode;
}

class ValidationFailure extends Failure {
  const ValidationFailure([super.serverMessage, this.fieldErrors = const {}]);
  final Map<String, String> fieldErrors;
}

class UnknownFailure extends Failure {
  const UnknownFailure([super.serverMessage]);
}
