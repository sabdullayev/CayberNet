import 'package:flutter/material.dart';
import 'package:mobile/core/di/service_locator.dart';
import 'package:mobile/core/theme/cyber_colors.dart';
import 'package:mobile/core/theme/cyber_typography.dart';
import 'package:mobile/core/widgets/cyber_button.dart';
import 'package:mobile/core/widgets/cyber_card.dart';
import 'package:mobile/core/widgets/cyber_text_field.dart';
import 'package:mobile/features/auth/domain/entities/user_entity.dart';
import 'package:mobile/features/auth/domain/repositories/auth_repository.dart';

class EditProfileModal extends StatefulWidget {
  final UserEntity currentUser;
  final ValueChanged<UserEntity> onProfileUpdated;

  const EditProfileModal({
    super.key,
    required this.currentUser,
    required this.onProfileUpdated,
  });

  static Future<UserEntity?> show(
    BuildContext context, {
    required UserEntity currentUser,
    required ValueChanged<UserEntity> onProfileUpdated,
  }) {
    return showDialog<UserEntity>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (_) => EditProfileModal(
        currentUser: currentUser,
        onProfileUpdated: onProfileUpdated,
      ),
    );
  }

  @override
  State<EditProfileModal> createState() => _EditProfileModalState();
}

class _EditProfileModalState extends State<EditProfileModal> {
  late final TextEditingController _usernameController;
  late final TextEditingController _cyberTagController;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.currentUser.username);
    _cyberTagController = TextEditingController(text: widget.currentUser.cyberTag);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _cyberTagController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final newUsername = _usernameController.text.trim();
    final newTag = _cyberTagController.text.trim().toUpperCase();

    try {
      final authRepo = sl<AuthRepository>();
      final updatedUser = await authRepo.updateProfile(
        username: newUsername != widget.currentUser.username ? newUsername : null,
        cyberTag: newTag != widget.currentUser.cyberTag ? newTag : null,
      );

      widget.onProfileUpdated(updatedUser);
      if (mounted) {
        Navigator.of(context).pop(updatedUser);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Профиль успешно обновлен: ${updatedUser.username} [${updatedUser.cyberTag}]',
              style: CyberTypography.monoSmall.copyWith(color: CyberColors.cyberCyan),
            ),
            backgroundColor: CyberColors.panel,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: CyberCard(
        borderColor: CyberColors.cyberCyan.withValues(alpha: 0.7),
        cutRadius: 14,
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: const ShapeDecoration(
                      color: CyberColors.inputFill,
                      shape: BeveledRectangleBorder(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(6),
                          bottomRight: Radius.circular(6),
                        ),
                        side: BorderSide(color: CyberColors.cyberCyan, width: 1.2),
                      ),
                    ),
                    child: const Icon(
                      Icons.manage_accounts_outlined,
                      size: 16,
                      color: CyberColors.cyberCyan,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'МОДИФИКАЦИЯ ПРОФИЛЯ',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CyberTypography.headerSmall.copyWith(
                        fontSize: 13,
                        color: CyberColors.textPrimary,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.close, color: CyberColors.textMuted, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              Text(
                'Измени позывной или свой уникальный Cyber-Tag. Все изменения мгновенно синхронизируются в Сетке.',
                style: CyberTypography.monoSmall.copyWith(
                  fontSize: 11,
                  color: CyberColors.textMuted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),

              // Username field
              CyberTextField(
                controller: _usernameController,
                labelText: 'КИБЕР-ПОЗЫВНОЙ (USERNAME)',
                hintText: 'cyber_runner',
                prefixIcon: Icons.badge_outlined,
                accentColor: CyberColors.cyberCyan,
                enabled: !_isLoading,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Позывной не может быть пустым';
                  }
                  if (val.trim().length < 3) {
                    return 'Минимум 3 символа';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // CyberTag field
              CyberTextField(
                controller: _cyberTagController,
                labelText: 'СЕТЕВОЙ ТЕГ (CYBER-TAG)',
                hintText: 'CYBER#1024',
                prefixIcon: Icons.fingerprint,
                accentColor: CyberColors.katanaGold,
                enabled: !_isLoading,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Cyber-Tag не может быть пустым';
                  }
                  if (val.trim().length < 3) {
                    return 'Минимум 3 символа';
                  }
                  return null;
                },
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: CyberColors.neonCrimson.withValues(alpha: 0.15),
                    border: Border.all(
                      color: CyberColors.neonCrimson.withValues(alpha: 0.6),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: CyberColors.neonCrimson,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: CyberTypography.monoSmall.copyWith(
                            color: CyberColors.neonCrimson,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Save button
              CyberButton(
                text: 'СОХРАНИТЬ ИЗМЕНЕНИЯ',
                icon: Icons.save_outlined,
                accentColor: CyberColors.cyberCyan,
                isLoading: _isLoading,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
