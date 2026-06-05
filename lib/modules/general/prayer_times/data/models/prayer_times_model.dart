import 'package:adhan/adhan.dart';

class PrayerTimesModel {
  final double latitude;
  final double longitude;
  final String timezone;
  final String dateReadable;
  final String hijriDate;

  PrayerTimesModel({
    required this.latitude,
    required this.longitude,
    required this.timezone,
    required this.dateReadable,
    required this.hijriDate,
  });

  factory PrayerTimesModel.fromAladhanJson(Map<String, dynamic> json) {
    final dateJson = json['date'] as Map<String, dynamic>;
    final readable = dateJson['readable']?.toString() ?? '';
    
    final hijriJson = dateJson['hijri'] as Map<String, dynamic>;
    final hijriDay = hijriJson['day']?.toString() ?? '';
    final hijriMonthEn = hijriJson['month']?['en']?.toString() ?? '';
    final hijriYear = hijriJson['year']?.toString() ?? '';
    final hijriDateStr = '$hijriDay $hijriMonthEn $hijriYear';

    final metaJson = json['meta'] as Map<String, dynamic>;
    final timezoneStr = metaJson['timezone']?.toString() ?? 'UTC';
    final lat = double.tryParse(metaJson['latitude']?.toString() ?? '0') ?? 0.0;
    final lon = double.tryParse(metaJson['longitude']?.toString() ?? '0') ?? 0.0;

    return PrayerTimesModel(
      latitude: lat,
      longitude: lon,
      timezone: timezoneStr,
      dateReadable: readable,
      hijriDate: hijriDateStr,
    );
  }

  factory PrayerTimesModel.fromJson(Map<String, dynamic> json) {
    return PrayerTimesModel(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      timezone: json['timezone'] as String,
      dateReadable: json['dateReadable'] as String,
      hijriDate: json['hijriDate'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'timezone': timezone,
      'dateReadable': dateReadable,
      'hijriDate': hijriDate,
    };
  }

  factory PrayerTimesModel.defaultLocation() {
    return PrayerTimesModel(
      latitude: 6.5244, // Lagos, Nigeria default
      longitude: 3.3792,
      timezone: 'Africa/Lagos',
      dateReadable: '04 Jun 2026',
      hijriDate: '18 Dhul-Hijjah 1447',
    );
  }

  /// Get adhan's PrayerTimes object calculated locally for a specific date.
  PrayerTimes getPrayerTimesForDate(DateTime date, {CalculationMethod method = CalculationMethod.muslim_world_league}) {
    final coordinates = Coordinates(latitude, longitude);
    final dateComponents = DateComponents.from(date);
    final params = method.getParameters();
    params.madhab = Madhab.shafi;
    return PrayerTimes(coordinates, dateComponents, params);
  }
}
