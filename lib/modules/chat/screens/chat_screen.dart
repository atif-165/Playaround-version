import 'dart:async';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';

import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../../../core/config/app_config.dart';
import '../../../routing/routes.dart';
import '../models/chat_room.dart';
import '../models/chat_message.dart';
import '../models/chat_background.dart';
import '../services/chat_service.dart';
import '../services/chat_background_service.dart';
import '../widgets/message_bubble.dart';
import '../../venue/services/venue_service.dart';
import '../../../models/venue_booking_model.dart';
import '../../team/services/team_service.dart';
import '../../team/models/team_model.dart';

import 'entity_selector_screen.dart';
import 'chat_background_selector_screen.dart';
import 'chat_settings_screen.dart';
import 'team_chat_settings_screen.dart';

const _chatBackgroundColor = Color(0xFF050414);
const LinearGradient _chatBackgroundGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [
    Color(0xFF1B1848),
    Color(0xFF080612),
  ],
);
const LinearGradient _chatPanelGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
    Color(0xFF181536),
    Color(0xFF0E0D24),
  ],
);
const Color _chatPanelColor = Color(0xFF14112D);
const Color _chatOverlayColor = Color(0xFF1C1A3C);
const Color _chatAccentColor = Color(0xFFFFC56F);
const Color _chatOutlineColor = Color(0x33FFFFFF);

/// Screen for individual chat conversations
class ChatScreen extends StatefulWidget {
  final ChatRoom chatRoom;
  final String? backgroundImageUrl;
  final bool triggerCelebration;

  const ChatScreen({
    super.key,
    required this.chatRoom,
    this.backgroundImageUrl,
    this.triggerCelebration = false,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with SingleTickerProviderStateMixin {
  final ChatService _chatService = ChatService();
  final ChatBackgroundService _backgroundService = ChatBackgroundService();
  final VenueService _venueService = VenueService();
  final TeamService _teamService = TeamService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();
  final ImagePicker _imagePicker = ImagePicker();
  
  Team? _teamInfo;
  bool _isLoadingTeamInfo = false;

  bool _showEmojiPicker = false;
  bool _isTyping = false;
  ChatBackground _currentBackground = ChatBackgrounds.defaultBackground;
  ChatBubbleColors _bubbleColors = ChatBubbleColors.defaults;
  String? _overrideBackgroundImage;
  bool _showCelebration = false;
  late ChatRoom _chatRoom;
  Map<String, dynamic>? _nonConnectionMeta;
  StreamSubscription<ChatRoom?>? _chatRoomSubscription;
  bool _isProcessingNonConnectionAction = false;
  bool _chatClosedByUserAction = false;
  late final AnimationController _celebrationController;
  late final Animation<double> _celebrationScale;
  late final Animation<double> _celebrationOpacity;
  VenueBookingModel? _venueBooking;
  final List<ChatMessage> _olderMessages = [];
  List<ChatMessage> _latestMessages = [];
  bool _hasMoreMessages = true;
  bool _isLoadingMoreMessages = false;

  @override
  void initState() {
    super.initState();
    _chatRoom = widget.chatRoom;
    _nonConnectionMeta = _extractNonConnectionMetadata(_chatRoom);
    _chatRoomSubscription =
        _chatService.watchChatRoom(widget.chatRoom.id).listen((room) {
      if (!mounted) return;
      if (room == null) {
        final wasClosedByAction = _chatClosedByUserAction;
        _chatClosedByUserAction = false;
        if (!wasClosedByAction) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This conversation is no longer available.'),
            ),
          );
        }
        Navigator.of(context).pop();
        return;
      }
      final meta = _extractNonConnectionMetadata(room);
      final canSendAfterUpdate = _canSendMessagesForMeta(meta);
      setState(() {
        _chatRoom = room;
        _nonConnectionMeta = meta;
        if (!canSendAfterUpdate) {
          _isTyping = false;
        }
      });
    });
    _messageFocusNode.addListener(_onFocusChange);
    _overrideBackgroundImage = widget.backgroundImageUrl;
    _initCelebration();
    if (_overrideBackgroundImage == null) {
      _loadBackground();
    } else {
      // Load persisted background as fallback in case user switches later
      _loadBackground();
    }
    _loadBookingIfNeeded();
    _loadTeamInfoIfNeeded();
  }
  
  Future<void> _loadTeamInfoIfNeeded() async {
    // Check if this is a team chat
    if (_chatRoom.relatedEntityType == 'team' && 
        _chatRoom.relatedEntityId != null) {
      setState(() {
        _isLoadingTeamInfo = true;
      });
      try {
        final team = await _teamService.getTeam(_chatRoom.relatedEntityId!);
        if (mounted) {
          setState(() {
            _teamInfo = team;
            _isLoadingTeamInfo = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoadingTeamInfo = false;
          });
        }
      }
    }
  }

