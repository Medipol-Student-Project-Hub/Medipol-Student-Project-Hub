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
    // Backend’te last_message bazen Map, bazen String/null gelebiliyor.
    final dynamic lm = json['last_message'] ?? json['lastMessage'];

    String lastMessage = '';
    String lastMessageTime = '';

    if (lm is Map<String, dynamic>) {
      lastMessage = (lm['content'] ?? '').toString();
      lastMessageTime = (lm['created_at'] ?? '').toString();
    } else if (lm is String) {
      lastMessage = lm;
    }

    // Bazı backend cevaplarında ayrı alanlar da olabiliyor
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

    // unreadCount bazen string gibi gelebilir
    final dynamic uc = json['unread_count'] ?? json['unreadCount'] ?? 0;
    final int unreadCount = uc is int ? uc : int.tryParse(uc.toString()) ?? 0;

    return Conversation(
      id: json['id'].toString(),
      name: (json['name'] ?? 'Unknown').toString(),
      avatar: json['avatar']?.toString(),
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
    // sender bazen obje bazen string gelebilir
    final dynamic s = json['sender'];
    String senderName = 'Unknown';
    if (s is Map<String, dynamic>) {
      senderName = (s['name'] ?? s['email'] ?? 'Unknown').toString();
    } else if (s is String) {
      senderName = s;
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
