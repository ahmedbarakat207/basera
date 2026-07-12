import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:basera/core/utils/child_history_service.dart';
import 'package:basera/core/services/basera_database.dart';
import 'package:basera/core/models/safety_report.dart';
import 'package:basera/core/services/firebase_messaging_service.dart';

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

  FirebaseFirestore get _db => FirebaseFirestore.instance;
  FirebaseAuth get _auth => FirebaseAuth.instance;

  // ─────────────────────────────────────────────────────────────────────────
  // AUTH
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    await ChildHistoryService.instance.setUserRole(role);
    await ChildHistoryService.instance.setIsLoggedIn(true);

    if (isFirebaseAvailable) {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      ).timeout(const Duration(seconds: 15), onTimeout: () {
        throw Exception('Connection timed out. Please check your internet connection.');
      });
      final user = cred.user;
      if (user != null) {
        final Map<String, dynamic> doc = {
          'uid': user.uid,
          'name': name,
          'email': email,
          'role': role,
          'createdAt': FieldValue.serverTimestamp(),
        };
        if (role == 'child') {
          doc['visited_urls'] = [];
          doc['latest_report'] = null;
          doc['parentUid'] = null; // set later when parent links
        } else {
          doc['linked_children'] = []; // list of child UIDs
        }
        await _db.collection('users').doc(user.uid).set(doc).timeout(const Duration(seconds: 10), onTimeout: () {
          throw Exception('Database operation timed out. Please check if Firestore is enabled in your Firebase console and security rules allow writes.');
        });
        await updateFcmToken();
      }
    } else {
      debugPrint('Local-only Mode: Account simulated for $name as $role');
    }
  }

  Future<String> signIn({
    required String email,
    required String password,
  }) async {
    if (isFirebaseAvailable) {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      ).timeout(const Duration(seconds: 15), onTimeout: () {
        throw Exception('Connection timed out. Please check your internet connection.');
      });
      final user = cred.user;
      if (user != null) {
        final doc = await _db.collection('users').doc(user.uid).get().timeout(const Duration(seconds: 10), onTimeout: () {
          throw Exception('Database operation timed out. Please check if Firestore is enabled in your Firebase console.');
        });
        if (doc.exists) {
          final role = doc.data()?['role'] as String? ?? 'parent';
          await ChildHistoryService.instance.setUserRole(role);
          await ChildHistoryService.instance.setIsLoggedIn(true);
          await updateFcmToken();
          return role;
        }
      }
      await ChildHistoryService.instance.setIsLoggedIn(true);
      return 'parent';
    } else {
      final role = email.toLowerCase().contains('child') ? 'child' : 'parent';
      await ChildHistoryService.instance.setUserRole(role);
      await ChildHistoryService.instance.setIsLoggedIn(true);
      debugPrint('Local-only Mode: Signed in as $role (mock)');
      return role;
    }
  }

  Future<void> signOut() async {
    await ChildHistoryService.instance.setIsLoggedIn(false);
    if (isFirebaseAvailable) {
      await _auth.signOut();
    }
  }

  Future<void> updateFcmToken() async {
    if (!isFirebaseAvailable || currentUser == null) return;
    try {
      final token = await FirebaseMessagingService.instance.getToken();
      if (token != null) {
        await _db.collection('users').doc(currentUser!.uid).update({
          'fcmToken': token,
        });
      }
    } catch (e) {
      debugPrint('Failed to update FCM token: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PARENT ↔ CHILD LINKING
  // ─────────────────────────────────────────────────────────────────────────

  /// Links a child account to the currently signed-in parent.
  ///
  /// Strategy:
  /// 1. Sign in as child temporarily to verify credentials + get child UID.
  /// 2. Immediately restore parent session.
  /// 3. Write bidirectional link in Firestore.
  ///
  /// Throws a human-readable [Exception] on any failure.
  Future<Map<String, dynamic>> linkChildAccount({
    required String childEmail,
    required String childPassword,
  }) async {
    if (!isFirebaseAvailable) {
      // Offline mock — just return a fake linked child
      return {
        'uid': 'mock-child-id',
        'name': 'Demo Child Account',
        'email': childEmail,
        'role': 'child',
      };
    }

    final parentUser = currentUser;
    if (parentUser == null) {
      throw Exception('You must be signed in as a parent to link a child account.');
    }

    // Remember parent credentials for re-auth
    final parentUid = parentUser.uid;

    // 1. Verify child credentials using a SECONDARY Firebase App 
    // so we don't log the parent out of the main instance!
    FirebaseApp? secondaryApp;
    try {
      secondaryApp = Firebase.app('SecondaryApp');
    } catch (e) {
      secondaryApp = await Firebase.initializeApp(
        name: 'SecondaryApp',
        options: Firebase.app().options,
      );
    }
    final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

    UserCredential childCred;
    try {
      childCred = await secondaryAuth.signInWithEmailAndPassword(
        email: childEmail,
        password: childPassword,
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapAuthCode(e.code));
    }

    final childUser = childCred.user;
    if (childUser == null) {
      throw Exception('Could not retrieve child account information.');
    }

    // 2. Validate the child account has role == 'child'
    final childDoc = await _db.collection('users').doc(childUser.uid).get();
    if (!childDoc.exists) {
      await secondaryAuth.signOut();
      throw Exception('This account does not exist in Basera Safety. Ask the child to register first.');
    }
    final childData = childDoc.data()!;
    final childRole = childData['role'] as String? ?? 'parent';
    if (childRole != 'child') {
      await secondaryAuth.signOut();
      throw Exception('The account "$childEmail" is registered as a parent, not a child account.');
    }

    // 3. Check if already linked to another parent (Override for demo purposes)
    final existingParentUid = childData['parentUid'] as String?;
    if (existingParentUid != null && existingParentUid != parentUid) {
      // For this demo, we will just silently override the previous parent link 
      // instead of throwing an error, so users don't get stuck.
    }

    final childUid = childUser.uid;
    final childName = childData['name'] as String? ?? 'Child';

    // 4. Write bidirectional Firestore link (Using primary app, authenticated as Parent!)
    final batch = _db.batch();

    // Child doc: set parentUid
    batch.update(_db.collection('users').doc(childUid), {
      'parentUid': parentUid,
    });

    // Parent doc: add child UID to linked_children array
    batch.update(_db.collection('users').doc(parentUid), {
      'linked_children': FieldValue.arrayUnion([childUid]),
    });

    await batch.commit();

    // 5. Sign child out of secondary app
    await secondaryAuth.signOut();

    // 6. Persist locally so parent stays logged in after app restart
    await ChildHistoryService.instance.setUserRole('parent');
    await ChildHistoryService.instance.setIsLoggedIn(true);

    return {
      'uid': childUid,
      'name': childName,
      'email': childEmail,
      'role': 'child',
    };
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CHILDREN PROFILES
  // ─────────────────────────────────────────────────────────────────────────

  /// Fetches only the children linked to the currently signed-in parent.
  Future<List<Map<String, dynamic>>> fetchChildren() async {
    if (!isFirebaseAvailable) {
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

    final parentUser = currentUser;
    if (parentUser == null) return [];

    // Read parent's linked_children array
    final parentDoc = await _db.collection('users').doc(parentUser.uid).get();
    if (!parentDoc.exists) return [];

    final linkedUids = List<String>.from(
      parentDoc.data()?['linked_children'] ?? [],
    );
    if (linkedUids.isEmpty) return [];

    // Batch-fetch each linked child document
    final futures = linkedUids.map((uid) => _db.collection('users').doc(uid).get());
    final docs = await Future.wait(futures);

    return docs
        .where((d) => d.exists)
        .map((d) => d.data()!)
        .toList();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // URL SYNC  (child device → Firestore)
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> syncUrlVisit(String url) async {
    bool isSynced = false;

    if (isFirebaseAvailable && currentUser != null) {
      try {
        String targetUid = currentUser!.uid;
        
        // Single-device demo support: if logged in as a parent who has linked a child,
        // write the simulated web visit to the first linked child's document.
        final parentDoc = await _db.collection('users').doc(targetUid).get();
        final linked = parentDoc.data()?['linked_children'] as List?;
        if (linked != null && linked.isNotEmpty) {
           targetUid = linked.first.toString();
        }

        await _db.collection('users').doc(targetUid).update({
          'visited_urls': FieldValue.arrayUnion([url]),
        });
        isSynced = true;
      } catch (e) {
        debugPrint('Firestore upload failed: $e. Queued in SQLite.');
      }
    }

    await BaseraDatabase.instance.insertUrl(url, isSynced: isSynced);
  }

  Future<void> syncUrlVisitDirect(String url) async {
    if (isFirebaseAvailable && currentUser != null) {
      String targetUid = currentUser!.uid;
      final parentDoc = await _db.collection('users').doc(targetUid).get();
      final linked = parentDoc.data()?['linked_children'] as List?;
      if (linked != null && linked.isNotEmpty) {
         targetUid = linked.first.toString();
      }
      
      await _db.collection('users').doc(targetUid).update({
        'visited_urls': FieldValue.arrayUnion([url]),
      });
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SAFETY REPORT SYNC
  // ─────────────────────────────────────────────────────────────────────────

  /// Saves the AI safety report to the CHILD's Firestore doc (so the parent
  /// stream picks it up) and also locally.
  Future<void> syncSafetyReport(String childUid, SafetyReport report) async {
    // Always save locally first
    await ChildHistoryService.instance.saveReport(report);

    if (isFirebaseAvailable) {
      await _db.collection('users').doc(childUid).update({
        'latest_report': report.toJson(),
      });
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // REAL-TIME STREAMS  (parent device reads child's Firestore doc)
  // ─────────────────────────────────────────────────────────────────────────

  Stream<List<String>> streamChildUrls(String childUid) {
    if (isFirebaseAvailable) {
      return _db
          .collection('users')
          .doc(childUid)
          .snapshots()
          .map((snap) {
            if (!snap.exists) return <String>[];
            final list = snap.data()?['visited_urls'] as List? ?? [];
            return list.cast<String>();
          });
    }
    return Stream.fromFuture(ChildHistoryService.instance.getVisitedUrls());
  }

  Stream<SafetyReport?> streamChildReport(String childUid) {
    if (isFirebaseAvailable) {
      return _db
          .collection('users')
          .doc(childUid)
          .snapshots()
          .map((snap) {
            if (!snap.exists) return null;
            final reportData = snap.data()?['latest_report'] as Map<String, dynamic>?;
            if (reportData == null) return null;
            return SafetyReport.fromJson(reportData);
          });
    }
    return Stream.fromFuture(ChildHistoryService.instance.getLatestReport());
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────────────────────

  String _mapAuthCode(String code) {
    switch (code) {
      case 'user-not-found':
      case 'invalid-credential':
        return 'Incorrect child email or password.';
      case 'wrong-password':
        return 'The child password is incorrect.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please wait a moment and try again.';
      case 'network-request-failed':
        return 'Network error. Check your internet connection.';
      default:
        return 'Could not verify child credentials ($code).';
    }
  }
}