  void _initCelebration() {
    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _celebrationScale = Tween<double>(begin: 0.7, end: 1.6).animate(
      CurvedAnimation(
        parent: _celebrationController,
        curve: Curves.easeOutQuart,
      ),
    );

    _celebrationOpacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 45,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 55,
      ),
    ]).animate(_celebrationController);

    _celebrationController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() {
          _showCelebration = false;
        });
        _celebrationController.reset();
      }
    });

    if (widget.triggerCelebration) {
      _showCelebration = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _celebrationController.forward();
        }
      });
    }
  }

  Future<void> _loadBackground() async {
    final background =
        await _backgroundService.getBackgroundForChat(_chatRoom.id);
    final bubbleColors =
        await _backgroundService.getBubbleColors(_chatRoom.id);
    if (mounted) {
      setState(() {
        _currentBackground = background;
        _bubbleColors = bubbleColors;
        if (_currentBackground.type == ChatBackgroundType.customImage &&
            _currentBackground.imageUrl != null) {
          _overrideBackgroundImage = _currentBackground.imageUrl;
        }
      });
    }
  }

  Future<void> _loadBookingIfNeeded() async {
    final metadata = _chatRoom.metadata;
    if (metadata != null && metadata['type'] == 'venue_booking') {
      final bookingId = metadata['bookingId'] as String?;
      if (bookingId != null) {
        final booking = await _venueService.getVenueBooking(bookingId);
        if (mounted && booking != null) {
          setState(() {
            _venueBooking = booking;
          });
        }
      }
    }
  }

  Future<void> _loadOlderMessages() async {
    if (_isLoadingMoreMessages || !_hasMoreMessages) return;

    final oldestMessage = _olderMessages.isNotEmpty
        ? _olderMessages.last
        : (_latestMessages.isNotEmpty ? _latestMessages.last : null);

    if (oldestMessage == null) return;

    setState(() {
      _isLoadingMoreMessages = true;
    });

    final olderMessages = await _chatService.fetchOlderMessages(
      _chatRoom.id,
      oldestMessage,
    );

    if (!mounted) return;

    setState(() {
      if (olderMessages.isEmpty) {
        _hasMoreMessages = false;
      } else {
        _olderMessages.addAll(olderMessages);
        _hasMoreMessages = olderMessages.length == 50;
      }
      _isLoadingMoreMessages = false;
    });

    if (olderMessages.isNotEmpty) {
      _markMessagesAsRead(olderMessages);
    }
  }

  void _markMessagesAsRead(List<ChatMessage> messages) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    for (final message in messages) {
      if (message.fromId == currentUserId) continue;
      if (message.readBy.contains(currentUserId)) continue;
      _chatService.markMessageAsRead(_chatRoom.id, message.id);
    }
  }

  @override
  void dispose() {
    _chatRoomSubscription?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocusNode.dispose();
    _celebrationController.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_messageFocusNode.hasFocus && _showEmojiPicker) {
      setState(() {
        _showEmojiPicker = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    String displayName = _chatRoom.getDisplayName(currentUserId);
    String? subtitle;
    
    // For team chats, show team name and department
    if (_chatRoom.relatedEntityType == 'team' && _teamInfo != null) {
      displayName = _teamInfo!.name;
      subtitle = _teamInfo!.sportType.displayName;
    }

    return PopScope(
      canPop: !_showEmojiPicker,
      onPopInvokedWithResult: (didPop, result) {
        if (_showEmojiPicker) {
          setState(() {
            _showEmojiPicker = false;
          });
        }
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: _buildAppBar(),
        body: Stack(
          children: [
            Container(
              decoration: _buildBackgroundDecoration(),
            ),
            if (_overrideBackgroundImage != null)
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.55),
                      Colors.black.withOpacity(0.65),
                    ],
                  ),
                ),
              ),
            Positioned.fill(
              child: Column(
                children: [
                  if (_shouldShowNonConnectionBanner)
                    _buildNonConnectionBanner(),
                  Expanded(child: _buildMessagesList()),
                  _buildInputSection(),
                  if (_showEmojiPicker && AppConfig.enableEmojiPicker)
                    _buildEmojiPicker(),
                ],
              ),
            ),
            if (_showCelebration)
              Positioned.fill(
                child: _buildCelebrationOverlay(),
              ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _buildBackgroundDecoration() {
    if (_overrideBackgroundImage != null &&
        _overrideBackgroundImage!.trim().isNotEmpty) {
      return BoxDecoration(
        image: DecorationImage(
          image: CachedNetworkImageProvider(_overrideBackgroundImage!),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.25),
            BlendMode.darken,
          ),
        ),
      );
    }

    switch (_currentBackground.type) {
      case ChatBackgroundType.solid:
        return BoxDecoration(
          color: _currentBackground.solidColor ?? _chatBackgroundColor,
        );
      case ChatBackgroundType.gradient:
        return BoxDecoration(
          gradient: _currentBackground.gradient,
        );
      case ChatBackgroundType.pattern:
        return BoxDecoration(
          color: _currentBackground.solidColor,
        );
      case ChatBackgroundType.customImage:
        if (_currentBackground.imageUrl != null &&
            _currentBackground.imageUrl!.isNotEmpty) {
          return BoxDecoration(
            image: DecorationImage(
              image: CachedNetworkImageProvider(_currentBackground.imageUrl!),
              fit: BoxFit.cover,
            ),
          );
        }
        return const BoxDecoration(
          gradient: _chatBackgroundGradient,
        );
    }
  }

  Widget _buildCelebrationOverlay() {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _celebrationController,
        builder: (context, child) {
          final opacity = _celebrationOpacity.value.clamp(0.0, 1.0);
          final scale = _celebrationScale.value;

          return Opacity(
            opacity: opacity,
            child: Stack(
              children: [
                _buildFireworkBurst(
                  alignment: const Alignment(0.0, -0.6),
                  color: Colors.pinkAccent,
                  baseSize: 240,
                  scale: scale,
                ),
                _buildFireworkBurst(
                  alignment: const Alignment(-0.75, -0.15),
                  color: Colors.blueAccent,
                  baseSize: 210,
                  scale: scale * 0.9,
                ),
                _buildFireworkBurst(
                  alignment: const Alignment(0.8, -0.05),
                  color: Colors.amberAccent,
                  baseSize: 220,
                  scale: scale * 1.1,
                ),
                _buildSparkles(scale),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFireworkBurst({
    required Alignment alignment,
    required Color color,
    required double baseSize,
    required double scale,
  }) {
    final size = baseSize * scale;
    return Align(
      alignment: alignment,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withOpacity(0.55),
              color.withOpacity(0.25),
              Colors.transparent,
            ],
            stops: const [0.0, 0.45, 1.0],
          ),
        ),
      ),
    );
  }

  Widget _buildSparkles(double scale) {
    final sparkles = [
      const Offset(-0.6, 0.15),
      const Offset(0.45, 0.3),
      const Offset(-0.2, -0.35),
      const Offset(0.2, -0.65),
      const Offset(0.75, 0.05),
    ];

    return Stack(
      children: sparkles
          .map(
            (offset) => Align(
              alignment: Alignment(offset.dx, offset.dy),
              child: Transform.scale(
                scale: (1.2 - scale * 0.25).clamp(0.65, 1.15),
                child: Icon(
                  Icons.star_rounded,
                  color: Colors.white.withOpacity(0.85),
                  size: 18 + (scale * 6),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    String displayName = _chatRoom.getDisplayName(currentUserId);
    String? subtitle;
    
    // For team chats, show team name and department
    if (_chatRoom.relatedEntityType == 'team' && _teamInfo != null) {
      displayName = _teamInfo!.name;
      subtitle = _teamInfo!.sportType.displayName;
    }
    
    final displayImage = _chatRoom.getDisplayImage(currentUserId);

    return PreferredSize(
      preferredSize: Size.fromHeight(56.h), // Reduced height
      child: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 56.h,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: _chatBackgroundGradient,
          ),
        ),
        title: GestureDetector(
          onTap: () => _openChatSettings(),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18.r,
                backgroundColor: Colors.white.withOpacity(0.1),
                backgroundImage:
                    (displayImage != null && displayImage.isNotEmpty)
                        ? NetworkImage(displayImage)
                        : null,
                child: (displayImage == null || displayImage.isEmpty)
                    ? Text(
                        _getInitials(displayName),
                        style: TextStyles.font12DarkBlue400Weight.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    : null,
              ),
              SizedBox(width: 10.w), // Reduced gap
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: TextStyles.font16DarkBlue600Weight.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle,
                        style: TextStyles.font12Grey400Weight.copyWith(
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    else if (_chatRoom.type == ChatType.group)
                      Text(
                        '${_chatRoom.participants.length} members',
                        style: TextStyles.font12Grey400Weight.copyWith(
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            onPressed: _showChatInfo,
            icon: Icon(
              Icons.info_outline,
              size: 20.sp, // Reduced icon size
                  color: Colors.white,
            ),
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
                color: _chatPanelColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
            itemBuilder: (context) {
              final currentUserId =
                  FirebaseAuth.instance.currentUser?.uid ?? '';
              final isVenueOwner = _venueBooking?.venueOwnerId == currentUserId;
              final isPendingBooking =
                  _venueBooking?.status == VenueBookingStatus.pending;

              return [
                // Booking management options for venue owner
                if (isVenueOwner &&
                    isPendingBooking &&
                    _venueBooking != null) ...[
                  const PopupMenuItem(
                    value: 'confirm_booking',
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green),
                        SizedBox(width: 8),
                        Text('Confirm Booking'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'reject_booking',
                    child: Row(
                      children: [
                        Icon(Icons.cancel, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Reject Booking'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'divider',
                    enabled: false,
                    child: Divider(),
                  ),
                ],
                // Regular chat options
                const PopupMenuItem(
                  value: 'change_background',
                  child: Row(
                    children: [
                      Icon(Icons.wallpaper),
                      SizedBox(width: 8),
                      Text('Change Background'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'reset_background',
                  child: Row(
                    children: [
                      Icon(Icons.restore),
                      SizedBox(width: 8),
                      Text('Reset Background'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'share_entity',
                  child: Row(
                    children: [
                      Icon(Icons.share_outlined),
                      SizedBox(width: 8),
                      Text('Share'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'clear_chat',
                  child: Row(
                    children: [
                      Icon(Icons.clear_all),
                      SizedBox(width: 8),
                      Text('Clear Chat'),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    return StreamBuilder<List<ChatMessage>>(
      stream: _chatService.getChatMessages(_chatRoom.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            _olderMessages.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(
              color: _chatAccentColor,
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48.sp,
              color: Colors.redAccent,
                ),
                Gap(16.h),
                Text(
                  'Error loading messages',
                  style: TextStyles.font16DarkBlue600Weight,
                ),
                Gap(8.h),
                Text(
                  'Please try again later',
                  style: TextStyles.font14Grey400Weight,
                ),
              ],
            ),
          );
        }

        final latestMessages = (snapshot.data ?? [])
            .where((message) => !message.isDeleted)
            .toList();
        _latestMessages = latestMessages;

        final combinedMessages = [...latestMessages, ..._olderMessages];
        _hasMoreMessages =
            _olderMessages.isNotEmpty || latestMessages.length == 50;

        if (combinedMessages.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 48.sp,
                  color: Colors.white54,
                ),
                Gap(16.h),
                Text(
                  'No messages yet',
                  style: TextStyles.font16DarkBlue600Weight,
                ),
                Gap(8.h),
                Text(
                  'Start the conversation!',
                  style: TextStyles.font14Grey400Weight,
                ),
              ],
            ),
          );
        }

        _markMessagesAsRead(latestMessages);

        return ListView.builder(
          controller: _scrollController,
          reverse: true,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          itemCount: combinedMessages.length + (_hasMoreMessages ? 1 : 0),
          itemBuilder: (context, index) {
            if (_hasMoreMessages && index == combinedMessages.length) {
              return _buildLoadMoreTile();
            }

            final message = combinedMessages[index];
            final isMe = message.fromId == currentUserId;
            final isGroupChat = _chatRoom.type == ChatType.group;
            final showSenderInfo = !isMe && isGroupChat;

            return MessageBubble(
              message: message,
              isMe: isMe,
              isGroupChat: isGroupChat,
              showSenderInfo: showSenderInfo,
              onDelete: () => _deleteMessage(message),
              onTap: () => _handleMessageTap(message),
              onLongPress: message.type == MessageType.entity &&
                      message.sharedEntity?.type == EntityType.post
                  ? () => _showPostReactions(message)
                  : null,
              bubbleColors: _bubbleColors,
            );
          },
        );
      },
    );
  }

  Widget _buildLoadMoreTile() {
    if (_isLoadingMoreMessages) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        child: const Center(
          child: CircularProgressIndicator(
              color: _chatAccentColor, strokeWidth: 2),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Center(
        child: TextButton.icon(
          onPressed: _loadOlderMessages,
          icon: const Icon(Icons.history),
          label: const Text('Load earlier messages'),
        ),
      ),
    );
  }

  Widget _buildInputSection() {
    final bool canSend = _canSendMessages;
    final String? restrictionMessage = _nonConnectionInputHint();
    final bool showEmojiPicker = AppConfig.enableEmojiPicker;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        border: Border(
          top: BorderSide(
            color: Colors.redAccent,
            width: 1.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8.r,
            offset: Offset(0, -2.h),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (restrictionMessage != null)
              Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: Text(
                  restrictionMessage,
                  style: TextStyles.font12Grey400Weight
                      .copyWith(color: Colors.white70),
                ),
              ),
            Row(
              children: [
                if (showEmojiPicker)
                  IconButton(
                    onPressed:
                        canSend ? _toggleEmojiPicker : _showRestrictionMessage,
                    icon: Icon(
                      _showEmojiPicker
                          ? Icons.keyboard
                          : Icons.emoji_emotions_outlined,
                      color: canSend ? _chatAccentColor : Colors.grey,
                      size: 24.sp,
                    ),
                  ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    focusNode: _messageFocusNode,
                    enabled: canSend,
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: TextStyles.font14Grey400Weight
                          .copyWith(color: Colors.grey[500]),
                      filled: true,
                      fillColor: _chatPanelColor.withOpacity(0.85),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24.r),
                        borderSide: BorderSide(
                          color: _chatOutlineColor,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24.r),
                        borderSide: BorderSide(
                          color: _chatOutlineColor,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24.r),
                        borderSide: const BorderSide(
                          color: _chatAccentColor,
                          width: 2,
                        ),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 12.h,
                      ),
                    ),
                    style: TextStyles.font14DarkBlue500Weight
                        .copyWith(color: Colors.white),
                    onChanged: (text) {
                      if (!canSend) {
                        setState(() {
                          _isTyping = false;
                        });
                        return;
                      }
                      setState(() {
                        _isTyping = text.trim().isNotEmpty;
                      });
                    },
                  ),
                ),
                SizedBox(width: 8.w),
                if (_isTyping && canSend)
                  IconButton(
                    onPressed: _sendTextMessage,
                    icon: Icon(
                      Icons.send,
                      color: _chatAccentColor,
                      size: 26.sp,
                    ),
                  )
                else if (canSend) ...[
                  IconButton(
                    onPressed: _pickAndSendImage,
                    icon: Icon(
                      Icons.camera_alt_outlined,
                      color: _chatAccentColor,
                      size: 24.sp,
                    ),
                  ),
                  IconButton(
                    onPressed: _showAttachmentOptions,
                    icon: Icon(
                      Icons.attach_file,
                      color: _chatAccentColor,
                      size: 24.sp,
                    ),
                  ),
                ] else
                  IconButton(
                    onPressed: _showRestrictionMessage,
                    icon: Icon(
                      Icons.info_outline,
                      color: Colors.white54,
                      size: 24.sp,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmojiPicker() {
    // We keep the dependency isolated to only this widget
    // ignore: implementation_imports
    // Using alias to prevent symbol leakage
    // Note: This is a regular import at file top in most cases; here we keep it localized for clarity.
    return SizedBox(
      height: 250.h,
      child: EmojiPicker(
        onEmojiSelected: (category, emoji) {
          _messageController.text += emoji.emoji;
          setState(() {
            _isTyping = _messageController.text.trim().isNotEmpty;
          });
        },
        config: Config(
          height: 250.h,
          checkPlatformCompatibility: true,
          emojiViewConfig: EmojiViewConfig(
            emojiSizeMax: 28.sp,
          backgroundColor: _chatAccentColor,
          ),
          skinToneConfig: const SkinToneConfig(),
          categoryViewConfig: const CategoryViewConfig(),
          bottomActionBarConfig: const BottomActionBarConfig(),
          searchViewConfig: const SearchViewConfig(),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final words = name.trim().split(' ');
    if (words.isEmpty) return '?';
    if (words.length == 1) return words[0][0].toUpperCase();
    return '${words[0][0]}${words[1][0]}'.toUpperCase();
  }

  void _toggleEmojiPicker() {
    setState(() {
      _showEmojiPicker = !_showEmojiPicker;
    });
    if (_showEmojiPicker) {
      _messageFocusNode.unfocus();
    }
  }

  Future<void> _sendTextMessage() async {
    if (!_canSendMessages) {
      _showRestrictionMessage();
      return;
    }

    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    setState(() {
      _isTyping = false;
    });

    final success = await _chatService.sendTextMessage(
      chatId: _chatRoom.id,
      text: text,
    );

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to send message'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }

    _scrollToBottom();
  }

  Future<void> _pickAndSendImage() async {
    if (!_canSendMessages) {
      _showRestrictionMessage();
      return;
    }

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        final success = await _chatService.sendImageMessage(
          chatId: _chatRoom.id,
          imageFile: File(image.path),
        );

        if (!success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to send image'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }

        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error picking image'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showChatInfo() {
    if (_chatRoom.type == ChatType.group) {
      // For team chats, show team chat settings
      if (_chatRoom.relatedEntityType == 'team' && _chatRoom.relatedEntityId != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => TeamChatSettingsScreen(
              chatRoom: _chatRoom,
              teamId: _chatRoom.relatedEntityId!,
            ),
          ),
        );
      } else {
        // For other group chats, show regular chat settings
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ChatSettingsScreen(chatRoom: _chatRoom),
          ),
        );
      }
    } else {
      // For direct chats, show user profile or connection info
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User profile feature coming soon!'),
          backgroundColor: _chatAccentColor,
        ),
      );
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'confirm_booking':
        _confirmBooking();
        break;
      case 'reject_booking':
        _rejectBooking();
        break;
      case 'change_background':
        _showBackgroundSelector();
        break;
      case 'reset_background':
        _resetBackground();
        break;
      case 'share_entity':
        _showEntitySelector();
        break;
      case 'clear_chat':
        _showClearChatDialog();
        break;
    }
  }

  Future<void> _confirmBooking() async {
    if (_venueBooking == null) return;

    try {
      await _venueService.updateBookingStatus(
        bookingId: _venueBooking!.id,
        status: VenueBookingStatus.confirmed,
      );

      // Send confirmation message
      await _chatService.sendTextMessage(
        chatId: _chatRoom.id,
        text:
            '✅ Booking confirmed! See you at ${_venueBooking!.venueTitle} on ${_venueBooking!.formattedDate} at ${_venueBooking!.formattedTimeSlot}.',
      );

      // Refresh booking
      await _loadBookingIfNeeded();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking confirmed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to confirm booking: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectBooking() async {
    if (_venueBooking == null) return;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Booking'),
        content: const Text('Are you sure you want to reject this booking?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _venueService.updateBookingStatus(
        bookingId: _venueBooking!.id,
        status: VenueBookingStatus.cancelled,
        cancellationReason: 'Rejected by venue owner',
      );

      // Send rejection message
      await _chatService.sendTextMessage(
        chatId: _chatRoom.id,
        text:
            '❌ Sorry, this booking has been rejected. Please try another time slot or venue.',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking rejected'),
            backgroundColor: Colors.orange,
          ),
        );
        // Close chat and go back
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reject booking: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _resetBackground() async {
    final success =
        await _backgroundService.resetChatBackground(_chatRoom.id);

    if (success && mounted) {
      final defaultBg = await _backgroundService.getGlobalBackground();
      setState(() {
        _currentBackground = defaultBg;
        _overrideBackgroundImage = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Background reset to default'),
          backgroundColor: _chatAccentColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _showBackgroundSelector() async {
    final result =
        await Navigator.of(context).push<ChatAppearanceSelection?>(
      MaterialPageRoute(
        builder: (context) => ChatBackgroundSelectorScreen(
          currentBackground: _currentBackground,
          bubbleColors: _bubbleColors,
          chatId: _chatRoom.id,
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _currentBackground = result.background;
        _bubbleColors = result.bubbleColors;
        _overrideBackgroundImage =
            result.background.type == ChatBackgroundType.customImage
                ? result.background.imageUrl
                : null;
      });
    }
  }

  Future<void> _openChatSettings() async {
    if (_chatRoom.type == ChatType.group) {
      // For team chats, show team chat settings
      if (_chatRoom.relatedEntityType == 'team' && _chatRoom.relatedEntityId != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => TeamChatSettingsScreen(
              chatRoom: _chatRoom,
              teamId: _chatRoom.relatedEntityId!,
            ),
          ),
        );
        return;
      }
      _showChatInfo();
      return;
    }

    final result = await Navigator.of(context).push<ChatSettingsAction?>(
      MaterialPageRoute(
        builder: (context) => ChatSettingsScreen(chatRoom: _chatRoom),
      ),
    );

    if (result == ChatSettingsAction.searchChat) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Search coming soon to chat settings.'),
        ),
      );
    }
  }

  void _showAttachmentOptions() {
    if (!_canSendMessages) {
      _showRestrictionMessage();
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(16.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading:
                  const Icon(Icons.camera_alt, color: _chatAccentColor),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _takePicture();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library,
                  color: _chatAccentColor),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickAndSendImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.share, color: _chatAccentColor),
              title: const Text('Share'),
              onTap: () {
                Navigator.pop(context);
                _showEntitySelector();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _takePicture() async {
    if (!_canSendMessages) {
      _showRestrictionMessage();
      return;
    }

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        final success = await _chatService.sendImageMessage(
          chatId: _chatRoom.id,
          imageFile: File(image.path),
        );

        if (!success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to send image'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }

        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error taking picture'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _deleteMessage(ChatMessage message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Message',
          style: TextStyles.font18DarkBlue600Weight,
        ),
        content: Text(
          'Are you sure you want to delete this message?',
          style: TextStyles.font14Grey400Weight,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyles.font14Grey400Weight,
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _chatService.deleteMessage(_chatRoom.id, message.id);
            },
            child: Text(
              'Delete',
              style: TextStyles.font14Blue400Weight.copyWith(
                color: Colors.redAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleMessageTap(ChatMessage message) {
    if (message.type == MessageType.image && message.imageUrl != null) {
      // TODO: Show full screen image viewer
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Image viewer feature coming soon!'),
          backgroundColor: _chatAccentColor,
        ),
      );
    } else if (message.type == MessageType.entity &&
        message.sharedEntity != null) {
      final entity = message.sharedEntity!;
      
      // Handle post entity - navigate to post detail
      if (entity.type == EntityType.post) {
        final postId = entity.metadata?['postId'] as String? ?? entity.id;
        Navigator.of(context).pushNamed(
          Routes.communityPostDetail,
          arguments: postId,
        );
      } else {
        // Handle other entity types
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Shared ${entity.type.value} tapped!'),
            backgroundColor: _chatAccentColor,
          ),
        );
      }
    }
  }

  void _showClearChatDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Clear Chat',
          style: TextStyles.font18DarkBlue600Weight,
        ),
        content: Text(
          'Are you sure you want to clear all messages in this chat? This action cannot be undone.',
          style: TextStyles.font14Grey400Weight,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyles.font14Grey400Weight,
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implement clear chat functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Clear chat feature coming soon!'),
                  backgroundColor: _chatAccentColor,
                ),
              );
            },
            child: Text(
              'Clear',
              style: TextStyles.font14Blue400Weight.copyWith(
                color: Colors.redAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEntitySelector() {
    showEntitySelector(
      context: context,
      onEntitySelected: _shareEntity,
    );
  }

  void _showPostReactions(ChatMessage message) {
    final entity = message.sharedEntity;
    if (entity == null || entity.type != EntityType.post) return;

    final postId = entity.metadata?['postId'] as String? ?? entity.id;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1B1848),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'React to Post',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 20.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildReactionButton(
                  icon: Icons.thumb_up_outlined,
                  label: 'Upvote',
                  onTap: () {
                    Navigator.pop(context);
                    _reactToPost(postId, 'upvote');
                  },
                ),
                _buildReactionButton(
                  icon: Icons.thumb_down_outlined,
                  label: 'Downvote',
                  onTap: () {
                    Navigator.pop(context);
                    _reactToPost(postId, 'downvote');
                  },
                ),
                _buildReactionButton(
                  icon: Icons.favorite_outline,
                  label: 'Like',
                  onTap: () {
                    Navigator.pop(context);
                    _reactToPost(postId, 'like');
                  },
                ),
                _buildReactionButton(
                  icon: Icons.bookmark_outline,
                  label: 'Save',
                  onTap: () {
                    Navigator.pop(context);
                    _reactToPost(postId, 'save');
                  },
                ),
              ],
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  Widget _buildReactionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: _chatAccentColor, size: 24.sp),
            SizedBox(height: 8.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _reactToPost(String postId, String reactionType) async {
    try {
      // Navigate to post detail screen where user can react
      Navigator.of(context).pushNamed(
        Routes.communityPostDetail,
        arguments: postId,
      );
      
      // Show feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Opening post to $reactionType...'),
            backgroundColor: _chatAccentColor,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open post: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _shareEntity(SharedEntity entity) async {
    if (!_canSendMessages) {
      _showRestrictionMessage();
      return;
    }

    try {
      final success = await _chatService.sendEntityMessage(
        chatId: _chatRoom.id,
        entity: entity,
      );

      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to share item'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }

      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error sharing item'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Map<String, dynamic>? _extractNonConnectionMetadata(ChatRoom chatRoom) {
    final metadata = chatRoom.metadata;
    if (metadata == null) return null;
    final nonConnection = metadata['nonConnection'];
    if (nonConnection is Map<String, dynamic>) {
      return Map<String, dynamic>.from(nonConnection);
    }
    return null;
  }

  String _statusForMeta(Map<String, dynamic>? meta) {
    return (meta?['status'] as String?)?.toLowerCase() ?? 'none';
  }

  bool _isInitiatorForMeta(Map<String, dynamic>? meta) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return false;
    final initiatorId = meta?['initiatorId'] as String?;
    return initiatorId != null && initiatorId == currentUserId;
  }

  int _allowedMessagesForMeta(Map<String, dynamic>? meta) {
    final allowed = meta?['allowedMessages'];
    if (allowed is int && allowed >= 0) {
      return allowed;
    }
    return 1;
  }

  int _initiatorCountForMeta(Map<String, dynamic>? meta) {
    final count = meta?['initiatorMessageCount'];
    if (count is int && count >= 0) {
      return count;
    }
    return 0;
  }

  bool _canSendMessagesForMeta(Map<String, dynamic>? meta) {
    if (meta == null) return true;
    final status = _statusForMeta(meta);
    if (status == 'accepted') {
      return true;
    }

    if (status == 'pending') {
      final isInitiator = _isInitiatorForMeta(meta);
      if (!isInitiator) return false;
      final allowed = _allowedMessagesForMeta(meta);
      final sent = _initiatorCountForMeta(meta);
      return allowed == 0 ? false : sent < allowed;
    }

    return false;
  }

  bool get _isNonConnectionChat => _nonConnectionMeta != null;

  String get _nonConnectionStatus => _statusForMeta(_nonConnectionMeta);

  bool get _isNonConnectionInitiator =>
      _isInitiatorForMeta(_nonConnectionMeta);

  bool get _isNonConnectionPendingReceiver =>
      _isNonConnectionChat &&
      _nonConnectionStatus == 'pending' &&
      !_isNonConnectionInitiator;

  bool get _canSendMessages => _canSendMessagesForMeta(_nonConnectionMeta);

  String? _nonConnectionInputHint() {
    if (!_isNonConnectionChat) return null;
    switch (_nonConnectionStatus) {
      case 'pending':
        return _isNonConnectionInitiator
            ? 'You can send one message until they accept.'
            : 'Accept to continue this conversation or choose Block/Report.';
      case 'blocked':
        return 'You have blocked this conversation.';
      case 'reported':
        return 'You reported this conversation.';
      default:
        return null;
    }
  }

  bool get _shouldShowNonConnectionBanner => _isNonConnectionPendingReceiver;

  String? get _otherParticipantId {
    if (_chatRoom.type != ChatType.direct) return null;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return null;
    final other = _chatRoom.participants.firstWhere(
      (participant) => participant.userId != currentUserId,
      orElse: () => _chatRoom.participants.first,
    );
    return other.userId;
  }

  Widget _buildNonConnectionBanner() {
    final bool isProcessing = _isProcessingNonConnectionAction;
    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: ColorsManager.warning.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: ColorsManager.warning.withOpacity(0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This message is from a non-connection.',
            style: TextStyles.font14DarkBlue600Weight
                .copyWith(color: Colors.white),
          ),
          Gap(4.h),
          Text(
            'Do you want to Block, Report, or Accept?',
            style: TextStyles.font12Grey400Weight
                .copyWith(color: Colors.white70),
          ),
          Gap(12.h),
          Wrap(
            spacing: 12.w,
            runSpacing: 8.h,
            children: [
              ElevatedButton(
                onPressed:
                    isProcessing ? null : _handleAcceptNonConnection,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorsManager.success,
                  foregroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 12.h,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24.r),
                  ),
                ),
                child: isProcessing
                    ? SizedBox(
                        width: 18.w,
                        height: 18.w,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.black),
                        ),
                      )
                    : const Text('Accept'),
              ),
              TextButton(
                onPressed:
                    isProcessing ? null : _handleReportNonConnection,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.orangeAccent,
                ),
                child: const Text('Report'),
              ),
              TextButton(
                onPressed:
                    isProcessing ? null : _handleBlockNonConnection,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                ),
                child: const Text('Block'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showRestrictionMessage() {
    if (!mounted) return;
    final message = _nonConnectionInputHint();
    if (message == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handleAcceptNonConnection() async {
    if (_isProcessingNonConnectionAction) return;

    setState(() {
      _isProcessingNonConnectionAction = true;
    });

    final success =
        await _chatService.acceptNonConnectionChat(_chatRoom.id);

    if (!mounted) return;

    setState(() {
      _isProcessingNonConnectionAction = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Message request accepted. You can now chat freely.'
              : 'Failed to accept the message request.',
        ),
        backgroundColor: success ? _chatAccentColor : Colors.redAccent,
      ),
    );
  }

  Future<void> _handleBlockNonConnection() async {
    if (_isProcessingNonConnectionAction) return;

    final otherUserId = _otherParticipantId;
    if (otherUserId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block user'),
        content: const Text(
          'Blocking removes this conversation and prevents further messages from this user.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Block',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isProcessingNonConnectionAction = true;
      _chatClosedByUserAction = true;
    });

    final success = await _chatService.blockNonConnectionChat(
      chatId: _chatRoom.id,
      otherUserId: otherUserId,
    );

    if (!mounted) return;

    if (!success) {
      setState(() {
        _isProcessingNonConnectionAction = false;
        _chatClosedByUserAction = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to block this user. Please try again.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      _isProcessingNonConnectionAction = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('User blocked and conversation removed.'),
      ),
    );
  }

  Future<void> _handleReportNonConnection() async {
    if (_isProcessingNonConnectionAction) return;

    final otherUserId = _otherParticipantId;
    if (otherUserId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report message'),
        content: const Text(
          'Report this conversation? It will be removed and reviewed by our team.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Report',
              style: TextStyle(color: Colors.orangeAccent),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isProcessingNonConnectionAction = true;
      _chatClosedByUserAction = true;
    });

    final success = await _chatService.reportNonConnectionChat(
      chatId: _chatRoom.id,
      otherUserId: otherUserId,
    );

    if (!mounted) return;

    if (!success) {
      setState(() {
        _isProcessingNonConnectionAction = false;
        _chatClosedByUserAction = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to report this conversation.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      _isProcessingNonConnectionAction = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('This message has been reported.'),
      ),
    );
  }
}
