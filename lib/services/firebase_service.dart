import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseService {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseStorage storage = FirebaseStorage.instance;

  Future<DocumentSnapshot> getUserData(String uid) async {
    return await firestore.collection('users').doc(uid).get();
  }

  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    await firestore.collection('users').doc(uid).update(data);
  }

  Future<String> uploadProfilePicture(String uid, File image) async {
    final ref = storage.ref().child('profile_pictures/$uid.jpg');
    await ref.putFile(image);
    final url = await ref.getDownloadURL();
    await firestore
        .collection('users')
        .doc(uid)
        .update({'profileImageUrl': url});
    return url;
  }

  Future<void> changePassword(
      String currentPassword, String newPassword) async {
    final user = auth.currentUser;
    if (user == null) throw Exception('Không có người dùng đăng nhập');

    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);
  }

  Future<void> deleteAccount() async {
    final user = auth.currentUser;
    if (user == null) throw Exception('Không có người dùng đăng nhập');

    await firestore.collection('users').doc(user.uid).delete();
    await storage
        .ref()
        .child('profile_pictures/${user.uid}.jpg')
        .delete()
        .catchError((_) {});
    await user.delete();
  }

  Future<void> signOut() async {
    await auth.signOut();
  }
}
