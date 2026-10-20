import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../data/business_catalog.dart';
import '../../data/michoacan_municipalities.dart';

class CatalogProvider extends ChangeNotifier {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  final Set<String> _municipalities = {...regionMunicipalities};
  final Set<String> _categories = {...businessCategories};
  final List<Map<String, dynamic>> requests = [];
  bool isLoading = false;

  List<String> get municipalities => _municipalities.toList()..sort();
  List<String> get categories => _categories.toList()..sort();

  Future<void> loadCatalogs() async {
    if (Firebase.apps.isEmpty) return;
    isLoading = true;
    notifyListeners();
    try {
      final snapshots = await Future.wait([
        _firestore.collection('available_municipalities').get(),
        _firestore.collection('available_categories').get(),
      ]);
      _municipalities
        ..clear()
        ..addAll(regionMunicipalities)
        ..addAll(
          snapshots[0].docs
              .where((document) => document.data()['active'] == true)
              .map((document) => document.data()['name'].toString()),
        );
      _categories
        ..clear()
        ..addAll(businessCategories)
        ..addAll(
          snapshots[1].docs
              .where((document) => document.data()['active'] == true)
              .map((document) => document.data()['name'].toString()),
        );
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadRequests() async {
    if (Firebase.apps.isEmpty) return;
    final snapshot = await _firestore
        .collection('catalog_requests')
        .where('status', isEqualTo: 'pending')
        .get();
    requests
      ..clear()
      ..addAll(
        snapshot.docs.map(
          (document) => {...document.data(), 'id': document.id},
        ),
      );
    notifyListeners();
  }

  void stageRequests({
    required WriteBatch batch,
    required List<Map<String, String>> suggestions,
    required String businessId,
    required String municipality,
    required String category,
  }) {
    if (suggestions.isEmpty) return;
    for (final suggestion in suggestions) {
      final type = suggestion['type'];
      final value = suggestion['value']?.trim() ?? '';
      if ((type != 'municipality' && type != 'category') || value.isEmpty) {
        throw ArgumentError(
          'La propuesta de municipio o categoría no es válida.',
        );
      }
      if (type == 'municipality' &&
          !michoacanMunicipalities.any(
            (officialName) => _normalize(officialName) == _normalize(value),
          )) {
        throw ArgumentError(
          'Solo se pueden solicitar municipios oficiales de Michoacán.',
        );
      }
      final reference = _firestore.collection('catalog_requests').doc();
      batch.set(reference, {
        'type': type,
        'value': value,
        'municipality': municipality,
        'category': category,
        'businessId': businessId,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> addMunicipality(String name) async {
    final normalized = _normalize(name);
    String? officialName;
    for (final municipality in michoacanMunicipalities) {
      if (_normalize(municipality) == normalized) {
        officialName = municipality;
        break;
      }
    }
    if (officialName == null) {
      throw ArgumentError('Selecciona un municipio oficial de Michoacán.');
    }
    if (_municipalities.any((value) => _normalize(value) == normalized)) {
      throw ArgumentError('Ese municipio ya está disponible.');
    }
    await _addCatalogEntry('available_municipalities', officialName);
    _municipalities.add(officialName);
    notifyListeners();
  }

  Future<void> addCategory(String name) async {
    final normalizedName = name.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalizedName.isEmpty) {
      throw ArgumentError('Escribe el nombre de la categoría.');
    }
    if (_categories.any(
      (value) => _normalize(value) == _normalize(normalizedName),
    )) {
      throw ArgumentError('Esa categoría ya está disponible.');
    }
    await _addCatalogEntry('available_categories', normalizedName);
    _categories.add(normalizedName);
    notifyListeners();
  }

  Future<void> reviewRequest({
    required String requestId,
    required bool approve,
  }) async {
    final index = requests.indexWhere((request) => request['id'] == requestId);
    if (index == -1) throw StateError('La solicitud ya no está disponible.');
    final request = requests[index];
    if (approve) {
      if (request['type'] == 'municipality') {
        final value = request['value'].toString();
        if (!_municipalities.any(
          (municipality) => _normalize(municipality) == _normalize(value),
        )) {
          await addMunicipality(value);
        }
      } else if (request['type'] == 'category') {
        final value = request['value'].toString();
        if (!_categories.any(
          (category) => _normalize(category) == _normalize(value),
        )) {
          await addCategory(value);
        }
      }
    }
    await _firestore.collection('catalog_requests').doc(requestId).update({
      'status': approve ? 'approved' : 'rejected',
      'reviewedAt': FieldValue.serverTimestamp(),
    });
    requests.removeAt(index);
    notifyListeners();
  }

  Future<void> _addCatalogEntry(String collection, String value) async {
    if (Firebase.apps.isEmpty) return;
    final matches = await _firestore
        .collection(collection)
        .where('normalizedName', isEqualTo: _normalize(value))
        .limit(1)
        .get();
    if (matches.docs.isNotEmpty) {
      await matches.docs.first.reference.set({
        'name': value,
        'active': true,
        'normalizedName': _normalize(value),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return;
    }
    await _firestore.collection(collection).add({
      'name': value,
      'active': true,
      'normalizedName': _normalize(value),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  String _normalize(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[áàä]'), 'a')
      .replaceAll(RegExp(r'[éèë]'), 'e')
      .replaceAll(RegExp(r'[íìï]'), 'i')
      .replaceAll(RegExp(r'[óòö]'), 'o')
      .replaceAll(RegExp(r'[úùü]'), 'u')
      .replaceAll('ñ', 'n')
      .replaceAll(RegExp(r'\s+'), ' ');
}
