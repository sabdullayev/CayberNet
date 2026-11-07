import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/di/service_locator.dart';
import 'core/theme/cyber_colors.dart';
import 'core/theme/cyber_theme.dart';
import 'core/theme/cyber_typography.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/auth/presentation/bloc/auth_state.dart';
import 'features/auth/presentation/screens/global_hub_screen.dart';
import 'features/auth/presentation/screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initServiceLocator();
  runApp(const CyberApp());
}

class CyberApp extends StatelessWidget {
  const CyberApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthBloc>(
      create: (context) => sl<AuthBloc>()..add(AuthCheckRequested()),
      child: MaterialApp(
        title: 'CyberNet',
        debugShowCheckedModeBanner: false,
        theme: CyberTheme.darkTheme,
        home: const AuthGate(),
      ),
    );
  }
}

typedef RoninApp = CyberApp;

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      buildWhen: (previous, current) {
        return current is AuthAuthenticated ||
            current is AuthUnauthenticated ||
            current is AuthInitial;
      },
      builder: (context, state) {
        if (state is AuthAuthenticated) {
          return GlobalHubScreen(user: state.user);
        }
        if (state is AuthUnauthenticated) {
          return const LoginScreen();
        }
        // Splash Loading while checking credentials
        return Scaffold(
          backgroundColor: CyberColors.background,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: ShapeDecoration(
                    color: CyberColors.surface,
                    shape: const BeveledRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(14)),
                      side: BorderSide(
                        color: CyberColors.neonCrimson,
                        width: 2,
                      ),
                    ),
                    shadows: [
                      BoxShadow(
                        color: CyberColors.neonCrimson.withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.security,
                    color: CyberColors.neonCrimson,
                    size: 38,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'CYBER NET',
                  style: CyberTypography.headerMedium.copyWith(
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'ИНИЦИАЛИЗАЦИЯ НЕЙРОМОДЕМА...',
                  style: CyberTypography.monoSmall.copyWith(
                    color: CyberColors.cyberCyan,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 24),
                const SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      CyberColors.neonCrimson,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
