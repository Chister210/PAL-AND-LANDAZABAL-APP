import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/subject.dart';

class SubjectService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _currentUserId;
  
  List<Subject> _subjects = [];
  List<Subject> get subjects => _subjects;
  
  void initializeForUser(String userId) {
    _currentUserId = userId;
    _loadSubjects();
  }

  void _loadSubjects() async {
    if (_currentUserId == null) return;
    
    try {
      // Use real-time listener to automatically update when subjects change
      _firestore
          .collection('subjects')
          .where('userId', isEqualTo: _currentUserId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .listen((snapshot) {
        _subjects = snapshot.docs
            .map((doc) => Subject.fromJson(doc.data()))
            .toList();
        
        notifyListeners();
      });
    } catch (e) {
      debugPrint('Error loading subjects: $e');
    }
  }

  Future<void> addSubject(Subject subject) async {
    try {
      await _firestore
          .collection('subjects')
          .doc(subject.id)
          .set(subject.toJson());
      
      _subjects.insert(0, subject);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding subject: $e');
      rethrow;
    }
  }

  Future<void> updateSubject(Subject subject) async {
    try {
      await _firestore
          .collection('subjects')
          .doc(subject.id)
          .update(subject.toJson());
      
      final index = _subjects.indexWhere((s) => s.id == subject.id);
      if (index != -1) {
        _subjects[index] = subject;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating subject: $e');
      rethrow;
    }
  }

  Future<void> deleteSubject(String subjectId) async {
    try {
      await _firestore
          .collection('subjects')
          .doc(subjectId)
          .delete();
      
      _subjects.removeWhere((s) => s.id == subjectId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting subject: $e');
      rethrow;
    }
  }

  Future<void> attachFiles(String subjectId, List<SubjectFile> newFiles) async {
    try {
      final subject = _subjects.firstWhere((s) => s.id == subjectId);
      final updatedFiles = [...subject.files, ...newFiles];
      final updatedSubject = subject.copyWith(
        files: updatedFiles,
        updatedAt: DateTime.now(),
      );
      
      await updateSubject(updatedSubject);
    } catch (e) {
      debugPrint('Error attaching files: $e');
      rethrow;
    }
  }

  Future<void> removeFile(String subjectId, String fileName) async {
    try {
      final subject = _subjects.firstWhere((s) => s.id == subjectId);
      final updatedFiles = subject.files.where((f) => f.name != fileName).toList();
      final updatedSubject = subject.copyWith(
        files: updatedFiles,
        updatedAt: DateTime.now(),
      );
      
      await updateSubject(updatedSubject);
    } catch (e) {
      debugPrint('Error removing file: $e');
      rethrow;
    }
  }
}
