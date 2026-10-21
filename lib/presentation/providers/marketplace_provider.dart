import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class MarketplaceProduct {
  final String id;
  final String name;
  final String description;
  final double price;
  final String sellerUid;
  final String sellerName;
  final String municipality;
  final List<String> photoUrls;
  final List<String> photoPaths;
  final DateTime createdAt;

  DateTime get expiresAt => createdAt.add(const Duration(days: 5));

  const MarketplaceProduct({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.sellerUid,
    required this.sellerName,
    required this.municipality,
    required this.photoUrls,
    required this.photoPaths,
    required this.createdAt,
  });

  factory MarketplaceProduct.fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    final createdAt = data['createdAt'];

    return MarketplaceProduct(
      id: document.id,
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0,
      sellerUid: data['sellerUid'] as String? ?? '',
      sellerName: data['sellerName'] as String? ?? '',
      municipality: data['municipality'] as String? ?? '',
      photoUrls: List<String>.from(data['photoUrls'] as List? ?? const []),
      photoPaths: List<String>.from(data['photoPaths'] as List? ?? const []),
      createdAt: createdAt is Timestamp
          ? createdAt.toDate()
          : DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class MarketplaceProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;

  List<MarketplaceProduct> products = const [];
  String? errorMessage;
  bool isLoading = true;

  MarketplaceProvider() {
    _subscription = _firestore
        .collection('marketplace_products')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .listen(
          (snapshot) {
            final now = DateTime.now();
            products = snapshot.docs
                .map(MarketplaceProduct.fromDocument)
                .where((product) => product.expiresAt.isAfter(now))
                .toList();
            errorMessage = null;
            isLoading = false;
            notifyListeners();
          },
          onError: (Object error) {
            errorMessage = error is FirebaseException
                ? error.message ?? 'No se pudieron cargar los productos.'
                : 'No se pudieron cargar los productos.';
            isLoading = false;
            notifyListeners();
          },
        );
  }

  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;

  Future<void> createProduct({
    required String name,
    required String description,
    required double price,
    required String sellerName,
    required String municipality,
    required List<XFile> images,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) {
      throw StateError('Regístrate o inicia sesión para publicar productos.');
    }
    if (images.isEmpty || images.length > 3) {
      throw ArgumentError('Selecciona entre una y tres fotos del producto.');
    }
    if (municipality.trim().isEmpty) {
      throw StateError('Completa el municipio en tu perfil antes de publicar.');
    }

    final document = _firestore.collection('marketplace_products').doc();
    final uploadedPaths = <String>[];
    final photoUrls = <String>[];

    try {
      for (var index = 0; index < images.length; index++) {
        final image = images[index];
        final extension = _fileExtension(image.name);
        final path = 'marketplace/${user.uid}/${document.id}/$index.$extension';
        final reference = _storage.ref(path);
        await reference.putData(
          await image.readAsBytes(),
          SettableMetadata(contentType: _contentType(image, extension)),
        );
        uploadedPaths.add(path);
        photoUrls.add(await reference.getDownloadURL());
      }

      await document.set({
        'name': name.trim(),
        'description': description.trim(),
        'price': price,
        'sellerUid': user.uid,
        'sellerName': sellerName.trim(),
        'municipality': municipality.trim(),
        'photoUrls': photoUrls,
        'photoPaths': uploadedPaths,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException {
      await _cleanUpUploadedFiles(uploadedPaths);
      rethrow;
    }
  }

  Future<void> deleteProduct(MarketplaceProduct product) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous || user.uid != product.sellerUid) {
      throw StateError('Solo el propietario puede eliminar este producto.');
    }

    await _deletePhotoPaths(product.photoPaths);
    await _firestore
        .collection('marketplace_products')
        .doc(product.id)
        .delete();
  }

  Future<void> _cleanUpUploadedFiles(List<String> paths) async {
    try {
      await _deletePhotoPaths(paths);
    } on FirebaseException catch (error) {
      debugPrint(
        'No se pudieron limpiar fotos incompletas del Marketplace: $error',
      );
    }
  }

  Future<void> _deletePhotoPaths(List<String> paths) async {
    for (final path in paths) {
      try {
        await _storage.ref(path).delete();
      } on FirebaseException catch (error) {
        if (error.code != 'object-not-found') rethrow;
      }
    }
  }

  String _fileExtension(String fileName) {
    final extension = fileName.contains('.')
        ? fileName.split('.').last.toLowerCase()
        : 'jpg';
    return switch (extension) {
      'png' || 'webp' || 'gif' => extension,
      _ => 'jpg',
    };
  }

  String _contentType(XFile file, String extension) {
    final mimeType = file.mimeType;
    if (mimeType != null && mimeType.startsWith('image/')) return mimeType;
    return switch (extension) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'gif' => 'image/gif',
      _ => 'image/jpeg',
    };
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
