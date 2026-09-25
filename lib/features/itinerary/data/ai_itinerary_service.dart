import '../../alerts/domain/condition_alert.dart';
import '../../places/domain/place.dart';
import '../../places/domain/place_category.dart';
import '../../recommendations/domain/recommendation_context.dart';
import '../../recommendations/domain/recommendation_engine.dart';
import '../../recommendations/domain/scored_place.dart';
import '../../weather/domain/weather.dart';
import '../domain/ai_plan.dart';
import '../domain/itinerary.dart';
import '../domain/itinerary_planner.dart';
import 'gemini_client.dart';

/// Plans a day with an LLM choosing and describing the stops.
abstract interface class AiItineraryService {
  Future<Itinerary> plan({
    required ItineraryRequest request,
    required List<Place> places,
    required VisitorType visitor,
    WeatherReport? weather,
    List<ConditionAlert> alerts,
  });
}

class GeminiItineraryService implements AiItineraryService {
  GeminiItineraryService({required this.client, required this.planner, required this.engine});

  final GeminiClient client;
  final ItineraryPlanner planner;
  final RecommendationEngine engine;

  /// How many places the model chooses from.
  static const candidateCount = 20;

  @override
  Future<Itinerary> plan({
    required ItineraryRequest request,
    required List<Place> places,
    required VisitorType visitor,
    WeatherReport? weather,
    List<ConditionAlert> alerts = const [],
  }) async {
    final candidates = selectCandidates(request, places, weather, alerts);
    if (candidates.isEmpty) throw StateError('No places are open in this time window');
    final dayAlerts = [for (final a in alerts) if (a.isRelevantOn(request.startTime)) a];

    final text = await client.generateJson(
      system: AiPlanPrompt.systemFor(request),
      prompt: AiPlanPrompt.prompt(
        request: request,
        visitor: visitor,
        candidates: candidates,
        forecast: weather?.dayOf(request.startTime),
        startWeather: weather?.at(request.startTime),
        alerts: dayAlerts,
      ),
      schema: AiPlanPrompt.schema([for (final c in candidates) c.place.id]),
    );

    final byId = {for (final c in candidates) c.place.id: c.place};
    final suggestion = AiPlanParser.parse(text, byId.keys.toSet(), maxStops: request.maxStops);
    final notes = {for (final s in suggestion.stops) s.placeId: s.note};
    var ordered = [for (final s in suggestion.stops) byId[s.placeId]!];

    Itinerary schedule() => planner.schedule(
          request,
          ordered,
          weather: weather,
          alerts: alerts,
          notes: notes,
          source: PlanSource.ai,
          summary: suggestion.summary.isEmpty ? null : suggestion.summary,
        );

    // The model sometimes misjudges timing: drop stops that would be closed,
    // then trailing stops that run past the end of the day.
    var itinerary = schedule();
    final closed = {
      for (final s in itinerary.stops)
        if (s.warnings.contains(StopWarning.closedOnArrival)) s.place,
    };
    if (closed.isNotEmpty) {
      ordered = [for (final p in ordered) if (!closed.contains(p)) p];
      itinerary = schedule();
    }
    while (ordered.length > 1 && itinerary.stops.last.warnings.contains(StopWarning.pastEndTime)) {
      ordered = ordered.sublist(0, ordered.length - 1);
      itinerary = schedule();
    }
    if (itinerary.isEmpty) throw StateError('AI plan had no feasible stops');
    return itinerary;
  }

  /// The best places for the day: scored at the start and middle of the time
  /// window, keeping those open at some point in it.
  List<ScoredPlace> selectCandidates(
    ItineraryRequest request,
    List<Place> places,
    WeatherReport? weather,
    List<ConditionAlert> alerts,
  ) {
    final start = request.startTime;
    final mid = start.add(Duration(minutes: request.availableMinutes ~/ 2));
    RecommendationContext ctx(DateTime t) => RecommendationContext(
          time: t,
          weather: weather?.at(t),
          interests: request.interests,
          alerts: alerts,
        );

    final best = <String, ScoredPlace>{};
    for (final t in [start, mid]) {
      for (final s in engine.rank(places, ctx(t))) {
        final existing = best[s.place.id];
        if (existing == null || s.score > existing.score) best[s.place.id] = s;
      }
    }

    final startMin = start.hour * 60 + start.minute;
    final endMin = startMin + request.availableMinutes;
    bool openInWindow(Place p) {
      final h = p.openingHours;
      if (h.isClosedOn(start)) return false;
      if (h.alwaysOpen) return true;
      return h.closeMinute - p.visitMinutes >= startMin && h.openMinute + p.visitMinutes <= endMin;
    }

    final ranked = [
      for (final s in best.values)
        if (openInWindow(s.place) && !s.reasons.any((r) => r.kind == ReasonKind.closureAlert)) s,
    ]..sort((a, b) => b.score.compareTo(a.score));
    return ranked.take(candidateCount).toList();
  }
}
