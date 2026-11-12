import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/repositories/repositories.dart';

/// Single source of truth for the signed-in user. The router listens to it
/// to redirect between the auth screens and the rest of the app.
class SessionViewModel extends ChangeNotifier {
  SessionViewModel(this._auth) {
    _user = _auth.currentUser;
    _sub = _auth.authStateChanges().listen((user) {
      _user = user;
      _initialized = true;
      notifyListeners();
    });
  }

  final AuthRepository _auth;
  late final StreamSubscription<AppUser?> _sub;

  AppUser? _user;
  bool _initialized = false;

  AppUser? get user => _user;
  bool get isSignedIn => _user != null;
  bool get initialized => _initialized;

  bool get supportsEmailPassword => _auth.supportsEmailPassword;
  bool get supportsGuest => _auth.supportsGuest;

  Future<void> signOut() => _auth.signOut();

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
