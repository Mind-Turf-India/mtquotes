import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mtquotes/screens/User_Home/components/Resume/resume_data.dart';

class ResumeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Add this method to get the user ID
  String get userId {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not authenticated");
    return user.email!.replaceAll('.', '_');
  }

  // Save resume data to Firestore
  Future<String> saveResume(ResumeData resumeData) async {
    try {
      // Create a new document reference with auto-generated ID
      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('resume')
          .doc();

      // Set the document data
      await docRef.set(resumeData.toMap());

      return docRef.id; // Return the new document ID
    } catch (e) {
      print('Error saving resume: $e');
      throw e;
    }
  }

  // Update an existing resume
  Future<void> updateResume(String resumeId, ResumeData resumeData) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('resume')
          .doc(resumeId)
          .update(resumeData.toMap());
    } catch (e) {
      print('Error updating resume: $e');
      throw e;
    }
  }

  // Get a list of all resumes for the current user
  Future<List<ResumeData>> getAllResumes() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('resume')
          .orderBy('updatedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ResumeData.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting resumes: $e');
      throw e;
    }
  }

  // Get a specific resume by ID
  Future<ResumeData> getResume(String resumeId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('resume')
          .doc(resumeId)
          .get();

      if (!doc.exists) {
        throw Exception('Resume not found');
      }

      return ResumeData.fromMap(doc.data()!);
    } catch (e) {
      print('Error getting resume: $e');
      throw e;
    }
  }

  // Delete a resume
  Future<void> deleteResume(String resumeId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('resume')
          .doc(resumeId)
          .delete();
    } catch (e) {
      print('Error deleting resume: $e');
      throw e;
    }
  }
}