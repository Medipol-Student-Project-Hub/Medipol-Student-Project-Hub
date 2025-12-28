class Conversation {
  final String id;
  final String name;
  final String? avatar;
  final String lastMessage;
  final String lastMessageTime;
  final int unreadCount;
  final bool isOnline;
  final bool isGroup;

  Conversation({
    required this.id,
    required this.name,
    this.avatar,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
    this.isOnline = false,
    this.isGroup = false,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    String displayName = '';
    String? avatarUrl;

    // Try to get name from multiple sources
    final conversationName = json['name']?.toString() ?? '';
    if (conversationName.isNotEmpty && conversationName != 'Unknown') {
      displayName = conversationName;
      avatarUrl = json['avatar']?.toString();
    }

    // If still empty, try other_participant
    if (displayName.isEmpty || displayName == 'Unknown') {
      final other = json['other_participant'];
      if (other is Map) {
        // Try nested user object first
        if (other['user'] is Map) {
          displayName = other['user']['name']?.toString() ?? '';
          avatarUrl = other['user']['profile_image']?.toString();
        }
        
        // If still empty, try direct fields
        if (displayName.isEmpty) {
          displayName = other['name']?.toString() ?? '';
        }
        if (displayName.isEmpty) {
          displayName = other['email']?.toString() ?? '';
        }
        if (avatarUrl == null) {
          avatarUrl = other['profile_image']?.toString() ?? other['avatar']?.toString();
        }
      }
    }

    // If still empty, try participants array
    if (displayName.isEmpty || displayName == 'Unknown') {
      final participants = json['participants'];
      if (participants is List && participants.isNotEmpty) {
        for (var p in participants) {
          if (p is Map) {
            final pName = p['name']?.toString() ?? 
                         p['user']?['name']?.toString() ?? 
                         p['email']?.toString() ?? '';
            if (pName.isNotEmpty) {
              displayName = pName;
              avatarUrl = p['profile_image']?.toString() ?? 
                         p['user']?['profile_image']?.toString();
              break;
            }
          }
        }
      }
    }

    // Last resort
    if (displayName.isEmpty || displayName == 'Unknown') {
      displayName = 'User ${json['id'] ?? 'Unknown'}';
    }

    // Parse last message
    final dynamic lm = json['last_message'] ?? json['lastMessage'];
    String lastMessage = '';
    String lastMessageTime = '';

    if (lm is Map<String, dynamic>) {
      lastMessage = (lm['content'] ?? '').toString();
      lastMessageTime = (lm['created_at'] ?? '').toString();
    } else if (lm is String) {
      lastMessage = lm;
    }

    if (lastMessage.isEmpty) {
      lastMessage = (json['last_message_text'] ??
              json['lastMessageText'] ??
              json['last_message_content'] ??
              '')
          .toString();
    }

    if (lastMessageTime.isEmpty) {
      lastMessageTime =
          (json['last_message_time'] ?? json['lastMessageTime'] ?? '').toString();
    }

    // Parse unread count
    final dynamic uc = json['unread_count'] ?? json['unreadCount'] ?? 0;
    final int unreadCount = uc is int ? uc : int.tryParse(uc.toString()) ?? 0;

    return Conversation(
      id: json['id'].toString(),
      name: displayName,
      avatar: avatarUrl,
      lastMessage: lastMessage,
      lastMessageTime: lastMessageTime,
      unreadCount: unreadCount,
      isOnline: (json['is_online'] ?? json['isOnline'] ?? false) == true,
      isGroup: (json['is_group'] ?? json['isGroup'] ?? false) == true,
    );
  }
}

class Message {
  final String id;
  final String conversationId;
  final String sender;
  final String content;
  final String time;
  final bool isOwn;

  Message({
    required this.id,
    required this.conversationId,
    required this.sender,
    required this.content,
    required this.time,
    required this.isOwn,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    String senderName = '';
    
    // Try sender_name first
    senderName = json['sender_name']?.toString() ?? '';
    
    // If empty, try sender object
    if (senderName.isEmpty) {
      final sender = json['sender'];
      if (sender is Map) {
        senderName = sender['name']?.toString() ?? 
                    sender['user']?['name']?.toString() ?? 
                    sender['email']?.toString() ?? '';
      } else if (sender != null) {
        senderName = sender.toString();
      }
    }
    
    // Last resort
    if (senderName.isEmpty) {
      senderName = 'User';
    }

    return Message(
      id: json['id'].toString(),
      conversationId: (json['conversation'] ?? json['conversationId'] ?? '').toString(),
      sender: senderName,
      content: (json['content'] ?? '').toString(),
      time: (json['created_at'] ?? json['time'] ?? '').toString(),
      isOwn: (json['is_own'] ?? json['isOwn'] ?? false) == true,
    );
  }
}