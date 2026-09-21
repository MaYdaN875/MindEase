typedef JsonMap = Map<String, dynamic>;

JsonMap objectMap(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : {};
int supportCount(dynamic value) => value is num ? value.toInt() : 0;

class SupportPage<T> {
  final List<T> items;
  final String? nextCursor;
  final bool hasMore;

  const SupportPage({
    required this.items,
    this.nextCursor,
    required this.hasMore,
  });

  factory SupportPage.fromJson(
    JsonMap json,
    T Function(JsonMap) itemFactory,
  ) {
    final rawList = json['items'] as List? ?? [];
    return SupportPage(
      items: rawList.map((e) => itemFactory(objectMap(e))).toList(),
      nextCursor: json['nextCursor']?.toString(),
      hasMore: json['hasMore'] == true,
    );
  }
}

class SupportTicket {
  final String id;
  final int ticketNumber;
  final String subject;
  final String category;
  final String priority;
  final String status;
  final String source;
  final String? referenceType;
  final String? referenceId;
  final String? assignedToName;
  final String? assignedToId;
  final String? userName;
  final String? userEmail;
  final String? lastMessageSnippet;
  final int messagesCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? firstResponseAt;
  final DateTime? resolvedAt;
  final DateTime? closedAt;
  final List<TicketMessage> messages;
  final bool isOwner;

  SupportTicket.fromJson(JsonMap json)
      : id = json['id'] ?? '',
        ticketNumber = supportCount(json['ticketNumber']),
        subject = json['subject'] ?? '',
        category = json['category'] ?? 'OTHER',
        priority = json['priority'] ?? 'MEDIUM',
        status = json['status'] ?? 'OPEN',
        source = json['source'] ?? 'USER',
        referenceType = json['referenceType'],
        referenceId = json['referenceId'],
        assignedToName = objectMap(json['assignedTo'])['name'],
        assignedToId = objectMap(json['assignedTo'])['id'] ?? json['assignedToId'],
        userName = objectMap(json['user'])['name'],
        userEmail = objectMap(json['user'])['email'],
        lastMessageSnippet = objectMap(json['lastMessage'])['content'],
        messagesCount = supportCount(json['messagesCount'] ?? objectMap(json['_count'])['messages']),
        createdAt = DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
        updatedAt = DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
        firstResponseAt = json['firstResponseAt'] != null ? DateTime.tryParse(json['firstResponseAt']) : null,
        resolvedAt = json['resolvedAt'] != null ? DateTime.tryParse(json['resolvedAt']) : null,
        closedAt = json['closedAt'] != null ? DateTime.tryParse(json['closedAt']) : null,
        messages = (json['messages'] as List? ?? [])
            .map((m) => TicketMessage.fromJson(objectMap(m)))
            .toList(),
        isOwner = json['isOwner'] == true;
}

class TicketMessage {
  final String id;
  final String content;
  final bool isInternalNote;
  final List<String> attachments;
  final DateTime createdAt;
  final String senderId;
  final String senderName;
  final bool isStaff;
  final bool isMine;

  TicketMessage.fromJson(JsonMap json)
      : id = json['id'] ?? '',
        content = json['content'] ?? '',
        isInternalNote = json['isInternalNote'] == true,
        attachments = (json['attachments'] as List? ?? []).map((e) => e.toString()).toList(),
        createdAt = DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
        senderId = objectMap(json['sender'])['id'] ?? json['senderId'] ?? '',
        senderName = objectMap(json['sender'])['name'] ?? 'Usuario',
        isStaff = objectMap(json['sender'])['isStaff'] == true,
        isMine = json['isMine'] == true;
}

class UserReport {
  final String id;
  final String reason;
  final String description;
  final List<String> evidenceUrls;
  final String status;
  final String? reportedUserName;
  final String? reportedUserId;
  final String? reporterName;
  final String? appointmentId;
  final String? ticketId;
  final DateTime createdAt;

  UserReport.fromJson(JsonMap json)
      : id = json['id'] ?? '',
        reason = json['reason'] ?? 'OTHER',
        description = json['description'] ?? '',
        evidenceUrls = (json['evidenceUrls'] as List? ?? []).map((e) => e.toString()).toList(),
        status = json['status'] ?? 'PENDING',
        reportedUserName = objectMap(json['reportedUser'])['name'],
        reportedUserId = objectMap(json['reportedUser'])['id'] ?? json['reportedUserId'],
        reporterName = objectMap(json['reporter'])['name'],
        appointmentId = json['appointmentId'],
        ticketId = json['ticketId'],
        createdAt = DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now();
}

class SupportMetrics {
  final int totalTickets;
  final int openCount;
  final int inProgressCount;
  final int waitingUserCount;
  final int resolvedCount;
  final int closedCount;
  final int activeTicketsCount;
  final int urgentOpenCount;
  final int unassignedCount;
  final int avgFirstResponseMinutes;

  SupportMetrics.fromJson(JsonMap json)
      : totalTickets = supportCount(json['totalTickets']),
        openCount = supportCount(json['openCount']),
        inProgressCount = supportCount(json['inProgressCount']),
        waitingUserCount = supportCount(json['waitingUserCount']),
        resolvedCount = supportCount(json['resolvedCount']),
        closedCount = supportCount(json['closedCount']),
        activeTicketsCount = supportCount(json['activeTicketsCount']),
        urgentOpenCount = supportCount(json['urgentOpenCount']),
        unassignedCount = supportCount(json['unassignedCount']),
        avgFirstResponseMinutes = supportCount(json['avgFirstResponseMinutes']);
}
