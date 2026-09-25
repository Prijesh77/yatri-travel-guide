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
    return '$title nearby – lively, expect crowds';
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

  @override
  String get noteUnverifiedRoute =>
      'Route not verified for 2026 – confirm locally';

  @override
  String get noteRerouted => 'Adjusted to avoid a reported disruption';

  @override
  String get tabHome => 'Home';

  @override
  String get tabTransit => 'Transit';

  @override
  String get tabAlerts => 'Alerts';

  @override
  String get tabProfile => 'Profile';

  @override
  String get search => 'Search';

  @override
  String get searchHint => 'Search transport, stays, and more';

  @override
  String get planTripWithAi => 'Plan a trip with AI';

  @override
  String get budgetConditionAware => 'Budget-aware, condition-aware';

  @override
  String get categories => 'Categories';

  @override
  String get catTransport => 'Transport';

  @override
  String get catStays => 'Stays';

  @override
  String plannedCategory(String category) {
    String _temp0 = intl.Intl.selectLogic(category, {
      'education': 'Education',
      'fitness': 'Fitness',
      'adventure': 'Adventure',
      'health': 'Health',
      'other': 'More',
    });
    return '$_temp0';
  }

  @override
  String disruptionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count disruptions',
      one: '1 disruption',
      zero: 'No disruptions',
    );
    return '$_temp0';
  }

  @override
  String eventsToday(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count events today',
      one: '1 event today',
      zero: 'No events today',
    );
    return '$_temp0';
  }

  @override
  String get findYourRoute => 'Find your route';

  @override
  String get fromHint => 'From';

  @override
  String get whereTo => 'Where to?';

  @override
  String get swap => 'Swap';

  @override
  String get bestOption => 'Best option';

  @override
  String get otherWays => 'Other ways to go';

  @override
  String get noBusRoute =>
      'No bus route found between these points in our data. Try a taxi or bike taxi, or ask locally.';

  @override
  String everyMinutes(int minutes) {
    return 'Every ~$minutes min';
  }

  @override
  String boardAt(String stop, int minutes) {
    return 'Board at $stop · $minutes min walk';
  }

  @override
  String totalTime(String duration) {
    return '~$duration total';
  }

  @override
  String changes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count changes',
      one: '1 change',
    );
    return '$_temp0';
  }

  @override
  String get roughStop => 'Stop position approximate';

  @override
  String routeStatus(String status) {
    String _temp0 = intl.Intl.selectLogic(status, {
      'verified': 'Verified 2026',
      'announced': 'Announced – verify',
      'osm': 'OSM-mapped – verify',
      'reported': 'Reported – verify',
      'local': 'Local listing – verify',
      'historical': 'Historical – may not run',
      'other': 'Unverified',
    });
    return '$_temp0';
  }

  @override
  String walkTo(String stop) {
    return 'Walk to $stop';
  }

  @override
  String walkBetween(String from, String to) {
    return 'Walk from $from to $to';
  }

  @override
  String get walkToDestination => 'Walk to your destination';

  @override
  String rideFromTo(String route, String board, String alight) {
    return '$route: $board → $alight';
  }

  @override
  String stopsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stops',
      one: '1 stop',
    );
    return '$_temp0';
  }

  @override
  String waitAbout(int minutes) {
    return 'wait ~$minutes min';
  }

  @override
  String disruptionOnRoute(String title) {
    return 'Reported on this route: $title. Road travel may take longer.';
  }

  @override
  String get transitDisclaimer =>
      'Routes come from the Yatri transport data pack (Sajha Yatayat 2026 routes are verified; others need checking). Frequencies are only shown where published.';

  @override
  String get popularHubs => 'Popular hubs';

  @override
  String get rideHailing => 'Taxis & ride-hailing';

  @override
  String networkSource(int routes, int stops) {
    return '$routes bus routes · $stops stops in the data pack';
  }

  @override
  String busJourney(String routes, String board, String alight) {
    return '$routes: board at $board, get off at $alight';
  }

  @override
  String get routeHere => 'Route here';

  @override
  String get pickerHubs => 'Hubs';

  @override
  String get pickerPlaces => 'Places';

  @override
  String get pickerStops => 'Bus stops';

  @override
  String get noResults => 'No results';

  @override
  String get fareCheck => 'Fare check';

  @override
  String get fareFromHint => 'From (stop or place)';

  @override
  String get fareToHint => 'To (stop or place)';

  @override
  String fareMode(String mode) {
    String _temp0 = intl.Intl.selectLogic(mode, {
      'bus': 'Bus',
      'microbus': 'Microbus',
      'tempo': 'Tempo',
      'taxi': 'Taxi',
      'bikeTaxi': 'Bike taxi',
      'other': 'Other',
    });
    return '$_temp0';
  }

  @override
  String get fareCheckIntro =>
      'Pick where you are going to see the official fare and what other travellers reported paying.';

  @override
  String basedOnReports(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Based on $count crowdsourced reports',
      one: 'Based on 1 crowdsourced report',
    );
    return '$_temp0';
  }

  @override
  String get includesSamples => 'includes sample data';

  @override
  String get noFareReports =>
      'No fare reports for this trip yet – be the first to add one.';

  @override
  String officialFare(String fare, String distance) {
    return 'Official fare: $fare ($distance, April 2026 slab)';
  }

  @override
  String meterFare(String fare, String distance) {
    return 'Meter: $fare ($distance; Rs 58 + Rs 12 per 200 m)';
  }

  @override
  String appEstimate(String fare, String distance) {
    return 'App estimate: $fare ($distance)';
  }

  @override
  String get fareLow => 'Low';

  @override
  String get fareTypical => 'Typical';

  @override
  String get fareHigh => 'High';

  @override
  String get submitFareReport => 'Submit a fare report';

  @override
  String get farePaid => 'Fare you paid';

  @override
  String get submit => 'Submit';

  @override
  String get fareReportThanks => 'Thanks! Your fare report was added.';

  @override
  String get loadSampleFares => 'Load sample fare reports';

  @override
  String get reportsOnDevice =>
      'Reports are saved on this device for now; sharing them with other travellers comes with the Yatri backend.';

  @override
  String get liveConditions => 'Live conditions';

  @override
  String get report => 'Report';

  @override
  String get disruptions => 'Disruptions';

  @override
  String get events => 'Events';

  @override
  String get noDisruptions => 'No disruptions reported.';

  @override
  String get noEvents => 'No events today.';

  @override
  String get allClear => 'All clear';

  @override
  String get allClearBody =>
      'No disruptions or events reported for today. Seen a road closure, bandh or jatra? Report it to help others.';

  @override
  String get loadSampleReports => 'Load sample reports';

  @override
  String alertType(String type) {
    String _temp0 = intl.Intl.selectLogic(type, {
      'roadClosure': 'Road closed',
      'traffic': 'Heavy traffic',
      'bandh': 'Bandh',
      'closure': 'Place closed',
      'festival': 'Event / jatra',
      'other': 'Alert',
    });
    return '$_temp0';
  }

  @override
  String alertSource(String source) {
    String _temp0 = intl.Intl.selectLogic(source, {
      'official': 'Official',
      'community': 'Community',
      'sample': 'Sample',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String confirms(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count confirms',
      one: '1 confirm',
      zero: 'no confirms yet',
    );
    return '$_temp0';
  }

  @override
  String get stillThere => 'Still there';

  @override
  String get confirmed => 'Confirmed';

  @override
  String get removeReport => 'Remove report';

  @override
  String eventWhen(String day, String time) {
    return '$day $time';
  }

  @override
  String get justNow => 'just now';

  @override
  String minutesAgo(int minutes) {
    return '$minutes min ago';
  }

  @override
  String hoursAgo(int hours) {
    return '$hours h ago';
  }

  @override
  String get today => 'Today';

  @override
  String get tomorrow => 'Tomorrow';

  @override
  String get reportTitle => 'Report a condition';

  @override
  String get whatsHappening => 'What\'s happening?';

  @override
  String get where => 'Where';

  @override
  String reportHint(String type) {
    String _temp0 = intl.Intl.selectLogic(type, {
      'roadClosure': 'e.g. Road closed near Maitighar',
      'traffic': 'e.g. Standstill at Koteshwor',
      'bandh': 'e.g. Valley-wide bandh until 6 pm',
      'closure': 'e.g. Garden of Dreams closed today',
      'festival': 'e.g. Jatra procession at Basantapur',
      'other': 'Describe it',
    });
    return '$_temp0';
  }

  @override
  String get reportThanks => 'Thanks! Your report is live on this device.';

  @override
  String get planWithAi => 'Plan with AI';

  @override
  String get budget => 'Budget';

  @override
  String budgetLevel(String style) {
    String _temp0 = intl.Intl.selectLogic(style, {
      'budget': 'Budget',
      'balanced': 'Mid-range',
      'comfort': 'Comfort',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String interestChoice(String choice) {
    String _temp0 = intl.Intl.selectLogic(choice, {
      'culture': 'Culture',
      'food': 'Food',
      'nature': 'Nature',
      'views': 'Views',
      'shopping': 'Shopping',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String planOptionsSummary(String date, String time, String hours) {
    return '$date · from $time · $hours';
  }

  @override
  String get generateItinerary => 'Generate itinerary';

  @override
  String get planning => 'Planning…';

  @override
  String get aiOff =>
      'AI is off (no Gemini API key in this build), so the built-in condition-aware planner is used.';

  @override
  String get planIntro =>
      'Choose a budget and interests, then generate a plan that fits today’s weather, air quality, opening hours and reported disruptions.';

  @override
  String get suggestedItinerary => 'Suggested itinerary';

  @override
  String get plannedWithAi =>
      'Planned with Gemini AI, checked against live conditions';

  @override
  String get plannedOnDevice => 'Planned on this device (condition-aware)';

  @override
  String get aiUnavailableFallback =>
      'AI unavailable right now – used the built-in planner';

  @override
  String departVia(String routes) {
    return 'Depart via $routes';
  }

  @override
  String walkFor(String duration) {
    return 'Walk $duration';
  }

  @override
  String avoids(String title) {
    return 'Avoids $title';
  }

  @override
  String get tagRerouted => 'rerouted';

  @override
  String get tagEvent => 'event';

  @override
  String optionalEventNearby(String title) {
    return 'Optional: $title nearby';
  }

  @override
  String fromPlaceTo(String place) {
    return 'To $place';
  }

  @override
  String get staysSearchHint => 'Search hotels, guesthouses';

  @override
  String stayType(String type) {
    String _temp0 = intl.Intl.selectLogic(type, {
      'heritage': 'Heritage',
      'boutique': 'Boutique',
      'hotel': 'Hotel',
      'resort': 'Resort',
      'guesthouse': 'Guesthouse',
      'hostel': 'Hostel',
      'other': 'Stay',
    });
    return '$_temp0';
  }

  @override
  String priceBand(String band) {
    String _temp0 = intl.Intl.selectLogic(band, {
      'budget': 'Budget',
      'mid': 'Mid-range',
      'upscale': 'Upscale',
      'luxury': 'Luxury',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String perNight(String range) {
    return '$range/night';
  }

  @override
  String get staysDisclaimer =>
      'Price ranges are approximate for the price band and change by season; check with the property. No ratings are shown until we have real reviews.';

  @override
  String get save => 'Save';

  @override
  String get unsave => 'Remove from saved';

  @override
  String plannedSearchHint(String category) {
    String _temp0 = intl.Intl.selectLogic(category, {
      'education': 'Search schools, training centres',
      'fitness': 'Search gyms, studios',
      'adventure': 'Search trekking, rafting operators',
      'health': 'Search clinics, pharmacies',
      'other': 'Search',
    });
    return '$_temp0';
  }

  @override
  String plannedItemA(String category) {
    String _temp0 = intl.Intl.selectLogic(category, {
      'education': 'Language institute',
      'fitness': 'Full gym',
      'adventure': 'Guided trekking',
      'health': 'General clinic',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String plannedItemB(String category) {
    String _temp0 = intl.Intl.selectLogic(category, {
      'education': 'Vocational training',
      'fitness': 'Yoga studio',
      'adventure': 'White-water rafting',
      'health': 'Pharmacy',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String get detailsComingSoon => 'Details coming soon';

  @override
  String get plannedNote =>
      'This category is planned for a later phase of Yatri.';

  @override
  String get guestUser => 'Guest user';

  @override
  String get signInToSync => 'Sign in to sync';

  @override
  String get accountsComingSoon => 'Accounts and sync are coming soon.';

  @override
  String get savedLocations => 'Saved locations';

  @override
  String get noSaved =>
      'Nothing saved yet. Tap the bookmark on a place or stay.';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageNepaliSoon => 'नेपाली (Nepali) – coming soon';

  @override
  String get notifications => 'Notifications';

  @override
  String get notificationsHint => 'Disruptions near your saved places';

  @override
  String preferencesSummary(String visitor, String budget) {
    return '$visitor · $budget';
  }

  @override
  String get aboutData => 'About the data';

  @override
  String get aboutPlaces =>
      'Places: 63 attractions with approximate hours and entry fees – verify locally.';

  @override
  String get aboutWeather =>
      'Weather and air quality: Open-Meteo. Maps: © OpenStreetMap contributors.';

  @override
  String aboutAiOn(String model) {
    return 'AI planning: Google Gemini ($model, free tier). Only your preferences and the day’s conditions are sent – never your exact location.';
  }

  @override
  String get aboutAiOff =>
      'AI planning is off in this build (no API key); plans are made on the device.';
}
