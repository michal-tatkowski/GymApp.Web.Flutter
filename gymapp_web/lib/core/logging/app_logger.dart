import 'package:logger/logger.dart';

/// App-wide logger. Prefer this over `print()`.
/// Usage: `log.i('message')`, `log.e('msg', error: e, stackTrace: s)`.
final Logger log = Logger(
  printer: PrettyPrinter(
    methodCount: 0,
    errorMethodCount: 5,
    lineLength: 100,
    colors: true,
    printEmojis: false,
    dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
  ),
);
