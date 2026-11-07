import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/core/theme/cyber_colors.dart';
import 'package:mobile/core/theme/cyber_typography.dart';
import 'package:mobile/core/widgets/cyber_button.dart';
import 'package:mobile/core/widgets/cyber_card.dart';

class SeedPhraseDialog extends StatelessWidget {
  final List<String> seedPhrase;
  final VoidCallback onConfirmed;

  const SeedPhraseDialog({
    super.key,
    required this.seedPhrase,
    required this.onConfirmed,
  });

  @override
  Widget build(BuildContext context) {
    final phraseText = seedPhrase.join(' ');

    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: CyberCard(
          borderColor: CyberColors.katanaGold,
          borderWidth: 1.5,
          cutRadius: 16,
          backgroundColor: CyberColors.panel,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.security,
                    color: CyberColors.katanaGold,
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'CYBER-СИД КЛЮЧИ ДОСТУПА',
                      style: CyberTypography.headerSmall.copyWith(
                        color: CyberColors.katanaGold,
                        fontSize: 14,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: ShapeDecoration(
                  color: CyberColors.katanaGold.withValues(alpha: 0.1),
                  shape: const BeveledRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(6),
                      bottomRight: Radius.circular(6),
                    ),
                    side: BorderSide(
                      color: CyberColors.katanaGold,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: CyberColors.katanaGold,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Сохрани эти 12 слов в надежном хранилище. Это единственный способ восстановить доступ к твоему Cyber-ID!',
                        style: CyberTypography.monoSmall.copyWith(
                          color: CyberColors.katanaGold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // 12 Words Grid
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const ShapeDecoration(
                  color: CyberColors.inputFill,
                  shape: BeveledRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                    side: BorderSide(color: CyberColors.borderSubtle, width: 1),
                  ),
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(seedPhrase.length, (index) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: ShapeDecoration(
                        color: CyberColors.panel,
                        shape: BeveledRectangleBorder(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            bottomRight: Radius.circular(4),
                          ),
                          side: BorderSide(
                            color: CyberColors.cyberCyan.withValues(alpha: 0.5),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${index + 1}. ',
                            style: CyberTypography.monoSmall.copyWith(
                              color: CyberColors.cyberCyan,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            seedPhrase[index],
                            style: CyberTypography.monoRegular.copyWith(
                              color: CyberColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 16),
              CyberButton(
                text: 'Скопировать все 12 слов',
                isOutlined: true,
                accentColor: CyberColors.cyberCyan,
                icon: Icons.copy,
                height: 42,
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: phraseText));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Сид-фраза скопирована в буфер обмена'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              CyberButton(
                text: 'Я СОХРАНИЛ КЛЮЧИ (ВОЙТИ)',
                accentColor: CyberColors.katanaGold,
                icon: Icons.check_circle_outline,
                height: 48,
                onPressed: () {
                  Navigator.of(context).pop();
                  onConfirmed();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
