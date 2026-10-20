import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

import '../../data/municipal_events.dart';
import '../widgets/municipal_events_carousel.dart';

class MunicipalEventProvider extends ChangeNotifier {
  final Map<String, List<MunicipalEvent>> _eventsByMunicipality = {};
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  FirebaseStorage get _storage => FirebaseStorage.instance;

  List<MunicipalEvent> eventsFor(String municipality) =>
      _eventsByMunicipality[municipality] ??
      municipalEvents[municipality] ??
      const [];

  Future<void> loadMunicipality(
    String municipality, {
    bool includeHidden = false,
  }) async {
    final defaults = municipalEvents[municipality] ?? const <MunicipalEvent>[];
    if (Firebase.apps.isEmpty) {
      _eventsByMunicipality[municipality] = defaults;
      notifyListeners();
      return;
    }

    final snapshot = await _firestore
        .collection('municipal_events')
        .where('municipality', isEqualTo: municipality)
        .get();
    final overrides = {
      for (final document in snapshot.docs) document.id: document.data(),
    };
    final events = <MunicipalEvent>[];
    for (var index = 0; index < defaults.length; index++) {
      final defaultEvent = defaults[index];
      final id = 'legacy-$index';
      final override = overrides.remove(id);
      if (override?['active'] == false && !includeHidden) continue;
      events.add(_fromMap(id, override, defaultEvent));
    }

    for (final entry in overrides.entries) {
      if (entry.value['active'] == false && !includeHidden) continue;
      events.add(_fromMap(entry.key, entry.value, null));
    }
    _eventsByMunicipality[municipality] = events;
    notifyListeners();
  }

  Future<void> loadAllMunicipalities(Iterable<String> municipalities) async {
    for (final municipality in municipalities) {
      await loadMunicipality(municipality);
    }
  }

  Future<String> saveEvent({
    required String municipality,
    required String? eventId,
    required String title,
    required String date,
    required String description,
    required String sourceUrl,
    required String iconName,
    File? imageFile,
    String? currentImageUrl,
  }) async {
    final collection = _firestore.collection('municipal_events');
    final reference = eventId == null
        ? collection.doc()
        : collection.doc(eventId);
    var imageUrl = currentImageUrl ?? '';
    if (imageFile != null) {
      final fileName = imageFile.path.split(RegExp(r'[\\/]')).last;
      final safeName = fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
      final extension = fileName.split('.').last.toLowerCase();
      final contentType = switch (extension) {
        'png' => 'image/png',
        'webp' => 'image/webp',
        'gif' => 'image/gif',
        _ => 'image/jpeg',
      };
      final upload = await _storage
          .ref()
          .child(
            'events/$municipality/${reference.id}_${DateTime.now().microsecondsSinceEpoch}_$safeName',
          )
          .putFile(imageFile, SettableMetadata(contentType: contentType));
      imageUrl = await upload.ref.getDownloadURL();
    }
    await reference.set({
      'municipality': municipality,
      'title': title.trim(),
      'date': date.trim(),
      'description': description.trim(),
      'sourceUrl': sourceUrl.trim(),
      'icon': iconName,
      'imageUrl': imageUrl,
      'active': true,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await loadMunicipality(municipality);
    return reference.id;
  }

  Future<void> hideEvent({
    required String municipality,
    required String eventId,
  }) async {
    await _firestore.collection('municipal_events').doc(eventId).set({
      'municipality': municipality,
      'active': false,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await loadMunicipality(municipality);
  }

  MunicipalEvent _fromMap(
    String id,
    Map<String, dynamic>? data,
    MunicipalEvent? fallback,
  ) {
    final values = data ?? const <String, dynamic>{};
    return MunicipalEvent(
      id: id,
      title: (values['title'] ?? fallback?.title ?? '').toString(),
      date: (values['date'] ?? fallback?.date ?? '').toString(),
      description: (values['description'] ?? fallback?.description ?? '')
          .toString(),
      sourceUrl: (values['sourceUrl'] ?? fallback?.sourceUrl)?.toString(),
      imageUrl: (values['imageUrl'] ?? fallback?.imageUrl)?.toString(),
      isActive: values['active'] != false,
      icon: _iconFromName(
        (values['icon'] ?? '').toString(),
        fallback?.icon ?? Icons.event,
      ),
    );
  }

  IconData _iconFromName(String name, IconData fallback) {
    const icons = {
      'event': Icons.event,
      'festival': Icons.festival,
      'celebration': Icons.celebration,
      'church': Icons.church,
      'eco': Icons.eco,
      'music': Icons.music_note,
      'sports': Icons.sports,
      'culture': Icons.theater_comedy,
    };
    return icons[name] ?? fallback;
  }
}
