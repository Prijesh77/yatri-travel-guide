import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

import '../../features/places/domain/place_category.dart';
import '../../features/recommendations/domain/scored_place.dart';
import '../../features/transport/domain/transport_option.dart';
import '../../features/weather/domain/weather.dart';

/// Accent colours that sit beside the Material colour scheme. They come in
/// light and dark variants, so read them from the theme with `context.yatri`
/// rather than hard-coding values in widgets.
@immutable
class YatriColors extends ThemeExtension<YatriColors> {
  const YatriColors({
    required this.ai,
    required this.aiContainer,
    required this.alert,
    required this.alertContainer,
    required this.event,
    required this.eventContainer,
    required this.transit,
    required this.transitContainer,
    required this.planned,
    required this.plannedContainer,
    required this.success,
    required this.origin,
    required this.destination,
    required this.heroStart,
    required this.heroEnd,
  });

  /// AI planning (violet).
  final Color ai;
  final Color aiContainer;

  /// Disruptions and warnings (amber).
  final Color alert;
  final Color alertContainer;

  /// Events, verified data and "all clear" (green).
  final Color event;
  final Color eventContainer;

  /// Transport and other live features (navy).
  final Color transit;
  final Color transitContainer;

  /// Features that are not built yet (warm grey).
  final Color planned;
  final Color plannedContainer;

  /// "Good to go" text, such as open now or a positive reason.
  final Color success;

  /// Journey start and end dots.
  final Color origin;
  final Color destination;

  /// Home header gradient.
  final Color heroStart;
  final Color heroEnd;

  static const light = YatriColors(
    ai: Color(0xFF4B3FB0),
    aiContainer: Color(0xFFEDEBFC),
    alert: Color(0xFF8A4B08),
    alertContainer: Color(0xFFFCEBD6),
    event: Color(0xFF2E6B1F),
    eventContainer: Color(0xFFE3F1DC),
    transit: Color(0xFF1D4E89),
    transitContainer: Color(0xFFE3EEFA),
    planned: Color(0xFF7A776F),
    plannedContainer: Color(0xFFF0EEE8),
    success: Color(0xFF2E7D32),
    origin: Color(0xFF4E8F25),
    destination: Color(0xFFD83B2F),
    heroStart: Color(0xFF173F70),
    heroEnd: Color(0xFF2F6CB3),
  );

  static const dark = YatriColors(
    ai: Color(0xFFCBC3FF),
    aiContainer: Color(0xFF2E2858),
    alert: Color(0xFFFFC98A),
    alertContainer: Color(0xFF4A2F10),
    event: Color(0xFFA8D98F),
    eventContainer: Color(0xFF203A18),
    transit: Color(0xFFA9C8F5),
    transitContainer: Color(0xFF1B2E47),
    planned: Color(0xFFA19E95),
    plannedContainer: Color(0xFF2A2925),
    success: Color(0xFF8BD18E),
    origin: Color(0xFF8BD16A),
    destination: Color(0xFFFF8A80),
    heroStart: Color(0xFF0F2846),
    heroEnd: Color(0xFF1F4C80),
  );

  @override
  YatriColors copyWith() => this;

  @override
  YatriColors lerp(YatriColors? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return YatriColors(
      ai: l(ai, other.ai),
      aiContainer: l(aiContainer, other.aiContainer),
      alert: l(alert, other.alert),
      alertContainer: l(alertContainer, other.alertContainer),
      event: l(event, other.event),
      eventContainer: l(eventContainer, other.eventContainer),
      transit: l(transit, other.transit),
      transitContainer: l(transitContainer, other.transitContainer),
      planned: l(planned, other.planned),
      plannedContainer: l(plannedContainer, other.plannedContainer),
      success: l(success, other.success),
      origin: l(origin, other.origin),
      destination: l(destination, other.destination),
      heroStart: l(heroStart, other.heroStart),
      heroEnd: l(heroEnd, other.heroEnd),
    );
  }
}

extension YatriThemeContext on BuildContext {
  YatriColors get yatri => Theme.of(this).extension<YatriColors>() ?? YatriColors.light;
}

class AppTheme {
  /// Wireframe navy blue.
  static const seed = Color(0xFF1D4E89);

  static const fontFamily = 'PlusJakartaSans';

