import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';

import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../../../core/config/app_config.dart';
import '../models/chat_room.dart';
import '../models/chat_message.dart';
import '../services/chat_service.dart';
import '../widgets/message_bubble.dart';

import 'entity_selector_screen.dart';
import 'group_chat_info_screen.dart';

/// Screen for individual chat conversations
class ChatScreen extends StatefulWidget {
  final ChatRoom chatRoom;

  const ChatScreen({
    super.key,
    required this.chatRoom,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();
  final ImagePicker _imagePicker = ImagePicker();

  bool _showEmojiPicker = false;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _messageFocusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocusNode.dispose();
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
    final displayName = widget.chatRoom.getDisplayName(currentUserId);

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
        backgroundColor: ColorsManager.chatBackground,
        appBar: _buildAppBar(displayName),
        body: Column(
          children: [
            Expanded(child: _buildMessagesList()),
            _buildInputSection(),
            if (_showEmojiPicker && AppConfig.enableEmojiPicker) _buildEmojiPicker(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(String displayName) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final displayImage = widget.chatRoom.getDisplayImage(currentUserId);

    return PreferredSize(
      preferredSize: Size.fromHeight(56.h), // Reduced height
      child: AppBar(
        backgroundColor: ColorsManager.mainBlue, // Changed to #247CFF
        foregroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 56.h, // Reduced toolbar height
        title: Row(
          children: [
            CircleAvatar(
              radius: 16.r, // Reduced avatar size
              backgroundColor: Colors.white.withAlpha(51),
              backgroundImage: (displayImage != null && displayImage.isNotEmpty)
                  ? NetworkImage(displayImage)
                  : null,
              child: (displayImage == null || displayImage.isEmpty)
                  ? Text(
                      _getInitials(displayName),
                      style: TextStyles.font12DarkBlue400Weight.copyWith(
                        color: Colors.white,
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
                  style: TextStyles.font14DarkBlue500Weight.copyWith( // Reduced font size
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.chatRoom.type == ChatType.group)
                  Text(
                    '${widget.chatRoom.participants.length} members',
                    style: TextStyles.font10Grey400Weight.copyWith(
                      color: Colors.white.withAlpha(204),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: _showChatInfo,
          icon: Icon(
            Icons.info_outline,
            size: 20.sp, // Reduced icon size
          ),
        ),
        PopupMenuButton<String>(
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
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
          ],
        ),
      ],
      ),
    );
  }

  Widget _buildMessagesList() {
    return StreamBuilder<List<ChatMessage>>(
      stream: _chatService.getChatMessages(widget.chatRoom.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: ColorsManager.mainBlue,
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
                  color: ColorsManager.coralRed,
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

        final messages = snapshot.data ?? [];

        if (messages.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 48.sp,
                  color: ColorsManager.gray76,
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

        return ListView.builder(
          controller: _scrollController,
          reverse: true,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
            final isMe = message.senderId == FirebaseAuth.instance.currentUser?.uid;
            final showSenderInfo = !isMe && widget.chatRoom.type == ChatType.group;

            return MessageBubble(
              message: message,
              isMe: isMe,
              showSenderInfo: showSenderInfo,
              onDelete: () => _deleteMessage(message),
              onTap: () => _handleMessageTap(message),
            );
          },
        );
      },
    );
  }

  Widget _buildInputSection() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide( 
            color: Colors.grey.withAlpha(51),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (AppConfig.enableEmojiPicker)
              IconButton(
                onPressed: _toggleEmojiPicker,
                icon: Icon(
                  _showEmojiPicker ? Icons.keyboard : Icons.emoji_emotions_outlined,
                  color: ColorsManager.mainBlue,
                  size: 24.sp,
                ),
              ),
            Expanded(
              child: TextField(
                controller: _messageController,
                focusNode: _messageFocusNode,
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyles.font14Grey400Weight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24.r),
                    borderSide: BorderSide( 
                      color: Colors.grey.withAlpha(77),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24.r),
                    borderSide: BorderSide( 
                      color: Colors.grey.withAlpha(77),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24.r),
                    borderSide: const BorderSide(
                      color: ColorsManager.neonBlue,
                    ),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 8.h,
                  ),
                ),
                onChanged: (text) {
                  setState(() {
                    _isTyping = text.trim().isNotEmpty;
                  });
                },
              ),
            ),
            SizedBox(width: 8.w),
            if (_isTyping)
              IconButton(
                onPressed: _sendTextMessage,
                icon: Icon(
                  Icons.send,
                  color: ColorsManager.neonBlue,
                  size: 24.sp,
                ),
              )
            else ...[
              IconButton(
                onPressed: _pickAndSendImage,
                icon: Icon(
                  Icons.camera_alt_outlined,
                  color: ColorsManager.neonBlue,
                  size: 24.sp,
                ),
              ),
              IconButton(
                onPressed: _showAttachmentOptions,
                icon: Icon(
                  Icons.attach_file,
                  color: ColorsManager.neonBlue,
                  size: 24.sp,
                ),
              ),
            ],
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
            backgroundColor: ColorsManager.neonBlue,
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
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    setState(() {
      _isTyping = false;
    });

    final success = await _chatService.sendTextMessage(
      chatId: widget.chatRoom.id,
      text: text,
    );

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to send message'),
          backgroundColor: ColorsManager.coralRed,
        ),
      );
    }

    _scrollToBottom();
  }

  Future<void> _pickAndSendImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        final success = await _chatService.sendImageMessage(
          chatId: widget.chatRoom.id,
          imageFile: File(image.path),
        );

        if (!success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to send image'),
              backgroundColor: ColorsManager.coralRed,
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
            backgroundColor: ColorsManager.coralRed,
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
    if (widget.chatRoom.type == ChatType.group) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => GroupChatInfoScreen(chatRoom: widget.chatRoom),
        ),
      );
    } else {
      // For direct chats, show user profile or connection info
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User profile feature coming soon!'),
          backgroundColor: ColorsManager.mainBlue,
        ),
      );
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'share_entity':
        _showEntitySelector();
        break;
      case 'clear_chat':
        _showClearChatDialog();
        break;
    }
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(16.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: ColorsManager.mainBlue),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _takePicture();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: ColorsManager.mainBlue),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickAndSendImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.share, color: ColorsManager.mainBlue),
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
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        final success = await _chatService.sendImageMessage(
          chatId: widget.chatRoom.id,
          imageFile: File(image.path),
        );

        if (!success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to send image'),
              backgroundColor: ColorsManager.coralRed,
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
            backgroundColor: ColorsManager.coralRed,
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
              _chatService.deleteMessage(widget.chatRoom.id, message.id);
            },
            child: Text(
              'Delete',
              style: TextStyles.font14Blue400Weight.copyWith(
                color: ColorsManager.coralRed,
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
          backgroundColor: ColorsManager.mainBlue,
        ),
      );
    } else if (message.type == MessageType.entity && message.sharedEntity != null) {
      // TODO: Handle entity tap (navigate to profile, venue, etc.)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Shared ${message.sharedEntity!.type.value} tapped!'),
          backgroundColor: ColorsManager.mainBlue,
        ),
      );
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
                  backgroundColor: ColorsManager.mainBlue,
                ),
              );
            },
            child: Text(
              'Clear',
              style: TextStyles.font14Blue400Weight.copyWith(
                color: ColorsManager.coralRed,
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

  Future<void> _shareEntity(SharedEntity entity) async {
    try {
      final success = await _chatService.sendEntityMessage(
        chatId: widget.chatRoom.id,
        entity: entity,
      );

      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to share item'),
            backgroundColor: ColorsManager.coralRed,
          ),
        );
      }

      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error sharing item'),
            backgroundColor: ColorsManager.coralRed,
          ),
        );
      }
    }
  }
}
