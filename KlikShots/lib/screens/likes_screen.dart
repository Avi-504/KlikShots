import 'package:KlikShots/models/users.dart';
import 'package:KlikShots/widgets/progress.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'home.dart';

class LikeScreen extends StatefulWidget {
  final userId;
  final postId;
  LikeScreen({this.postId, this.userId});
  @override
  _LikeScreenState createState() => _LikeScreenState();
}

class _LikeScreenState extends State<LikeScreen> {
  final List<User> users = [];
  var isLoading = true;
  var isInit = true;
  var ref;
  @override
  void initState() {
    getuserLikes();
    postRef
        .document(widget.userId)
        .collection('userPost')
        .document(widget.postId)
        .get();

    super.initState();
  }

  void getuserLikes() async {
    DocumentSnapshot ref = await postRef
        .document(widget.userId)
        .collection('userPost')
        .document(widget.postId)
        .get();
    print(ref.data['likes']);
    setusers(context, ref);
  }

  void setusers(BuildContext context, DocumentSnapshot snapshot) {
    if (isInit) {
      Map likes = snapshot.data['likes'];
      likes.forEach((key, value) async {
        if (value) {
          DocumentSnapshot user = await userRef.document(key).get();
          final eachUser = User.fromDocument(user);
          setState(() {
            isLoading = false;
          });
          users.add(eachUser);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(
            'Likes',
            style: TextStyle(
              color: Colors.white,
            ),
          ),
          centerTitle: true,
        ),
        backgroundColor: Colors.grey[900],
        body: isLoading
            ? circularProgress()
            : ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.transparent,
                      backgroundImage:
                          CachedNetworkImageProvider(users[index].photoUrl),
                    ),
                    title: Text(
                      users[index].username,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    subtitle: Text(
                      users[index].displayName,
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.w400,
                        fontSize: 16,
                      ),
                    ),
                  );
                }));
  }
}
