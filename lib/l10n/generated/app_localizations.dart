import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Yatri'**
  String get appTitle;

  /// No description provided for @tabExplore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get tabExplore;

  /// No description provided for @tabPlan.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get tabPlan;

  /// No description provided for @tabMap.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get tabMap;

  /// No description provided for @goodForToday.
  ///
  /// In en, this message translates to:
  /// **'Good for today'**
  String get goodForToday;

  /// No description provided for @allCategories.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allCategories;

  /// No description provided for @categoryName.
  ///
  /// In en, this message translates to:
  /// **'{category, select, heritage{Heritage} temple{Temples} nature{Nature} food{Food} shopping{Shopping} viewpoint{Viewpoints} other{Other}}'**
  String categoryName(String category);

  /// No description provided for @cityName.
  ///
  /// In en, this message translates to:
  /// **'{city, select, kathmandu{Kathmandu} lalitpur{Lalitpur} bhaktapur{Bhaktapur} other{Kathmandu Valley}}'**
  String cityName(String city);

  /// No description provided for @settingName.
  ///
  /// In en, this message translates to:
  /// **'{setting, select, indoor{Indoor} outdoor{Outdoor} mixed{Indoor & outdoor} other{}}'**
  String settingName(String setting);

  /// No description provided for @dayPartName.
  ///
  /// In en, this message translates to:
  /// **'{part, select, earlyMorning{early morning} morning{morning} afternoon{afternoon} evening{evening} night{night} other{day}}'**
  String dayPartName(String part);

  /// No description provided for @weatherCondition.
  ///
  /// In en, this message translates to:
  /// **'{condition, select, clear{Clear} partlyCloudy{Partly cloudy} cloudy{Cloudy} fog{Foggy} drizzle{Drizzle} rain{Rain} heavyRain{Heavy rain} thunderstorm{Thunderstorms} snow{Snow} other{Unknown}}'**
  String weatherCondition(String condition);

  /// No description provided for @airQuality.
  ///
  /// In en, this message translates to:
  /// **'{level, select, good{Good air} moderate{Moderate air} sensitive{Unhealthy for sensitive groups} unhealthy{Unhealthy air} veryUnhealthy{Very unhealthy air} other{}}'**
  String airQuality(String level);

  /// No description provided for @aqiValue.
  ///
  /// In en, this message translates to:
  /// **'AQI {aqi}'**
  String aqiValue(int aqi);

  /// No description provided for @weatherValley.
  ///
  /// In en, this message translates to:
  /// **'Kathmandu Valley'**
  String get weatherValley;

  /// No description provided for @weatherUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated {time}'**
  String weatherUpdated(String time);

  /// No description provided for @weatherOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline · saved {time}'**
  String weatherOffline(String time);

  /// No description provided for @weatherUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Weather unavailable – suggestions ignore weather for now.'**
  String get weatherUnavailable;

  /// No description provided for @weatherToday.
  ///
  /// In en, this message translates to:
  /// **'Today {min}°–{max}°'**
  String weatherToday(int min, int max);

  /// No description provided for @rainChance.
  ///
  /// In en, this message translates to:
  /// **'{percent}% chance of rain'**
  String rainChance(int percent);

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @reasonIndoorInRain.
  ///
  /// In en, this message translates to:
  /// **'Indoor, good for a rainy {dayPart}'**
  String reasonIndoorInRain(String dayPart);

  /// No description provided for @reasonCoveredInRain.
  ///
  /// In en, this message translates to:
  /// **'Partly covered, OK in the rain'**
  String get reasonCoveredInRain;

  /// No description provided for @reasonOutdoorInRain.
  ///
  /// In en, this message translates to:
  /// **'Outdoors – expect rain'**
  String get reasonOutdoorInRain;

  /// No description provided for @reasonNoViews.
  ///
  /// In en, this message translates to:
  /// **'Clouds may hide the views'**
  String get reasonNoViews;

  /// No description provided for @reasonClearViews.
  ///
  /// In en, this message translates to:
  /// **'Clear skies for the views'**
  String get reasonClearViews;

  /// No description provided for @reasonPleasantOutdoors.
  ///
  /// In en, this message translates to:
  /// **'Pleasant weather for being outside'**
  String get reasonPleasantOutdoors;

  /// No description provided for @reasonPoorAirOutdoor.
  ///
  /// In en, this message translates to:
  /// **'Outdoors while air quality is poor (AQI {aqi})'**
  String reasonPoorAirOutdoor(int aqi);

  /// No description provided for @reasonIndoorPoorAir.
  ///
  /// In en, this message translates to:
  /// **'Indoor, away from the poor air'**
  String get reasonIndoorPoorAir;

  /// No description provided for @reasonHotMidday.
  ///
  /// In en, this message translates to:
  /// **'Hot and exposed at midday'**
  String get reasonHotMidday;

  /// No description provided for @reasonBestTimeNow.
  ///
  /// In en, this message translates to:
  /// **'{dayPart, select, earlyMorning{Best around sunrise} morning{Best in the morning} afternoon{Good in the afternoon} evening{Lovely in the evening light} other{Good time to visit}}'**
  String reasonBestTimeNow(String dayPart);

  /// No description provided for @reasonMealTime.
  ///
  /// In en, this message translates to:
  /// **'Good time for a meal'**
  String get reasonMealTime;

  /// No description provided for @reasonAfterDark.
  ///
  /// In en, this message translates to:
  /// **'Better in daylight'**
  String get reasonAfterDark;

  /// No description provided for @reasonClosedToday.
  ///
  /// In en, this message translates to:
  /// **'Closed today'**
  String get reasonClosedToday;

  /// No description provided for @reasonClosedNow.
  ///
  /// In en, this message translates to:
  /// **'Closed for the day'**
  String get reasonClosedNow;

  /// No description provided for @reasonOpensLater.
  ///
  /// In en, this message translates to:
  /// **'Opens at {time}'**
  String reasonOpensLater(String time);

  /// No description provided for @reasonClosesSoon.
  ///
  /// In en, this message translates to:
  /// **'Closes in {minutes} min'**
  String reasonClosesSoon(int minutes);

  /// No description provided for @reasonNearby.
  ///
  /// In en, this message translates to:
  /// **'{distance} away'**
  String reasonNearby(String distance);

  /// No description provided for @reasonFar.
  ///
  /// In en, this message translates to:
  /// **'{distance} away – allow travel time'**
  String reasonFar(String distance);

  /// No description provided for @reasonMatchesInterest.
  ///
  /// In en, this message translates to:
  /// **'Matches your interest: {category}'**
  String reasonMatchesInterest(String category);

  /// No description provided for @reasonHighlight.
  ///
  /// In en, this message translates to:
  /// **'A valley highlight'**
  String get reasonHighlight;

  /// No description provided for @reasonFestival.
  ///
  /// In en, this message translates to:
  /// **'{title}: expect crowds'**
  String reasonFestival(String title);

  /// No description provided for @reasonClosureAlert.
  ///
  /// In en, this message translates to:
  /// **'Closed: {title}'**
  String reasonClosureAlert(String title);

  /// No description provided for @reasonRoadClosure.
  ///
  /// In en, this message translates to:
  /// **'{title}: slower access'**
  String reasonRoadClosure(String title);

  /// No description provided for @reasonBandhWalkable.
  ///
  /// In en, this message translates to:
  /// **'Walkable during the bandh'**
  String get reasonBandhWalkable;

  /// No description provided for @reasonBandhTransport.
  ///
  /// In en, this message translates to:
  /// **'Bandh: little transport running'**
  String get reasonBandhTransport;

  /// No description provided for @suitability.
  ///
  /// In en, this message translates to:
  /// **'{level, select, excellent{Great right now} good{Good right now} fair{OK right now} notIdeal{Not ideal right now} unavailable{Closed right now} other{}}'**
  String suitability(String level);

  /// No description provided for @suitabilityAtVisit.
  ///
  /// In en, this message translates to:
  /// **'{level, select, excellent{Great at this time} good{Good at this time} fair{OK at this time} notIdeal{Not ideal at this time} unavailable{Closed at this time} other{}}'**
  String suitabilityAtVisit(String level);

  /// No description provided for @distanceKm.
  ///
  /// In en, this message translates to:
  /// **'{km} km'**
  String distanceKm(String km);

  /// No description provided for @distanceM.
  ///
  /// In en, this message translates to:
  /// **'{meters} m'**
  String distanceM(int meters);

  /// No description provided for @durationMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String durationMinutes(int minutes);

  /// No description provided for @durationHours.
  ///
  /// In en, this message translates to:
  /// **'{hours} h'**
  String durationHours(int hours);

  /// No description provided for @durationHoursMinutes.
  ///
  /// In en, this message translates to:
  /// **'{hours} h {minutes} min'**
  String durationHoursMinutes(int hours, int minutes);

  /// No description provided for @npr.
  ///
  /// In en, this message translates to:
  /// **'NPR {amount}'**
  String npr(String amount);

  /// No description provided for @nprRange.
  ///
  /// In en, this message translates to:
  /// **'NPR {min}–{max}'**
  String nprRange(String min, String max);

  /// No description provided for @free.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get free;

  /// No description provided for @aboutSection.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutSection;

  /// No description provided for @openingHoursLabel.
  ///
  /// In en, this message translates to:
  /// **'Opening hours'**
  String get openingHoursLabel;

  /// No description provided for @openAllDay.
  ///
  /// In en, this message translates to:
  /// **'Open all day'**
  String get openAllDay;

  /// No description provided for @hoursRange.
  ///
  /// In en, this message translates to:
  /// **'{open}–{close}'**
  String hoursRange(String open, String close);

  /// No description provided for @closedOnDays.
  ///
  /// In en, this message translates to:
  /// **'Closed on {days}'**
  String closedOnDays(String days);

  /// No description provided for @openNowClosesAt.
  ///
  /// In en, this message translates to:
  /// **'Open now · closes {time}'**
  String openNowClosesAt(String time);

  /// No description provided for @opensAtToday.
  ///
  /// In en, this message translates to:
  /// **'Opens today at {time}'**
  String opensAtToday(String time);

  /// No description provided for @closedNowStatus.
  ///
  /// In en, this message translates to:
  /// **'Closed now'**
  String get closedNowStatus;

  /// No description provided for @closedTodayStatus.
  ///
  /// In en, this message translates to:
  /// **'Closed today'**
  String get closedTodayStatus;

  /// No description provided for @openNow.
  ///
  /// In en, this message translates to:
  /// **'Open now'**
  String get openNow;

  /// No description provided for @typicalVisit.
  ///
  /// In en, this message translates to:
  /// **'Typical visit'**
  String get typicalVisit;

  /// No description provided for @entryFee.
  ///
  /// In en, this message translates to:
  /// **'Entry fee'**
  String get entryFee;

  /// No description provided for @visitorFee.
  ///
  /// In en, this message translates to:
  /// **'{visitor, select, foreigner{Foreigners} saarc{SAARC} nepali{Nepali} other{}}'**
  String visitorFee(String visitor);

  /// No description provided for @feesApproximate.
  ///
  /// In en, this message translates to:
  /// **'Fees are approximate and change often.'**
  String get feesApproximate;

  /// No description provided for @settingLabel.
  ///
  /// In en, this message translates to:
  /// **'Setting'**
  String get settingLabel;

  /// No description provided for @rightNow.
  ///
  /// In en, this message translates to:
  /// **'Right now'**
  String get rightNow;

  /// No description provided for @gettingThere.
  ///
  /// In en, this message translates to:
  /// **'Getting there'**
  String get gettingThere;

  /// No description provided for @fromYourLocation.
  ///
  /// In en, this message translates to:
  /// **'From your location'**
  String get fromYourLocation;

  /// No description provided for @fromPlace.
  ///
  /// In en, this message translates to:
  /// **'From {place}'**
  String fromPlace(String place);

  /// No description provided for @addToItinerary.
  ///
  /// In en, this message translates to:
  /// **'Add to itinerary'**
  String get addToItinerary;

  /// No description provided for @addedToItinerary.
  ///
  /// In en, this message translates to:
  /// **'Added to your plan'**
  String get addedToItinerary;

  /// No description provided for @alreadyInItinerary.
  ///
  /// In en, this message translates to:
  /// **'Already in your plan'**
  String get alreadyInItinerary;

  /// No description provided for @viewPlan.
  ///
  /// In en, this message translates to:
  /// **'View plan'**
  String get viewPlan;

  /// No description provided for @photosComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Photos coming soon'**
  String get photosComingSoon;

  /// No description provided for @showOnMap.
  ///
  /// In en, this message translates to:
  /// **'Show on map'**
  String get showOnMap;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @transportMode.
  ///
  /// In en, this message translates to:
  /// **'{mode, select, walk{Walk} bikeTaxi{Bike taxi} taxi{Taxi} bus{Local bus} other{}}'**
  String transportMode(String mode);

  /// No description provided for @perVehicle.
  ///
  /// In en, this message translates to:
  /// **'per vehicle'**
  String get perVehicle;

  /// No description provided for @perPerson.
  ///
  /// In en, this message translates to:
  /// **'per person'**
  String get perPerson;

  /// No description provided for @busRoute.
  ///
  /// In en, this message translates to:
  /// **'{route}: board at {board}, get off at {alight}'**
  String busRoute(String route, String board, String alight);

  /// No description provided for @busEstimated.
  ///
  /// In en, this message translates to:
  /// **'No sample route – ask locally which bus to take'**
  String get busEstimated;

  /// No description provided for @noteNightFare.
  ///
  /// In en, this message translates to:
  /// **'Night fare'**
  String get noteNightFare;

  /// No description provided for @noteRushHour.
  ///
  /// In en, this message translates to:
  /// **'Rush-hour traffic'**
  String get noteRushHour;

  /// No description provided for @noteNoBusService.
  ///
  /// In en, this message translates to:
  /// **'Buses not running now'**
  String get noteNoBusService;

  /// No description provided for @noteBandh.
  ///
  /// In en, this message translates to:
  /// **'Bandh: vehicles may not run'**
  String get noteBandh;

  /// No description provided for @transportDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Times and fares are estimates. Agree taxi fares before you ride.'**
  String get transportDisclaimer;

  /// No description provided for @suggested.
  ///
  /// In en, this message translates to:
  /// **'Suggested'**
  String get suggested;

  /// No description provided for @notAvailable.
  ///
  /// In en, this message translates to:
  /// **'Not available'**
  String get notAvailable;

  /// No description provided for @travelTime.
  ///
  /// In en, this message translates to:
  /// **'{duration} travel'**
  String travelTime(String duration);

  /// No description provided for @planYourDay.
  ///
  /// In en, this message translates to:
  /// **'Plan your day'**
  String get planYourDay;

  /// No description provided for @planDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get planDate;

  /// No description provided for @planStartTime.
  ///
  /// In en, this message translates to:
  /// **'Start time'**
  String get planStartTime;

  /// No description provided for @planTimeAvailable.
  ///
  /// In en, this message translates to:
  /// **'Time available'**
  String get planTimeAvailable;

  /// No description provided for @hoursValue.
  ///
  /// In en, this message translates to:
  /// **'{hours, plural, =1{1 hour} other{{hours} hours}}'**
  String hoursValue(int hours);

  /// No description provided for @planStartFrom.
  ///
  /// In en, this message translates to:
  /// **'Start from'**
  String get planStartFrom;

  /// No description provided for @myLocation.
  ///
  /// In en, this message translates to:
  /// **'My location'**
  String get myLocation;

  /// No description provided for @planInterests.
  ///
  /// In en, this message translates to:
  /// **'Interests'**
  String get planInterests;

  /// No description provided for @planInterestsHint.
  ///
  /// In en, this message translates to:
  /// **'Leave empty for a mix of everything'**
  String get planInterestsHint;

  /// No description provided for @planTravelStyle.
  ///
  /// In en, this message translates to:
  /// **'Getting around'**
  String get planTravelStyle;

  /// No description provided for @travelStyle.
  ///
  /// In en, this message translates to:
  /// **'{style, select, budget{Budget} balanced{Balanced} comfort{Comfort} other{}}'**
  String travelStyle(String style);

  /// No description provided for @travelStyleHint.
  ///
  /// In en, this message translates to:
  /// **'{style, select, budget{Local buses and walking where possible} balanced{Bus when it\'s not much slower, otherwise taxi} comfort{Taxis, walking only short hops} other{}}'**
  String travelStyleHint(String style);

  /// No description provided for @planButton.
  ///
  /// In en, this message translates to:
  /// **'Plan my day'**
  String get planButton;

  /// No description provided for @itineraryTitle.
  ///
  /// In en, this message translates to:
  /// **'Your day'**
  String get itineraryTitle;

  /// No description provided for @itinerarySummary.
  ///
  /// In en, this message translates to:
  /// **'{stops, plural, =1{1 stop} other{{stops} stops}} · {start}–{end}'**
  String itinerarySummary(int stops, String start, String end);

  /// No description provided for @itineraryCosts.
  ///
  /// In en, this message translates to:
  /// **'Transport {transport} · Entry {entry}'**
  String itineraryCosts(String transport, String entry);

  /// No description provided for @newPlan.
  ///
  /// In en, this message translates to:
  /// **'New plan'**
  String get newPlan;

  /// No description provided for @optimizeOrder.
  ///
  /// In en, this message translates to:
  /// **'Optimise order'**
  String get optimizeOrder;

  /// No description provided for @orderOptimized.
  ///
  /// In en, this message translates to:
  /// **'Stops reordered for less travel'**
  String get orderOptimized;

  /// No description provided for @clearPlan.
  ///
  /// In en, this message translates to:
  /// **'Clear plan'**
  String get clearPlan;

  /// No description provided for @removeStop.
  ///
  /// In en, this message translates to:
  /// **'Remove stop'**
  String get removeStop;

  /// No description provided for @stopRemoved.
  ///
  /// In en, this message translates to:
  /// **'Removed {place}'**
  String stopRemoved(String place);

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @emptyItinerary.
  ///
  /// In en, this message translates to:
  /// **'No stops fit this time window. Try more time, another start time or different interests.'**
  String get emptyItinerary;

  /// No description provided for @visitWindow.
  ///
  /// In en, this message translates to:
  /// **'{arrive}–{depart}'**
  String visitWindow(String arrive, String depart);

  /// No description provided for @waitForOpening.
  ///
  /// In en, this message translates to:
  /// **'Wait {minutes} min for opening'**
  String waitForOpening(int minutes);

  /// No description provided for @warningClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed at this time'**
  String get warningClosed;

  /// No description provided for @warningClosesDuringVisit.
  ///
  /// In en, this message translates to:
  /// **'Closes before your visit ends'**
  String get warningClosesDuringVisit;

  /// No description provided for @warningPastEnd.
  ///
  /// In en, this message translates to:
  /// **'Runs past your end time'**
  String get warningPastEnd;

  /// No description provided for @dayForecast.
  ///
  /// In en, this message translates to:
  /// **'Forecast: {condition}, {min}°–{max}°'**
  String dayForecast(String condition, int min, int max);

  /// No description provided for @reorderHint.
  ///
  /// In en, this message translates to:
  /// **'Drag the handle to reorder stops'**
  String get reorderHint;

  /// No description provided for @startPoint.
  ///
  /// In en, this message translates to:
  /// **'Start: {place}'**
  String startPoint(String place);

  /// No description provided for @showRouteOnMap.
  ///
  /// In en, this message translates to:
  /// **'Show on map'**
  String get showRouteOnMap;

  /// No description provided for @mapShowPlan.
  ///
  /// In en, this message translates to:
  /// **'Plan route'**
  String get mapShowPlan;

  /// No description provided for @youAreHere.
  ///
  /// In en, this message translates to:
  /// **'You are here'**
  String get youAreHere;

  /// No description provided for @preferencesTitle.
  ///
  /// In en, this message translates to:
  /// **'Your preferences'**
  String get preferencesTitle;

  /// No description provided for @visitorTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Visitor type (for entry fees)'**
  String get visitorTypeLabel;

  /// No description provided for @visitorType.
  ///
  /// In en, this message translates to:
  /// **'{visitor, select, foreigner{Foreign visitor} saarc{SAARC national} nepali{Nepali citizen} other{}}'**
  String visitorType(String visitor);

  /// No description provided for @interestsHint.
  ///
  /// In en, this message translates to:
  /// **'Suggestions favour these'**
  String get interestsHint;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @locationOff.
  ///
  /// In en, this message translates to:
  /// **'Turn on location for distance-aware suggestions'**
  String get locationOff;

  /// No description provided for @locationOutside.
  ///
  /// In en, this message translates to:
  /// **'You seem to be outside the valley, so distances are hidden'**
  String get locationOutside;

  /// No description provided for @errorLoading.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load data'**
  String get errorLoading;

  /// No description provided for @showAll.
  ///
  /// In en, this message translates to:
  /// **'Show all ({count})'**
  String showAll(int count);

  /// No description provided for @showFewer.
  ///
  /// In en, this message translates to:
  /// **'Show fewer'**
  String get showFewer;

  /// No description provided for @noPlacesMatch.
  ///
  /// In en, this message translates to:
  /// **'Nothing open matches this filter right now.'**
  String get noPlacesMatch;

  /// No description provided for @presetThamel.
  ///
  /// In en, this message translates to:
  /// **'Thamel'**
  String get presetThamel;

  /// No description provided for @presetPatan.
  ///
  /// In en, this message translates to:
  /// **'Patan Durbar Square'**
  String get presetPatan;

  /// No description provided for @presetBhaktapur.
  ///
  /// In en, this message translates to:
  /// **'Bhaktapur Durbar Square'**
  String get presetBhaktapur;

  /// No description provided for @presetBoudha.
  ///
  /// In en, this message translates to:
  /// **'Boudha'**
  String get presetBoudha;

  /// No description provided for @presetAirport.
  ///
  /// In en, this message translates to:
  /// **'Tribhuvan Airport'**
  String get presetAirport;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
