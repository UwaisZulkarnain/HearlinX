import 'package:flutter/material.dart';

class AuthProvider extends ChangeNotifier {
  final _isAuthenticated = false;

  bool get isAuthenticated => _isAuthenticated;
}
