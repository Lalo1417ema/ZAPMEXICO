import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

import '../../core/utils/business_category_images.dart';
import '../../data/business_catalog.dart';
import 'catalog_provider.dart';

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
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  FirebaseStorage get _storage => FirebaseStorage.instance;

  bool isLoading = false;
  String? businessesLoadError;
  int _nextBusinessId = 0;
  int _nextReviewId = 0;

  BusinessProvider() {
    _refreshStatusLists();
  }

  Future<void> fetchApprovedBusinesses() async {
    await _fetchBusinesses(status: 'approved');
  }

  Future<void> fetchPendingBusinesses() async {
    await _fetchBusinesses(status: 'pending');
  }

  Future<void> fetchRejectedBusinesses() async {
    await _fetchBusinesses(status: 'rejected');
  }

  Future<void> fetchAllBusinessesForAdmin() async {
    await _fetchBusinesses();
  }

  Future<void> _fetchBusinesses({String? status}) async {
    if (Firebase.apps.isEmpty) {
      _refreshStatusLists();
      return;
    }
    isLoading = true;
    businessesLoadError = null;
    notifyListeners();
    try {
      Query<Map<String, dynamic>> query = _firestore.collection('businesses');
      if (status != null) {
        query = query.where('status', isEqualTo: status);
        if (status == 'approved') {
          query = query.where('blocked', isEqualTo: false);
        }
      }
      final snapshot = await query.get();
      for (final document in snapshot.docs) {
        if (status == null && !document.data().containsKey('blocked')) {
          await document.reference.update({'blocked': false});
        }
        _mergeBusiness({...document.data(), 'id': document.id});
      }
      _refreshStatusLists();
    } on FirebaseException catch (error) {
      businessesLoadError =
          error.message ?? 'No se pudieron cargar los negocios.';
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
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
    if (business == null) {
      throw StateError('No se encontró el negocio seleccionado.');
    }

    if (Firebase.apps.isNotEmpty) {
      await _firestore.collection('businesses').doc(businessId).set({
        ...business,
        ...data,
        'id': businessId,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
    business.addAll(data);
    _refreshStatusLists();
  }

  Future<void> setBusinessBlocked({
    required String businessId,
    required bool blocked,
  }) async {
    await updateBusiness(
      businessId: businessId,
      data: {
        'blocked': blocked,
        'blockedAt': blocked
            ? FieldValue.serverTimestamp()
            : FieldValue.delete(),
      },
    );
  }

  Future<String> submitBusinessRequest({
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
    File? logoImage,
    List<File> galleryImages = const [],
    CatalogProvider? catalogProvider,
    List<Map<String, String>> catalogSuggestions = const [],
  }) async {
    final firebaseConfigured = Firebase.apps.isNotEmpty;
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
    if (firebaseConfigured && galleryImages.length < 3) {
      throw ArgumentError(
        'Agrega al menos 3 fotos para la galería del negocio.',
      );
    }
    if (galleryImages.length > 20) {
      throw ArgumentError('La galería admite un máximo de 20 fotos.');
    }

    final currentUser = firebaseConfigured
        ? FirebaseAuth.instance.currentUser
        : null;
    if (firebaseConfigured && currentUser == null) {
      throw StateError('Inicia sesión antes de registrar un negocio.');
    }

    final businessId = firebaseConfigured
        ? _firestore.collection('businesses').doc().id
        : 'local-${_nextBusinessId++}';
    final businessReference = firebaseConfigured
        ? _firestore.collection('businesses').doc(businessId)
        : null;
    final now = DateTime.now();
    final business = <String, dynamic>{
      'id': businessId,
      'name': name.trim(),
      'owner': owner.trim(),
      'email': email.trim(),
      'phone': phone.trim(),
      'whatsapp': whatsapp.trim(),
      'city': city.trim(),
      'address': address.trim(),
      'location': city.trim(),
      'schedule': schedule.trim(),
      'category': category,
      'description': description.trim(),
      'facebook': facebook.trim(),
      'instagram': instagram.trim(),
      'website': website.trim(),
      'logoUrl': businessCategoryImageAsset(category),
      'imageIsIllustrative': true,
      'gallery': <String>[],
      'rating': 0.0,
      'reviewCount': 0,
      'status': 'pending',
      'blocked': false,
      'adminComment': '',
      'reviewedBy': '',
      'createdBy': currentUser?.uid ?? 'demo-user',
      'createdAt': firebaseConfigured ? FieldValue.serverTimestamp() : now,
      'updatedAt': firebaseConfigured ? FieldValue.serverTimestamp() : now,
    };
    if (firebaseConfigured) {
      final batch = _firestore.batch();
      batch.set(businessReference!, business);
      catalogProvider?.stageRequests(
        batch: batch,
        suggestions: catalogSuggestions,
        businessId: businessId,
        municipality: city,
        category: category,
      );
      await batch.commit();
      final logoUrl = logoImage == null
          ? null
          : await uploadBusinessImage(
              businessId: businessId,
              imageFile: logoImage,
              kind: 'logo',
            );
      final gallery = <String>[];
      for (final image in galleryImages) {
        gallery.add(
          await uploadBusinessImage(
            businessId: businessId,
            imageFile: image,
            kind: 'gallery',
          ),
        );
      }
      await businessReference.update({
        'logoUrl': ?logoUrl,
        'imageIsIllustrative': logoUrl == null,
        'gallery': gallery,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (logoUrl != null) {
        business['logoUrl'] = logoUrl;
        business['imageIsIllustrative'] = false;
      }
      business['gallery'] = gallery;
      business['createdAt'] = DateTime.now();
      business['updatedAt'] = DateTime.now();
    } else if (galleryImages.isNotEmpty || logoImage != null) {
      throw StateError('Firebase debe estar habilitado para subir imágenes.');
    }
    _mergeBusiness(business);
    _refreshStatusLists();
    return businessId;
  }

  Future<void> approveBusiness(String businessId) async {
    final business = _findBusiness(businessId);
    if (Firebase.apps.isNotEmpty &&
        (business?['gallery'] is! List ||
            (business!['gallery'] as List).length < 3)) {
      throw StateError('Agrega al menos 3 fotos antes de aprobar el negocio.');
    }
    await updateBusiness(
      businessId: businessId,
      data: {
        'status': 'approved',
        'adminComment': '',
        'reviewedBy': Firebase.apps.isEmpty
            ? 'demo-admin'
            : FirebaseAuth.instance.currentUser?.uid ?? '',
        'reviewedAt': DateTime.now(),
      },
    );
  }

  Future<void> rejectBusiness(String businessId, String comment) async {
    final normalizedComment = comment.trim();
    if (normalizedComment.isEmpty) {
      throw ArgumentError('Escribe el motivo del rechazo.');
    }
    await updateBusiness(
      businessId: businessId,
      data: {
        'status': 'rejected',
        'adminComment': normalizedComment,
        'reviewedBy': Firebase.apps.isEmpty
            ? 'demo-admin'
            : FirebaseAuth.instance.currentUser?.uid ?? '',
        'reviewedAt': DateTime.now(),
      },
    );
  }

  Future<String> uploadBusinessImage({
    required String businessId,
    required File imageFile,
    required String kind,
  }) async {
    final fileName = imageFile.path.split(RegExp(r'[\\/]')).last;
    final safeName = fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final reference = _storage.ref().child(
      'businesses/$businessId/${kind}_${DateTime.now().microsecondsSinceEpoch}_$safeName',
    );
    final extension = fileName.split('.').last.toLowerCase();
    final contentType = switch (extension) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'gif' => 'image/gif',
      _ => 'image/jpeg',
    };
    final task = await reference.putFile(
      imageFile,
      SettableMetadata(contentType: contentType),
    );
    return task.ref.getDownloadURL();
  }

  Future<String> uploadBusinessLogo({
    required String businessId,
    required File imageFile,
  }) => uploadBusinessImage(
    businessId: businessId,
    imageFile: imageFile,
    kind: 'logo',
  );

  Future<String> uploadGalleryImage({
    required String businessId,
    required File imageFile,
  }) => uploadBusinessImage(
    businessId: businessId,
    imageFile: imageFile,
    kind: 'gallery',
  );

  Future<void> fetchApprovedBusinessesAdmin() async {
    await _fetchBusinesses(status: 'approved');
  }

  Future<void> addGalleryImage({
    required String businessId,
    required File imageFile,
  }) async {
    final business = _findBusiness(businessId);
    if (business == null) {
      throw StateError('No se encontró el negocio seleccionado.');
    }
    final imageUrl = await uploadBusinessImage(
      businessId: businessId,
      imageFile: imageFile,
      kind: 'gallery',
    );
    final gallery = List<String>.from(business['gallery'] as List? ?? [])
      ..add(imageUrl);
    await updateBusiness(businessId: businessId, data: {'gallery': gallery});
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
      (total, review) => total + (review['rating'] as num).toDouble(),
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

  void _mergeBusiness(Map<String, dynamic> value) {
    final businessId = value['id']?.toString();
    if (businessId == null || businessId.isEmpty) return;

    final existing = _findBusiness(businessId);
    if (existing == null) {
      _allBusinesses.add(value);
    } else {
      existing.addAll(value);
    }
  }

  Map<String, dynamic>? _findBusiness(String businessId) {
    for (final business in _allBusinesses) {
      if (business['id']?.toString() == businessId) return business;
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
      ..addAll(
        approvedBusinesses.where((business) => business['blocked'] != true),
      );
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
