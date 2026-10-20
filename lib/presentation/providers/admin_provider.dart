import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'business_provider.dart';

class AdminProvider extends ChangeNotifier {
  bool isLoading = false;
  final List<Map<String, dynamic>> users = [];

  int totalUsers = 0;
  int approvedBusinesses = 0;
  int pendingBusinesses = 0;
  int rejectedBusinesses = 0;
  int totalReviews = 0;
  int totalFavorites = 0;

  Future<void> loadStatistics(BusinessProvider businessProvider) async {
    isLoading = true;
    notifyListeners();
    try {
      final users = await FirebaseFirestore.instance.collection('users').get();
      this.users
        ..clear()
        ..addAll(
          users.docs.map(
            (document) => {...document.data(), 'uid': document.id},
          ),
        );
      totalUsers = this.users.length;
      approvedBusinesses = businessProvider.approvedBusinesses.length;
      pendingBusinesses = businessProvider.pendingBusinesses.length;
      rejectedBusinesses = businessProvider.rejectedBusinesses.length;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setUserBlocked({
    required String userId,
    required bool blocked,
  }) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).set({
      'blocked': blocked,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    final index = users.indexWhere((user) => user['uid'] == userId);
    if (index != -1) users[index]['blocked'] = blocked;
    notifyListeners();
  }

  Future<void> loadUsers() async {
    isLoading = true;
    notifyListeners();
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .get();
      users
        ..clear()
        ..addAll(
          snapshot.docs.map(
            (document) => {...document.data(), 'uid': document.id},
          ),
        );
      totalUsers = users.length;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
