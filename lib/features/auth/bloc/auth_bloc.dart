
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../data/auth_repository.dart';
import 'auth_state.dart';

part 'auth_event.dart';
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;
  StreamSubscription<User?>? _authSubscription;

  AuthBloc({required this.authRepository}) : super(AuthInitial()) {
    on<AuthStarted>(_onAuthStarted);
    on<_UserChanged>(_onUserChanged);
    on<_UserLoggedOut>(_onUserLoggedOut);
    on<AuthSignUpRequested>(_onSignUpRequested);
    on<AuthSignInRequested>(_onSignInRequested);
    on<AuthSignOutRequested>(_onSignOutRequested);
    on<AuthProfileCompleted>(_onProfileCompleted);
  }

  bool _isAuthenticating = false;

  Future<void> _onUserChanged(_UserChanged event, Emitter<AuthState> emit) async {
    if (!_isAuthenticating) {
      final complete = await authRepository.isProfileComplete(event.user.uid);
      emit(AuthAuthenticated(event.user, profileComplete: complete));
    }
  }

  void _onUserLoggedOut(_UserLoggedOut event, Emitter<AuthState> emit) {
    emit(AuthUnauthenticated());
  }

  void _onAuthStarted(AuthStarted event, Emitter<AuthState> emit) {
    _authSubscription?.cancel();
    _authSubscription = authRepository.authStateChanges.listen((user) {
      if (user != null) {
        add(_UserChanged(user));
      } else {
        add(_UserLoggedOut());
      }
    });
  }

  Future<void> _onSignUpRequested(
      AuthSignUpRequested event,
      Emitter<AuthState> emit,
      ) async {
    _isAuthenticating = true;
    emit(AuthLoading());
    try {
      await authRepository.signUp(
        email: event.email,
        password: event.password,
        name: event.name,
      );
      _isAuthenticating = false;
      final user = authRepository.currentUser;
      if (user != null) {
        // New sign-up → profile is NOT complete yet
        emit(AuthAuthenticated(user, profileComplete: false));
      }
    } on FirebaseAuthException catch (e) {
      _isAuthenticating = false;
      emit(AuthError(_mapFirebaseError(e.code)));
    } catch (e) {
      _isAuthenticating = false;
      emit(AuthError('An unexpected error occurred.'));
    }
  }

  Future<void> _onSignInRequested(
      AuthSignInRequested event,
      Emitter<AuthState> emit,
      ) async {
    _isAuthenticating = true;
    emit(AuthLoading());
    try {
      await authRepository.signIn(
        email: event.email,
        password: event.password,
      );
      _isAuthenticating = false;
      final user = authRepository.currentUser;
      if (user != null) {
        final complete = await authRepository.isProfileComplete(user.uid);
        emit(AuthAuthenticated(user, profileComplete: complete));
      }
    } on FirebaseAuthException catch (e) {
      _isAuthenticating = false;
      emit(AuthError(_mapFirebaseError(e.code)));
    } catch (e) {
      _isAuthenticating = false;
      emit(AuthError('An unexpected error occurred.'));
    }
  }

  Future<void> _onSignOutRequested(
      AuthSignOutRequested event,
      Emitter<AuthState> emit,
      ) async {
    await authRepository.signOut();
    emit(AuthUnauthenticated());
  }

  void _onProfileCompleted(
      AuthProfileCompleted event,
      Emitter<AuthState> emit,
      ) {
    final currentState = state;
    if (currentState is AuthAuthenticated) {
      emit(AuthAuthenticated(currentState.user, profileComplete: true));
    }
  }

  String _mapFirebaseError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'user-not-found':
      case 'invalid-credential':
      case 'wrong-password':
        return 'Incorrect email or password. Please try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return 'Authentication failed. Please try again. ($code)';
    }
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}

