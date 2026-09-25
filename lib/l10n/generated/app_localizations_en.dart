// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Yatri';

  @override
  String get tabExplore => 'Explore';

  @override
  String get tabPlan => 'Plan';

  @override
  String get tabMap => 'Map';

  @override
  String get goodForToday => 'Good for today';

  @override
  String get allCategories => 'All';

  @override
  String categoryName(String category) {
    String _temp0 = intl.Intl.selectLogic(category, {
      'heritage': 'Heritage',
      'temple': 'Temples',
      'nature': 'Nature',
      'food': 'Food',
      'shopping': 'Shopping',
      'viewpoint': 'Viewpoints',
      'other': 'Other',
    });
    return '$_temp0';
  }

  @override
  String cityName(String city) {
    String _temp0 = intl.Intl.selectLogic(city, {
      'kathmandu': 'Kathmandu',
      'lalitpur': 'Lalitpur',
      'bhaktapur': 'Bhaktapur',
      'other': 'Kathmandu Valley',
    });
    return '$_temp0';
  }

  @override
  String settingName(String setting) {
    String _temp0 = intl.Intl.selectLogic(setting, {
      'indoor': 'Indoor',
      'outdoor': 'Outdoor',
      'mixed': 'Indoor & outdoor',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String dayPartName(String part) {
    String _temp0 = intl.Intl.selectLogic(part, {
      'earlyMorning': 'early morning',
      'morning': 'morning',
      'afternoon': 'afternoon',
      'evening': 'evening',
      'night': 'night',
      'other': 'day',
    });
    return '$_temp0';
  }

  @override
  String weatherCondition(String condition) {
    String _temp0 = intl.Intl.selectLogic(condition, {
      'clear': 'Clear',
      'partlyCloudy': 'Partly cloudy',
      'cloudy': 'Cloudy',
      'fog': 'Foggy',
      'drizzle': 'Drizzle',
      'rain': 'Rain',
      'heavyRain': 'Heavy rain',
      'thunderstorm': 'Thunderstorms',
      'snow': 'Snow',
      'other': 'Unknown',
    });
    return '$_temp0';
  }

  @override
  String airQuality(String level) {
    String _temp0 = intl.Intl.selectLogic(level, {
      'good': 'Good air',
      'moderate': 'Moderate air',
      'sensitive': 'Unhealthy for sensitive groups',
      'unhealthy': 'Unhealthy air',
      'veryUnhealthy': 'Very unhealthy air',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String aqiValue(int aqi) {
    return 'AQI $aqi';
  }

  @override
  String get weatherValley => 'Kathmandu Valley';

  @override
  String weatherUpdated(String time) {
    return 'Updated $time';
  }

  @override
  String weatherOffline(String time) {
    return 'Offline · saved $time';
  }

  @override
  String get weatherUnavailable =>
      'Weather unavailable – suggestions ignore weather for now.';

  @override
  String weatherToday(int min, int max) {
    return 'Today $min°–$max°';
  }

  @override
  String rainChance(int percent) {
    return '$percent% chance of rain';
  }

  @override
  String get retry => 'Retry';

  @override
  String reasonIndoorInRain(String dayPart) {
    return 'Indoor, good for a rainy $dayPart';
  }

  @override
  String get reasonCoveredInRain => 'Partly covered, OK in the rain';

  @override
  String get reasonOutdoorInRain => 'Outdoors – expect rain';

  @override
  String get reasonNoViews => 'Clouds may hide the views';

  @override
  String get reasonClearViews => 'Clear skies for the views';

  @override
  String get reasonPleasantOutdoors => 'Pleasant weather for being outside';

  @override
  String reasonPoorAirOutdoor(int aqi) {
    return 'Outdoors while air quality is poor (AQI $aqi)';
  }

  @override
  String get reasonIndoorPoorAir => 'Indoor, away from the poor air';

  @override
  String get reasonHotMidday => 'Hot and exposed at midday';

  @override
  String reasonBestTimeNow(String dayPart) {
    String _temp0 = intl.Intl.selectLogic(dayPart, {
      'earlyMorning': 'Best around sunrise',
      'morning': 'Best in the morning',
      'afternoon': 'Good in the afternoon',
      'evening': 'Lovely in the evening light',
      'other': 'Good time to visit',
    });
    return '$_temp0';
  }

  @override
  String get reasonMealTime => 'Good time for a meal';

  @override
  String get reasonAfterDark => 'Better in daylight';

  @override
  String get reasonClosedToday => 'Closed today';

  @override
  String get reasonClosedNow => 'Closed for the day';

  @override
  String reasonOpensLater(String time) {
    return 'Opens at $time';
  }

  @override
  String reasonClosesSoon(int minutes) {
    return 'Closes in $minutes min';
  }

  @override
  String reasonNearby(String distance) {
    return '$distance away';
  }

  @override
  String reasonFar(String distance) {
    return '$distance away – allow travel time';
  }

  @override
  String reasonMatchesInterest(String category) {
    return 'Matches your interest: $category';
  }

  @override
  String get reasonHighlight => 'A valley highlight';

  @override
  String reasonFestival(String title) {
    return '$title: expect crowds';
  }

  @override
  String reasonClosureAlert(String title) {
    return 'Closed: $title';
  }

  @override
  String reasonRoadClosure(String title) {
    return '$title: slower access';
  }

  @override
  String get reasonBandhWalkable => 'Walkable during the bandh';

  @override
  String get reasonBandhTransport => 'Bandh: little transport running';

  @override
  String suitability(String level) {
    String _temp0 = intl.Intl.selectLogic(level, {
      'excellent': 'Great right now',
      'good': 'Good right now',
      'fair': 'OK right now',
      'notIdeal': 'Not ideal right now',
      'unavailable': 'Closed right now',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String suitabilityAtVisit(String level) {
    String _temp0 = intl.Intl.selectLogic(level, {
      'excellent': 'Great at this time',
      'good': 'Good at this time',
      'fair': 'OK at this time',
      'notIdeal': 'Not ideal at this time',
      'unavailable': 'Closed at this time',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String distanceKm(String km) {
    return '$km km';
  }

  @override
  String distanceM(int meters) {
    return '$meters m';
  }

  @override
  String durationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String durationHours(int hours) {
    return '$hours h';
  }

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String npr(String amount) {
    return 'NPR $amount';
  }

  @override
  String nprRange(String min, String max) {
    return 'NPR $min–$max';
  }

  @override
  String get free => 'Free';

  @override
  String get aboutSection => 'About';

  @override
  String get openingHoursLabel => 'Opening hours';

  @override
  String get openAllDay => 'Open all day';

  @override
  String hoursRange(String open, String close) {
    return '$open–$close';
  }

  @override
  String closedOnDays(String days) {
    return 'Closed on $days';
  }

  @override
  String openNowClosesAt(String time) {
    return 'Open now · closes $time';
  }

  @override
  String opensAtToday(String time) {
    return 'Opens today at $time';
  }

  @override
  String get closedNowStatus => 'Closed now';

  @override
  String get closedTodayStatus => 'Closed today';

  @override
  String get openNow => 'Open now';

  @override
  String get typicalVisit => 'Typical visit';

  @override
  String get entryFee => 'Entry fee';

  @override
  String visitorFee(String visitor) {
    String _temp0 = intl.Intl.selectLogic(visitor, {
      'foreigner': 'Foreigners',
      'saarc': 'SAARC',
      'nepali': 'Nepali',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String get feesApproximate => 'Fees are approximate and change often.';

  @override
  String get settingLabel => 'Setting';

  @override
  String get rightNow => 'Right now';

  @override
  String get gettingThere => 'Getting there';

  @override
  String get fromYourLocation => 'From your location';

  @override
  String fromPlace(String place) {
    return 'From $place';
  }

  @override
  String get addToItinerary => 'Add to itinerary';

  @override
  String get addedToItinerary => 'Added to your plan';

  @override
  String get alreadyInItinerary => 'Already in your plan';

  @override
  String get viewPlan => 'View plan';

  @override
  String get photosComingSoon => 'Photos coming soon';

  @override
  String get showOnMap => 'Show on map';

  @override
  String get details => 'Details';

  @override
  String transportMode(String mode) {
    String _temp0 = intl.Intl.selectLogic(mode, {
      'walk': 'Walk',
      'bikeTaxi': 'Bike taxi',
      'taxi': 'Taxi',
      'bus': 'Local bus',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String get perVehicle => 'per vehicle';

  @override
  String get perPerson => 'per person';

  @override
  String busRoute(String route, String board, String alight) {
    return '$route: board at $board, get off at $alight';
  }

  @override
  String get busEstimated => 'No sample route – ask locally which bus to take';

  @override
  String get noteNightFare => 'Night fare';

  @override
  String get noteRushHour => 'Rush-hour traffic';

  @override
  String get noteNoBusService => 'Buses not running now';

  @override
  String get noteBandh => 'Bandh: vehicles may not run';

  @override
  String get transportDisclaimer =>
      'Times and fares are estimates. Agree taxi fares before you ride.';

  @override
  String get suggested => 'Suggested';

  @override
  String get notAvailable => 'Not available';

  @override
  String travelTime(String duration) {
    return '$duration travel';
  }

  @override
  String get planYourDay => 'Plan your day';

  @override
  String get planDate => 'Date';

  @override
  String get planStartTime => 'Start time';

  @override
  String get planTimeAvailable => 'Time available';

  @override
  String hoursValue(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours hours',
      one: '1 hour',
    );
    return '$_temp0';
  }

  @override
  String get planStartFrom => 'Start from';

  @override
  String get myLocation => 'My location';

  @override
  String get planInterests => 'Interests';

  @override
  String get planInterestsHint => 'Leave empty for a mix of everything';

  @override
  String get planTravelStyle => 'Getting around';

  @override
  String travelStyle(String style) {
    String _temp0 = intl.Intl.selectLogic(style, {
      'budget': 'Budget',
      'balanced': 'Balanced',
      'comfort': 'Comfort',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String travelStyleHint(String style) {
    String _temp0 = intl.Intl.selectLogic(style, {
      'budget': 'Local buses and walking where possible',
      'balanced': 'Bus when it\'s not much slower, otherwise taxi',
      'comfort': 'Taxis, walking only short hops',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String get planButton => 'Plan my day';

  @override
  String get itineraryTitle => 'Your day';

  @override
  String itinerarySummary(int stops, String start, String end) {
    String _temp0 = intl.Intl.pluralLogic(
      stops,
      locale: localeName,
      other: '$stops stops',
      one: '1 stop',
    );
    return '$_temp0 · $start–$end';
  }

  @override
  String itineraryCosts(String transport, String entry) {
    return 'Transport $transport · Entry $entry';
  }

  @override
  String get newPlan => 'New plan';

  @override
  String get optimizeOrder => 'Optimise order';

  @override
  String get orderOptimized => 'Stops reordered for less travel';

  @override
  String get clearPlan => 'Clear plan';

  @override
  String get removeStop => 'Remove stop';

  @override
  String stopRemoved(String place) {
    return 'Removed $place';
  }

  @override
  String get undo => 'Undo';

  @override
  String get emptyItinerary =>
      'No stops fit this time window. Try more time, another start time or different interests.';

  @override
  String visitWindow(String arrive, String depart) {
    return '$arrive–$depart';
  }

  @override
  String waitForOpening(int minutes) {
    return 'Wait $minutes min for opening';
  }

  @override
  String get warningClosed => 'Closed at this time';

  @override
  String get warningClosesDuringVisit => 'Closes before your visit ends';

  @override
  String get warningPastEnd => 'Runs past your end time';

  @override
  String dayForecast(String condition, int min, int max) {
    return 'Forecast: $condition, $min°–$max°';
  }

  @override
  String get reorderHint => 'Drag the handle to reorder stops';

  @override
  String startPoint(String place) {
    return 'Start: $place';
  }

  @override
  String get showRouteOnMap => 'Show on map';

  @override
  String get mapShowPlan => 'Plan route';

  @override
  String get youAreHere => 'You are here';

  @override
  String get preferencesTitle => 'Your preferences';

  @override
  String get visitorTypeLabel => 'Visitor type (for entry fees)';

  @override
  String visitorType(String visitor) {
    String _temp0 = intl.Intl.selectLogic(visitor, {
      'foreigner': 'Foreign visitor',
      'saarc': 'SAARC national',
      'nepali': 'Nepali citizen',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String get interestsHint => 'Suggestions favour these';

  @override
  String get done => 'Done';

  @override
  String get preferences => 'Preferences';

  @override
  String get locationOff => 'Turn on location for distance-aware suggestions';

  @override
  String get locationOutside =>
      'You seem to be outside the valley, so distances are hidden';

  @override
  String get errorLoading => 'Couldn\'t load data';

  @override
  String showAll(int count) {
    return 'Show all ($count)';
  }

  @override
  String get showFewer => 'Show fewer';

  @override
  String get noPlacesMatch => 'Nothing open matches this filter right now.';

  @override
  String get presetThamel => 'Thamel';

  @override
  String get presetPatan => 'Patan Durbar Square';

  @override
  String get presetBhaktapur => 'Bhaktapur Durbar Square';

  @override
  String get presetBoudha => 'Boudha';

  @override
  String get presetAirport => 'Tribhuvan Airport';
}
