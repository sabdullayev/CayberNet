import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/theme/cyber_colors.dart';
import 'package:mobile/core/theme/cyber_typography.dart';
import 'package:mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:mobile/features/auth/presentation/bloc/auth_state.dart';
import 'package:mobile/features/auth/presentation/screens/global_hub_screen.dart';
import 'package:mobile/features/auth/presentation/screens/widgets/cyber_id_tab.dart';
import 'package:mobile/features/auth/presentation/screens/widgets/email_tab.dart';
import 'package:mobile/features/auth/presentation/screens/widgets/seed_phrase_dialog.dart';
import 'package:mobile/features/auth/presentation/screens/widgets/telegram_tab.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: CyberColors.panel,
              shape: const BeveledRectangleBorder(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
                side: BorderSide(color: CyberColors.neonCrimson, width: 1.5),
              ),
              content: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: CyberColors.neonCrimson,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      state.message,
                      style: CyberTypography.monoSmall.copyWith(
                        color: CyberColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        } else if (state is AuthCyberIdRegisteredSeedReady) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => SeedPhraseDialog(
              seedPhrase: state.seedPhrase,
              onConfirmed: () {
                context.read<AuthBloc>().add(AuthSeedPhraseDismissed());
              },
            ),
          );
        } else if (state is AuthAuthenticated) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => GlobalHubScreen(user: state.user),
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: CyberColors.voidBackground,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Column(
                    children: [
                      // Minimal Cyber Emblem & Title
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 58,
                              height: 58,
                              decoration: ShapeDecoration(
                                color: CyberColors.panel,
                                shape: const BeveledRectangleBorder(
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(14),
                                    bottomRight: Radius.circular(14),
                                    topRight: Radius.circular(3),
                                    bottomLeft: Radius.circular(3),
                                  ),
                                  side: BorderSide(
                                    color: CyberColors.neonCrimson,
                                    width: 1.5,
                                  ),
                                ),
                                shadows: [
                                  BoxShadow(
                                    color: CyberColors.neonCrimson.withValues(alpha: 0.35),
                                    blurRadius: 18,
                                    spreadRadius: -1,
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.shield_outlined,
                                  size: 30,
                                  color: CyberColors.neonCrimson,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Title
                            Text(
                              'CYBER NET',
                              style: CyberTypography.headerLarge.copyWith(
                                color: CyberColors.textPrimary,
                                letterSpacing: 3.0,
                                fontSize: 20,
                                shadows: [
                                  Shadow(
                                    color: CyberColors.neonCrimson.withValues(alpha: 0.4),
                                    blurRadius: 12,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // 3-Tab Bar with Tactical Chamfered Corners
                      Container(
                        clipBehavior: Clip.antiAlias,
                        decoration: const ShapeDecoration(
                          color: CyberColors.panel,
                          shape: BeveledRectangleBorder(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(8),
                              bottomRight: Radius.circular(8),
                              topRight: Radius.circular(2),
                              bottomLeft: Radius.circular(2),
                            ),
                            side: BorderSide(
                              color: CyberColors.borderSubtle,
                              width: 1,
                            ),
                          ),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          indicatorColor: CyberColors.neonCrimson,
                          indicatorWeight: 2.5,
                          indicatorSize: TabBarIndicatorSize.label,
                          labelPadding: const EdgeInsets.symmetric(horizontal: 6),
                          labelColor: Colors.white,
                          unselectedLabelColor: CyberColors.textMuted,
                          labelStyle: CyberTypography.monoBold.copyWith(
                            fontSize: 11,
                            letterSpacing: 1.2,
                          ),
                          unselectedLabelStyle: CyberTypography.monoRegular.copyWith(
                            fontSize: 11,
                            letterSpacing: 1.0,
                          ),
                          tabs: const [
                            Tab(text: 'CYBER-ID'),
                            Tab(text: 'НЕЙРОЛИНК'),
                            Tab(text: 'EMAIL OTP'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Native swipeable TabBarView for butter-smooth swiping
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    physics: const BouncingScrollPhysics(),
                    children: const [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: SingleChildScrollView(
                          physics: BouncingScrollPhysics(),
                          child: CyberIdTab(),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: SingleChildScrollView(
                          physics: BouncingScrollPhysics(),
                          child: TelegramTab(),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: SingleChildScrollView(
                          physics: BouncingScrollPhysics(),
                          child: EmailTab(),
                        ),
                      ),
                    ],
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
