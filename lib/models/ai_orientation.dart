class AIMessage {
  final String id;
  final String role; // 'USER' | 'ASSISTANT'
  final String content;
  final DateTime createdAt;

  AIMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
  });

  factory AIMessage.fromJson(Map<String, dynamic> json) {
    return AIMessage(
      id: json['id']?.toString() ?? '',
      role: json['role']?.toString().toUpperCase() ?? 'ASSISTANT',
      content: json['content']?.toString() ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  bool get isUser => role == 'USER';
}

class CrisisResource {
  final String name;
  final String phone;
  final String? url;
  final String? description;
  final String type;

  CrisisResource({
    required this.name,
    required this.phone,
    this.url,
    this.description,
    required this.type,
  });

  factory CrisisResource.fromJson(Map<String, dynamic> json) {
    return CrisisResource(
      name: json['name']?.toString() ?? 'Línea de Ayuda',
      phone: json['phone']?.toString() ?? '911',
      url: json['url']?.toString(),
      description: json['description']?.toString(),
      type: json['type']?.toString() ?? 'GENERAL',
    );
  }
}

class SuggestedSpecialty {
  final String id;
  final String name;
  final String reason;

  SuggestedSpecialty({
    required this.id,
    required this.name,
    required this.reason,
  });

  factory SuggestedSpecialty.fromJson(Map<String, dynamic> json) {
    return SuggestedSpecialty(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      reason: json['reason']?.toString() ?? '',
    );
  }
}

class RecommendedPsychologistItem {
  final String id;
  final String userId;
  final String name;
  final String? academicBackground;
  final String? photoUrl;
  final int consultationPrice;
  final double score;
  final List<String> matchReasons;
  final List<String> specialties;

  RecommendedPsychologistItem({
    required this.id,
    required this.userId,
    required this.name,
    this.academicBackground,
    this.photoUrl,
    required this.consultationPrice,
    required this.score,
    required this.matchReasons,
    required this.specialties,
  });

  factory RecommendedPsychologistItem.fromJson(Map<String, dynamic> json) {
    final reasons = (json['matchReasons'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    final specs = (json['specialties'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    return RecommendedPsychologistItem(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Psicólogo Verificado',
      academicBackground: json['academicBackground']?.toString(),
      photoUrl: json['photoUrl']?.toString(),
      consultationPrice: (json['consultationPrice'] as num?)?.toInt() ?? 500,
      score: (json['score'] as num?)?.toDouble() ?? 50.0,
      matchReasons: reasons,
      specialties: specs,
    );
  }
}

class AIOrientationSession {
  final String id;
  final String status; // 'ACTIVE' | 'COMPLETED' | 'ESCALATED' | 'CANCELLED'
  final String riskLevel; // 'LOW' | 'MODERATE' | 'HIGH' | 'EMERGENCY'
  final String? summary;
  final DateTime startedAt;
  final DateTime? completedAt;
  final List<AIMessage> messages;

  AIOrientationSession({
    required this.id,
    required this.status,
    required this.riskLevel,
    this.summary,
    required this.startedAt,
    this.completedAt,
    required this.messages,
  });

  factory AIOrientationSession.fromJson(Map<String, dynamic> json) {
    final msgs = (json['messages'] as List<dynamic>?)
            ?.map((m) => AIMessage.fromJson(m as Map<String, dynamic>))
            .toList() ??
        [];

    return AIOrientationSession(
      id: json['id']?.toString() ?? '',
      status: json['status']?.toString() ?? 'ACTIVE',
      riskLevel: json['riskLevel']?.toString() ?? 'LOW',
      summary: json['summary']?.toString(),
      startedAt: json['startedAt'] != null
          ? DateTime.tryParse(json['startedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'].toString())
          : null,
      messages: msgs,
    );
  }

  bool get isComplete => status == 'COMPLETED';
  bool get isEscalated => status == 'ESCALATED' || riskLevel == 'HIGH' || riskLevel == 'EMERGENCY';
}
