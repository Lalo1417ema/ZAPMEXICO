import 'package:flutter/material.dart';

import '../../data/business_catalog.dart';

class AdminProvider extends ChangeNotifier {
  bool isLoading = false;

  int totalUsers = 0;
  int approvedBusinesses = 0;
  int pendingBusinesses = 0;
  int rejectedBusinesses = 0;
  int totalReviews = 0;
  int totalFavorites = 0;

  Future<void> loadStatistics() async {
    isLoading = true;
    notifyListeners();

    approvedBusinesses = createInitialBusinessCatalog().length;
    pendingBusinesses = 0;
    rejectedBusinesses = 0;
    totalUsers = 0;
    totalReviews = 0;
    totalFavorites = 0;

    isLoading = false;
    notifyListeners();
  }
}
