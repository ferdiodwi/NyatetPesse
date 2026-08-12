import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final bool isPinSetup;
  
  AuthState({
    this.isLoading = true,
    this.isAuthenticated = false,
    this.isPinSetup = false,
  });
  
  AuthState copyWith({bool? isLoading, bool? isAuthenticated, bool? isPinSetup}) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isPinSetup: isPinSetup ?? this.isPinSetup,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState()) {
    _checkPinStatus();
  }

  static const String _pinKey = 'user_secure_pin';

  Future<void> _checkPinStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final pin = prefs.getString(_pinKey);
    
    state = state.copyWith(
      isLoading: false,
      isPinSetup: pin != null && pin.isNotEmpty,
      isAuthenticated: false,
    );
  }

  Future<bool> setupPin(String pin) async {
    if (pin.length != 6) return false;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pinKey, pin);
    
    state = state.copyWith(
      isPinSetup: true,
      isAuthenticated: true, // Login directly after setup
    );
    return true;
  }

  Future<bool> verifyPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final savedPin = prefs.getString(_pinKey);
    
    if (savedPin == pin) {
      state = state.copyWith(isAuthenticated: true);
      return true;
    }
    return false;
  }
  
  void logout() {
    state = state.copyWith(isAuthenticated: false);
  }
}
