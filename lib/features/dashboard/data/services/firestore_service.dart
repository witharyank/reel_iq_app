import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/models/content_calendar_model.dart';

class FirestoreCalendarService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String?> _uid() async => _auth.currentUser?.uid;

  Future<void> saveCalendar(ContentCalendarModel calendar) async {
    final uid = await _uid();
    if (uid == null) return;
    final docRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('calendars')
        .doc(calendar.id);
    await docRef.set(calendar.toJson());
    // Save days as sub‑collection
    final batch = _firestore.batch();
    for (final day in calendar.days) {
      final dayRef = docRef.collection('days').doc(day.day.toString());
      batch.set(dayRef, day.toJson());
    }
    await batch.commit();
  }

  Future<List<ContentCalendarModel>> fetchCalendars() async {
    final uid = await _uid();
    if (uid == null) return [];
    final snapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('calendars')
        .orderBy('createdAt', descending: true)
        .get();
    final calendars = <ContentCalendarModel>[];
    for (final doc in snapshot.docs) {
      final calendar = ContentCalendarModel.fromJson(doc.data());
      final daysSnap = await doc.reference.collection('days').get();
      calendar.days = daysSnap.docs
          .map((d) => ContentCalendarDay.fromJson(d.data()))
          .toList();
      calendars.add(calendar);
    }
    return calendars;
  }

  Future<void> deleteCalendar(String calendarId) async {
    final uid = await _uid();
    if (uid == null) return;
    final docRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('calendars')
        .doc(calendarId);
    // Delete sub‑collection days first
    final days = await docRef.collection('days').get();
    for (final d in days.docs) {
      await d.reference.delete();
    }
    await docRef.delete();
  }
}
