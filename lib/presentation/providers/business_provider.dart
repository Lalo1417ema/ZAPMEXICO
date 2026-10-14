import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/utils/business_category_images.dart';
import '../../data/business_catalog.dart';

class BusinessProvider extends ChangeNotifier {
  final List<Map<String, dynamic>> _allBusinesses =
      createInitialBusinessCatalog();
  final List<Map<String, dynamic>> businesses = [];
  final List<Map<String, dynamic>> pendingBusinesses = [];
  final List<Map<String, dynamic>> approvedBusinesses = [];
  final List<Map<String, dynamic>> rejectedBusinesses = [];
  final List<Map<String, dynamic>> favoriteBusinesses = [];
  final List<Map<String, dynamic>> _reviews = [];
  final Set<String> favoriteIds = {};

  bool isLoading = false;
  String? businessesLoadError;
  int _nextBusinessId = 0;
  int _nextReviewId = 0;

  BusinessProvider() {
    _refreshStatusLists();
  }

  Future<void> fetchApprovedBusinesses() async {
    businessesLoadError = null;
    _refreshStatusLists();
  }

  Future<void> fetchPendingBusinesses() async {
    _refreshStatusLists();
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  Future<void> updateBusiness({
    required String businessId,
    required Map<String, dynamic> data,
  }) async {
    final business = _findBusiness(businessId);
    if (business == null) return;
    business.addAll(data);
    _refreshStatusLists();
  }

  Future<void> submitBusinessRequest({
    required String name,
    required String owner,
    required String email,
    required String phone,
    required String whatsapp,
    required String city,
    required String address,
    required String schedule,
    required String category,
    required String description,
    required String facebook,
    required String instagram,
    required String website,
  }) async {
    final requiredFields = {
      'nombre': name,
      'teléfono': phone,
      'municipio': city,
      'dirección': address,
      'horario': schedule,
      'descripción': description,
    };
    final missingFields = requiredFields.entries
        .where((field) => field.value.trim().isEmpty)
        .map((field) => field.key)
        .toList();
    if (missingFields.isNotEmpty) {
      throw ArgumentError(
        'Completa los campos requeridos: ${missingFields.join(', ')}.',
      );
    }

    _allBusinesses.add({
      'id': 'local-${_nextBusinessId++}',
      'name': name,
      'owner': owner,
      'email': email,
      'phone': phone,
      'whatsapp': whatsapp,
      'city': city,
      'address': address,
      'location': city,
      'schedule': schedule,
      'category': category,
      'description': description,
      'facebook': facebook,
      'instagram': instagram,
      'website': website,
      'logoUrl': businessCategoryImageAsset(category),
      'imageIsIllustrative': true,
      'gallery': <String>[],
      'rating': 0.0,
      'reviewCount': 0,
      'status': 'pending',
      'adminComment': '',
      'reviewedBy': '',
      'createdBy': 'demo-user',
    });
    _refreshStatusLists();
  }

  Future<void> approveBusiness(String businessId) async {
    await updateBusiness(businessId: businessId, data: {'status': 'approved'});
  }

  Future<void> rejectBusiness(String businessId, String comment) async {
    await updateBusiness(
      businessId: businessId,
      data: {'status': 'rejected', 'adminComment': comment},
    );
  }

  Future<String> uploadBusinessLogo(File imageFile) async => imageFile.path;

  Future<String> uploadGalleryImage(File imageFile) async =>
      uploadBusinessLogo(imageFile);

  Future<void> fetchApprovedBusinessesAdmin() async {
    approvedBusinesses
      ..clear()
      ..addAll(
        _allBusinesses.where((business) => business['status'] == 'approved'),
      );
    notifyListeners();
  }

  Future<void> fetchRejectedBusinesses() async {
    _refreshStatusLists();
  }

  Future<void> addGalleryImage({
    required String businessId,
    required File imageFile,
  }) async {
    final business = _findBusiness(businessId);
    if (business == null) return;
    final gallery = List<String>.from(business['gallery'] as List? ?? []);
    gallery.add(imageFile.path);
    business['gallery'] = gallery;
    notifyListeners();
  }

  Future<void> addReview({
    required String businessId,
    required double rating,
    required String comment,
  }) async {
    if (_reviews.any(
      (review) =>
          review['businessId'] == businessId && review['userId'] == 'demo-user',
    )) {
      throw Exception('Ya has calificado este negocio anteriormente.');
    }

    _reviews.add({
      'id': 'review-${_nextReviewId++}',
      'businessId': businessId,
      'userId': 'demo-user',
      'userName': 'Visitante',
      'rating': rating,
      'comment': comment,
      'createdAt': DateTime.now(),
    });
    await recalculateRating(businessId);
  }

  Future<void> recalculateRating(String businessId) async {
    final reviews = _reviews
        .where((review) => review['businessId'] == businessId)
        .toList();
    if (reviews.isEmpty) return;

    final business = _findBusiness(businessId);
    if (business == null) return;
    final total = reviews.fold<double>(
      0,
      (sum, review) => sum + (review['rating'] as num).toDouble(),
    );
    business['rating'] = total / reviews.length;
    business['reviewCount'] = reviews.length;
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> fetchReviews(String businessId) async {
    return _reviews
        .where((review) => review['businessId'] == businessId)
        .toList()
        .reversed
        .toList();
  }

  bool isFavorite(String businessId) => favoriteIds.contains(businessId);

  Future<void> fetchFavorites() async {
    favoriteBusinesses
      ..clear()
      ..addAll(
        _allBusinesses.where(
          (business) => favoriteIds.contains(business['id']),
        ),
      );
    notifyListeners();
  }

  Future<void> toggleFavorite(String businessId) async {
    if (!favoriteIds.add(businessId)) {
      favoriteIds.remove(businessId);
    }
    await fetchFavorites();
  }

  Map<String, dynamic>? _findBusiness(String businessId) {
    for (final business in _allBusinesses) {
      if (business['id'] == businessId) return business;
    }
    return null;
  }

  void _refreshStatusLists() {
    approvedBusinesses
      ..clear()
      ..addAll(
        _allBusinesses.where((business) => business['status'] == 'approved'),
      );
    pendingBusinesses
      ..clear()
      ..addAll(
        _allBusinesses.where((business) => business['status'] == 'pending'),
      );
    rejectedBusinesses
      ..clear()
      ..addAll(
        _allBusinesses.where((business) => business['status'] == 'rejected'),
      );
    businesses
      ..clear()
      ..addAll(approvedBusinesses);
    favoriteBusinesses
      ..clear()
      ..addAll(
        _allBusinesses.where(
          (business) => favoriteIds.contains(business['id']),
        ),
      );
    notifyListeners();
  }
}
