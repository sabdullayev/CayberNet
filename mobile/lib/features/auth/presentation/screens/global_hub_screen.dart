import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/storage/auth_storage.dart';
import '../../../../core/theme/cyber_colors.dart';
import '../../../../core/theme/cyber_typography.dart';
import '../../../../core/widgets/cyber_badge.dart';
import '../../../../core/widgets/cyber_button.dart';
import '../../../../core/widgets/cyber_card.dart';
import '../../../../core/widgets/cyber_text_field.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../global_chat/domain/entities/room_entity.dart';
import '../../../global_chat/domain/repositories/chat_repository.dart';
import '../../../global_chat/presentation/bloc/chat_bloc.dart';
import '../../../global_chat/presentation/screens/global_chat_screen.dart';
import '../../../global_chat/presentation/widgets/cyber_dossier_modal.dart';
import 'widgets/create_room_modal.dart';
import 'widgets/edit_profile_modal.dart';

enum ChatCategory { all, direct, group, channel }

class GlobalHubScreen extends StatefulWidget {
  final UserEntity user;

  const GlobalHubScreen({super.key, required this.user});

  @override
  State<GlobalHubScreen> createState() => _GlobalHubScreenState();
}

class _GlobalHubScreenState extends State<GlobalHubScreen> {
  late UserEntity _currentUser;
  List<RoomEntity> _rooms = [];
  bool _isLoadingRooms = true;
  bool _isEnteringChat = false;
  ChatCategory _selectedCategory = ChatCategory.all;

  // Search
  final _searchController = TextEditingController();
  Timer? _searchDebounce;
  String _searchQuery = '';
  List<UserEntity> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
    _loadRooms();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _loadRooms() async {
    setState(() => _isLoadingRooms = true);
    try {
      final chatRepo = sl<ChatRepository>();
      final rooms = await chatRepo.getMyRooms();
      if (!mounted) return;
      setState(() {
        _rooms = rooms;
        _isLoadingRooms = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingRooms = false);
    }
  }

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    final trimmed = query.trim();
    setState(() => _searchQuery = trimmed);

    if (trimmed.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    _searchDebounce = Timer(const Duration(milliseconds: 350), () async {
      setState(() => _isSearching = true);
      try {
        final chatRepo = sl<ChatRepository>();
        final results = await chatRepo.searchUsers(trimmed);
        if (!mounted) return;
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      } catch (_) {
        if (mounted) setState(() => _isSearching = false);
      }
    });
  }

  Future<void> _enterGlobalChat() async {
    if (_isEnteringChat) return;
    setState(() => _isEnteringChat = true);

    try {
      final token = sl<AuthStorage>().getAccessToken();
      if (token == null || token.isEmpty) {
        throw Exception('Сессионный ключ отсутствует. Выполни повторный вход.');
      }

      final chatRepo = sl<ChatRepository>();
      final room = await chatRepo.getGlobalRoom();

      if (!mounted) return;

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => sl<ChatBloc>(),
            child: ChatScreen(
              roomId: room.id,
              token: token,
              currentUserId: _currentUser.id,
              roomTitle: 'НЕО-ТОКИО СЕКТОР 01',
              isDirect: false,
            ),
          ),
        ),
      );

