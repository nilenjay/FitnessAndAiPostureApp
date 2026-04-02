part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthStarted extends AuthEvent {}

class AuthSignUpRequested extends AuthEvent {
  final String email;
  final String password;
  final String name;
  AuthSignUpRequested({required this.email, required this.password, required this.name});
  @override
  List<Object?> get props => [email, password, name];
}

class AuthSignInRequested extends AuthEvent {
  final String email;
  final String password;
  AuthSignInRequested({required this.email, required this.password});
  @override
  List<Object?> get props => [email, password];
}

class AuthSignOutRequested extends AuthEvent {}

/// Fired after the user completes the profile setup screen.
class AuthProfileCompleted extends AuthEvent {}

class _UserChanged extends AuthEvent {
  final User user;
  _UserChanged(this.user);
  @override
  List<Object?> get props => [user];
}

class _UserLoggedOut extends AuthEvent {}