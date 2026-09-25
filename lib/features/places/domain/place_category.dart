enum PlaceCategory {
  heritage,
  temple,
  nature,
  food,
  shopping,
  viewpoint;

  static PlaceCategory parse(String value) => values.firstWhere(
        (c) => c.name == value,
        orElse: () => throw FormatException('Unknown category "$value"'),
      );
}

enum City {
  kathmandu,
  lalitpur,
  bhaktapur;

  static City parse(String value) => values.firstWhere(
        (c) => c.name == value.toLowerCase(),
        orElse: () => throw FormatException('Unknown city "$value"'),
      );
}

/// Whether a place is under cover. `mixed` means partly covered (e.g. a
/// palace square with an indoor museum).
enum Setting {
  indoor,
  outdoor,
  mixed;

  static Setting parse(String value) => values.firstWhere(
        (c) => c.name == value,
        orElse: () => throw FormatException('Unknown setting "$value"'),
      );
}

/// Ticket prices differ for foreigners, SAARC nationals and Nepali citizens.
enum VisitorType { foreigner, saarc, nepali }
