import 'package:flutter/material.dart';
import 'package:mobile/core/theme/cyber_colors.dart';
import 'package:mobile/core/theme/cyber_typography.dart';
import 'package:mobile/core/widgets/cyber_button.dart';
import 'package:mobile/core/widgets/cyber_card.dart';
import 'package:mobile/core/widgets/cyber_text_field.dart';

class SeedRestoreDialog extends StatefulWidget {
  final Function(String seedPhrase, String? newPassword) onRestore;

  const SeedRestoreDialog({super.key, required this.onRestore});

  @override
  State<SeedRestoreDialog> createState() => _SeedRestoreDialogState();
}

class _SeedRestoreDialogState extends State<SeedRestoreDialog> {
  final _phraseController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _phraseController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: CyberCard(
        borderColor: CyberColors.cyberCyan,
        borderWidth: 1.5,
        cutRadius: 16,
        backgroundColor: CyberColors.panel,
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.vpn_key, color: CyberColors.cyberCyan, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    'НЕЙРО-ВОССТАНОВЛЕНИЕ',
                    style: CyberTypography.headerSmall.copyWith(
                      color: CyberColors.cyberCyan,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Введи свои 12 киберпанк-слов через пробел для расшифровки терминала:',
                style: CyberTypography.bodySmall,
              ),
              const SizedBox(height: 16),
              CyberTextField(
                controller: _phraseController,
                hintText: 'matrix neon cipher neural proxy...',
                labelText: '12 Киберпанк Слов',
                maxLines: 3,
                accentColor: CyberColors.cyberCyan,
              ),
              const SizedBox(height: 14),
              CyberTextField(
                controller: _passwordController,
                hintText: 'Новый пароль (опционально)',
                labelText: 'Сброс пароля',
                obscureText: true,
                prefixIcon: Icons.lock_outline,
                accentColor: CyberColors.cyberCyan,
              ),
              const SizedBox(height: 20),
              CyberButton(
                text: 'ВОССТАНОВИТЬ ДОСТУП',
                accentColor: CyberColors.cyberCyan,
                icon: Icons.restore,
                onPressed: () {
                  final phrase = _phraseController.text.trim();
                  if (phrase.isEmpty) return;
                  final newPass = _passwordController.text.trim();
                  Navigator.of(context).pop();
                  widget.onRestore(
                    phrase,
                    newPass.isNotEmpty ? newPass : null,
                  );
                },
              ),
              const SizedBox(height: 10),
              CyberButton(
                text: 'ОТМЕНА',
                isOutlined: true,
                accentColor: CyberColors.textMuted,
                height: 40,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
