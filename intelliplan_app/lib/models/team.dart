import 'package:cloud_firestore/cloud_firestore.dart';

class Team {
  final String id;
  final String name;
  final String description;
  final String ownerId;
  final String ownerName;
  final List<TeamMember> members;
  final DateTime createdAt;
  final String? inviteCode;

  Team({
    required this.id,
    required this.name,
    required this.description,
    required this.ownerId,
    required this.ownerName,
    required this.members,
    required this.createdAt,
    this.inviteCode,
  });

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      ownerId: json['ownerId'] ?? '',
      ownerName: json['ownerName'] ?? 'Unknown',
      members: (json['members'] as List<dynamic>?)
              ?.map((m) => TeamMember.fromJson(m as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      inviteCode: json['inviteCode'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'members': members.map((m) => m.toJson()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'inviteCode': inviteCode,
    };
  }

  Team copyWith({
    String? id,
    String? name,
    String? description,
    String? ownerId,
    String? ownerName,
    List<TeamMember>? members,
    DateTime? createdAt,
    String? inviteCode,
  }) {
    return Team(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      members: members ?? this.members,
      createdAt: createdAt ?? this.createdAt,
      inviteCode: inviteCode ?? this.inviteCode,
    );
  }
}

class TeamMember {
  final String userId;
  final String name;
  final String email;
  final String role; // 'owner', 'admin', 'member'
  final DateTime joinedAt;

  TeamMember({
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
    required this.joinedAt,
  });

  factory TeamMember.fromJson(Map<String, dynamic> json) {
    return TeamMember(
      userId: json['userId'] ?? '',
      name: json['name'] ?? 'Unknown',
      email: json['email'] ?? '',
      role: json['role'] ?? 'member',
      joinedAt: (json['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'role': role,
      'joinedAt': Timestamp.fromDate(joinedAt),
    };
  }

  TeamMember copyWith({
    String? userId,
    String? name,
    String? email,
    String? role,
    DateTime? joinedAt,
  }) {
    return TeamMember(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }
}

class TeamInvite {
  final String id;
  final String teamId;
  final String teamName;
  final String inviteCode;
  final String createdBy;
  final String createdByName;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool isActive;
  final int maxUses;
  final int currentUses;

  TeamInvite({
    required this.id,
    required this.teamId,
    required this.teamName,
    required this.inviteCode,
    required this.createdBy,
    required this.createdByName,
    required this.createdAt,
    required this.expiresAt,
    this.isActive = true,
    this.maxUses = 50,
    this.currentUses = 0,
  });

  factory TeamInvite.fromJson(Map<String, dynamic> json) {
    return TeamInvite(
      id: json['id'] ?? '',
      teamId: json['teamId'] ?? '',
      teamName: json['teamName'] ?? '',
      inviteCode: json['inviteCode'] ?? '',
      createdBy: json['createdBy'] ?? '',
      createdByName: json['createdByName'] ?? 'Unknown',
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (json['expiresAt'] as Timestamp?)?.toDate() ?? DateTime.now().add(const Duration(days: 7)),
      isActive: json['isActive'] ?? true,
      maxUses: json['maxUses'] ?? 50,
      currentUses: json['currentUses'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'teamId': teamId,
      'teamName': teamName,
      'inviteCode': inviteCode,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'isActive': isActive,
      'maxUses': maxUses,
      'currentUses': currentUses,
    };
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isValid => isActive && !isExpired && currentUses < maxUses;

  TeamInvite copyWith({
    String? id,
    String? teamId,
    String? teamName,
    String? inviteCode,
    String? createdBy,
    String? createdByName,
    DateTime? createdAt,
    DateTime? expiresAt,
    bool? isActive,
    int? maxUses,
    int? currentUses,
  }) {
    return TeamInvite(
      id: id ?? this.id,
      teamId: teamId ?? this.teamId,
      teamName: teamName ?? this.teamName,
      inviteCode: inviteCode ?? this.inviteCode,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isActive: isActive ?? this.isActive,
      maxUses: maxUses ?? this.maxUses,
      currentUses: currentUses ?? this.currentUses,
    );
  }
}
