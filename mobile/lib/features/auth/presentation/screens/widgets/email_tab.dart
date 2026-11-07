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

class EmailTab extends StatefulWidget {
  const EmailTab({super.key});

  @override
  State<EmailTab> createState() => _EmailTabState();
}

class _EmailTabState extends State<EmailTab> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _codeSent = false;
  String? _devCodeHint;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _sendCode() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(
          AuthEmailOtpSendRequested(email: _emailController.text.trim()),
        );
  }

  void _verifyCode() {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введи 6-значный проверочный код')),
      );
      return;
    }
    context.read<AuthBloc>().add(
          AuthEmailOtpVerifySubmitted(
            email: _emailController.text.trim(),
            code: code,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthEmailOtpSent) {
          setState(() {
            _codeSent = true;
            _devCodeHint = state.devCode;
          });
          if (state.devCode != null) {
            _codeController.text = state.devCode!;
          }
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CyberCard(
                borderColor: CyberColors.techYellow.withValues(alpha: 0.45),
                cutRadius: 12,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
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
                              side: BorderSide(color: CyberColors.techYellow, width: 1),
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.mark_email_read_outlined,
                              color: CyberColors.techYellow,
                              size: 22,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'КОРПОРАТИВНАЯ ПОЧТА',
                                style: CyberTypography.headerSmall.copyWith(
                                  color: CyberColors.techYellow,
                                  fontSize: 14,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Вход по одноразовому OTP ключу',
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

                    // Email input
                    CyberTextField(
                      controller: _emailController,
                      labelText: 'Электронный адрес',
                      hintText: 'operator@cybernet.io',
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: Icons.alternate_email,
                      accentColor: CyberColors.techYellow,
                      enabled: !_codeSent || !isLoading,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Укажи email';
                        }
                        if (!v.contains('@') || !v.contains('.')) {
                          return 'Некорректный формат email';
                        }
                        return null;
                      },
                    ),
                    if (!_codeSent) ...[
                      const SizedBox(height: 18),
                      CyberButton(
                        text: 'ОТПРАВИТЬ КЛЮЧ ДОСТУПА',
                        accentColor: CyberColors.techYellow,
                        icon: Icons.send_rounded,
                        isLoading: isLoading,
                        onPressed: _sendCode,
                      ),
                    ] else ...[
                      const SizedBox(height: 14),
                      if (_devCodeHint != null) ...[
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: CyberColors.inputFill,
                            border: Border.all(
                              color: CyberColors.techYellow.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.terminal,
                                color: CyberColors.techYellow,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'DEV OTP: $_devCodeHint',
                                  style: CyberTypography.monoBold.copyWith(
                                    color: CyberColors.techYellow,
                                    fontSize: 12,
                                    letterSpacing: 2.0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                      CyberTextField(
                        controller: _codeController,
                        labelText: '6-значный OTP ключ',
                        hintText: '123456',
                        keyboardType: TextInputType.number,
                        prefixIcon: Icons.security_rounded,
                        accentColor: CyberColors.techYellow,
                        validator: (v) =>
                            v == null || v.length != 6 ? 'Введи 6 цифр' : null,
                      ),
                      const SizedBox(height: 18),
                      CyberButton(
                        text: 'ПОДТВЕРДИТЬ ВХОД',
                        accentColor: CyberColors.techYellow,
                        icon: Icons.verified_user_outlined,
                        isLoading: isLoading,
                        onPressed: _verifyCode,
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              _codeSent = false;
                              _codeController.clear();
                            });
                          },
                          child: Text(
                            '← Использовать другой email',
                            style: CyberTypography.monoSmall.copyWith(
                              color: CyberColors.textMuted,
                              fontSize: 11,
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
}
