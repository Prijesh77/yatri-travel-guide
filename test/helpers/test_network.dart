import 'package:yatri/features/transport/domain/route_network.dart';

/// A tiny synthetic network along latitude 27.70 / longitude 85.34 so tests
/// do not depend on the real data pack.
///
///   A (verified):   a1 --- a2 --- a3
///   B (osm):                       b1 (next to a3) --- b2 --- b3
///   H (historical): a1 ---------------------------------------- b3
///   N (verified, night only 20:00-23:00): a1 --- a3
RouteNetwork testNetwork() => RouteNetwork.fromJson({
      'version': 1,
      'network': {
        'roadDistanceFactor': 1.3,
        'routeDistanceFactor': 1.1,
        'maxWalkToStopKm': 0.6,
        'transferWalkKm': 0.3,
        'rushHours': [
          {'start': '08:00', 'end': '10:00'},
        ],
        'rushHourSpeedFactor': 0.5,
      },
      'modes': {
        'walk': {'speedKmh': 4.5, 'maxKm': 3.0},
        'bikeTaxi': {'speedKmh': 20, 'pickupMinutes': 5, 'baseFare': 40, 'perKm': 20, 'minFare': 70},
        'taxi': {
          'speedKmh': 18,
          'pickupMinutes': 5,
          'baseFare': 58,
          'perKm': 60,
          'minFare': 58,
          'fareSpreadLow': 0,
          'fareSpreadHigh': 0.3,
          'night': {'start': '21:00', 'end': '06:00', 'multiplier': 1.3},
        },
        'bus': {
          'speedKmh': 15,
          'waitMinutes': 10,
          'serviceHours': {'start': '06:00', 'end': '20:00'},
          'fareSlabs': [
            {'upToKm': 5, 'fare': 24},
            {'upToKm': 10, 'fare': 33},
            {'upToKm': 999, 'fare': 50},
          ],
        },
      },
      'stops': [
        {'id': 'a1', 'name': 'A1', 'lat': 27.70, 'lng': 85.30},
        {'id': 'a2', 'name': 'A2', 'lat': 27.70, 'lng': 85.32},
        {'id': 'a3', 'name': 'A3', 'lat': 27.70, 'lng': 85.34},
        {'id': 'b1', 'name': 'B1', 'lat': 27.7015, 'lng': 85.3405, 'accuracy': 'rough'},
        {'id': 'b2', 'name': 'B2', 'lat': 27.72, 'lng': 85.34},
        {'id': 'b3', 'name': 'B3', 'lat': 27.74, 'lng': 85.34},
      ],
      'routes': [
        {'id': 'A', 'name': 'Route A', 'status': 'verified', 'stops': ['a1', 'a2', 'a3'], 'frequencyMinutes': 6},
        {'id': 'B', 'name': 'Route B', 'status': 'osm', 'stops': ['b1', 'b2', 'b3']},
        {'id': 'H', 'name': 'Route H', 'status': 'historical', 'stops': ['a1', 'b3']},
        {
          'id': 'N',
          'name': 'Night N',
          'status': 'verified',
          'stops': ['a1', 'a3'],
          'serviceHours': {'start': '20:00', 'end': '23:00'},
        },
      ],
    });