  /// Shared corner radii.
  static const radiusS = 10.0;
  static const radiusM = 14.0;
  static const radiusL = 20.0;

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final base = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
      dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
    );
    // Neutral, slightly cool surfaces instead of the tinted defaults.
    final scheme = isLight
        ? base.copyWith(
            surface: const Color(0xFFF7F8FA),
            surfaceContainerLowest: Colors.white,
            surfaceContainerLow: Colors.white,
            surfaceContainer: const Color(0xFFF0F2F5),
            surfaceContainerHigh: const Color(0xFFE9ECF0),
            surfaceContainerHighest: const Color(0xFFE2E6EB),
            outlineVariant: const Color(0xFFDDE1E7),
          )
        : base.copyWith(
            surface: const Color(0xFF101318),
            surfaceContainerLowest: const Color(0xFF0B0E12),
            surfaceContainerLow: const Color(0xFF171B21),
            surfaceContainer: const Color(0xFF1C2027),
            surfaceContainerHigh: const Color(0xFF242932),
            surfaceContainerHighest: const Color(0xFF2E343D),
            outlineVariant: const Color(0xFF353B45),
          );

    final textTheme = _textTheme(ThemeData(colorScheme: scheme, useMaterial3: true, fontFamily: fontFamily).textTheme);

    final rounded = RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusM));
    const buttonText = TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w700, fontSize: 15);

    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      fontFamily: fontFamily,
      textTheme: textTheme,
      scaffoldBackgroundColor: scheme.surface,
      extensions: [isLight ? YatriColors.light : YatriColors.dark],
      visualDensity: VisualDensity.standard,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusL - 2),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: isLight ? 0.7 : 0.5)),
        ),
        margin: EdgeInsets.zero,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(minimumSize: const Size(64, 50), shape: rounded, textStyle: buttonText),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(minimumSize: const Size(64, 50), shape: rounded, textStyle: buttonText),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 44),
          shape: rounded,
          textStyle: buttonText,
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(shape: rounded, textStyle: buttonText.copyWith(fontSize: 14)),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          shape: rounded,
          side: BorderSide(color: scheme.outlineVariant),
          selectedBackgroundColor: scheme.primaryContainer,
          selectedForegroundColor: scheme.onPrimaryContainer,
          textStyle: const TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: ChipThemeData(
        showCheckmark: false,
        shape: const StadiumBorder(),
        side: BorderSide(color: scheme.outlineVariant),
        backgroundColor: scheme.surfaceContainerLow,
        selectedColor: scheme.primaryContainer,
        labelStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 70,
        elevation: 0,
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primaryContainer,
        indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusM)),
        labelTextStyle: WidgetStateProperty.resolveWith((states) => textTheme.labelSmall?.copyWith(
              fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
              color: states.contains(WidgetState.selected) ? scheme.onSurface : scheme.onSurfaceVariant,
            )),
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
              color: states.contains(WidgetState.selected) ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
            )),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        showDragHandle: true,
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusS + 2)),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, thickness: 1, space: 1),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        iconColor: scheme.onSurfaceVariant,
        titleTextStyle: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        subtitleTextStyle: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
      ),
      switchTheme: SwitchThemeData(
        thumbIcon: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? const Icon(Icons.check, size: 14) : null,
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
        },
      ),
    );
  }

  static TextTheme _textTheme(TextTheme t) => t.copyWith(
        displaySmall: t.displaySmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -1),
        headlineMedium: t.headlineMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5),
        headlineSmall: t.headlineSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.4),
        titleLarge: t.titleLarge?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.2),
        titleMedium: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        titleSmall: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        labelLarge: t.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        labelMedium: t.labelMedium?.copyWith(fontWeight: FontWeight.w600),
      );
}

extension CategoryStyle on PlaceCategory {
  IconData get icon => switch (this) {
        PlaceCategory.heritage => Icons.account_balance,
        PlaceCategory.temple => Icons.temple_buddhist,
        PlaceCategory.nature => Icons.park,
        PlaceCategory.food => Icons.restaurant,
        PlaceCategory.shopping => Icons.shopping_bag,
        PlaceCategory.viewpoint => Icons.landscape,
      };

  Color get color => switch (this) {
        PlaceCategory.heritage => const Color(0xFF8D5B3E),
        PlaceCategory.temple => const Color(0xFFD35400),
        PlaceCategory.nature => const Color(0xFF2E7D32),
        PlaceCategory.food => const Color(0xFFC2185B),
        PlaceCategory.shopping => const Color(0xFF6A1B9A),
        PlaceCategory.viewpoint => const Color(0xFF1565C0),
      };
}

extension WeatherStyle on WeatherCondition {
  IconData icon({bool isDay = true}) => switch (this) {
        WeatherCondition.clear => isDay ? Icons.wb_sunny : Icons.nightlight_round,
        WeatherCondition.partlyCloudy => isDay ? Icons.wb_cloudy : Icons.nights_stay,
        WeatherCondition.cloudy => Icons.cloud,
        WeatherCondition.fog => Icons.foggy,
        WeatherCondition.drizzle => Icons.grain,
        WeatherCondition.rain => Icons.umbrella,
        WeatherCondition.heavyRain => Icons.water_drop,
        WeatherCondition.thunderstorm => Icons.thunderstorm,
        WeatherCondition.snow => Icons.ac_unit,
      };
}

extension AirQualityStyle on AirQualityLevel {
  Color get color => switch (this) {
        AirQualityLevel.good => const Color(0xFF2E7D32),
        AirQualityLevel.moderate => const Color(0xFF9E7700),
        AirQualityLevel.sensitive => const Color(0xFFE65100),
        AirQualityLevel.unhealthy => const Color(0xFFC62828),
        AirQualityLevel.veryUnhealthy => const Color(0xFF6A1B9A),
      };
}

extension SuitabilityStyle on Suitability {
  Color color(ColorScheme scheme) => switch (this) {
        Suitability.excellent => const Color(0xFF2E7D32),
        Suitability.good => const Color(0xFF558B2F),
        Suitability.fair => const Color(0xFF9E7700),
        Suitability.notIdeal => const Color(0xFFE65100),
        Suitability.unavailable => scheme.outline,
      };

  IconData get icon => switch (this) {
        Suitability.excellent => Icons.star,
        Suitability.good => Icons.thumb_up_alt_outlined,
        Suitability.fair => Icons.remove_circle_outline,
        Suitability.notIdeal => Icons.warning_amber,
        Suitability.unavailable => Icons.block,
      };
}

extension TransportStyle on TransportMode {
  IconData get icon => switch (this) {
        TransportMode.walk => Icons.directions_walk,
        TransportMode.bikeTaxi => Icons.two_wheeler,
        TransportMode.taxi => Icons.local_taxi,
        TransportMode.bus => Icons.directions_bus,
      };
}
