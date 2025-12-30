import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../models/deck_model.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<void> createUserDoc(String uid, String fullName, String email) async {
    await _firestore.collection('users').doc(uid).set({
      'fullName': fullName,
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
      'photoUrl': "",
    });
  }

  Future<Map<String, dynamic>?> getUserData(String uid) async {
    DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists && doc.data() != null) {
      return doc.data() as Map<String, dynamic>;
    }
    return null;
  }

  Future<void> updateUserData(String uid, {String? fullName, String? email}) async {
    Map<String, dynamic> data = {};
    if (fullName != null) data['fullName'] = fullName;
    if (email != null) data['email'] = email;
    
    if (data.isNotEmpty) {
      await _firestore.collection('users').doc(uid).set(data, SetOptions(merge: true));
    }
  }

  Future<String> uploadProfileImage(String uid, XFile image) async {
    final storageRef = _storage.ref().child('profile_images').child('$uid.jpg');
    final bytes = await image.readAsBytes();
    final metadata = SettableMetadata(contentType: 'image/jpeg');

    await storageRef.putData(bytes, metadata);
    String downloadUrl = await storageRef.getDownloadURL();
    
    downloadUrl = "$downloadUrl?t=${DateTime.now().millisecondsSinceEpoch}";

    await _firestore.collection('users').doc(uid).set({
      'photoUrl': downloadUrl
    }, SetOptions(merge: true));

    return downloadUrl;
  }

  Future<void> saveDeck(String uid, DeckModel deck) async {
    final decksRef = _firestore.collection('users').doc(uid).collection('decks');
    
    if (deck.id != null) {
      await decksRef.doc(deck.id).update(deck.toMap());
    } else {
      DocumentReference docRef = await decksRef.add(deck.toMap());
      deck.id = docRef.id;
    }
  }

  Future<void> deleteDeck(String uid, String deckId) async {
    await _firestore.collection('users').doc(uid).collection('decks').doc(deckId).delete();
  }

  Stream<QuerySnapshot> getUserDecksStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('decks')
        .orderBy('updatedAt', descending: true)
        .snapshots();
  }
}