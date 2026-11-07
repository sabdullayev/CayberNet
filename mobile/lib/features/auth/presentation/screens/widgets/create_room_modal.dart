import 'package:flutter/material.dart';
import '../../../../../core/theme/cyber_colors.dart';
import '../../../../../core/theme/cyber_typography.dart';
import '../../../../../core/widgets/cyber_button.dart';
import '../../../../../core/widgets/cyber_card.dart';
import '../../../../../core/widgets/cyber_text_field.dart';

enum NewRoomType { group, channel }

class CreateRoomModal extends StatefulWidget {
  final Future<void> Function({
    required String name,
    required NewRoomType type,
  }) onCreate;

  const CreateRoomModal({super.key, required this.onCreate});

  static Future<void> show(
    BuildContext context, {
    required Future<void> Function({
      required String name,
      required NewRoomType type,
    }) onCreate,
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => CreateRoomModal(onCreate: onCreate),
    );
  }

  @override
  State<CreateRoomModal> createState() => _CreateRoomModalState();
}

class _CreateRoomModalState extends State<CreateRoomModal> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  NewRoomType _selectedType = NewRoomType.group;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await widget.onCreate(
        name: _nameController.text.trim(),
        type: _selectedType,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceAll('Exception: ', ''),
              style: CyberTypography.monoSmall,
            ),
            backgroundColor: CyberColors.panel,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = _selectedType == NewRoomType.group
        ? CyberColors.cyberCyan
        : CyberColors.katanaGold;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: CyberCard(
        borderColor: activeColor.withValues(alpha: 0.7),
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
                    decoration: ShapeDecoration(
                      color: CyberColors.inputFill,
                      shape: BeveledRectangleBorder(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(6),
                          bottomRight: Radius.circular(6),
                        ),
                        side: BorderSide(color: activeColor, width: 1.2),
                      ),
                    ),
                    child: Icon(
                      _selectedType == NewRoomType.group
                          ? Icons.hub_outlined
                          : Icons.cell_tower,
                      size: 16,
                      color: activeColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'СОЗДАНИЕ КИБЕР-УЗЛА',
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
              const SizedBox(height: 16),

              // Room Type Selector (Beveled Segmented)
              Container(
                height: 44,
                clipBehavior: Clip.antiAlias,
                decoration: const ShapeDecoration(
                  color: CyberColors.inputFill,
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
                      child: _buildTypeButton(
                        type: NewRoomType.group,
                        icon: Icons.groups_outlined,
                        label: 'СИНДИКАТ',
                        color: CyberColors.cyberCyan,
                      ),
                    ),
                    Container(width: 1, height: 24, color: CyberColors.borderSubtle),
                    Expanded(
                      child: _buildTypeButton(
                        type: NewRoomType.channel,
                        icon: Icons.campaign_outlined,
                        label: 'КАНАЛ',
                        color: CyberColors.katanaGold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Description Info
              Text(
                _selectedType == NewRoomType.group
                    ? 'Синдикат — закрытая или открытая группа операторов с общим чатом для совместных операций.'
                    : 'Нейро-Канал — бродкаст-вещание для публикации новостей, отчетов и системных трансляций.',
                style: CyberTypography.bodySmall.copyWith(
                  color: CyberColors.textMuted,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 16),

              // Room Name Input
              CyberTextField(
                controller: _nameController,
                labelText: _selectedType == NewRoomType.group
                    ? 'Название синдиката'
                    : 'Название канала',
                hintText: _selectedType == NewRoomType.group
                    ? 'Cyber Syndicate 01'
                    : 'Netrunner News 2099',
                prefixIcon: _selectedType == NewRoomType.group
                    ? Icons.tag
                    : Icons.campaign,
                accentColor: activeColor,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Введи название';
                  }
                  if (v.trim().length < 2) {
                    return 'Минимум 2 символа';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Create Button
              CyberButton(
                text: _selectedType == NewRoomType.group
                    ? 'СОЗДАТЬ СИНДИКАТ'
                    : 'СОЗДАТЬ НЕЙРО-КАНАЛ',
                accentColor: activeColor,
                icon: Icons.add,
                isLoading: _isLoading,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeButton({
    required NewRoomType type,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    final isSelected = _selectedType == type;

    return InkWell(
      onTap: () => setState(() => _selectedType = type),
      child: Container(
        color: isSelected ? color.withValues(alpha: 0.15) : Colors.transparent,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? color : CyberColors.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: CyberTypography.monoBold.copyWith(
                fontSize: 11,
                color: isSelected ? Colors.white : CyberColors.textMuted,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
