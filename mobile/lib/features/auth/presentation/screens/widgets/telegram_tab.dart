import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mobile/core/theme/cyber_colors.dart';
import 'package:mobile/core/theme/cyber_typography.dart';
import 'package:mobile/core/widgets/cyber_button.dart';
import 'package:mobile/core/widgets/cyber_card.dart';
import 'package:mobile/core/widgets/cyber_text_field.dart';
import 'package:mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:mobile/features/auth/presentation/bloc/auth_state.dart';

class TelegramTab extends StatefulWidget {
  const TelegramTab({super.key});

  @override
  State<TelegramTab> createState() => _TelegramTabState();
}

class _TelegramTabState extends State<TelegramTab> {
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(
          AuthTelegramVerifySubmitted(code: _codeController.text.trim()),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CyberCard(
                borderColor: CyberColors.cyberCyan.withValues(alpha: 0.45),
                cutRadius: 12,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Row
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: ShapeDecoration(
                            color: CyberColors.inputFill,
                            shape: const BeveledRectangleBorder(
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(8),
                                bottomRight: Radius.circular(8),
                              ),
                              side: BorderSide(color: CyberColors.cyberCyan, width: 1),
                            ),
                          ),
                          child: const Center(
                            child: FaIcon(
                              FontAwesomeIcons.telegram,
                              color: CyberColors.cyberCyan,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TELEGRAM NEUROMODEM',
                                style: CyberTypography.headerSmall.copyWith(
                                  color: CyberColors.cyberCyan,
                                  fontSize: 14,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Аппаратный мост авторизации',
                                style: CyberTypography.monoSmall.copyWith(
                                  color: CyberColors.textMuted,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Instruction steps in dark tactical container
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: CyberColors.inputFill,
                        border: Border.all(color: CyberColors.borderSubtle),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStep('01', 'Запусти официального бота в Telegram'),
                          const SizedBox(height: 8),
                          _buildStep('02', 'Отправь команду /start или /code'),
                          const SizedBox(height: 8),
                          _buildStep('03', 'Введи сгенерированный 6-значный ключ:'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // OTP input field
                    CyberTextField(
                      controller: _codeController,
                      labelText: 'Одноразовый ключ доступа',
                      hintText: '777888',
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.lock_clock_outlined,
                      accentColor: CyberColors.cyberCyan,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Введи 6-значный код';
                        }
                        if (v.trim().length != 6) {
                          return 'Код должен содержать 6 цифр';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),

                    // Connect button
                    CyberButton(
                      text: 'ПОДКЛЮЧИТЬ НЕЙРОЛИНК',
                      accentColor: CyberColors.cyberCyan,
                      icon: Icons.electrical_services,
                      isLoading: isLoading,
                      onPressed: _submit,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStep(String number, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            color: CyberColors.cyberCyan.withValues(alpha: 0.15),
            border: Border.all(color: CyberColors.cyberCyan.withValues(alpha: 0.6)),
          ),
          child: Text(
            number,
            style: CyberTypography.monoSmall.copyWith(
              color: CyberColors.cyberCyan,
              fontWeight: FontWeight.bold,
              fontSize: 9,
              letterSpacing: 1.0,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: CyberTypography.monoSmall.copyWith(
              color: CyberColors.textPrimary,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }
}
