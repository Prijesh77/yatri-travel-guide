import 'package:intl/intl.dart';

import '../../features/itinerary/domain/itinerary.dart';
import '../../features/location/domain/start_presets.dart';
import '../../features/recommendations/domain/scored_place.dart';
import '../../features/transport/domain/transport_option.dart';
import '../time/kathmandu_time.dart';
import 'l10n.dart';

/// Turns domain values into display strings. Everything user-facing goes
/// through [AppLocalizations] so a Nepali ARB file is all that is needed to
/// translate the UI.
extension Formatters on AppLocalizations {
  String time(DateTime t) => DateFormat.Hm(localeName).format(t);

  String minuteOfDayTime(int minutes) => time(atMinuteOfDay(DateTime.utc(2000), minutes));

  String duration(int minutes) {
    if (minutes < 60) return durationMinutes(minutes);
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? durationHours(h) : durationHoursMinutes(h, m);
  }

  String amount(int value) => NumberFormat.decimalPattern(localeName).format(value);

  String fee(int value) => value == 0 ? free : npr(amount(value));

  String fare(FareRange range) {
    if (range.isFree) return free;
    if (range.isExact) return npr(amount(range.min));
    return nprRange(amount(range.min), amount(range.max));
  }

  String distance(double km) {
    if (km < 1) return distanceM(((km * 1000) / 50).round().clamp(1, 20) * 50);
    return distanceKm(NumberFormat('0.0', localeName).format(km));
  }

  String reason(ScoreReason r) => switch (r.kind) {
        ReasonKind.indoorInRain => reasonIndoorInRain(dayPartName((r.dayPart ?? DayPart.afternoon).name)),
        ReasonKind.coveredInRain => reasonCoveredInRain,
        ReasonKind.outdoorInRain => reasonOutdoorInRain,
        ReasonKind.noViews => reasonNoViews,
        ReasonKind.clearViews => reasonClearViews,
        ReasonKind.pleasantOutdoors => reasonPleasantOutdoors,
        ReasonKind.poorAirOutdoor => reasonPoorAirOutdoor(r.aqi ?? 0),
        ReasonKind.indoorPoorAir => reasonIndoorPoorAir,
        ReasonKind.hotMidday => reasonHotMidday,
        ReasonKind.bestTimeNow => reasonBestTimeNow((r.dayPart ?? DayPart.morning).name),
        ReasonKind.mealTime => reasonMealTime,
        ReasonKind.afterDark => reasonAfterDark,
        ReasonKind.closedToday => reasonClosedToday,
        ReasonKind.closedNow => reasonClosedNow,
        ReasonKind.opensLater => reasonOpensLater(minuteOfDayTime(r.minutes ?? 0)),
        ReasonKind.closesSoon => reasonClosesSoon(r.minutes ?? 0),
        ReasonKind.nearby => reasonNearby(distance(r.distanceKm ?? 0)),
        ReasonKind.far => reasonFar(distance(r.distanceKm ?? 0)),
        ReasonKind.matchesInterest => reasonMatchesInterest(categoryName(r.category?.name ?? '')),
        ReasonKind.highlight => reasonHighlight,
        ReasonKind.festival => reasonFestival(r.alertTitle ?? ''),
        ReasonKind.closureAlert => reasonClosureAlert(r.alertTitle ?? ''),
        ReasonKind.roadClosure => reasonRoadClosure(r.alertTitle ?? ''),
        ReasonKind.bandhWalkable => reasonBandhWalkable,
        ReasonKind.bandhTransport => reasonBandhTransport,
      };

  /// Short line for place cards, e.g. "Indoor, good for a rainy afternoon ·
  /// 1.2 km away".
  String cardReason(ScoredPlace s) {
    if (!s.isAvailable) {
      return reason(s.reasons.firstWhere((r) => r.kind.isBlocking));
    }
    final parts = [for (final r in s.highlights) reason(r)];
    return parts.join(' · ');
  }

  String transportNote(TransportNote note) => switch (note) {
        TransportNote.nightFare => noteNightFare,
        TransportNote.rushHour => noteRushHour,
        TransportNote.noBusService => noteNoBusService,
        TransportNote.estimatedRoute => busEstimated,
        TransportNote.bandh => noteBandh,
        TransportNote.unverifiedRoute => noteUnverifiedRoute,
        TransportNote.rerouted => noteRerouted,
      };

  String stopWarning(StopWarning w) => switch (w) {
        StopWarning.closedOnArrival => warningClosed,
        StopWarning.closesDuringVisit => warningClosesDuringVisit,
        StopWarning.pastEndTime => warningPastEnd,
      };

  String preset(StartPreset p) => switch (p) {
        StartPreset.thamel => presetThamel,
        StartPreset.patan => presetPatan,
        StartPreset.bhaktapur => presetBhaktapur,
        StartPreset.boudha => presetBoudha,
        StartPreset.airport => presetAirport,
      };

  /// Start points store a preset name, or an empty label for "my location".
  String startLabel(StartPoint start) {
    if (start.label.isEmpty) return myLocation;
    final preset = StartPreset.values.asNameMap()[start.label];
    return preset != null ? this.preset(preset) : start.label;
  }

  /// "20 min ago", "3 h ago".
  String ago(DateTime then, DateTime now) {
    final m = now.difference(then).inMinutes;
    if (m < 1) return justNow;
    if (m < 60) return minutesAgo(m);
    return hoursAgo(m ~/ 60);
  }

  /// "Today", "Tomorrow" or a short date.
  String relativeDay(DateTime t, DateTime now) {
    final days = dateOnly(t).difference(dateOnly(now)).inDays;
    if (days == 0) return today;
    if (days == 1) return tomorrow;
    return DateFormat.MMMEd(localeName).format(t);
  }

  String priceRangeShort((int, int) range) => nprRange(amount(range.$1), amount(range.$2));

  String pricePerNight((int, int) range) => perNight(priceRangeShort(range));

  String weekdays(Iterable<int> days) {
    final format = DateFormat.EEEE(localeName);
    // 2024-01-01 was a Monday.
    return [for (final d in days.toList()..sort()) format.format(DateTime.utc(2024, 1, d))].join(', ');
  }
}
