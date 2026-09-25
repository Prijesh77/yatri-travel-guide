import 'dart:convert';

import '../../../core/time/kathmandu_time.dart';
import '../../alerts/domain/condition_alert.dart';
import '../../places/domain/place_category.dart';
import '../../recommendations/domain/scored_place.dart';
import '../../transport/domain/transport_option.dart';
import '../../weather/domain/weather.dart';
import 'itinerary.dart';

/// What the AI model sends back: an ordered list of place ids with a short
/// tip each, plus a one-line summary of the day.
class AiPlanSuggestion {
  const AiPlanSuggestion({required this.summary, required this.stops});
  final String summary;
  final List<AiStop> stops;
}

class AiStop {
  const AiStop(this.placeId, this.note);
  final String placeId;
  final String note;
}

/// Builds the prompt for the AI planner and validates its answer.
///
/// The model only chooses and orders places from a candidate list the app
/// provides (already filtered for opening hours and conditions) and writes
/// short tips. Times, transport and warnings are then computed on device, so
/// the model cannot invent places, prices or opening hours.
class AiPlanPrompt {
  static const system = '''
You are Yatri, a local trip planner for the Kathmandu Valley (Kathmandu, Lalitpur, Bhaktapur).
Plan ONE day for the traveller using ONLY places from the "candidates" list, referenced by their "id".
Rules:
- Pick between 2 and MAX_STOPS stops that fit between the start and end time, including travel.
- Order stops to keep travel short; start near the start point.
- Respect each place's opening hours on that date and its typical visit length.
- Use the weather: prefer indoor places when rain is likely or air quality is poor; viewpoints need clear skies; sunrise/evening places at those times.
- Avoid areas with active disruptions (road closures, traffic, bandh). Events (jatras, processions) near a stop are worth mentioning as optional.
- Match the interests and the budget (budget = free or cheap entry, local transport; comfort = fewer, better-known stops).
- Include at most one meal stop unless food is an interest.
- Each note: max 20 words, practical and specific (what to see or when to go). Do not state prices or opening hours that are not in the data.
- Summary: one sentence explaining why this plan suits today's conditions.
''';

  static Map<String, dynamic> schema(List<String> candidateIds) => {
        'type': 'OBJECT',
        'properties': {
          'summary': {'type': 'STRING'},
          'stops': {
            'type': 'ARRAY',
            'items': {
              'type': 'OBJECT',
              'properties': {
                'placeId': {'type': 'STRING', 'enum': candidateIds},
                'note': {'type': 'STRING'},
              },
              'required': ['placeId', 'note'],
            },
          },
        },
        'required': ['summary', 'stops'],
      };

  static String systemFor(ItineraryRequest request) =>
      system.replaceAll('MAX_STOPS', '${request.maxStops}');

  /// JSON context for the model. Coordinates are rounded so no precise
  /// location of the user leaves the device.
  static String prompt({
    required ItineraryRequest request,
    required VisitorType visitor,
    required List<ScoredPlace> candidates,
    DailyForecast? forecast,
    WeatherSnapshot? startWeather,
    List<ConditionAlert> alerts = const [],
  }) {
    final day = request.startTime;
    String hhmm(DateTime t) => formatHhMm(minuteOfDay(t));
    final data = {
      'date': '${day.year}-${_pad2(day.month)}-${_pad2(day.day)}',
      'weekday': const ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][day.weekday - 1],
      'startTime': hhmm(request.startTime),
      'endTime': hhmm(request.endTime),
      'start': {
        'label': request.start.label.isEmpty ? 'traveller location' : request.start.label,
        'lat': _round(request.start.location.lat),
        'lng': _round(request.start.location.lng),
      },
      'budget': switch (request.travelStyle) {
        TravelStyle.budget => 'budget',
        TravelStyle.balanced => 'mid-range',
        TravelStyle.comfort => 'comfort',
      },
      'visitor': visitor.name,
      'interests': [for (final c in request.interests) c.name],
      'maxStops': request.maxStops,
      'weather': {
        if (forecast != null) ...{
          'condition': forecast.condition.name,
          'minC': forecast.minC.round(),
          'maxC': forecast.maxC.round(),
          if (forecast.precipitationProbability != null) 'rainChancePercent': forecast.precipitationProbability,
        },
        if (startWeather?.usAqi != null) 'usAqi': startWeather!.usAqi,
        if (forecast == null && startWeather != null) 'conditionAtStart': startWeather.condition.name,
      },
      'alerts': [
        for (final a in alerts)
          {
            'type': a.type.name,
            'title': a.title,
            if (a.locationLabel.isNotEmpty) 'where': a.locationLabel,
            'from': hhmm(a.start),
            'to': hhmm(a.end),
          },
      ],
      'candidates': [
        for (final s in candidates)
          {
            'id': s.place.id,
            'name': s.place.name,
            'city': s.place.city.name,
            'category': s.place.category.name,
            if (s.place.secondaryCategories.isNotEmpty)
              'alsoGoodFor': [for (final c in s.place.secondaryCategories) c.name],
            'setting': s.place.setting.name,
            'hours': s.place.openingHours.alwaysOpen
                ? 'open all day'
                : '${formatHhMm(s.place.openingHours.openMinute)}-${formatHhMm(s.place.openingHours.closeMinute)}',
            'visitMinutes': s.place.visitMinutes,
            'entryFeeNpr': s.place.entryFee.forVisitor(visitor),
            'bestTimes': s.place.bestTimes,
            'kmFromStart': _round(s.place.location.distanceKmTo(request.start.location), 1),
            'suitability': s.score.round(),
            'why': [for (final r in s.reasons.take(3)) r.kind.name],
          },
      ],
    };
    return 'Plan my day. Data:\n${jsonEncode(data)}';
  }

  static String _pad2(int n) => n.toString().padLeft(2, '0');
  static double _round(double v, [int digits = 2]) => double.parse(v.toStringAsFixed(digits));
}

class AiPlanParser {
  /// Parses the model's JSON, tolerating a ```json fence. Unknown or repeated
  /// place ids are dropped; at most [maxStops] are kept. Throws
  /// [FormatException] if nothing usable remains.
  static AiPlanSuggestion parse(String text, Set<String> knownIds, {int maxStops = 6}) {
    var body = text.trim();
    final fence = RegExp(r'^```(?:json)?\s*([\s\S]*?)\s*```$').firstMatch(body);
    if (fence != null) body = fence.group(1)!;

    final Object? decoded;
    try {
      decoded = jsonDecode(body);
    } on FormatException {
      throw const FormatException('AI response is not valid JSON');
    }
    if (decoded is! Map<String, dynamic>) throw const FormatException('AI response is not an object');

    final seen = <String>{};
    final stops = <AiStop>[];
    for (final raw in (decoded['stops'] as List? ?? const [])) {
      if (raw is! Map) continue;
      final id = raw['placeId'];
      if (id is! String || !knownIds.contains(id) || !seen.add(id)) continue;
      final note = (raw['note'] as String? ?? '').trim();
      stops.add(AiStop(id, note.length > 160 ? '${note.substring(0, 157)}...' : note));
      if (stops.length == maxStops) break;
    }
    if (stops.isEmpty) throw const FormatException('AI response has no usable stops');
    final summary = (decoded['summary'] as String? ?? '').trim();
    return AiPlanSuggestion(summary: summary, stops: stops);
  }
}
