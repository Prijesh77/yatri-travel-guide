import 'package:flutter_test/flutter_test.dart';
import 'package:yatri/core/time/kathmandu_time.dart';
import 'package:yatri/features/places/domain/opening_hours.dart';

import '../../helpers/fixtures.dart';

void main() {
  final museum = OpeningHours.fromJson({'open': '10:30', 'close': '16:30', 'closedOn': ['tue']});

  test('status through the day', () {
    expect(museum.statusAt(ktm(2026, 10, 1, 9)).state, OpenState.opensLater);
    expect(museum.statusAt(ktm(2026, 10, 1, 9)).minutesUntilOpen, 90);
    expect(museum.statusAt(ktm(2026, 10, 1, 12)).state, OpenState.open);
    expect(museum.statusAt(ktm(2026, 10, 1, 16)).minutesUntilClose, 30);
    expect(museum.statusAt(ktm(2026, 10, 1, 16, 30)).state, OpenState.closedForDay);
  });

  test('weekly closing day', () {
    expect(museum.statusAt(tuesday.add(const Duration(hours: 12))).state, OpenState.closedToday);
    expect(museum.isClosedOn(tuesday), isTrue);
  });

  test('isOpenFor checks the whole visit', () {
    expect(museum.isOpenFor(ktm(2026, 10, 1, 15), 60), isTrue);
    expect(museum.isOpenFor(ktm(2026, 10, 1, 16), 60), isFalse);
    expect(museum.isOpenFor(ktm(2026, 10, 1, 10), 30), isFalse);
  });

  test('always open', () {
    const always = OpeningHours.always();
    expect(always.isOpenFor(ktm(2026, 10, 1, 3), 600), isTrue);
    expect(OpeningHours.fromJson({'alwaysOpen': true}).alwaysOpen, isTrue);
  });

  test('rejects bad data', () {
    expect(() => OpeningHours.fromJson({'open': '18:00', 'close': '09:00'}), throwsFormatException);
    expect(() => OpeningHours.fromJson({'open': '9', 'close': '17:00'}), throwsFormatException);
    expect(() => OpeningHours.fromJson({'open': '09:00', 'close': '17:00', 'closedOn': ['xyz']}),
        throwsFormatException);
  });

  test('JSON round trip', () {
    final back = OpeningHours.fromJson(museum.toJson());
    expect(back.openMinute, museum.openMinute);
    expect(back.closeMinute, museum.closeMinute);
    expect(back.closedWeekdays, museum.closedWeekdays);
  });
}
