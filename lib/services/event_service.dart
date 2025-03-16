import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unibuzz_community/models/event_model.dart';
import 'package:unibuzz_community/services/auth_service.dart';
import 'package:unibuzz_community/services/image_hosting_service.dart';

class EventService {
  static final EventService _instance = EventService._internal();
  factory EventService() => _instance;
  EventService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot> getEventsStream({String? category}) {
    var query = _firestore
        .collection('events')
        .where('dateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime.now()))
        .orderBy('dateTime');

    if (category != null && category != 'All') {
      query = query.where('category', isEqualTo: category);
    }

    return query.snapshots();
  }

  Future<void> createEvent(Event event) async {
    final user = AuthService().currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _firestore.collection('events').add({
      'title': event.title,
      'description': event.description,
      'category': event.category,
      'location': event.location,
      'coordinates': event.coordinates,
      'dateTime': Timestamp.fromDate(event.dateTime),
      'organizerId': user.uid,
      'imageUrl': event.imageUrl,
      'maxAttendees': event.maxAttendees,
      'attendees': [],
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> toggleAttendance(String eventId) async {
    final user = AuthService().currentUser;
    if (user == null) throw Exception('User not authenticated');

    final eventRef = _firestore.collection('events').doc(eventId);
    
    return _firestore.runTransaction((transaction) async {
      final eventDoc = await transaction.get(eventRef);
      if (!eventDoc.exists) throw Exception('Event not found');

      final List<String> attendees = List<String>.from(eventDoc.data()?['attendees'] ?? []);
      final int maxAttendees = eventDoc.data()?['maxAttendees'] ?? 0;

      if (attendees.contains(user.uid)) {
        attendees.remove(user.uid);
      } else if (maxAttendees == 0 || attendees.length < maxAttendees) {
        attendees.add(user.uid);
      } else {
        throw Exception('Event is full');
      }

      transaction.update(eventRef, {'attendees': attendees});
    });
  }

  Stream<DocumentSnapshot> getEventStream(String eventId) {
    return _firestore.collection('events').doc(eventId).snapshots();
  }

  Future<List<Event>> searchEvents(String query) async {
    final querySnapshot = await _firestore
        .collection('events')
        .where('dateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime.now()))
        .orderBy('dateTime')
        .get();

    return querySnapshot.docs
        .map((doc) => Event.fromMap(doc.data(), doc.id))
        .where((event) =>
            event.title.toLowerCase().contains(query.toLowerCase()) ||
            event.description.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  Future<void> deleteEvent(String eventId) async {
    final user = AuthService().currentUser;
    if (user == null) throw Exception('User not authenticated');

    final eventDoc = await _firestore.collection('events').doc(eventId).get();
    if (eventDoc.data()?['organizerId'] != user.uid) {
      throw Exception('Not authorized to delete this event');
    }

    await _firestore.collection('events').doc(eventId).delete();
  }

  Future<void> updateEvent(
    String eventId, {
    String? title,
    String? description,
    String? category,
    String? location,
    GeoPoint? coordinates,  // Add this parameter
    DateTime? dateTime,
    int? maxAttendees,
    String? imageUrl,
  }) async {
    final updates = <String, dynamic>{};
    if (title != null) updates['title'] = title;
    if (description != null) updates['description'] = description;
    if (category != null) updates['category'] = category;
    if (location != null) updates['location'] = location;
    if (coordinates != null) updates['coordinates'] = coordinates;  // Add this line
    if (dateTime != null) updates['dateTime'] = Timestamp.fromDate(dateTime);
    if (maxAttendees != null) updates['maxAttendees'] = maxAttendees;
    if (imageUrl != null) updates['imageUrl'] = imageUrl;

    await _firestore.collection('events').doc(eventId).update(updates);
  }
}
