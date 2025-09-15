import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/death_case_model.dart';
import '../models/enums.dart';
import 'notification_service.dart';

class DeathCaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create new death case
  Future<String> createDeathCase(DeathCaseModel deathCase) async {
    try {
      final docRef = await _firestore
          .collection('death_cases')
          .add(deathCase.toMap());
      
      await docRef.update({'id': docRef.id});
      
      // Send notification to all staff
      await NotificationService.notifyStaffNewCase(
        caseName: deathCase.fullName,
        caseId: docRef.id,
        serviceType: deathCase.serviceType,
      );
      
      return docRef.id;
    } catch (e) {
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

  // Accept death case (for staff) - TIDAK BERUBAH
  Future<void> acceptDeathCase(String caseId, String staffId) async {
    try {
      await _firestore.collection('death_cases').doc(caseId).update({
        'status': CaseStatus.accepted.value,
        'staffId': staffId,
        'acceptedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to accept death case: ${e.toString()}');
    }
  }

  // UPDATED: Decline death case - TETAP PENDING, TAMBAH DECLINED STAFF LIST
  Future<void> declineDeathCase(String caseId, String staffId) async {
    try {
      // Get current case data
      final docSnapshot = await _firestore.collection('death_cases').doc(caseId).get();
      
      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        List<dynamic> declinedByStaff = data['declinedByStaff'] ?? [];
        
        // Add staff to declined list if not already there
        if (!declinedByStaff.contains(staffId)) {
          declinedByStaff.add(staffId);
        }
        
        // PENTING: Status tetap pending, cuma update declined staff list
        await _firestore.collection('death_cases').doc(caseId).update({
          'declinedByStaff': declinedByStaff,
          // STATUS TIDAK BERUBAH - tetap pending
        });
      }
    } catch (e) {
      throw Exception('Failed to decline death case: ${e.toString()}');
    }
  }

  // Complete death case
  Future<void> completeDeathCase(String caseId) async {
    try {
      await _firestore.collection('death_cases').doc(caseId).update({
        'status': CaseStatus.completed.value,
        'completedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to complete death case: ${e.toString()}');
    }
  }
}