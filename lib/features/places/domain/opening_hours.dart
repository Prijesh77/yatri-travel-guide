import '../../../core/time/kathmandu_time.dart';

enum OpenState {
  /// Open now.
  open,

  /// Opens later today.
  opensLater,

  /// Already closed for the day.
  closedForDay,

  /// Closed all day (weekly closing day).
  closedToday,
}

class OpenStatus {
  const OpenStatus(this.state, {this.minutesUntilClose, this.minutesUntilOpen, this.opensAt, this.closesAt});

  final OpenState state;
  final int? minutesUntilClose;
  final int? minutesUntilOpen;

  /// Minutes after midnight.
  final int? opensAt;
  final int? closesAt;

  bool get isOpen => state == OpenState.open;
}

/// Daily opening hours in Kathmandu time with optional weekly closing days.
class OpeningHours {
  const OpeningHours({
    required this.openMinute,
    required this.closeMinute,
    this.closedWeekdays = const {},
    this.alwaysOpen = false,
  });

  const OpeningHours.always()
      : openMinute = 0,
        closeMinute = 24 * 60,
        closedWeekdays = const {},
        alwaysOpen = true;

  final int openMinute;
  final int closeMinute;

  /// `DateTime.weekday` values (Monday = 1).
  final Set<int> closedWeekdays;
  final bool alwaysOpen;

  factory OpeningHours.fromJson(Map<String, dynamic> json) {
    if (json['alwaysOpen'] == true) return const OpeningHours.always();
    final open = parseHhMm(json['open'] as String);
    final close = parseHhMm(json['close'] as String);
    if (close <= open) {
      throw FormatException('close must be after open: $json');
    }
    return OpeningHours(
      openMinute: open,
      closeMinute: close,
      closedWeekdays: {
        for (final d in (json['closedOn'] as List? ?? const [])) parseWeekday(d as String),
      },
    );
  }

  Map<String, dynamic> toJson() => alwaysOpen
      ? {'alwaysOpen': true}
      : {
          'open': formatHhMm(openMinute),
          'close': formatHhMm(closeMinute),
          'closedOn': [
            for (final d in closedWeekdays) const ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'][d - 1],
          ],
        };

  bool isClosedOn(DateTime day) => !alwaysOpen && closedWeekdays.contains(day.weekday);

  OpenStatus statusAt(DateTime t) {
    if (alwaysOpen) return const OpenStatus(OpenState.open);
    if (isClosedOn(t)) return const OpenStatus(OpenState.closedToday);
    final m = minuteOfDay(t);
    if (m < openMinute) {
      return OpenStatus(OpenState.opensLater,
          minutesUntilOpen: openMinute - m, opensAt: openMinute, closesAt: closeMinute);
    }
    if (m >= closeMinute) {
      return OpenStatus(OpenState.closedForDay, opensAt: openMinute, closesAt: closeMinute);
    }
    return OpenStatus(OpenState.open,
        minutesUntilClose: closeMinute - m, opensAt: openMinute, closesAt: closeMinute);
  }

  /// True if the place is open for the whole window `[start, start+minutes]`.
  bool isOpenFor(DateTime start, int minutes) {
    if (alwaysOpen) return true;
    final s = statusAt(start);
    return s.isOpen && s.minutesUntilClose! >= minutes;
  }
}
