import 'dart:math';

final _random = Random.secure();

/// Random UUID v4 ("xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx") — ids the app assigns
/// itself, e.g. workouts saved offline (the API accepts them as entry ids).
String newUuid() {
  final b = List<int>.generate(16, (_) => _random.nextInt(256));
  b[6] = (b[6] & 0x0f) | 0x40; // version 4
  b[8] = (b[8] & 0x3f) | 0x80; // RFC 4122 variant
  String hex(int from, int to) => b.sublist(from, to).map((x) => x.toRadixString(16).padLeft(2, '0')).join();
  return '${hex(0, 4)}-${hex(4, 6)}-${hex(6, 8)}-${hex(8, 10)}-${hex(10, 16)}';
}
