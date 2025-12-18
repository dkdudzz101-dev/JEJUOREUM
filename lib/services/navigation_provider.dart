import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class NavigationProvider extends ChangeNotifier {
  bool _isNavigating = false;
  bool _isWeakGpsSignal = false;
  Position? _currentPosition;
  double? _remainingDistance;
  int? _remainingTime;
  bool _isOnline = true;

  // Getters
  bool get isNavigating => _isNavigating;
  bool get isWeakGpsSignal => _isWeakGpsSignal;
  Position? get currentPosition => _currentPosition;
  double? get remainingDistance => _remainingDistance;
  int? get remainingTime => _remainingTime;
  bool get isOnline => _isOnline;

  // Setters
  void updateNavigationStatus(bool isNavigating) {
    if (_isNavigating != isNavigating) {
      _isNavigating = isNavigating;
      notifyListeners();
    }
  }

  void updateGpsSignalStatus(bool isWeak) {
    if (_isWeakGpsSignal != isWeak) {
      _isWeakGpsSignal = isWeak;
      notifyListeners();
    }
  }

  void updatePosition(Position position) {
    _currentPosition = position;
    notifyListeners();
  }

  void updateRemainingDistance(double? distance) {
    if (_remainingDistance != distance) {
      _remainingDistance = distance;
      notifyListeners();
    }
  }

  void updateRemainingTime(int? time) {
    if (_remainingTime != time) {
      _remainingTime = time;
      notifyListeners();
    }
  }

  void updateOnlineStatus(bool isOnline) {
    if (_isOnline != isOnline) {
      _isOnline = isOnline;
      notifyListeners();
    }
  }

  // Calculate remaining time based on distance (walking speed ~5 km/h)
  void calculateRemainingTime() {
    if (_remainingDistance != null) {
      // Walking speed: 5 km/h = 83.33 m/min
      _remainingTime = (_remainingDistance! * 1000 / 83.33).round();
      notifyListeners();
    }
  }

  // Reset all values
  void reset() {
    _isNavigating = false;
    _isWeakGpsSignal = false;
    _currentPosition = null;
    _remainingDistance = null;
    _remainingTime = null;
    _isOnline = true;
    notifyListeners();
  }
}
