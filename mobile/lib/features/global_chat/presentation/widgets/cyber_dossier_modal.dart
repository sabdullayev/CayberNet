import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/cyber_colors.dart';
import '../../../../core/theme/cyber_typography.dart';
import '../../../../core/widgets/cyber_badge.dart';
import '../../../../core/widgets/cyber_button.dart';
import '../../../../core/widgets/cyber_card.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../domain/repositories/chat_repository.dart';
import '../bloc/chat_bloc.dart';
import '../screens/global_chat_screen.dart';

class CyberDossierModal extends StatefulWidget {
  final UserEntity user;
  final String currentUserId;
  final String token;

  const CyberDossierModal({
    super.key,
    required this.user,
    required this.currentUserId,
    required this.token,
  });

  static Future<void> show(
    BuildContext context, {
    required UserEntity user,
    required String currentUserId,
    required String token,
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (_) => CyberDossierModal(
        user: user,
        currentUserId: currentUserId,
        token: token,
      ),
    );
  }

  @override
  State<CyberDossierModal> createState() => _CyberDossierModalState();
}

class _CyberDossierModalState extends State<CyberDossierModal> {
  late int _honorPoints;
  bool _isGivingHonor = false;
  bool _isOpeningDirect = false;

  @override
  void initState() {
    super.initState();
    _honorPoints = widget.user.honorPoints;
  }

  String get _currentRank {
    if (_honorPoints < 10) return "Скиталец Сетки";
    if (_honorPoints < 50) return "Нетраннер";
    if (_honorPoints < 100) return "Кибер-Агент";
    return "Архитектор Сетки";
  }

  Color get _rankColor {
    if (_honorPoints >= 100) return CyberColors.katanaGold;
    if (_honorPoints >= 50) return CyberColors.cyberCyan;
    if (_honorPoints >= 10) return CyberColors.neonCrimson;
    return CyberColors.textMuted;
  }

  bool get _isSelf => widget.user.id == widget.currentUserId;

  Future<void> _giveHonor() async {
    if (_isGivingHonor || _isSelf) return;
    setState(() => _isGivingHonor = true);

    try {
      final chatRepo = sl<ChatRepository>();
      final newPoints = await chatRepo.giveHonor(widget.user.id);
      // Also notify room via WS
      chatRepo.sendGiveHonor(widget.user.id);

      if (!mounted) return;
      setState(() => _honorPoints = newPoints);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '🔥 Репутация пользователю ${widget.user.username} повышена (+1 Rep)!',
            style: CyberTypography.monoSmall.copyWith(color: CyberColors.katanaGold),
          ),
          backgroundColor: CyberColors.surface,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceAll('Exception: ', ''),
            style: CyberTypography.monoSmall.copyWith(color: CyberColors.neonCrimson),
          ),
          backgroundColor: CyberColors.surface,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isGivingHonor = false);
    }
  }

  Future<void> _openDirectChat() async {
    if (_isOpeningDirect || _isSelf) return;
    setState(() => _isOpeningDirect = true);

    try {
      final chatRepo = sl<ChatRepository>();
      final room = await chatRepo.getOrCreateDirectRoom(widget.user.id);

      if (!mounted) return;
      Navigator.of(context).pop(); // Close dossier modal

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => sl<ChatBloc>(),
            child: ChatScreen(
              roomId: room.id,
              token: widget.token,
              currentUserId: widget.currentUserId,
              roomTitle: 'КАНАЛ: ${widget.user.username}',
              isDirect: true,
              interlocutor: widget.user,
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceAll('Exception: ', ''),
            style: CyberTypography.monoSmall.copyWith(color: CyberColors.neonCrimson),
          ),
          backgroundColor: CyberColors.surface,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isOpeningDirect = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: CyberCard(
        borderColor: _rankColor.withValues(alpha: 0.8),
        cutRadius: 14,
        padding: const EdgeInsets.all(18.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.shield_outlined, color: _rankColor, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'CYBER-ДОСЬЕ // СЕТЬ',
                      style: CyberTypography.headerSmall.copyWith(
                        color: _rankColor,
                        fontSize: 13,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: CyberColors.textMuted, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Avatar Container
            Container(
              width: 76,
              height: 76,
              decoration: ShapeDecoration(
                color: CyberColors.inputFill,
                shape: BeveledRectangleBorder(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                    topRight: Radius.circular(4),
                    bottomLeft: Radius.circular(4),
                  ),
                  side: BorderSide(color: _rankColor, width: 2),
                ),
                shadows: [
                  BoxShadow(
                    color: _rankColor.withValues(alpha: 0.35),
                    blurRadius: 16,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  Icons.person,
                  size: 42,
                  color: _rankColor,
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Username
            Text(
              widget.user.username,
              style: CyberTypography.headerMedium.copyWith(
                color: CyberColors.textPrimary,
                fontSize: 18,
                letterSpacing: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),

            // Cyber-Tag Badge & Rank
            Wrap(
              spacing: 8,
              runSpacing: 4,
              alignment: WrapAlignment.center,
              children: [
                CyberBadge(
                  label: widget.user.cyberTag,
                  color: CyberColors.cyberCyan,
                  cutRadius: 3,
                ),
                CyberBadge(
                  label: _currentRank,
                  color: _rankColor,
                  cutRadius: 3,
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Honor Points Counter
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: const ShapeDecoration(
                color: CyberColors.inputFill,
                shape: BeveledRectangleBorder(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(6),
                    bottomRight: Radius.circular(6),
                  ),
                  side: BorderSide(color: CyberColors.borderSubtle, width: 1),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.flash_on, color: CyberColors.katanaGold, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'РЕПУТАЦИЯ: $_honorPoints REP',
                    style: CyberTypography.monoBold.copyWith(
                      color: CyberColors.katanaGold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Action Buttons
            if (!_isSelf) ...[
              CyberButton(
                text: 'ОТКРЫТЬ ПРИВАТНЫЙ КАНАЛ (ЛС)',
                icon: Icons.cell_tower,
                accentColor: CyberColors.cyberCyan,
                isLoading: _isOpeningDirect,
                onPressed: _openDirectChat,
              ),
              const SizedBox(height: 10),
              CyberButton(
                text: 'ПОВЫСИТЬ РЕПУТАЦИЮ (+1 REP)',
                icon: Icons.flash_on,
                accentColor: CyberColors.katanaGold,
                isLoading: _isGivingHonor,
                onPressed: _giveHonor,
              ),
            ] else ...[
              Text(
                '[ ТВОЙ НЕЙРОПРОФИЛЬ В СЕТИ ]',
                style: CyberTypography.monoSmall.copyWith(
                  color: CyberColors.textMuted,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
