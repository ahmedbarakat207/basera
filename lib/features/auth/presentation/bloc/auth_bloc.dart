import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:basera/core/services/firebase_backend_service.dart';
import 'package:basera/core/utils/child_history_service.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final FirebaseBackendService _authService = FirebaseBackendService.instance;

  AuthBloc() : super(AuthInitial()) {
    on<AuthCheckRequested>(_onCheckStatus);
    on<AuthLoginRequested>(_onLogin);
    on<AuthSignUpRequested>(_onSignUp);
    on<AuthLogoutRequested>(_onLogout);
  }

  Future<void> _onCheckStatus(AuthCheckRequested event, Emitter<AuthState> emit) async {
    final isLoggedIn = await ChildHistoryService.instance.getIsLoggedIn();
    if (isLoggedIn) {
      final role = await ChildHistoryService.instance.getUserRole();
      emit(Authenticated(role: role));
    } else {
      emit(Unauthenticated());
    }
  }

  Future<void> _onLogin(AuthLoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final role = await _authService.signIn(
        email: event.email,
        password: event.password,
      );
      emit(Authenticated(role: role));
    } catch (e) {
      emit(AuthError(message: _mapErrorToMessage(e)));
    }
  }

  Future<void> _onSignUp(AuthSignUpRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await _authService.signUp(
        email: event.email,
        password: event.password,
        name: event.name,
        role: event.role,
      );
      emit(Authenticated(role: event.role));
    } catch (e) {
      emit(AuthError(message: _mapErrorToMessage(e)));
    }
  }

  Future<void> _onLogout(AuthLogoutRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await _authService.signOut();
      emit(Unauthenticated());
    } catch (e) {
      emit(AuthError(message: _mapErrorToMessage(e)));
    }
  }

  String _mapErrorToMessage(dynamic error) {
    final strErr = error.toString();
    if (strErr.contains('user-not-found') || strErr.contains('invalid-credential')) {
      return 'Incorrect email address or password.';
    } else if (strErr.contains('email-already-in-use')) {
      return 'This email address is already registered.';
    } else if (strErr.contains('network-request-failed') || strErr.contains('NetworkError')) {
      return 'Network connection failed. Please check your internet connection and try again.';
    } else if (strErr.contains('weak-password')) {
      return 'The password is too weak. Please use at least 6 characters.';
    } else if (strErr.contains('invalid-email')) {
      return 'The email format is invalid.';
    }
    return 'An unexpected authentication error occurred: $strErr';
  }
}
