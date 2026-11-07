import 'package:equatable/equatable.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/entities/auth_tokens.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {
  final String? message;

  const AuthLoading({this.message});

  @override
  List<Object?> get props => [message];
}

class AuthUnauthenticated extends AuthState {
  final String? errorMessage;

  const AuthUnauthenticated({this.errorMessage});

  @override
  List<Object?> get props => [errorMessage];
}

class AuthCyberIdRegisteredSeedReady extends AuthState {
  final UserEntity user;
  final AuthTokens tokens;
  final List<String> seedPhrase;

  const AuthCyberIdRegisteredSeedReady({
    required this.user,
    required this.tokens,
    required this.seedPhrase,
  });

  @override
  List<Object?> get props => [user, tokens, seedPhrase];
}

class AuthAuthenticated extends AuthState {
  final UserEntity user;

  const AuthAuthenticated({required this.user});

  @override
  List<Object?> get props => [user];
}

class AuthEmailOtpSent extends AuthState {
  final String email;
  final String? devCode;

  const AuthEmailOtpSent({required this.email, this.devCode});

  @override
  List<Object?> get props => [email, devCode];
}

class AuthError extends AuthState {
  final String message;

  const AuthError({required this.message});

  @override
  List<Object?> get props => [message];
}