      // Refresh rooms when returning from chat
      _loadRooms();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceAll('Exception: ', ''),
            style: CyberTypography.monoSmall,
          ),
          backgroundColor: CyberColors.panel,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isEnteringChat = false);
      }
    }
  }

  Future<void> _openRoom(RoomEntity room) async {
    final token = sl<AuthStorage>().getAccessToken();
    if (token == null || token.isEmpty) return;

    String roomTitle;
    if (room.isGlobal) {
      roomTitle = 'НЕО-ТОКИО СЕКТОР 01';
    } else if (room.isDirect) {
      roomTitle = room.interlocutor != null
          ? 'КАНАЛ: ${room.interlocutor!.username}'
          : room.name;
    } else if (room.isGroup) {
      roomTitle = 'СИНДИКАТ: ${room.name}';
    } else {
      roomTitle = 'КАНАЛ: ${room.name}';
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => sl<ChatBloc>(),
          child: ChatScreen(
            roomId: room.id,
            token: token,
            currentUserId: _currentUser.id,
            roomTitle: roomTitle,
            isDirect: room.isDirect,
            interlocutor: room.interlocutor,
          ),
        ),
      ),
    );

    _loadRooms();
  }

  void _openCreateRoomModal() {
    CreateRoomModal.show(
      context,
      onCreate: ({required String name, required NewRoomType type}) async {
        final chatRepo = sl<ChatRepository>();
        RoomEntity newRoom;
        if (type == NewRoomType.group) {
          newRoom = await chatRepo.createGroup(name);
        } else {
          newRoom = await chatRepo.createChannel(name);
        }
        await _loadRooms();
        if (mounted) {
          _openRoom(newRoom);
        }
      },
    );
  }

  void _openEditProfileModal() {
    EditProfileModal.show(
      context,
      currentUser: _currentUser,
      onProfileUpdated: (updatedUser) {
        setState(() => _currentUser = updatedUser);
      },
    );
  }

  void _openDossier(UserEntity user) {
    final token = sl<AuthStorage>().getAccessToken() ?? '';
    CyberDossierModal.show(
      context,
      user: user,
      currentUserId: _currentUser.id,
      token: token,
    ).then((_) {
      _loadRooms();
    });
  }

  Color get _rankColor {
    if (_currentUser.isDaimyo) return CyberColors.katanaGold;
    if (_currentUser.honorPoints >= 50) return CyberColors.cyberCyan;
    if (_currentUser.honorPoints >= 10) return CyberColors.neonCrimson;
    return CyberColors.textMuted;
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final nonGlobalRooms = _rooms.where((r) => !r.isGlobal).toList();
    final directRooms = nonGlobalRooms.where((r) => r.isDirect).toList();
    final groupRooms = nonGlobalRooms.where((r) => r.isGroup).toList();
    final channelRooms = nonGlobalRooms.where((r) => r.isChannel).toList();
    final globalRoom = _rooms.where((r) => r.isGlobal).firstOrNull;

    List<RoomEntity> currentCategoryRooms;
    switch (_selectedCategory) {
      case ChatCategory.all:
        currentCategoryRooms = nonGlobalRooms;
        break;
      case ChatCategory.direct:
        currentCategoryRooms = directRooms;
        break;
      case ChatCategory.group:
        currentCategoryRooms = groupRooms;
        break;
      case ChatCategory.channel:
        currentCategoryRooms = channelRooms;
        break;
    }

    return Scaffold(
      backgroundColor: CyberColors.voidBackground,
      appBar: AppBar(
        backgroundColor: CyberColors.voidBackground,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: const ShapeDecoration(
                color: CyberColors.panel,
                shape: BeveledRectangleBorder(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(6),
                    bottomRight: Radius.circular(6),
                  ),
                  side: BorderSide(color: CyberColors.neonCrimson, width: 1.2),
                ),
              ),
              child: const Icon(
                Icons.shield_outlined,
                size: 16,
                color: CyberColors.neonCrimson,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'CYBER NET',
              style: CyberTypography.headerSmall.copyWith(
                color: CyberColors.textPrimary,
                letterSpacing: 2.0,
                fontSize: 16,
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: 34,
            height: 34,
            child: IconButton(
              padding: EdgeInsets.zero,
              tooltip: 'Создать группу или канал',
              icon: const Icon(Icons.add_circle_outline, color: CyberColors.cyberCyan, size: 20),
              onPressed: _openCreateRoomModal,
            ),
          ),
          const SizedBox(width: 2),
          SizedBox(
            width: 34,
            height: 34,
            child: IconButton(
              padding: EdgeInsets.zero,
              tooltip: 'Обновить данные',
              icon: const Icon(Icons.refresh, color: CyberColors.cyberCyan, size: 19),
              onPressed: _loadRooms,
            ),
          ),
          const SizedBox(width: 2),
          SizedBox(
            width: 34,
            height: 34,
            child: IconButton(
              padding: EdgeInsets.zero,
              tooltip: 'Выйти из терминала',
              icon: const Icon(Icons.power_settings_new, color: CyberColors.neonCrimson, size: 19),
              onPressed: () => _confirmLogout(context),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: CyberColors.cyberCyan,
          backgroundColor: CyberColors.panel,
          onRefresh: _loadRooms,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Profile Tactical Card (Tappable to Edit Profile)
                InkWell(
                  onTap: _openEditProfileModal,
                  child: CyberCard(
                    borderColor: _rankColor.withValues(alpha: 0.6),
                    cutRadius: 14,
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Chamfered Avatar with glowing border
                            Container(
                              width: 64,
                              height: 64,
                              decoration: ShapeDecoration(
                                color: CyberColors.inputFill,
                                shape: BeveledRectangleBorder(
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(10),
                                    bottomRight: Radius.circular(10),
                                    topRight: Radius.circular(2),
                                    bottomLeft: Radius.circular(2),
                                  ),
                                  side: BorderSide(color: _rankColor, width: 1.8),
                                ),
                                shadows: [
                                  BoxShadow(
                                    color: _rankColor.withValues(alpha: 0.25),
                                    blurRadius: 12,
                                    spreadRadius: -1,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.person,
                                  color: _rankColor,
                                  size: 36,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),

                            // Identity Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: [
                                      CyberBadge(
                                        label: _currentUser.cyberTag,
                                        color: CyberColors.cyberCyan,
                                        cutRadius: 3,
                                      ),
                                      CyberBadge(
                                        label: _currentUser.rank,
                                        color: _rankColor,
                                        cutRadius: 3,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _currentUser.username,
                                    style: CyberTypography.headerMedium.copyWith(
                                      color: CyberColors.textPrimary,
                                      fontSize: 18,
                                      letterSpacing: 1.2,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.flash_on, color: CyberColors.katanaGold, size: 15),
                                      const SizedBox(width: 4),
                                      Text(
                                        'РЕПУТАЦИЯ: ${_currentUser.honorPoints} REP',
                                        style: CyberTypography.monoBold.copyWith(
                                          color: CyberColors.katanaGold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.edit_outlined,
                              color: CyberColors.textMuted,
                              size: 18,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(height: 1, color: CyberColors.borderSubtle),
                        const SizedBox(height: 8),

                        // Session Status & Edit Footer
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: CyberColors.matrixGreen,
                                    boxShadow: [
                                      BoxShadow(
                                        color: CyberColors.matrixGreen,
                                        blurRadius: 6,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'СЕТЬ: ОНЛАЙН',
                                  style: CyberTypography.monoBold.copyWith(
                                    color: CyberColors.matrixGreen,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'НАСТРОЙКА ▶',
                              style: CyberTypography.monoSmall.copyWith(
                                color: CyberColors.cyberCyan,
                                fontSize: 9,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // 2. Search Bar with Tactical 3px Accent Bar
                CyberTextField(
                  controller: _searchController,
                  labelText: 'ПОИСК В СЕТИ',
                  hintText: 'Введи Cyber-Tag или username...',
                  prefixIcon: Icons.search,
                  accentColor: CyberColors.cyberCyan,
                  onChanged: _onSearchChanged,
                ),
                const SizedBox(height: 14),

                // 3. Search Results Overlay (if searching)
                if (_searchQuery.isNotEmpty) ...[
                  Row(
                    children: [
                      const Icon(Icons.radar, color: CyberColors.cyberCyan, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'РЕЗУЛЬТАТЫ СКАНИРОВАНИЯ СЕТИ',
                        style: CyberTypography.monoSmall.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: CyberColors.cyberCyan,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (_isSearching)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(color: CyberColors.cyberCyan),
                      ),
                    )
                  else if (_searchResults.isEmpty)
                    CyberCard(
                      borderColor: CyberColors.borderSubtle,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Center(
                          child: Text(
                            'ПОЛЬЗОВАТЕЛИ НЕ НАЙДЕНЫ',
                            style: CyberTypography.monoSmall.copyWith(
                              color: CyberColors.textMuted,
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    ..._searchResults.map(
                      (u) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: InkWell(
                          onTap: () => _openDossier(u),
                          child: CyberCard(
                            borderColor: CyberColors.cyberCyan.withValues(alpha: 0.45),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            child: Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: const ShapeDecoration(
                                    color: CyberColors.inputFill,
                                    shape: BeveledRectangleBorder(
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(6),
                                        bottomRight: Radius.circular(6),
                                      ),
                                      side: BorderSide(color: CyberColors.cyberCyan),
                                    ),
                                  ),
                                  child: const Icon(Icons.person, color: CyberColors.cyberCyan, size: 20),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 4,
                                        children: [
                                          CyberBadge(
                                            label: u.cyberTag,
                                            color: CyberColors.cyberCyan,
                                            cutRadius: 3,
                                          ),
                                          CyberBadge(
                                            label: u.rank,
                                            color: u.isDaimyo ? CyberColors.katanaGold : CyberColors.neonCrimson,
                                            cutRadius: 3,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        u.username,
                                        style: CyberTypography.headerSmall.copyWith(
                                          color: CyberColors.textPrimary,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '⚡${u.honorPoints}',
                                  style: CyberTypography.monoSmall.copyWith(
                                    color: CyberColors.katanaGold,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.chevron_right, color: CyberColors.textMuted, size: 18),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 14),
                ],

                // 4. Pinned Global Hub Card (Tappable to Enter)
                Row(
                  children: [
                    const Icon(Icons.hub, color: CyberColors.cyberCyan, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'ГЛАВНЫЙ НЕЙРОУЗЕЛ',
                      style: CyberTypography.monoSmall.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: CyberColors.cyberCyan,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _isEnteringChat ? null : _enterGlobalChat,
                  child: CyberCard(
                    borderColor: CyberColors.cyberCyan.withValues(alpha: 0.5),
                    cutRadius: 14,
                    padding: const EdgeInsets.all(14.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: const ShapeDecoration(
                                color: CyberColors.inputFill,
                                shape: BeveledRectangleBorder(
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(6),
                                    bottomRight: Radius.circular(6),
                                  ),
                                  side: BorderSide(color: CyberColors.cyberCyan, width: 1),
                                ),
                              ),
                              child: const Icon(Icons.cell_tower, color: CyberColors.cyberCyan, size: 20),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'НЕО-ТОКИО СЕКТОР 01',
                                    style: CyberTypography.headerMedium.copyWith(
                                      fontSize: 15,
                                      color: CyberColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'ОФИЦИАЛЬНЫЙ НЕЙРО-ХАБ',
                                    style: CyberTypography.monoSmall.copyWith(
                                      fontSize: 9,
                                      color: CyberColors.cyberCyan,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_isEnteringChat)
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: CyberColors.cyberCyan,
                                ),
                              )
                            else
                              const Row(
                                children: [
                                  CyberBadge(
                                    label: 'GLOBAL',
                                    color: CyberColors.matrixGreen,
                                    cutRadius: 3,
                                  ),
                                  SizedBox(width: 4),
                                  Icon(Icons.chevron_right, color: CyberColors.cyberCyan, size: 20),
                                ],
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (globalRoom?.lastMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                            decoration: BoxDecoration(
                              color: CyberColors.inputFill,
                              border: const Border(
                                left: BorderSide(color: CyberColors.cyberCyan, width: 2.5),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    globalRoom!.lastMessage!.isDeleted
                                        ? '⚡ [СООБЩЕНИЕ УНИЧТОЖЕНО]'
                                        : '${globalRoom.lastMessage!.senderUsername ?? 'Агент'}: ${globalRoom.lastMessage!.content}',
                                    style: CyberTypography.bodySmall.copyWith(
                                      color: globalRoom.lastMessage!.isDeleted
                                          ? CyberColors.neonCrimson
                                          : CyberColors.textMuted,
                                      fontSize: 11,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _formatTime(globalRoom.lastMessage!.createdAt),
                                  style: CyberTypography.monoSmall.copyWith(
                                    color: CyberColors.textMuted,
                                    fontSize: 9,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          Text(
                            'Главный узел синхронизации CyberNet. Тапни для входа в реалтайм-сектор.',
                            style: CyberTypography.bodySmall.copyWith(
                              color: CyberColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 5. Telegram-style Chats Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.forum_outlined, color: CyberColors.cyberCyan, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'КИБЕР-УЗЛЫ И ДИАЛОГИ',
                          style: CyberTypography.monoSmall.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: CyberColors.cyberCyan,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${nonGlobalRooms.length}',
                      style: CyberTypography.monoBold.copyWith(
                        color: CyberColors.cyberCyan,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Category Filter Bar (Telegram Style - Symmetrical HUD tabs)
                Row(
                  children: [
                    Expanded(
                      child: _buildCategoryChip(
                        category: ChatCategory.all,
                        label: 'ВСЕ',
                        count: nonGlobalRooms.length,
                        accentColor: CyberColors.cyberCyan,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: _buildCategoryChip(
                        category: ChatCategory.direct,
                        label: 'ЛИЧНЫЕ',
                        count: directRooms.length,
                        accentColor: CyberColors.neonCrimson,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: _buildCategoryChip(
                        category: ChatCategory.group,
                        label: 'ГРУППЫ',
                        count: groupRooms.length,
                        accentColor: CyberColors.cyberCyan,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: _buildCategoryChip(
                        category: ChatCategory.channel,
                        label: 'КАНАЛЫ',
                        count: channelRooms.length,
                        accentColor: CyberColors.katanaGold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (_isLoadingRooms)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(color: CyberColors.cyberCyan),
                    ),
                  )
                else if (currentCategoryRooms.isEmpty)
                  CyberCard(
                    borderColor: CyberColors.borderSubtle,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            _selectedCategory == ChatCategory.group
                                ? Icons.groups_outlined
                                : (_selectedCategory == ChatCategory.channel
                                    ? Icons.campaign_outlined
                                    : Icons.forum_outlined),
                            color: CyberColors.textMuted,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _getEmptyTitle(),
                            style: CyberTypography.monoSmall.copyWith(
                              color: CyberColors.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getEmptySubtitle(),
                            style: CyberTypography.bodySmall.copyWith(
                              color: CyberColors.textMuted.withValues(alpha: 0.7),
                              fontSize: 10,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (_selectedCategory == ChatCategory.group ||
                              _selectedCategory == ChatCategory.channel) ...[
                            const SizedBox(height: 12),
                            CyberButton(
                              text: _selectedCategory == ChatCategory.group
                                  ? 'СОЗДАТЬ СИНДИКАТ'
                                  : 'СОЗДАТЬ НЕЙРО-КАНАЛ',
                              accentColor: _selectedCategory == ChatCategory.group
                                  ? CyberColors.cyberCyan
                                  : CyberColors.katanaGold,
                              icon: Icons.add,
                              onPressed: _openCreateRoomModal,
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                else
                  ...currentCategoryRooms.map((room) => _buildRoomTile(room)),

                const SizedBox(height: 24),

                // 6. Logout Button
                CyberButton(
                  text: 'РАЗОРВАТЬ НЕЙРОСВЯЗЬ (ВЫЙТИ)',
                  accentColor: CyberColors.neonCrimson,
                  icon: Icons.power_settings_new,
                  isOutlined: true,
                  onPressed: () => _confirmLogout(context),
                ),
                const SizedBox(height: 70), // Safe scroll clearance for FAB
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreateRoomModal,
        backgroundColor: CyberColors.panel,
        elevation: 6,
        shape: const BeveledRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(10),
            bottomRight: Radius.circular(10),
            topRight: Radius.circular(2),
            bottomLeft: Radius.circular(2),
          ),
          side: BorderSide(color: CyberColors.cyberCyan, width: 1.5),
        ),
        child: const Icon(Icons.add, color: CyberColors.cyberCyan, size: 26),
      ),
    );
  }

  String _getEmptyTitle() {
    switch (_selectedCategory) {
      case ChatCategory.all:
        return 'НЕТ АКТИВНЫХ ДИАЛОГОВ';
      case ChatCategory.direct:
        return 'НЕТ ЛИЧНЫХ ЧАТОВ';
      case ChatCategory.group:
        return 'НЕТ КИБЕР-СИНДИКАТОВ';
      case ChatCategory.channel:
        return 'НЕТ НЕЙРО-КАНАЛОВ';
    }
  }

  String _getEmptySubtitle() {
    switch (_selectedCategory) {
      case ChatCategory.all:
        return 'Найди пользователя в поиске выше или создай группу/канал.';
      case ChatCategory.direct:
        return 'Найди пользователя через поиск выше и открой канал.';
      case ChatCategory.group:
        return 'Создай группу операторов для совместных операций.';
      case ChatCategory.channel:
        return 'Создай свой бродкаст-канал для вещания.';
    }
  }

  Widget _buildCategoryChip({
    required ChatCategory category,
    required String label,
    required int count,
    required Color accentColor,
  }) {
    final isSelected = _selectedCategory == category;

    return InkWell(
      onTap: () => setState(() => _selectedCategory = category),
      borderRadius: BorderRadius.circular(4),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: ShapeDecoration(
          color: isSelected ? accentColor.withValues(alpha: 0.18) : CyberColors.panel,
          shape: BeveledRectangleBorder(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              bottomRight: Radius.circular(6),
              topRight: Radius.circular(2),
              bottomLeft: Radius.circular(2),
            ),
            side: BorderSide(
              color: isSelected ? accentColor : CyberColors.borderSubtle.withValues(alpha: 0.6),
              width: 1.0,
            ),
          ),
          shadows: isSelected
              ? [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.22),
                    blurRadius: 8,
                    spreadRadius: -1,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: CyberTypography.monoBold.copyWith(
                  fontSize: 10,
                  color: isSelected ? Colors.white : CyberColors.textMuted,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: ShapeDecoration(
                  color: isSelected ? accentColor : CyberColors.surfaceElevated,
                  shape: const BeveledRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(3),
                      bottomRight: Radius.circular(3),
                    ),
                  ),
                ),
                child: Text(
                  '$count',
                  style: CyberTypography.monoBold.copyWith(
                    fontSize: 8.5,
                    color: isSelected ? Colors.black : CyberColors.textPrimary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRoomTile(RoomEntity room) {
    if (room.isDirect) {
      return _buildDirectRoomTile(room);
    } else if (room.isGroup) {
      return _buildGroupRoomTile(room);
    } else {
      return _buildChannelRoomTile(room);
    }
  }

  Widget _buildDirectRoomTile(RoomEntity room) {
    final interlocutor = room.interlocutor;
    final lastMsg = room.lastMessage;
    final rankColor = interlocutor != null && interlocutor.isDaimyo
        ? CyberColors.katanaGold
        : (interlocutor != null && interlocutor.honorPoints >= 50
            ? CyberColors.cyberCyan
            : CyberColors.neonCrimson);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: InkWell(
        onTap: () => _openRoom(room),
        child: CyberCard(
          borderColor: CyberColors.borderSubtle,
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  if (interlocutor != null) _openDossier(interlocutor);
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: ShapeDecoration(
                    color: CyberColors.inputFill,
                    shape: BeveledRectangleBorder(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      ),
                      side: BorderSide(color: rankColor),
                    ),
                  ),
                  child: Center(
                    child: Icon(Icons.person, color: rankColor, size: 24),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            interlocutor?.username ?? room.name,
                            style: CyberTypography.headerSmall.copyWith(
                              fontSize: 14,
                              color: CyberColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (interlocutor != null) ...[
                          const SizedBox(width: 6),
                          CyberBadge(
                            label: interlocutor.rank,
                            color: rankColor,
                            cutRadius: 3,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        if (interlocutor != null) ...[
                          CyberBadge(
                            label: interlocutor.cyberTag,
                            color: CyberColors.cyberCyan,
                            cutRadius: 2,
                          ),
                          const SizedBox(width: 6),
                        ],
                        Expanded(
                          child: Text(
                            lastMsg == null
                                ? 'Канал открыт. Нет сообщений.'
                                : (lastMsg.isDeleted
                                    ? '⚡ [СООБЩЕНИЕ УНИЧТОЖЕНО]'
                                    : lastMsg.content),
                            style: CyberTypography.bodySmall.copyWith(
                              color: lastMsg != null && lastMsg.isDeleted
                                  ? CyberColors.neonCrimson
                                  : CyberColors.textMuted,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatTime(lastMsg?.createdAt ?? room.createdAt),
                    style: CyberTypography.monoSmall.copyWith(
                      color: CyberColors.textMuted,
                      fontSize: 9,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Icon(Icons.chevron_right, color: CyberColors.textMuted, size: 16),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroupRoomTile(RoomEntity room) {
    final lastMsg = room.lastMessage;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: InkWell(
        onTap: () => _openRoom(room),
        child: CyberCard(
          borderColor: CyberColors.cyberCyan.withValues(alpha: 0.4),
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const ShapeDecoration(
                  color: CyberColors.inputFill,
                  shape: BeveledRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                    side: BorderSide(color: CyberColors.cyberCyan, width: 1.2),
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.hub_outlined, color: CyberColors.cyberCyan, size: 22),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            room.name,
                            style: CyberTypography.headerSmall.copyWith(
                              fontSize: 14,
                              color: CyberColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const CyberBadge(
                          label: 'СИНДИКАТ',
                          color: CyberColors.cyberCyan,
                          cutRadius: 3,
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      lastMsg == null
                          ? 'Синдикат создан. Нет сообщений.'
                          : (lastMsg.isDeleted
                              ? '⚡ [СООБЩЕНИЕ УНИЧТОЖЕНО]'
                              : '${lastMsg.senderUsername ?? 'Оператор'}: ${lastMsg.content}'),
                      style: CyberTypography.bodySmall.copyWith(
                        color: lastMsg != null && lastMsg.isDeleted
                            ? CyberColors.neonCrimson
                            : CyberColors.textMuted,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatTime(lastMsg?.createdAt ?? room.createdAt),
                    style: CyberTypography.monoSmall.copyWith(
                      color: CyberColors.textMuted,
                      fontSize: 9,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Icon(Icons.chevron_right, color: CyberColors.textMuted, size: 16),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChannelRoomTile(RoomEntity room) {
    final lastMsg = room.lastMessage;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: InkWell(
        onTap: () => _openRoom(room),
        child: CyberCard(
          borderColor: CyberColors.katanaGold.withValues(alpha: 0.4),
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const ShapeDecoration(
                  color: CyberColors.inputFill,
                  shape: BeveledRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                    side: BorderSide(color: CyberColors.katanaGold, width: 1.2),
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.cell_tower, color: CyberColors.katanaGold, size: 22),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            room.name,
                            style: CyberTypography.headerSmall.copyWith(
                              fontSize: 14,
                              color: CyberColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const CyberBadge(
                          label: 'КАНАЛ',
                          color: CyberColors.katanaGold,
                          cutRadius: 3,
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      lastMsg == null
                          ? 'Нейро-канал открыт. Ожидание трансляций.'
                          : (lastMsg.isDeleted
                              ? '⚡ [СООБЩЕНИЕ УНИЧТОЖЕНО]'
                              : lastMsg.content),
                      style: CyberTypography.bodySmall.copyWith(
                        color: lastMsg != null && lastMsg.isDeleted
                            ? CyberColors.neonCrimson
                            : CyberColors.textMuted,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatTime(lastMsg?.createdAt ?? room.createdAt),
                    style: CyberTypography.monoSmall.copyWith(
                      color: CyberColors.textMuted,
                      fontSize: 9,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Icon(Icons.chevron_right, color: CyberColors.textMuted, size: 16),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CyberColors.panel,
        shape: const BeveledRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12),
            bottomRight: Radius.circular(12),
          ),
          side: BorderSide(color: CyberColors.neonCrimson, width: 1.5),
        ),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: CyberColors.neonCrimson, size: 22),
            const SizedBox(width: 8),
            Text(
              'РАЗРЫВ НЕЙРОСВЯЗИ',
              style: CyberTypography.headerSmall.copyWith(
                color: CyberColors.neonCrimson,
                fontSize: 15,
              ),
            ),
          ],
        ),
        content: Text(
          'Ты уверен, что хочешь отключить терминал и разорвать сессионный ключ?',
          style: CyberTypography.bodyMedium.copyWith(color: CyberColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'ОТМЕНА',
              style: CyberTypography.monoSmall.copyWith(color: CyberColors.cyberCyan),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<AuthBloc>().add(AuthLogoutRequested());
            },
            child: Text(
              'ОТКЛЮЧИТЬСЯ',
              style: CyberTypography.monoBold.copyWith(
                color: CyberColors.neonCrimson,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
