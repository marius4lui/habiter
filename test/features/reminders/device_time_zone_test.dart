import 'package:flutter_test/flutter_test.dart';
import 'package:habiter/core/time/local_date.dart';
import 'package:habiter/features/reminders/infrastructure/device_time_zone_service.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

void main() {
  setUpAll(tz_data.initializeTimeZones);

  test(
    'resolves Berlin spring gap and fall overlap without a fixed offset',
    () {
      final berlin = tz.getLocation('Europe/Berlin');
      final spring = DeviceTimeZoneService.resolveWallClock(
        location: berlin,
        date: LocalDate(2026, 3, 29),
        hour: 2,
        minute: 30,
      );
      final fall = DeviceTimeZoneService.resolveWallClock(
        location: berlin,
        date: LocalDate(2026, 10, 25),
        hour: 2,
        minute: 30,
      );

      expect(spring.hour, 3);
      expect(spring.minute, 30);
      expect(fall.hour, 2);
      expect(
        fall.timeZoneOffset,
        anyOf(const Duration(hours: 1), const Duration(hours: 2)),
      );
    },
  );

  test('resolves New York and Kolkata using their device rules', () {
    final date = LocalDate(2026, 8, 14);
    final newYork = DeviceTimeZoneService.resolveWallClock(
      location: tz.getLocation('America/New_York'),
      date: date,
      hour: 9,
      minute: 15,
    );
    final kolkata = DeviceTimeZoneService.resolveWallClock(
      location: tz.getLocation('Asia/Kolkata'),
      date: date,
      hour: 9,
      minute: 15,
    );

    expect(newYork.timeZoneOffset, const Duration(hours: -4));
    expect(kolkata.timeZoneOffset, const Duration(hours: 5, minutes: 30));
  });

  test('unknown zones fall back safely and changes are observable', () async {
    final gateway = _MutableTimeZoneGateway('Not/AZone');
    final service = DeviceTimeZoneService(gateway);
    final first = await service.initialize();
    expect(first.location, tz.UTC);
    expect(first.usedFallback, isTrue);

    gateway.value = 'Europe/Berlin';
    expect(await service.refreshIfChanged(), isTrue);
    expect(tz.local.name, 'Europe/Berlin');
    expect(await service.refreshIfChanged(), isFalse);
  });
}

final class _MutableTimeZoneGateway implements DeviceTimeZoneGateway {
  _MutableTimeZoneGateway(this.value);
  String? value;

  @override
  Future<String?> currentTimeZoneId() async => value;
}
