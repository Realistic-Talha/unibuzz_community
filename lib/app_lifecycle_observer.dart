import 'package:flutter/material.dart';
import 'package:unibuzz_community/services/presence_service.dart';

class AppLifecycleObserver extends WidgetsBindingObserver {
  final PresenceService _presenceService = PresenceService();
  bool _wasInBackground = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        if (_wasInBackground) {
          _presenceService.initializePresence();
          _wasInBackground = false;
        }
        break;
      case AppLifecycleState.paused:
        _wasInBackground = true;
        break;
      default:
        break;
    }
  }
}
