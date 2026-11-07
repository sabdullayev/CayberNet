import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc({required this.authRepository}) : super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthCyberIdLoginSubmitted>(_onCyberIdLoginSubmitted);
    on<AuthCyberIdRegisterSubmitted>(_onCyberIdRegisterSubmitted);
    on<AuthCyberIdRestoreSubmitted>(_onCyberIdRestoreSubmitted);
    on<AuthEmailOtpSendRequested>(_onEmailOtpSendRequested);
    on<AuthEmailOtpVerifySubmitted>(_onEmailOtpVerifySubmitted);
    on<AuthTelegramVerifySubmitted>(_onTelegramVerifySubmitted);
    on<AuthSeedPhraseDismissed>(_onSeedPhraseDismissed);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: 'ПОИСК НЕЙРОСИГНАЛА...'));
    try {
      final user = await authRepository.getCurrentUser();
      if (user != null) {
        emit(AuthAuthenticated(user: user));
      } else {
        emit(const AuthUnauthenticated());
      }
    } catch (_) {
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onCyberIdLoginSubmitted(
    AuthCyberIdLoginSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: 'СИНХРОНИЗАЦИЯ CYBER-ID...'));
    try {
      final result = await authRepository.loginCyberId(
        identifier: event.identifier,
        password: event.password,
      );
      emit(AuthAuthenticated(user: result.user));
    } catch (e) {
      emit(AuthError(message: _cleanError(e)));
    }
  }

  Future<void> _onCyberIdRegisterSubmitted(
    AuthCyberIdRegisterSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: 'ГЕНЕРАЦИЯ КИБЕРПАНК СИД-ФРАЗЫ...'));
    try {
      final result = await authRepository.registerCyberId(
        username: event.username,
        password: event.password,
      );
      emit(AuthCyberIdRegisteredSeedReady(
        user: result.user,
        tokens: result.tokens,
        seedPhrase: result.seedPhrase,
      ));
    } catch (e) {
      emit(AuthError(message: _cleanError(e)));
    }
  }

  Future<void> _onCyberIdRestoreSubmitted(
    AuthCyberIdRestoreSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: 'РАСШИФРОВКА СИД-КЛЮЧЕЙ...'));
    try {
      final result = await authRepository.restoreCyberId(
        seedPhrase: event.seedPhrase,
        newPassword: event.newPassword,
      );
      emit(AuthAuthenticated(user: result.user));
    } catch (e) {
      emit(AuthError(message: _cleanError(e)));
    }
  }

  Future<void> _onEmailOtpSendRequested(
    AuthEmailOtpSendRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: 'ОТПРАВКА ШИФРОКЛЮЧА НА EMAIL...'));
    try {
      final devCode = await authRepository.sendEmailOtp(email: event.email);
      emit(AuthEmailOtpSent(email: event.email, devCode: devCode));
    } catch (e) {
      emit(AuthError(message: _cleanError(e)));
    }
  }

  Future<void> _onEmailOtpVerifySubmitted(
    AuthEmailOtpVerifySubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: 'ПРОВЕРКА OTP СЕТЕВОГО КЛЮЧА...'));
    try {
      final result = await authRepository.verifyEmailOtp(
        email: event.email,
        code: event.code,
      );
      emit(AuthAuthenticated(user: result.user));
    } catch (e) {
      emit(AuthError(message: _cleanError(e)));
    }
  }

  Future<void> _onTelegramVerifySubmitted(
    AuthTelegramVerifySubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: 'ПОДКЛЮЧЕНИЕ НЕЙРОЛИНКА TG...'));
    try {
      final result = await authRepository.verifyTelegramCode(code: event.code);
      emit(AuthAuthenticated(user: result.user));
    } catch (e) {
      emit(AuthError(message: _cleanError(e)));
    }
  }

  void _onSeedPhraseDismissed(
    AuthSeedPhraseDismissed event,
    Emitter<AuthState> emit,
  ) {
    if (state is AuthCyberIdRegisteredSeedReady) {
      final user = (state as AuthCyberIdRegisteredSeedReady).user;
      emit(AuthAuthenticated(user: user));
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await authRepository.logout();
    emit(const AuthUnauthenticated());
  }

  String _cleanError(dynamic error) {
    return error.toString().replaceAll('Exception: ', '').trim();
  }
}
