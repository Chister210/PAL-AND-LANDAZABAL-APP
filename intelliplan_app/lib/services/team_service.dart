import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';
import '../models/team.dart';
import 'notification_service.dart';

class TeamService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<Team> _userTeams = [];
  List<Team> get userTeams => _userTeams;
  
  /// Generate a unique 6-character invite code
  String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // Removed ambiguous chars
    final random = Random();
    return List.generate(6, (index) => chars[random.nextInt(chars.length)]).join();
  }

  /// Create a new team
  Future<Team> createTeam({
    required String name,
    required String description,
    required String ownerId,
    required String ownerName,
    required String ownerEmail,
  }) async {
    try {
      final teamId = _firestore.collection('teams').doc().id;
      final inviteCode = _generateInviteCode();
      
      final owner = TeamMember(
        userId: ownerId,
        name: ownerName,
        email: ownerEmail,
        role: 'owner',
        joinedAt: DateTime.now(),
      );

      final team = Team(
        id: teamId,
        name: name,
        description: description,
        ownerId: ownerId,
        ownerName: ownerName,
        members: [owner],
        createdAt: DateTime.now(),
        inviteCode: inviteCode,
      );

      final teamData = team.toJson();
      teamData['memberIds'] = [ownerId]; // Add array of member IDs for querying
      
      await _firestore.collection('teams').doc(teamId).set(teamData);
      
      // Create invite record
      final invite = TeamInvite(
        id: _firestore.collection('team_invites').doc().id,
        teamId: teamId,
        teamName: name,
        inviteCode: inviteCode,
        createdBy: ownerId,
        createdByName: ownerName,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 30)),
      );
      
      await _firestore.collection('team_invites').doc(invite.id).set(invite.toJson());
      
      debugPrint('✅ Team created: $name (Code: $inviteCode)');
      return team;
    } catch (e) {
      debugPrint('❌ Error creating team: $e');
      rethrow;
    }
  }

  /// Join a team using an invite code
  Future<void> joinTeamByCode({
    required String inviteCode,
    required String userId,
    required String userName,
    required String userEmail,
  }) async {
    try {
      // Find the invite
      final inviteSnapshot = await _firestore
          .collection('team_invites')
          .where('inviteCode', isEqualTo: inviteCode.toUpperCase())
          .limit(1)
          .get();

      if (inviteSnapshot.docs.isEmpty) {
        throw 'Invalid invite code';
      }

      final inviteData = inviteSnapshot.docs.first.data();
      final invite = TeamInvite.fromJson({...inviteData, 'id': inviteSnapshot.docs.first.id});

      if (!invite.isValid) {
        throw 'This invite has expired or reached max uses';
      }

      final teamId = invite.teamId;

      // Check if user is already a member
      final teamDoc = await _firestore.collection('teams').doc(teamId).get();
      if (!teamDoc.exists) {
        throw 'Team not found';
      }

      final teamData = teamDoc.data()!;
      final team = Team.fromJson({...teamData, 'id': teamDoc.id});

      if (team.members.any((m) => m.userId == userId)) {
        throw 'You are already a member of this team';
      }

      // Add user to team
      final newMember = TeamMember(
        userId: userId,
        name: userName,
        email: userEmail,
        role: 'member',
        joinedAt: DateTime.now(),
      );

      await _firestore.collection('teams').doc(teamId).update({
        'members': FieldValue.arrayUnion([newMember.toJson()]),
        'memberIds': FieldValue.arrayUnion([userId]),
      });

      // Increment invite uses
      await _firestore.collection('team_invites').doc(invite.id).update({
        'currentUses': FieldValue.increment(1),
      });

      debugPrint('✅ User $userName joined team ${team.name}');
    } catch (e) {
      debugPrint('❌ Error joining team: $e');
      rethrow;
    }
  }

  /// Generate a new invite for a team
  Future<TeamInvite> createInvite({
    required String teamId,
    required String createdBy,
    required String createdByName,
    int daysValid = 30,
  }) async {
    try {
      final teamDoc = await _firestore.collection('teams').doc(teamId).get();
      if (!teamDoc.exists) {
        throw 'Team not found';
      }

      final teamData = teamDoc.data()!;
      final inviteCode = _generateInviteCode();

      final invite = TeamInvite(
        id: _firestore.collection('team_invites').doc().id,
        teamId: teamId,
        teamName: teamData['name'] ?? 'Unknown Team',
        inviteCode: inviteCode,
        createdBy: createdBy,
        createdByName: createdByName,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(Duration(days: daysValid)),
      );

      await _firestore.collection('team_invites').doc(invite.id).set(invite.toJson());

      // Update team with latest invite code
      await _firestore.collection('teams').doc(teamId).update({
        'inviteCode': inviteCode,
      });

      debugPrint('✅ Invite created: $inviteCode');
      return invite;
    } catch (e) {
      debugPrint('❌ Error creating invite: $e');
      rethrow;
    }
  }

  /// Get teams for a specific user
  Stream<List<Team>> getUserTeams(String userId) {
    return _firestore
        .collection('teams')
        .where('memberIds', arrayContains: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Team.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  /// Get a specific team by ID
  Future<Team?> getTeamById(String teamId) async {
    try {
      final doc = await _firestore.collection('teams').doc(teamId).get();
      if (doc.exists) {
        return Team.fromJson({...doc.data()!, 'id': doc.id});
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error getting team: $e');
      return null;
    }
  }

  /// Get team tasks (tasks where isTeamTask = true and teamId matches)
  Stream<QuerySnapshot> getTeamTasks(String teamId) {
    return _firestore
        .collection('tasks')
        .where('teamId', isEqualTo: teamId)
        .where('isTeamTask', isEqualTo: true)
        .snapshots();
  }

  /// Add a team task
  Future<void> addTeamTask({
    required String teamId,
    required String userId,
    required String title,
    required String subject,
    String priority = 'medium',
    DateTime? dueDate,
    String? notes,
  }) async {
    try {
      final taskId = _firestore.collection('tasks').doc().id;
      
      await _firestore.collection('tasks').doc(taskId).set({
        'id': taskId,
        'teamId': teamId,
        'userId': userId,
        'title': title,
        'subject': subject,
        'priority': priority,
        'status': 'pending',
        'dueDate': dueDate != null ? Timestamp.fromDate(dueDate) : null,
        'notes': notes ?? '',
        'isTeamTask': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Team task added: $title');
    } catch (e) {
      debugPrint('❌ Error adding team task: $e');
      rethrow;
    }
  }

  /// Remove a user from a team
  Future<void> removeFromTeam({
    required String teamId,
    required String userId,
    required String requesterId,
    String? reason,
  }) async {
    try {
      final teamDoc = await _firestore.collection('teams').doc(teamId).get();
      if (!teamDoc.exists) {
        throw 'Team not found';
      }

      final team = Team.fromJson({...teamDoc.data()!, 'id': teamDoc.id});
      
      // Only owner or admins can remove members
      final requester = team.members.firstWhere(
        (m) => m.userId == requesterId,
        orElse: () => throw 'You are not a member of this team',
      );

      if (requester.role != 'owner' && requester.role != 'admin') {
        throw 'You do not have permission to remove members';
      }

      // Cannot remove the owner
      final targetMember = team.members.firstWhere(
        (m) => m.userId == userId,
        orElse: () => throw 'User not found in team',
      );

      if (targetMember.role == 'owner') {
        throw 'Cannot remove the team owner';
      }

      // Remove member from team (both members array and memberIds array)
      await _firestore.collection('teams').doc(teamId).update({
        'members': FieldValue.arrayRemove([targetMember.toJson()]),
        'memberIds': FieldValue.arrayRemove([userId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Delete all team tasks assigned to the removed member
      final tasksSnapshot = await _firestore
          .collection('tasks')
          .where('teamId', isEqualTo: teamId)
          .where('assignedTo', isEqualTo: userId)
          .get();

      final batch = _firestore.batch();
      for (var doc in tasksSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      debugPrint('✅ User removed from team and ${tasksSnapshot.docs.length} tasks deleted');

      // Send notification to removed user with reason
      if (reason != null && reason.isNotEmpty) {
        final notificationService = NotificationService();
        await notificationService.sendMemberRemovedNotification(
          userId: userId,
          teamName: team.name,
          reason: reason,
        );
        debugPrint('✅ Removal notification sent to user');
      }
    } catch (e) {
      debugPrint('❌ Error removing from team: $e');
      rethrow;
    }
  }

  /// Delete a team (owner only)
  Future<void> deleteTeam({
    required String teamId,
    required String userId,
  }) async {
    try {
      final teamDoc = await _firestore.collection('teams').doc(teamId).get();
      if (!teamDoc.exists) {
        throw 'Team not found';
      }

      final team = Team.fromJson({...teamDoc.data()!, 'id': teamDoc.id});

      if (team.ownerId != userId) {
        throw 'Only the team owner can delete the team';
      }

      // Delete all team tasks
      final tasksSnapshot = await _firestore
          .collection('tasks')
          .where('teamId', isEqualTo: teamId)
          .get();

      for (var doc in tasksSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete all invites
      final invitesSnapshot = await _firestore
          .collection('team_invites')
          .where('teamId', isEqualTo: teamId)
          .get();

      for (var doc in invitesSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete team
      await _firestore.collection('teams').doc(teamId).delete();

      debugPrint('✅ Team deleted');
    } catch (e) {
      debugPrint('❌ Error deleting team: $e');
      rethrow;
    }
  }

  /// Update team info
  Future<void> updateTeam({
    required String teamId,
    required String userId,
    String? name,
    String? description,
  }) async {
    try {
      final teamDoc = await _firestore.collection('teams').doc(teamId).get();
      if (!teamDoc.exists) {
        throw 'Team not found';
      }

      final team = Team.fromJson({...teamDoc.data()!, 'id': teamDoc.id});
      
      final member = team.members.firstWhere(
        (m) => m.userId == userId,
        orElse: () => throw 'You are not a member of this team',
      );

      if (member.role != 'owner' && member.role != 'admin') {
        throw 'You do not have permission to update team info';
      }

      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (description != null) updates['description'] = description;

      if (updates.isNotEmpty) {
        await _firestore.collection('teams').doc(teamId).update(updates);
        debugPrint('✅ Team updated');
      }
    } catch (e) {
      debugPrint('❌ Error updating team: $e');
      rethrow;
    }
  }
}
