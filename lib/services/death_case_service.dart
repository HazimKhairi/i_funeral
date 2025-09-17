import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/death_case_model.dart';
import '../models/enums.dart';
import 'firebase_cloud_messaging_service.dart';

class DeathCaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create new death case
  Future<String> createDeathCase(DeathCaseModel deathCase) async {
    try {
      print('📝 Creating new death case: ${deathCase.fullName}');
      
      // Create death case document
      final docRef = await _firestore
          .collection('death_cases')
          .add(deathCase.toMap());
      
      // Update document with its ID
      await docRef.update({'id': docRef.id});
      
      print('✅ Death case created with ID: ${docRef.id}');
      
      // 🚀 NEW: Send notification to ALL STAFF using Firebase Cloud Messaging
      await FirebaseCloudMessagingService.notifyStaffNewCase(
        caseName: deathCase.fullName,
        caseId: docRef.id,
        serviceType: deathCase.serviceType,
      );
      
      print('📡 FCM notification sent to ALL STAFF for case: ${deathCase.fullName}');
      
      return docRef.id;
    } catch (e) {
      print('❌ Failed to create death case: $e');
      throw Exception('Failed to create death case: ${e.toString()}');
    }
  }

  // Get death cases for waris
  Stream<List<DeathCaseModel>> getWarisDeathCases(String warisId) {
    return _firestore
        .collection('death_cases')
        .where('warisId', isEqualTo: warisId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => DeathCaseModel.fromFirestore(doc))
          .toList();
    });
  }

  // Get pending death cases for staff (new requests)
  Stream<List<DeathCaseModel>> getPendingDeathCases() {
    return _firestore
        .collection('death_cases')
        .where('status', isEqualTo: CaseStatus.pending.value)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => DeathCaseModel.fromFirestore(doc))
          .toList();
    });
  }

  // Get cases handled by specific staff (history)
  Stream<List<DeathCaseModel>> getStaffHandledCases(String staffId) {
    return _firestore
        .collection('death_cases')
        .where('staffId', isEqualTo: staffId)
        .orderBy('acceptedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => DeathCaseModel.fromFirestore(doc))
          .toList();
    });
  }

  // Accept death case (for staff)
  Future<void> acceptDeathCase(String caseId, String staffId) async {
    try {
      print('✅ Staff accepting case: $caseId');
      
      // Get the case data first
      final caseDoc = await _firestore.collection('death_cases').doc(caseId).get();
      if (!caseDoc.exists) {
        throw Exception('Death case not found');
      }

      final caseData = DeathCaseModel.fromFirestore(caseDoc);
      
      // Update case status to accepted
      await _firestore.collection('death_cases').doc(caseId).update({
        'status': CaseStatus.accepted.value,
        'staffId': staffId,
        'acceptedAt': Timestamp.now(),
      });

      print('✅ Death case accepted by staff: $staffId');

      // 🚀 NEW: Send notification to waris about case acceptance using FCM
      await FirebaseCloudMessagingService.notifyCaseStatusUpdate(
        caseName: caseData.fullName,
        caseId: caseId,
        status: CaseStatus.accepted,
        recipientUserId: caseData.warisId,
      );

      print('📡 Acceptance notification sent to waris via FCM');
    } catch (e) {
      print('❌ Failed to accept death case: $e');
      throw Exception('Failed to accept death case: ${e.toString()}');
    }
  }

  // Decline death case - CASE REMAINS PENDING, ADD STAFF TO DECLINED LIST
  Future<void> declineDeathCase(String caseId, String staffId) async {
    try {
      print('❌ Staff declining case: $caseId');
      
      // Get current case data
      final docSnapshot = await _firestore.collection('death_cases').doc(caseId).get();
      
      if (!docSnapshot.exists) {
        throw Exception('Death case not found');
      }

      final data = docSnapshot.data() as Map<String, dynamic>;
      List<dynamic> declinedByStaff = data['declinedByStaff'] ?? [];
      
      // Add staff to declined list if not already there
      if (!declinedByStaff.contains(staffId)) {
        declinedByStaff.add(staffId);
        
        // Update only the declined staff list - STATUS REMAINS PENDING
        await _firestore.collection('death_cases').doc(caseId).update({
          'declinedByStaff': declinedByStaff,
        });

        print('✅ Staff $staffId added to declined list for case $caseId');
        print('ℹ️ Case status remains PENDING for other staff to accept');
        
        // Note: We don't send notification for decline since case remains available
      }
    } catch (e) {
      print('❌ Failed to decline death case: $e');
      throw Exception('Failed to decline death case: ${e.toString()}');
    }
  }

  // Complete death case
  Future<void> completeDeathCase(String caseId) async {
    try {
      print('🎉 Completing death case: $caseId');
      
      // Get the case data first
      final caseDoc = await _firestore.collection('death_cases').doc(caseId).get();
      if (!caseDoc.exists) {
        throw Exception('Death case not found');
      }

      final caseData = DeathCaseModel.fromFirestore(caseDoc);
      
      // Update case status to completed
      await _firestore.collection('death_cases').doc(caseId).update({
        'status': CaseStatus.completed.value,
        'completedAt': Timestamp.now(),
      });

      print('✅ Death case marked as completed: $caseId');

      // 🚀 NEW: Send completion notification to waris using FCM
      await FirebaseCloudMessagingService.notifyCaseStatusUpdate(
        caseName: caseData.fullName,
        caseId: caseId,
        status: CaseStatus.completed,
        recipientUserId: caseData.warisId,
      );

      print('📡 Completion notification sent to waris via FCM');
    } catch (e) {
      print('❌ Failed to complete death case: $e');
      throw Exception('Failed to complete death case: ${e.toString()}');
    }
  }

  // Get case by ID
  Future<DeathCaseModel?> getCaseById(String caseId) async {
    try {
      final doc = await _firestore.collection('death_cases').doc(caseId).get();
      if (doc.exists) {
        return DeathCaseModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('❌ Failed to get case by ID: $e');
      throw Exception('Failed to get case: ${e.toString()}');
    }
  }

  // 🚀 NEW: Test method to send notification to all staff
  Future<void> testNotificationToAllStaff() async {
    try {
      print('🧪 Testing notification to all staff...');
      
      await FirebaseCloudMessagingService.sendTestNotification();
      
      print('✅ Test notification sent to all staff via FCM');
    } catch (e) {
      print('❌ Failed to send test notification: $e');
      throw Exception('Failed to send test notification: ${e.toString()}');
    }
  }

  // Get statistics for dashboard
  Future<Map<String, int>> getStaffStatistics(String staffId) async {
    try {
      final acceptedCases = await _firestore
          .collection('death_cases')
          .where('staffId', isEqualTo: staffId)
          .where('status', isEqualTo: CaseStatus.accepted.value)
          .get();

      final completedCases = await _firestore
          .collection('death_cases')
          .where('staffId', isEqualTo: staffId)
          .where('status', isEqualTo: CaseStatus.completed.value)
          .get();

      final pendingCases = await _firestore
          .collection('death_cases')
          .where('status', isEqualTo: CaseStatus.pending.value)
          .get();

      return {
        'accepted': acceptedCases.docs.length,
        'completed': completedCases.docs.length,
        'pending': pendingCases.docs.length,
      };
    } catch (e) {
      print('❌ Failed to get staff statistics: $e');
      return {
        'accepted': 0,
        'completed': 0,
        'pending': 0,
      };
    }
  }

  // Get statistics for waris
  Future<Map<String, int>> getWarisStatistics(String warisId) async {
    try {
      final allCases = await _firestore
          .collection('death_cases')
          .where('warisId', isEqualTo: warisId)
          .get();

      final acceptedCases = allCases.docs.where(
        (doc) => (doc.data()['status'] as String) == CaseStatus.accepted.value
      ).length;

      final completedCases = allCases.docs.where(
        (doc) => (doc.data()['status'] as String) == CaseStatus.completed.value
      ).length;

      final pendingCases = allCases.docs.where(
        (doc) => (doc.data()['status'] as String) == CaseStatus.pending.value
      ).length;

      return {
        'total': allCases.docs.length,
        'accepted': acceptedCases,
        'completed': completedCases,
        'pending': pendingCases,
      };
    } catch (e) {
      print('❌ Failed to get waris statistics: $e');
      return {
        'total': 0,
        'accepted': 0,
        'completed': 0,
        'pending': 0,
      };
    }
  }
}