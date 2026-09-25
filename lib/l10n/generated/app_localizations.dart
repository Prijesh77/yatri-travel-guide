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
  /// **'{title} nearby – lively, expect crowds'**
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

  /// No description provided for @noteUnverifiedRoute.
  ///
  /// In en, this message translates to:
  /// **'Route not verified for 2026 – confirm locally'**
  String get noteUnverifiedRoute;

  /// No description provided for @noteRerouted.
  ///
  /// In en, this message translates to:
  /// **'Adjusted to avoid a reported disruption'**
  String get noteRerouted;

  /// No description provided for @tabHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get tabHome;

  /// No description provided for @tabTransit.
  ///
  /// In en, this message translates to:
  /// **'Transit'**
  String get tabTransit;

  /// No description provided for @tabAlerts.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get tabAlerts;

  /// No description provided for @tabProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get tabProfile;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search transport, stays, and more'**
  String get searchHint;

  /// No description provided for @planTripWithAi.
  ///
  /// In en, this message translates to:
  /// **'Plan a trip with AI'**
  String get planTripWithAi;

  /// No description provided for @budgetConditionAware.
  ///
  /// In en, this message translates to:
  /// **'Budget-aware, condition-aware'**
  String get budgetConditionAware;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @catTransport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get catTransport;

  /// No description provided for @catStays.
  ///
  /// In en, this message translates to:
  /// **'Stays'**
  String get catStays;

  /// No description provided for @plannedCategory.
  ///
  /// In en, this message translates to:
  /// **'{category, select, education{Education} fitness{Fitness} adventure{Adventure} health{Health} other{More}}'**
  String plannedCategory(String category);

  /// No description provided for @disruptionsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No disruptions} =1{1 disruption} other{{count} disruptions}}'**
  String disruptionsCount(int count);

  /// No description provided for @eventsToday.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No events today} =1{1 event today} other{{count} events today}}'**
  String eventsToday(int count);

  /// No description provided for @findYourRoute.
  ///
  /// In en, this message translates to:
  /// **'Find your route'**
  String get findYourRoute;

  /// No description provided for @fromHint.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get fromHint;

  /// No description provided for @whereTo.
  ///
  /// In en, this message translates to:
  /// **'Where to?'**
  String get whereTo;

  /// No description provided for @swap.
  ///
  /// In en, this message translates to:
  /// **'Swap'**
  String get swap;

  /// No description provided for @bestOption.
  ///
  /// In en, this message translates to:
  /// **'Best option'**
  String get bestOption;

  /// No description provided for @otherWays.
  ///
  /// In en, this message translates to:
  /// **'Other ways to go'**
  String get otherWays;

  /// No description provided for @noBusRoute.
  ///
  /// In en, this message translates to:
  /// **'No bus route found between these points in our data. Try a taxi or bike taxi, or ask locally.'**
  String get noBusRoute;

  /// No description provided for @everyMinutes.
  ///
  /// In en, this message translates to:
  /// **'Every ~{minutes} min'**
  String everyMinutes(int minutes);

  /// No description provided for @boardAt.
  ///
  /// In en, this message translates to:
  /// **'Board at {stop} · {minutes} min walk'**
  String boardAt(String stop, int minutes);

  /// No description provided for @totalTime.
  ///
  /// In en, this message translates to:
  /// **'~{duration} total'**
  String totalTime(String duration);

  /// No description provided for @changes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 change} other{{count} changes}}'**
  String changes(int count);

  /// No description provided for @roughStop.
  ///
  /// In en, this message translates to:
  /// **'Stop position approximate'**
  String get roughStop;

  /// No description provided for @routeStatus.
  ///
  /// In en, this message translates to:
  /// **'{status, select, verified{Verified 2026} announced{Announced – verify} osm{OSM-mapped – verify} reported{Reported – verify} local{Local listing – verify} historical{Historical – may not run} other{Unverified}}'**
  String routeStatus(String status);

  /// No description provided for @walkTo.
  ///
  /// In en, this message translates to:
  /// **'Walk to {stop}'**
  String walkTo(String stop);

  /// No description provided for @walkBetween.
  ///
  /// In en, this message translates to:
  /// **'Walk from {from} to {to}'**
  String walkBetween(String from, String to);

  /// No description provided for @walkToDestination.
  ///
  /// In en, this message translates to:
  /// **'Walk to your destination'**
  String get walkToDestination;

  /// No description provided for @rideFromTo.
  ///
  /// In en, this message translates to:
  /// **'{route}: {board} → {alight}'**
  String rideFromTo(String route, String board, String alight);

  /// No description provided for @stopsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 stop} other{{count} stops}}'**
  String stopsCount(int count);

  /// No description provided for @waitAbout.
  ///
  /// In en, this message translates to:
  /// **'wait ~{minutes} min'**
  String waitAbout(int minutes);

  /// No description provided for @disruptionOnRoute.
  ///
  /// In en, this message translates to:
  /// **'Reported on this route: {title}. Road travel may take longer.'**
  String disruptionOnRoute(String title);

  /// No description provided for @transitDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Routes come from the Yatri transport data pack (Sajha Yatayat 2026 routes are verified; others need checking). Frequencies are only shown where published.'**
  String get transitDisclaimer;

  /// No description provided for @popularHubs.
  ///
  /// In en, this message translates to:
  /// **'Popular hubs'**
  String get popularHubs;

  /// No description provided for @rideHailing.
  ///
  /// In en, this message translates to:
  /// **'Taxis & ride-hailing'**
  String get rideHailing;

  /// No description provided for @networkSource.
  ///
  /// In en, this message translates to:
  /// **'{routes} bus routes · {stops} stops in the data pack'**
  String networkSource(int routes, int stops);

  /// No description provided for @busJourney.
  ///
  /// In en, this message translates to:
  /// **'{routes}: board at {board}, get off at {alight}'**
  String busJourney(String routes, String board, String alight);

  /// No description provided for @routeHere.
  ///
  /// In en, this message translates to:
  /// **'Route here'**
  String get routeHere;

  /// No description provided for @pickerHubs.
  ///
  /// In en, this message translates to:
  /// **'Hubs'**
  String get pickerHubs;

  /// No description provided for @pickerPlaces.
  ///
  /// In en, this message translates to:
  /// **'Places'**
  String get pickerPlaces;

  /// No description provided for @pickerStops.
  ///
  /// In en, this message translates to:
  /// **'Bus stops'**
  String get pickerStops;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get noResults;

  /// No description provided for @fareCheck.
  ///
  /// In en, this message translates to:
  /// **'Fare check'**
  String get fareCheck;

  /// No description provided for @fareFromHint.
  ///
  /// In en, this message translates to:
  /// **'From (stop or place)'**
  String get fareFromHint;

  /// No description provided for @fareToHint.
  ///
  /// In en, this message translates to:
  /// **'To (stop or place)'**
  String get fareToHint;

  /// No description provided for @fareMode.
  ///
  /// In en, this message translates to:
  /// **'{mode, select, bus{Bus} microbus{Microbus} tempo{Tempo} taxi{Taxi} bikeTaxi{Bike taxi} other{Other}}'**
  String fareMode(String mode);

  /// No description provided for @fareCheckIntro.
  ///
  /// In en, this message translates to:
  /// **'Pick where you are going to see the official fare and what other travellers reported paying.'**
  String get fareCheckIntro;

  /// No description provided for @basedOnReports.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Based on 1 crowdsourced report} other{Based on {count} crowdsourced reports}}'**
  String basedOnReports(int count);

  /// No description provided for @includesSamples.
  ///
  /// In en, this message translates to:
  /// **'includes sample data'**
  String get includesSamples;

  /// No description provided for @noFareReports.
  ///
  /// In en, this message translates to:
  /// **'No fare reports for this trip yet – be the first to add one.'**
  String get noFareReports;

  /// No description provided for @officialFare.
  ///
  /// In en, this message translates to:
  /// **'Official fare: {fare} ({distance}, April 2026 slab)'**
  String officialFare(String fare, String distance);

  /// No description provided for @meterFare.
  ///
  /// In en, this message translates to:
  /// **'Meter: {fare} ({distance}; Rs 58 + Rs 12 per 200 m)'**
  String meterFare(String fare, String distance);

  /// No description provided for @appEstimate.
  ///
  /// In en, this message translates to:
  /// **'App estimate: {fare} ({distance})'**
  String appEstimate(String fare, String distance);

  /// No description provided for @fareLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get fareLow;

  /// No description provided for @fareTypical.
  ///
  /// In en, this message translates to:
  /// **'Typical'**
  String get fareTypical;

  /// No description provided for @fareHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get fareHigh;

  /// No description provided for @submitFareReport.
  ///
  /// In en, this message translates to:
  /// **'Submit a fare report'**
  String get submitFareReport;

  /// No description provided for @farePaid.
  ///
  /// In en, this message translates to:
  /// **'Fare you paid'**
  String get farePaid;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @fareReportThanks.
  ///
  /// In en, this message translates to:
  /// **'Thanks! Your fare report was added.'**
  String get fareReportThanks;

  /// No description provided for @loadSampleFares.
  ///
  /// In en, this message translates to:
  /// **'Load sample fare reports'**
  String get loadSampleFares;

  /// No description provided for @reportsOnDevice.
  ///
  /// In en, this message translates to:
  /// **'Reports are saved on this device for now; sharing them with other travellers comes with the Yatri backend.'**
  String get reportsOnDevice;

  /// No description provided for @liveConditions.
  ///
  /// In en, this message translates to:
  /// **'Live conditions'**
  String get liveConditions;

  /// No description provided for @report.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get report;

  /// No description provided for @disruptions.
  ///
  /// In en, this message translates to:
  /// **'Disruptions'**
  String get disruptions;

  /// No description provided for @events.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get events;

  /// No description provided for @noDisruptions.
  ///
  /// In en, this message translates to:
  /// **'No disruptions reported.'**
  String get noDisruptions;

  /// No description provided for @noEvents.
  ///
  /// In en, this message translates to:
  /// **'No events today.'**
  String get noEvents;

  /// No description provided for @allClear.
  ///
  /// In en, this message translates to:
  /// **'All clear'**
  String get allClear;

  /// No description provided for @allClearBody.
  ///
  /// In en, this message translates to:
  /// **'No disruptions or events reported for today. Seen a road closure, bandh or jatra? Report it to help others.'**
  String get allClearBody;

  /// No description provided for @loadSampleReports.
  ///
  /// In en, this message translates to:
  /// **'Load sample reports'**
  String get loadSampleReports;

  /// No description provided for @alertType.
  ///
  /// In en, this message translates to:
  /// **'{type, select, roadClosure{Road closed} traffic{Heavy traffic} bandh{Bandh} closure{Place closed} festival{Event / jatra} other{Alert}}'**
  String alertType(String type);

  /// No description provided for @alertSource.
  ///
  /// In en, this message translates to:
  /// **'{source, select, official{Official} community{Community} sample{Sample} other{}}'**
  String alertSource(String source);

  /// No description provided for @confirms.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{no confirms yet} =1{1 confirm} other{{count} confirms}}'**
  String confirms(int count);

  /// No description provided for @stillThere.
  ///
  /// In en, this message translates to:
  /// **'Still there'**
  String get stillThere;

  /// No description provided for @confirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get confirmed;

  /// No description provided for @removeReport.
  ///
  /// In en, this message translates to:
  /// **'Remove report'**
  String get removeReport;

  /// No description provided for @eventWhen.
  ///
  /// In en, this message translates to:
  /// **'{day} {time}'**
  String eventWhen(String day, String time);

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get justNow;

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min ago'**
  String minutesAgo(int minutes);

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours} h ago'**
  String hoursAgo(int hours);

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @tomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get tomorrow;

  /// No description provided for @reportTitle.
  ///
  /// In en, this message translates to:
  /// **'Report a condition'**
  String get reportTitle;

  /// No description provided for @whatsHappening.
  ///
  /// In en, this message translates to:
  /// **'What\'s happening?'**
  String get whatsHappening;

  /// No description provided for @where.
  ///
  /// In en, this message translates to:
  /// **'Where'**
  String get where;

  /// No description provided for @reportHint.
  ///
  /// In en, this message translates to:
  /// **'{type, select, roadClosure{e.g. Road closed near Maitighar} traffic{e.g. Standstill at Koteshwor} bandh{e.g. Valley-wide bandh until 6 pm} closure{e.g. Garden of Dreams closed today} festival{e.g. Jatra procession at Basantapur} other{Describe it}}'**
  String reportHint(String type);

  /// No description provided for @reportThanks.
  ///
  /// In en, this message translates to:
  /// **'Thanks! Your report is live on this device.'**
  String get reportThanks;

  /// No description provided for @planWithAi.
  ///
  /// In en, this message translates to:
  /// **'Plan with AI'**
  String get planWithAi;

  /// No description provided for @budget.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get budget;

  /// No description provided for @budgetLevel.
  ///
  /// In en, this message translates to:
  /// **'{style, select, budget{Budget} balanced{Mid-range} comfort{Comfort} other{}}'**
  String budgetLevel(String style);

  /// No description provided for @interestChoice.
  ///
  /// In en, this message translates to:
  /// **'{choice, select, culture{Culture} food{Food} nature{Nature} views{Views} shopping{Shopping} other{}}'**
  String interestChoice(String choice);

  /// No description provided for @planOptionsSummary.
  ///
  /// In en, this message translates to:
  /// **'{date} · from {time} · {hours}'**
  String planOptionsSummary(String date, String time, String hours);

  /// No description provided for @generateItinerary.
  ///
  /// In en, this message translates to:
  /// **'Generate itinerary'**
  String get generateItinerary;

  /// No description provided for @planning.
  ///
  /// In en, this message translates to:
  /// **'Planning…'**
  String get planning;

  /// No description provided for @aiOff.
  ///
  /// In en, this message translates to:
  /// **'AI is off (no Gemini API key in this build), so the built-in condition-aware planner is used.'**
  String get aiOff;

  /// No description provided for @planIntro.
  ///
  /// In en, this message translates to:
  /// **'Choose a budget and interests, then generate a plan that fits today’s weather, air quality, opening hours and reported disruptions.'**
  String get planIntro;

  /// No description provided for @suggestedItinerary.
  ///
  /// In en, this message translates to:
  /// **'Suggested itinerary'**
  String get suggestedItinerary;

  /// No description provided for @plannedWithAi.
  ///
  /// In en, this message translates to:
  /// **'Planned with Gemini AI, checked against live conditions'**
  String get plannedWithAi;

  /// No description provided for @plannedOnDevice.
  ///
  /// In en, this message translates to:
  /// **'Planned on this device (condition-aware)'**
  String get plannedOnDevice;

  /// No description provided for @aiUnavailableFallback.
  ///
  /// In en, this message translates to:
  /// **'AI unavailable right now – used the built-in planner'**
  String get aiUnavailableFallback;

  /// No description provided for @departVia.
  ///
  /// In en, this message translates to:
  /// **'Depart via {routes}'**
  String departVia(String routes);

  /// No description provided for @walkFor.
  ///
  /// In en, this message translates to:
  /// **'Walk {duration}'**
  String walkFor(String duration);

  /// No description provided for @avoids.
  ///
  /// In en, this message translates to:
  /// **'Avoids {title}'**
  String avoids(String title);

  /// No description provided for @tagRerouted.
  ///
  /// In en, this message translates to:
  /// **'rerouted'**
  String get tagRerouted;

  /// No description provided for @tagEvent.
  ///
  /// In en, this message translates to:
  /// **'event'**
  String get tagEvent;

  /// No description provided for @optionalEventNearby.
  ///
  /// In en, this message translates to:
  /// **'Optional: {title} nearby'**
  String optionalEventNearby(String title);

  /// No description provided for @fromPlaceTo.
  ///
  /// In en, this message translates to:
  /// **'To {place}'**
  String fromPlaceTo(String place);

  /// No description provided for @staysSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search hotels, guesthouses'**
  String get staysSearchHint;

  /// No description provided for @stayType.
  ///
  /// In en, this message translates to:
  /// **'{type, select, heritage{Heritage} boutique{Boutique} hotel{Hotel} resort{Resort} guesthouse{Guesthouse} hostel{Hostel} other{Stay}}'**
  String stayType(String type);

  /// No description provided for @priceBand.
  ///
  /// In en, this message translates to:
  /// **'{band, select, budget{Budget} mid{Mid-range} upscale{Upscale} luxury{Luxury} other{}}'**
  String priceBand(String band);

  /// No description provided for @perNight.
  ///
  /// In en, this message translates to:
  /// **'{range}/night'**
  String perNight(String range);

  /// No description provided for @staysDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Price ranges are approximate for the price band and change by season; check with the property. No ratings are shown until we have real reviews.'**
  String get staysDisclaimer;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @unsave.
  ///
  /// In en, this message translates to:
  /// **'Remove from saved'**
  String get unsave;

  /// No description provided for @plannedSearchHint.
  ///
  /// In en, this message translates to:
  /// **'{category, select, education{Search schools, training centres} fitness{Search gyms, studios} adventure{Search trekking, rafting operators} health{Search clinics, pharmacies} other{Search}}'**
  String plannedSearchHint(String category);

  /// No description provided for @plannedItemA.
  ///
  /// In en, this message translates to:
  /// **'{category, select, education{Language institute} fitness{Full gym} adventure{Guided trekking} health{General clinic} other{}}'**
  String plannedItemA(String category);

  /// No description provided for @plannedItemB.
  ///
  /// In en, this message translates to:
  /// **'{category, select, education{Vocational training} fitness{Yoga studio} adventure{White-water rafting} health{Pharmacy} other{}}'**
  String plannedItemB(String category);

  /// No description provided for @detailsComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Details coming soon'**
  String get detailsComingSoon;

  /// No description provided for @plannedNote.
  ///
  /// In en, this message translates to:
  /// **'This category is planned for a later phase of Yatri.'**
  String get plannedNote;

  /// No description provided for @guestUser.
  ///
  /// In en, this message translates to:
  /// **'Guest user'**
  String get guestUser;

  /// No description provided for @signInToSync.
  ///
  /// In en, this message translates to:
  /// **'Sign in to sync'**
  String get signInToSync;

  /// No description provided for @accountsComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Accounts and sync are coming soon.'**
  String get accountsComingSoon;

  /// No description provided for @savedLocations.
  ///
  /// In en, this message translates to:
  /// **'Saved locations'**
  String get savedLocations;

  /// No description provided for @noSaved.
  ///
  /// In en, this message translates to:
  /// **'Nothing saved yet. Tap the bookmark on a place or stay.'**
  String get noSaved;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageNepaliSoon.
  ///
  /// In en, this message translates to:
  /// **'नेपाली (Nepali) – coming soon'**
  String get languageNepaliSoon;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @notificationsHint.
  ///
  /// In en, this message translates to:
  /// **'Disruptions near your saved places'**
  String get notificationsHint;

  /// No description provided for @preferencesSummary.
  ///
  /// In en, this message translates to:
  /// **'{visitor} · {budget}'**
  String preferencesSummary(String visitor, String budget);

  /// No description provided for @aboutData.
  ///
  /// In en, this message translates to:
  /// **'About the data'**
  String get aboutData;

  /// No description provided for @aboutPlaces.
  ///
  /// In en, this message translates to:
  /// **'Places: 63 attractions with approximate hours and entry fees – verify locally.'**
  String get aboutPlaces;

  /// No description provided for @aboutWeather.
  ///
  /// In en, this message translates to:
  /// **'Weather and air quality: Open-Meteo. Maps: © OpenStreetMap contributors.'**
  String get aboutWeather;

  /// No description provided for @aboutAiOn.
  ///
  /// In en, this message translates to:
  /// **'AI planning: Google Gemini ({model}, free tier). Only your preferences and the day’s conditions are sent – never your exact location.'**
  String aboutAiOn(String model);

  /// No description provided for @aboutAiOff.
  ///
  /// In en, this message translates to:
  /// **'AI planning is off in this build (no API key); plans are made on the device.'**
  String get aboutAiOff;
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
