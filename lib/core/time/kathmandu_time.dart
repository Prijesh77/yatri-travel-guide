/// Time handling for the app.
///
/// Opening hours, weather hours and itinerary times are all expressed in
/// Nepal Time (UTC+05:45), whatever timezone the phone is set to, so a visitor
/// planning from abroad still sees correct "open now" information.
///
/// Convention: a *Kathmandu wall time* is stored in a `DateTime` flagged as
/// UTC whose fields (year, month, hour, ...) equal the local Nepal clock
/// reading. UTC `DateTime`s have no daylight-saving jumps, so adding
/// durations is always safe. Never call `.toLocal()` on these values.
library;

const nepalUtcOffset = Duration(hours: 5, minutes: 45);

abstract interface class Clock {
  /// Current Kathmandu wall time.
  DateTime now();
}

class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now().toUtc().add(nepalUtcOffset);
}

class FixedClock implements Clock {
  const FixedClock(this.value);
  final DateTime value;

  @override
  DateTime now() => value;
}

/// Builds a Kathmandu wall time.
DateTime ktm(int year, int month, int day, [int hour = 0, int minute = 0]) =>
    DateTime.utc(year, month, day, hour, minute);

/// Parses an ISO local timestamp without offset (as returned by Open-Meteo
/// with `timezone=Asia/Kathmandu`) into a Kathmandu wall time.
DateTime parseKtmLocal(String iso) {
  final hasZone = iso.endsWith('Z') || RegExp(r'[+-]\d\d:\d\d$').hasMatch(iso);
  return hasZone ? DateTime.parse(iso).toUtc().add(nepalUtcOffset) : DateTime.parse('${iso}Z');
}

/// Minutes after midnight, e.g. `09:30` -> 570.
int minuteOfDay(DateTime t) => t.hour * 60 + t.minute;

/// Parses `HH:mm` into minutes after midnight.
int parseHhMm(String value) {
  final parts = value.split(':');
  if (parts.length != 2) {
    throw FormatException('Expected HH:mm, got "$value"');
  }
  final h = int.parse(parts[0]);
  final m = int.parse(parts[1]);
  if (h < 0 || h > 24 || m < 0 || m > 59) {
    throw FormatException('Invalid time "$value"');
  }
  return h * 60 + m;
}

String formatHhMm(int minutes) {
  final h = (minutes ~/ 60) % 24;
  final m = minutes % 60;
  return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
}

DateTime dateOnly(DateTime t) => DateTime.utc(t.year, t.month, t.day);

DateTime atMinuteOfDay(DateTime day, int minutes) =>
    dateOnly(day).add(Duration(minutes: minutes));

/// A window of the day, used for "best time to visit" and for wording
/// recommendation reasons ("good for a rainy afternoon").
enum DayPart {
  earlyMorning, // 04:00 - 07:00 (sunrise)
  morning, // 07:00 - 11:00
  afternoon, // 11:00 - 16:00
  evening, // 16:00 - 19:30 (sunset)
  night; // 19:30 - 04:00

  static DayPart of(DateTime t) {
    final m = minuteOfDay(t);
    if (m >= 4 * 60 && m < 7 * 60) return earlyMorning;
    if (m >= 7 * 60 && m < 11 * 60) return morning;
    if (m >= 11 * 60 && m < 16 * 60) return afternoon;
    if (m >= 16 * 60 && m < 19 * 60 + 30) return evening;
    return night;
  }

  static DayPart? tryParse(String value) {
    for (final p in values) {
      if (p.name == value) return p;
    }
    return null;
  }
}

/// Weekday parsing for `closedOn` lists (`mon` .. `sun`). Returns
/// `DateTime.weekday` numbers (Monday = 1).
int parseWeekday(String value) {
  const names = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
  final i = names.indexOf(value.toLowerCase().substring(0, 3));
  if (i < 0) throw FormatException('Unknown weekday "$value"');
  return i + 1;
}
