import 'package:KlikShots/screens/home.dart';
import 'package:KlikShots/widgets/progress.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:flutter/material.dart';

class Comments extends StatefulWidget {
  final postId;
  final postOwnerId;
  final postMediaUrl;
  Comments({
    this.postId,
    this.postMediaUrl,
    this.postOwnerId,
  });
  @override
  CommentsState createState() => CommentsState(
        postId: this.postId,
        postMediaUrl: this.postMediaUrl,
        postOwnerId: this.postOwnerId,
      );
}

class CommentsState extends State<Comments> {
  TextEditingController commentController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final postId;
  final postOwnerId;
  final postMediaUrl;
  var isValid = false;
  CommentsState({
    this.postId,
    this.postMediaUrl,
    this.postOwnerId,
  });
  Widget buildComments() {
    return StreamBuilder(
      stream: commentRef
          .document(postId)
          .collection('comments')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }
        List<Comment> comments = [];
        snapshot.data.documents.forEach((doc) {
          comments.add(Comment.fromDocument(doc));
        });
        return ListView(
          children: comments,
        );
      },
    );
  }

  void addComment() async {
    setState(() {
      isValid = _formKey.currentState.validate();
    });
    var isNotPostOwner = currentUser.id != postOwnerId;
    if (isValid) {
      FocusScope.of(context).unfocus();
      await commentRef.document(postId).collection('comments').add({
        'username': currentUser.username,
        'comment': commentController.text,
        'timestamp': DateTime.now(),
        'avatarUrl': currentUser.photoUrl,
        'userid': currentUser.id,
      });
      if (isNotPostOwner) {
        await activityRef.document(postOwnerId).collection('feedItem').add({
          'type': 'comment',
          'commentData': commentController.text,
          'username': currentUser.username,
          'userId': currentUser.id,
          'userProfileImg': currentUser.photoUrl,
          'postId': postId,
          'mediaUrl': postMediaUrl,
          'timestamp': DateTime.now(),
        });
      }
      commentController.clear();
    }
    commentController.clear();
    FocusScope.of(context).unfocus();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: Text('Comments'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(child: buildComments()),
          Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
            child: Form(
              key: _formKey,
              child: ListTile(
                title: TextFormField(
                  validator: (value) {
                    if (value.trim().length == 0 || value.isEmpty) {
                      return '';
                    }
                    return null;
                  },
                  controller: commentController,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white70,
                    labelText: 'Write a Comment...',
                    labelStyle: TextStyle(
                      color: Colors.black,
                    ),
                    suffixIcon: OutlineButton(
                      onPressed: addComment,
                      borderSide: BorderSide.none,
                      child: Text(
                        'Post',
                        style: TextStyle(
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class Comment extends StatelessWidget {
  final username;
  final userId;
  final avatarUrl;
  final comment;
  final timestamp;
  Comment({
    this.avatarUrl,
    this.comment,
    this.timestamp,
    this.userId,
    this.username,
  });

  factory Comment.fromDocument(DocumentSnapshot doc) {
    return Comment(
      username: doc['username'],
      userId: doc['userId'],
      timestamp: doc['timestamp'],
      avatarUrl: doc['avatarUrl'],
      comment: doc['comment'],
    );
  }
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: Text(
            comment,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
            ),
          ),
          leading: CircleAvatar(
            backgroundColor: Colors.transparent,
            backgroundImage: CachedNetworkImageProvider(avatarUrl),
          ),
          trailing: Text(
            timeago.format(
              timestamp.toDate(),
            ),
            style: TextStyle(
              color: Colors.grey,
            ),
            softWrap: true,
          ),
          subtitle: Text(
            username,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Divider(),
      ],
    );
  }
}
