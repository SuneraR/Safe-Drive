import 'dart:async';
import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

class RideBackgroundService {
  RideBackgroundService._();

  static final RideBackgroundService instance = RideBackgroundService._();

  static const String _notificationChannelId = 'safe_drive_monitoring';

  final FlutterBackgroundService _service = FlutterBackgroundService();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    await _service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onRideBackgroundServiceStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: _notificationChannelId,
        initialNotificationTitle: 'Safe Drive',
        initialNotificationContent: 'Background ride monitoring is ready.',
        foregroundServiceNotificationId: 101,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onRideBackgroundServiceForeground,
        onBackground: onRideBackgroundServiceBackground,
      ),
    );

    _initialized = true;
  }

  Future<void> start() async {
    if (!_initialized) {
      await initialize();
    }

    if (await _service.isRunning()) {
      return;
    }

    await _service.startService();
  }

  Future<void> stop() async {
    if (!await _service.isRunning()) {
      return;
    }

    _service.invoke('stopService');
  }
}

@pragma('vm:entry-point')
Future<void> onRideBackgroundServiceStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  if (service is AndroidServiceInstance) {
    service.setForegroundNotificationInfo(
      title: 'Safe Drive',
      content: 'Background ride monitoring is active.',
    );
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  Timer.periodic(const Duration(seconds: 30), (Timer timer) {
    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: 'Safe Drive',
        content: 'Background ride monitoring is active.',
      );
    }
  });
}

@pragma('vm:entry-point')
Future<bool> onRideBackgroundServiceBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

@pragma('vm:entry-point')
void onRideBackgroundServiceForeground(ServiceInstance service) {
  DartPluginRegistrant.ensureInitialized();
}