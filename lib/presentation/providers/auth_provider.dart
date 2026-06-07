import 'package:flutter/material.dart';
import '../../domain/entities/user.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/register_usecase.dart';

enum AuthState { initial, loading, success, error }

class AuthProvider extends ChangeNotifier {
  final LoginUseCase _loginUseCase;
  final RegisterUseCase _registerUseCase;
  final LogoutUsecase _logoutUsecase;

  AuthProvider(this._loginUseCase, this._registerUseCase,this._logoutUsecase);

  AuthState state = AuthState.initial;
  String? errorMessage;
  User? currentUser;

  Future<bool> login(String email, String password) async {
    try {
      state = AuthState.loading;
      errorMessage = null;
      notifyListeners();

      currentUser = await _loginUseCase(email, password);
      
      state = AuthState.success;
      notifyListeners();
      return true;
    } catch (e) {
      state = AuthState.error;
      errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
  }) async {
    try {
      state = AuthState.loading;
      errorMessage = null;
      notifyListeners();

      currentUser = await _registerUseCase(
        email: email,
        password: password,
        fullName: fullName,
        phoneNumber: phoneNumber,
      );
      
      state = AuthState.success;
      notifyListeners();
      return true;
    } catch (e) {
      state = AuthState.error;
      errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
  Future<void> logout() async {
    await _logoutUsecase();
    currentUser = null;
    state = AuthState.initial;
    notifyListeners();
  }
}
