import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/theme/cyber_colors.dart';
import 'package:mobile/core/theme/cyber_typography.dart';
import 'package:mobile/core/widgets/cyber_button.dart';
import 'package:mobile/core/widgets/cyber_card.dart';
import 'package:mobile/core/widgets/cyber_text_field.dart';
import 'package:mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:mobile/features/auth/presentation/bloc/auth_state.dart';
import 'seed_restore_dialog.dart';

class CyberIdTab extends StatefulWidget {
  const CyberIdTab({super.key});

  @override
  State<CyberIdTab> createState() => _CyberIdTabState();
}

class _CyberIdTabState extends State<CyberIdTab> {
  bool _isRegisterMode = false;
  final _identController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _identController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _setMode(bool registerMode) {
    if (_isRegisterMode == registerMode) return;
    setState(() {
      _isRegisterMode = registerMode;
      // Sync entered username between modes for convenience
      if (_isRegisterMode && _identController.text.trim().isNotEmpty && _usernameController.text.trim().isEmpty) {
        _usernameController.text = _identController.text.trim();
      } else if (!_isRegisterMode && _usernameController.text.trim().isNotEmpty && _identController.text.trim().isEmpty) {
        _identController.text = _usernameController.text.trim();
      }
      _passwordController.clear();
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final bloc = context.read<AuthBloc>();

    if (_isRegisterMode) {
      final uname = _usernameController.text.trim();
      _identController.text = uname; // Prefill ident for subsequent logins
      bloc.add(AuthCyberIdRegisterSubmitted(
        username: uname,
        password: _passwordController.text.trim(),
      ));
    } else {
      bloc.add(AuthCyberIdLoginSubmitted(
        identifier: _identController.text.trim(),
        password: _passwordController.text.trim(),
      ));
    }
  }

  void _openRestoreDialog() {
    showDialog(
      context: context,
      builder: (ctx) => SeedRestoreDialog(
        onRestore: (seedPhrase, newPass) {
          context.read<AuthBloc>().add(AuthCyberIdRestoreSubmitted(
                seedPhrase: seedPhrase,
                newPassword: newPass,
              ));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final isLoading = state is AuthLoading;
        final Color activeColor = _isRegisterMode ? CyberColors.neonCrimson : CyberColors.cyberCyan;

        return Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Mode Switcher
              Container(
                height: 42,
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
                    side: BorderSide(color: CyberColors.borderSubtle, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildModeButton(
                        title: 'АВТОРИЗАЦИЯ',
                        isSelected: !_isRegisterMode,
                        onTap: () => _setMode(false),
                      ),
                    ),
                    Container(width: 1, height: 20, color: CyberColors.borderSubtle),
                    Expanded(
                      child: _buildModeButton(
                        title: 'РЕГИСТРАЦИЯ',
                        isSelected: _isRegisterMode,
                        onTap: () => _setMode(true),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              CyberCard(
                borderColor: activeColor.withValues(alpha: 0.45),
                cutRadius: 12,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, anim) => FadeTransition(
                        opacity: anim,
                        child: child,
                      ),
                      child: _isRegisterMode
                          ? CyberTextField(
                              key: const ValueKey('reg_user'),
                              controller: _usernameController,
                              labelText: 'Cyber-Позывной',
                              hintText: 'cyber_ghost',
                              prefixIcon: Icons.badge_outlined,
                              accentColor: CyberColors.neonCrimson,
                              textInputAction: TextInputAction.next,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Укажи позывной';
                                if (v.trim().length < 3) return 'Минимум 3 символа';
                                return null;
                              },
                            )
                          : CyberTextField(
                              key: const ValueKey('login_ident'),
                              controller: _identController,
                              labelText: 'Cyber-Tag / Позывной',
                              hintText: 'CYBER#1024 или cyber_runner',
                              prefixIcon: Icons.fingerprint,
                              accentColor: CyberColors.cyberCyan,
                              textInputAction: TextInputAction.next,
                              validator: (v) =>
                                  v == null || v.trim().isEmpty ? 'Укажи идентификатор' : null,
                            ),
                    ),
                    const SizedBox(height: 14),
                    CyberTextField(
                      controller: _passwordController,
                      labelText: 'Пароль доступа',
                      hintText: '••••••••',
                      prefixIcon: Icons.lock_outline,
                      obscureText: true,
                      accentColor: activeColor,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Введи пароль';
                        if (_isRegisterMode && v.length < 6) {
                          return 'Минимум 6 символов';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),
                    CyberButton(
                      text: _isRegisterMode ? 'СОЗДАТЬ CYBER-ID' : 'ВОЙТИ В СЕТЬ',
                      accentColor: activeColor,
                      icon: _isRegisterMode ? Icons.person_add_alt_1 : Icons.login,
                      isLoading: isLoading,
                      onPressed: _submit,
                    ),
                    if (!_isRegisterMode) ...[
                      const SizedBox(height: 12),
                      Center(
                        child: TextButton.icon(
                          onPressed: _openRestoreDialog,
                          icon: const Icon(
                            Icons.vpn_key_outlined,
                            size: 14,
                            color: CyberColors.techYellow,
                          ),
                          label: Text(
                            'Восстановление по 12 сид-словам',
                            style: CyberTypography.monoSmall.copyWith(
                              color: CyberColors.techYellow,
                              fontSize: 10,
                              letterSpacing: 0.8,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModeButton({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final accent = _isRegisterMode ? CyberColors.neonCrimson : CyberColors.cyberCyan;
    return InkWell(
      onTap: onTap,
      child: Container(
        color: isSelected ? CyberColors.surfaceElevated : Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 3),
            Text(
              title,
              style: CyberTypography.monoSmall.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : CyberColors.textMuted,
                fontSize: 11,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 5),
            Container(
              height: 2,
              width: 44,
              decoration: BoxDecoration(
                color: isSelected ? accent : Colors.transparent,
                borderRadius: BorderRadius.circular(1),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.6),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
