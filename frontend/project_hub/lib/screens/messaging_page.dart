import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../providers/message_provider.dart';
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

  @override
  void initState() {
    super.initState();

    // Load conversations once after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<MessageProvider>();
      await provider.loadConversations();
    });
  }

  @override
  Widget build(BuildContext context) {
    final messageProvider = context.watch<MessageProvider>();
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    // Optional: show error as a small banner/snackbar-like bar
    final errorWidget = (messageProvider.error != null && messageProvider.error!.isNotEmpty)
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
        floatingActionButton: _buildNewConversationFab(messageProvider),
      );
    }

    // Mobile Layout
    if (_selectedConversation == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Messages'),
          actions: [
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
        floatingActionButton: _buildNewConversationFab(messageProvider),
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
              (_selectedConversation!.name.isNotEmpty ? _selectedConversation!.name[0] : '?'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
          title: Text(
            _selectedConversation!.name,
            style: const TextStyle(fontSize: 16),
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

  FloatingActionButton _buildNewConversationFab(MessageProvider messageProvider) {
    return FloatingActionButton(
      onPressed: () async {
        final createdConversation = await Navigator.push<Conversation?>(
          context,
          MaterialPageRoute(builder: (_) => const NewConversationPage()),
        );

        if (!mounted) return;

        if (createdConversation != null) {
          setState(() => _selectedConversation = createdConversation);

          // load messages so it isn't empty
          await messageProvider.loadMessages(createdConversation.id);

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Conversation started: ${createdConversation.name}')),
          );
        } else {
          // if nothing created, do nothing
        }
      },
      child: const Icon(LucideIcons.plus),
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
              const Icon(LucideIcons.messagesSquare, size: 40),
              const SizedBox(height: 12),
              const Text(
                'No conversations yet.',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              const Text(
                'Tap + to start a new chat.',
                textAlign: TextAlign.center,
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
            leading: Stack(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF0EA5E9),
                  child: Text(
                    conversation.name.isNotEmpty ? conversation.name[0] : '?',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                if (conversation.isOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
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
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              conversation.lastMessage,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  conversation.lastMessageTime,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF6B7280),
                      ),
                ),
                if (conversation.unreadCount > 0) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Color(0xFF0EA5E9),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${conversation.unreadCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            onTap: () async {
              setState(() => _selectedConversation = conversation);

              // IMPORTANT: load messages from API so chat isn't empty
              await messageProvider.loadMessages(conversation.id);
            },
          );
        },
      ),
    );
  }

  Widget _buildChatView(MessageProvider messageProvider, Conversation conversation) {
    final messages = messageProvider.getMessages(conversation.id);

    return Column(
      children: [
        Expanded(
          child: messageProvider.isLoading && messages.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : messages.isEmpty
                  ? const Center(child: Text('No messages yet.'))
                  : ListView.builder(
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
          child: Row(
            children: [
              IconButton(
                icon: const Icon(LucideIcons.paperclip),
                onPressed: () {},
              ),
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: null,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(LucideIcons.send),
                onPressed: () async {
                  final text = _messageController.text.trim();
                  if (text.isEmpty) return;

                  final ok = await messageProvider.sendMessage(conversation.id, text);

                  if (!mounted) return;

                  if (ok) {
                    _messageController.clear();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(messageProvider.error ?? 'Failed to send message')),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessageBubble(Message message) {
    return Align(
      alignment: message.isOwn ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        decoration: BoxDecoration(
          color: message.isOwn ? const Color(0xFF0EA5E9) : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!message.isOwn) ...[
              Text(
                message.sender,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
            ],
            Text(
              message.content,
              style: TextStyle(
                color: message.isOwn ? Colors.white : const Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message.time,
              style: TextStyle(
                fontSize: 10,
                color: message.isOwn
                    ? const Color.fromRGBO(255, 255, 255, 0.7)
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
    super.dispose();
  }
}
