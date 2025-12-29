import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../providers/message_provider.dart';
import '../providers/auth_provider.dart';
import '../models/message.dart';
import 'new_conversation_page.dart';

class MessagingPage extends StatefulWidget {
  const MessagingPage({super.key});

  @override
  State<MessagingPage> createState() => _MessagingPageState();
}

class _MessagingPageState extends State<MessagingPage> {
  Conversation? _selectedConversation;
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<MessageProvider>();
      await provider.loadConversations();
    });
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length == 1) {
      return parts[0].substring(0, 1).toUpperCase();
    }
    return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final messageProvider = context.watch<MessageProvider>();
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    final errorWidget = (messageProvider.error != null &&
            messageProvider.error!.isNotEmpty)
        ? Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: const Color(0xFFFFF3CD),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    messageProvider.error!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  onPressed: () => messageProvider.clearError(),
                  child: const Text('Dismiss'),
                ),
              ],
            ),
          )
        : const SizedBox.shrink();

    if (isTablet) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Messages'),
          actions: [
            IconButton(
              tooltip: 'New conversation',
              icon: const Icon(Icons.add),
              onPressed: () async {
                final createdConversation = await Navigator.push<Conversation?>(
                  context,
                  MaterialPageRoute(builder: (_) => const NewConversationPage()),
                );

                if (!mounted) return;

                if (createdConversation != null) {
                  setState(() => _selectedConversation = createdConversation);
                  await messageProvider.loadMessages(createdConversation.id);

                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Conversation started with ${createdConversation.name}')),
                  );
                }
              },
            ),
            IconButton(
              tooltip: 'Refresh',
              icon: const Icon(Icons.refresh),
              onPressed: () async {
                await messageProvider.refresh();
                if (!mounted) return;
                setState(() => _selectedConversation = null);
              },
            ),
          ],
        ),
        body: Column(
          children: [
            errorWidget,
            Expanded(
              child: Row(
                children: [
                  SizedBox(
                    width: 320,
                    child: _buildConversationList(messageProvider),
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(
                    child: _selectedConversation == null
                        ? const Center(child: Text('Select a conversation'))
                        : _buildChatView(messageProvider, _selectedConversation!),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Mobile Layout
    if (_selectedConversation == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Messages'),
          actions: [
            IconButton(
              tooltip: 'New conversation',
              icon: const Icon(Icons.add),
              onPressed: () async {
                final createdConversation = await Navigator.push<Conversation?>(
                  context,
                  MaterialPageRoute(builder: (_) => const NewConversationPage()),
                );

                if (!mounted) return;

                if (createdConversation != null) {
                  setState(() => _selectedConversation = createdConversation);
                  await messageProvider.loadMessages(createdConversation.id);

                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Conversation started with ${createdConversation.name}')),
                  );
                }
              },
            ),
            IconButton(
              tooltip: 'Refresh',
              icon: const Icon(Icons.refresh),
              onPressed: () async {
                await messageProvider.refresh();
              },
            ),
          ],
        ),
        body: Column(
          children: [
            errorWidget,
            Expanded(child: _buildConversationList(messageProvider)),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => setState(() => _selectedConversation = null),
        ),
        title: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundColor: const Color(0xFF0EA5E9),
            child: Text(
              _getInitials(_selectedConversation!.name),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          title: Text(
            _selectedConversation!.name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: _selectedConversation!.isOnline
              ? const Text(
                  'Online',
                  style: TextStyle(color: Color(0xFF10B981), fontSize: 12),
                )
              : null,
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.phone),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(LucideIcons.video),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          errorWidget,
          Expanded(child: _buildChatView(messageProvider, _selectedConversation!)),
        ],
      ),
    );
  }

  Widget _buildConversationList(MessageProvider messageProvider) {
    if (messageProvider.isLoading && messageProvider.conversations.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (messageProvider.conversations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.messagesSquare, size: 48, color: Color(0xFF6B7280)),
              const SizedBox(height: 16),
              const Text(
                'No conversations yet',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tap the + button to start a new chat',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () async => messageProvider.refresh(),
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => messageProvider.refresh(),
      child: ListView.builder(
        itemCount: messageProvider.conversations.length,
        itemBuilder: (context, index) {
          final conversation = messageProvider.conversations[index];

          return ListTile(
            selected: _selectedConversation?.id == conversation.id,
            selectedTileColor: const Color(0xFF0EA5E9).withOpacity(0.1),
            leading: Stack(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFF0EA5E9),
                  child: Text(
                    _getInitials(conversation.name),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (conversation.isOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            title: Text(
              conversation.name,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              conversation.lastMessage.isEmpty
                  ? 'No messages yet'
                  : conversation.lastMessage,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
              ),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (conversation.lastMessageTime.isNotEmpty)
                  Text(
                    conversation.lastMessageTime,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF6B7280),
                          fontSize: 11,
                        ),
                  ),
                if (conversation.unreadCount > 0) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: const BoxDecoration(
                      color: Color(0xFF0EA5E9),
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                    child: Center(
                      child: Text(
                        '${conversation.unreadCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            onTap: () async {
              setState(() => _selectedConversation = conversation);
              await messageProvider.loadMessages(conversation.id);

              if (mounted && _scrollController.hasClients) {
                _scrollController.jumpTo(0);
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildChatView(
      MessageProvider messageProvider, Conversation conversation) {
    final messages = messageProvider.getMessages(conversation.id);

    return Column(
      children: [
        Expanded(
          child: messageProvider.isLoading && messages.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : messages.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              LucideIcons.messageCircle,
                              size: 48,
                              color: Color(0xFF6B7280),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No messages yet',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Send a message to start the conversation!',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Color(0xFF6B7280)),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      reverse: true,
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[messages.length - 1 - index];
                        return _buildMessageBubble(message);
                      },
                    ),
        ),

        // Input
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
          ),
          child: SafeArea(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 150),
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.newline,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF0EA5E9),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(LucideIcons.send, color: Colors.white),
                    onPressed: () async {
                      final text = _messageController.text.trim();
                      if (text.isEmpty) return;

                      _messageController.clear();

                      final ok =
                          await messageProvider.sendMessage(conversation.id, text);

                      if (!mounted) return;

                      if (ok) {
                        if (_scrollController.hasClients) {
                          _scrollController.animateTo(
                            0,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                          );
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(messageProvider.error ??
                                'Failed to send message'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        _messageController.text = text;
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMessageBubble(Message message) {
    final isOwn = message.isOwn;

    return Align(
      alignment: isOwn ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        decoration: BoxDecoration(
          color: isOwn ? const Color(0xFF0EA5E9) : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isOwn ? 16 : 4),
            bottomRight: Radius.circular(isOwn ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isOwn && message.sender.isNotEmpty) ...[
              Text(
                message.sender,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isOwn ? Colors.white.withOpacity(0.9) : const Color(0xFF0EA5E9),
                ),
              ),
              const SizedBox(height: 4),
            ],
            Text(
              message.content,
              style: TextStyle(
                color: isOwn ? Colors.white : const Color(0xFF111827),
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message.time,
              style: TextStyle(
                fontSize: 10,
                color: isOwn
                    ? Colors.white.withOpacity(0.7)
                    : const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}