import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String id;
  final String username;
  final String bio;
  final String email;
  String photoUrl;
  final String displayName;

  User({
    this.id,
    this.bio,
    this.displayName,
    this.email,
    this.photoUrl,
    this.username,
  });

  factory User.fromDocument(DocumentSnapshot doc) {
    return User(
      id: doc['id'],
      username: doc['username'],
      email: doc['email'],
      photoUrl: doc['photoUrl'],
      bio: doc['bio'],
      displayName: doc['displayName'],
    );
  }
}
