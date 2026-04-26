import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TripRecord {
  TripRecord({
    required this.id,
    required this.tripDate,
    required this.tripDurationSeconds,
    required this.fatigueCount,
    required this.fatigueScore,
    required this.uploadedToFirebase,
  });

  final String id;
  final DateTime tripDate;
  final int tripDurationSeconds;
  final int fatigueCount;
  final double fatigueScore;
  final bool uploadedToFirebase;

  Map<String, dynamic> toLocalMap() {
    return <String, dynamic>{
      'id': id,
      'tripDate': tripDate.toIso8601String(),
      'tripDurationSeconds': tripDurationSeconds,
      'fatigueCount': fatigueCount,
      'fatigueScore': fatigueScore,
      'uploadedToFirebase': uploadedToFirebase,
    };
  }

  Map<String, dynamic> toFirestoreMap() {
    return <String, dynamic>{
      'id': id,
      'tripDate': Timestamp.fromDate(tripDate),
      'tripDurationSeconds': tripDurationSeconds,
      'fatigueCount': fatigueCount,
      'fatigueScore': fatigueScore,
      'uploadedToFirebase': uploadedToFirebase,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  TripRecord copyWith({bool? uploadedToFirebase}) {
    return TripRecord(
      id: id,
      tripDate: tripDate,
      tripDurationSeconds: tripDurationSeconds,
      fatigueCount: fatigueCount,
      fatigueScore: fatigueScore,
      uploadedToFirebase: uploadedToFirebase ?? this.uploadedToFirebase,
    );
  }

  static TripRecord fromLocalMap(Map<String, dynamic> map) {
    return TripRecord(
      id: (map['id'] ?? '').toString(),
      tripDate: DateTime.tryParse((map['tripDate'] ?? '').toString()) ??
          DateTime.now(),
      tripDurationSeconds: (map['tripDurationSeconds'] as num?)?.toInt() ?? 0,
      fatigueCount: (map['fatigueCount'] as num?)?.toInt() ?? 0,
      fatigueScore: (map['fatigueScore'] as num?)?.toDouble() ?? 0,
      uploadedToFirebase: map['uploadedToFirebase'] == true,
    );
  }
}

class TripHistoryService {
  static const String _tripHistoryKey = 'trip_history_v1';

  Future<void> persistTripAndUpload({
    required Duration tripDuration,
    required int fatigueCount,
    required double fatigueScore,
    required DateTime tripDate,
  }) async {
    final TripRecord record = TripRecord(
      id: tripDate.microsecondsSinceEpoch.toString(),
      tripDate: tripDate,
      tripDurationSeconds: tripDuration.inSeconds,
      fatigueCount: fatigueCount,
      fatigueScore: fatigueScore,
      uploadedToFirebase: false,
    );

    await _saveLocally(record);

    final bool uploaded = await _uploadToFirebase(record);
    if (uploaded) {
      await _markUploaded(record.id);
    }
  }

  Future<int> syncPendingTrips() async {
    final List<TripRecord> records = await loadTrips();
    int syncedCount = 0;

    for (final TripRecord record in records) {
      if (record.uploadedToFirebase) {
        continue;
      }

      final bool uploaded = await _uploadToFirebase(record);
      if (uploaded) {
        await _markUploaded(record.id);
        syncedCount++;
      }
    }

    return syncedCount;
  }

  Future<void> _saveLocally(TripRecord record) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<TripRecord> records = await loadTrips();
    records.insert(0, record);

    final List<String> encoded = records
        .map((TripRecord item) => jsonEncode(item.toLocalMap()))
        .toList();
    await prefs.setStringList(_tripHistoryKey, encoded);
  }

  Future<List<TripRecord>> loadTrips() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> encoded =
        prefs.getStringList(_tripHistoryKey) ?? <String>[];

    final List<TripRecord> records = <TripRecord>[];
    for (final String item in encoded) {
      try {
        final Object? decoded = jsonDecode(item);
        if (decoded is Map<String, dynamic>) {
          records.add(TripRecord.fromLocalMap(decoded));
        } else if (decoded is Map) {
          records.add(
            TripRecord.fromLocalMap(
              decoded.map(
                (Object? key, Object? value) =>
                    MapEntry(key.toString(), value),
              ),
            ),
          );
        }
      } catch (_) {
        // Skip malformed local records instead of failing entire load.
      }
    }

    return records;
  }

  Future<bool> _uploadToFirebase(TripRecord record) async {
    try {
      await FirebaseFirestore.instance
          .collection('trips')
          .doc(record.id)
          .set(record.toFirestoreMap());
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _markUploaded(String recordId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<TripRecord> records = await loadTrips();

    final List<TripRecord> updated = records
        .map(
          (TripRecord item) => item.id == recordId
              ? item.copyWith(uploadedToFirebase: true)
              : item,
        )
        .toList();

    final List<String> encoded = updated
        .map((TripRecord item) => jsonEncode(item.toLocalMap()))
        .toList();
    await prefs.setStringList(_tripHistoryKey, encoded);
  }
}
