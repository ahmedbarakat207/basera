import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:basera/core/utils/child_history_service.dart';
import 'package:basera/core/utils/groq_client.dart';
import 'package:basera/core/services/basera_database.dart';

class FirebaseBackendService {
  static final FirebaseBackendService instance = FirebaseBackendService._internal();
  FirebaseBackendService._internal();

  bool get isFirebaseAvailable {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  User? get currentUser {
    if (!isFirebaseAvailable) return null;
    return FirebaseAuth.instance.currentUser;
  }

  // Sign Up
  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    // Save locally first
    await ChildHistoryService.instance.setUserRole(role);
    await ChildHistoryService.instance.setIsLoggedIn(true);

    if (isFirebaseAvailable) {
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user != null) {
        // Create Firestore profile
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': name,
          'email': email,
          'role': role,
          'visited_urls': role == 'child' ? [] : null,
          'latest_report': null,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } else {
      debugPrint('Local-only Mode: Account simulated for $name as $role');
    }
  }

  // Sign In
  Future<String> signIn({
    required String email,
    required String password,
  }) async {
    if (isFirebaseAvailable) {
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user != null) {
        // Fetch role from Firestore
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists) {
          final role = doc.data()?['role'] as String? ?? 'parent';
          await ChildHistoryService.instance.setUserRole(role);
          await ChildHistoryService.instance.setIsLoggedIn(true);
          return role;
        }
      }
      await ChildHistoryService.instance.setIsLoggedIn(true);
      return 'parent';
    } else {
      // Mock login for offline testing: if email starts with child, assume child role
      final role = email.toLowerCase().contains('child') ? 'child' : 'parent';
      await ChildHistoryService.instance.setUserRole(role);
      await ChildHistoryService.instance.setIsLoggedIn(true);
      debugPrint('Local-only Mode: Signed in as $role (mock)');
      return role;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await ChildHistoryService.instance.setIsLoggedIn(false);
    if (isFirebaseAvailable) {
      await FirebaseAuth.instance.signOut();
    }
  }

  // Sync Child Visited URL
  Future<void> syncUrlVisit(String url) async {
    bool isSynced = false;

    if (isFirebaseAvailable && currentUser != null) {
      try {
        final uid = currentUser!.uid;
        // Append to visited_urls array in Firestore
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'visited_urls': FieldValue.arrayUnion([url]),
        });
        isSynced = true;
      } catch (e) {
        debugPrint('Firebase Firestore upload failed: $e. Saved to local SQLite queue.');
      }
    }

    // Save locally in SQLite Database
    await BaseraDatabase.instance.insertUrl(url, isSynced: isSynced);
  }

  // Direct sync from local SQLite queue (used by background SyncService)
  Future<void> syncUrlVisitDirect(String url) async {
    if (isFirebaseAvailable && currentUser != null) {
      final uid = currentUser!.uid;
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'visited_urls': FieldValue.arrayUnion([url]),
      });
    }
  }

  // Fetch children profiles from Firestore (for parent view selection)
  Future<List<Map<String, dynamic>>> fetchChildren() async {
    if (isFirebaseAvailable) {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'child')
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } else {
      // Offline mock child selection
      return [
        {
          'uid': 'mock-child-id',
          'name': 'Demo Child Account',
          'email': 'child@demo.com',
          'role': 'child',
          'visited_urls': await ChildHistoryService.instance.getVisitedUrls(),
        }
      ];
    }
  }

  // Sync safety report back to Firestore under the child's account profile
  Future<void> syncSafetyReport(String childUid, SafetyReport report) async {
    // Save report locally
    await ChildHistoryService.instance.saveReport(report);

    if (isFirebaseAvailable) {
      await FirebaseFirestore.instance.collection('users').doc(childUid).update({
        'latest_report': report.toJson(),
      });
    }
  }

  // Stream visited URLs for a specific child
  Stream<List<String>> streamChildUrls(String childUid) {
    if (isFirebaseAvailable) {
      return FirebaseFirestore.instance
          .collection('users')
          .doc(childUid)
          .snapshots()
          .map((snapshot) {
            if (!snapshot.exists) return [];
            final data = snapshot.data();
            final list = data?['visited_urls'] as List? ?? [];
            return list.cast<String>();
          });
    } else {
      // Mock stream for offline mode
      return Stream.fromFuture(ChildHistoryService.instance.getVisitedUrls());
    }
  }

  // Stream safety report for a specific child
  Stream<SafetyReport?> streamChildReport(String childUid) {
    if (isFirebaseAvailable) {
      return FirebaseFirestore.instance
          .collection('users')
          .doc(childUid)
          .snapshots()
          .map((snapshot) {
            if (!snapshot.exists) return null;
            final data = snapshot.data();
            final reportData = data?['latest_report'] as Map<String, dynamic>?;
            if (reportData == null) return null;
            return SafetyReport.fromJson(reportData);
          });
    } else {
      // Mock stream for offline mode
      return Stream.fromFuture(ChildHistoryService.instance.getLatestReport());
    }
  }
}
