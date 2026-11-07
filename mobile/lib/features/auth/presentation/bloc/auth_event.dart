import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {}

class AuthCyberIdLoginSubmitted extends AuthEvent {
  final String identifier;
  final String password;

  const AuthCyberIdLoginSubmitted({
    required this.identifier,
    required this.password,
  });

  @override
  List<Object?> get props => [identifier, password];
}

class AuthCyberIdRegisterSubmitted extends AuthEvent {
  final String username;
  final String password;

  const AuthCyberIdRegisterSubmitted({
    required this.username,
    required this.password,
  });

  @override
  List<Object?> get props => [username, password];
}

class AuthCyberIdRestoreSubmitted extends AuthEvent {
  final String seedPhrase;
  final String? newPassword;

  const AuthCyberIdRestoreSubmitted({
    required this.seedPhrase,
    this.newPassword,
  });

  @override
  List<Object?> get props => [seedPhrase, newPassword];
}

class AuthEmailOtpSendRequested extends AuthEvent {
  final String email;

  const AuthEmailOtpSendRequested({required this.email});

  @override
  List<Object?> get props => [email];
}

class AuthEmailOtpVerifySubmitted extends AuthEvent {
  final String email;
  final String code;

  const AuthEmailOtpVerifySubmitted({
    required this.email,
    required this.code,
  });

  @override
  List<Object?> get props => [email, code];
}

class AuthTelegramVerifySubmitted extends AuthEvent {
  final String code;

  const AuthTelegramVerifySubmitted({required this.code});

  @override
  List<Object?> get props => [code];
}

class AuthSeedPhraseDismissed extends AuthEvent {}

class AuthLogoutRequested extends AuthEvent {}
