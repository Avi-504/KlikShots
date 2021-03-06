import 'dart:async';

import 'package:KlikShots/models/users.dart';
import 'package:KlikShots/screens/comments.dart';
import 'package:KlikShots/screens/home.dart';
import 'package:KlikShots/screens/likes_screen.dart';
import 'package:KlikShots/screens/profile.dart';
import 'package:KlikShots/widgets/custom_image.dart';
import 'package:KlikShots/widgets/progress.dart';
import 'package:animator/animator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Post extends StatefulWidget {
  final postId;
  final userId;
  final username;
  final location;
  final caption;
  final mediaUrl;
  final likes;
  Post(
      {this.postId,
      this.userId,
      this.username,
      this.location,
      this.caption,
      this.mediaUrl,
      this.likes});

  factory Post.fromDocument(DocumentSnapshot doc) {
    return Post(
      postId: doc['postId'],
      userId: doc['userId'],
      mediaUrl: doc['mediaUrl'],
      likes: doc['likes'],
      caption: doc['caption'],
      location: doc['location'],
      username: doc['username'],
    );
  }
  int getLikesCount(likes) {
    if (likes == null) {
      return 0;
    }
    int count = 0;
    likes.values.forEach((value) {
      if (value) {
        count += 1;
      }
    });
    return count;
  }

  @override
  _PostState createState() => _PostState(
        postId: this.postId,
        userId: this.userId,
        location: this.location,
        caption: this.caption,
        likes: this.likes,
        username: this.username,
        mediaUrl: this.mediaUrl,
        likesCount: this.getLikesCount(this.likes),
      );
}

class _PostState extends State<Post> {
  final currentUserId = currentUser?.id;
  final postId;
  final userId;
  final username;
  final location;
  final caption;
  final mediaUrl;
  Map likes;
  int likesCount;
  var isLiked;
  var showHeart = false;
  _PostState({
    this.postId,
    this.userId,
    this.username,
    this.location,
    this.caption,
    this.mediaUrl,
    this.likes,
    this.likesCount,
  });

  Widget postHeader() {
    return FutureBuilder(
      future: userRef.document(userId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }
        final user = User.fromDocument(snapshot.data);
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(user.photoUrl),
            backgroundColor: Colors.transparent,
          ),
          title: GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => Profile(
                  profileId: user.id,
                ),
              ),
            ),
            child: Text(
              user.username,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          subtitle: Text(
            location,
            style: TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.w300,
            ),
          ),
          trailing: IconButton(
            icon: Icon(
              Icons.more_vert,
              color: Colors.white,
            ),
            onPressed: null,
          ),
        );
      },
    );
  }

  void addLikeToActivityFeed() {
    var isNotPostOwner = currentUserId != userId;
    if (isNotPostOwner) {
      activityRef
          .document(userId)
          .collection('feedItem')
          .document(postId)
          .setData({
        'type': 'like',
        'username': currentUser.username,
        'userId': currentUser.id,
        'userProfileImg': currentUser.photoUrl,
        'postId': postId,
        'mediaUrl': mediaUrl,
        'timestamp': DateTime.now(),
      });
    }
  }

  void removeLikeFromActivityFeed() {
    var isNotPostOwner = currentUserId != userId;
    if (isNotPostOwner) {
      activityRef
          .document(userId)
          .collection('feedItem')
          .document(postId)
          .get()
          .then((value) {
        if (value.exists) {
          value.reference.delete();
        }
      });
    }
  }

  void handleLikePost() {
    var _isLiked = likes[currentUserId] == true;
    if (_isLiked) {
      postRef
          .document(userId)
          .collection('userPost')
          .document(postId)
          .updateData({
        'likes.$currentUserId': false,
      });
      removeLikeFromActivityFeed();
      setState(() {
        likesCount -= 1;
        isLiked = false;
        likes[currentUserId] = false;
      });
    } else if (!_isLiked) {
      postRef
          .document(userId)
          .collection('userPost')
          .document(postId)
          .updateData({
        'likes.$currentUserId': true,
      });
      addLikeToActivityFeed();
      setState(() {
        likesCount += 1;
        isLiked = true;
        showHeart = true;
        likes[currentUserId] = true;
      });
      Timer(Duration(milliseconds: 1300), () {
        setState(() {
          showHeart = false;
        });
      });
    }
  }

  Widget postImage() {
    return Container(
      width: MediaQuery.of(context).size.width * 1,
      child: GestureDetector(
        onDoubleTap: handleLikePost,
        child: Stack(
          alignment: Alignment.center,
          children: [
            cachedNetworkImage(mediaUrl),
            showHeart
                ? Animator(
                    duration: Duration(milliseconds: 900),
                    tween: Tween(begin: 0.8, end: 1.4),
                    curve: Curves.elasticOut,
                    cycles: 0,
                    builder: (context, animatorState, child) => Transform.scale(
                          scale: animatorState.value,
                          child: Icon(
                            Icons.favorite,
                            color: Colors.white30,
                            size: 150,
                          ),
                        ))
                : Text(''),
          ],
        ),
      ),
    );
  }

  Widget postFooter() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(top: 10, left: 20),
              child: GestureDetector(
                onTap: handleLikePost,
                child: isLiked
                    ? Icon(
                        Icons.favorite,
                        size: 28,
                        color: Colors.red,
                      )
                    : Icon(
                        Icons.favorite_border,
                        size: 28,
                        color: Colors.red,
                      ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 10, left: 30),
              child: GestureDetector(
                onTap: () => showComments(
                  context,
                  postId: postId,
                  userId: userId,
                  mediaUrl: mediaUrl,
                ),
                child: Icon(
                  Icons.mode_comment,
                  size: 28,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        Row(
          children: [
            GestureDetector(
              onTap: likesCount == 0
                  ? null
                  : () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => LikeScreen(
                            postId: postId,
                            userId: userId,
                          ),
                          fullscreenDialog: true,
                        ),
                      );
                    },
              child: Container(
                margin: EdgeInsets.only(
                  left: 20,
                ),
                child: Text(
                  '$likesCount likes',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
        Row(
          children: [
            Container(
              margin: EdgeInsets.only(
                left: 20,
                top: 2,
              ),
              child: Text(
                '$username',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.03,
            ),
            Expanded(
              child: Text(
                caption,
                softWrap: true,
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void showComments(
    BuildContext context, {
    String mediaUrl,
    String postId,
    String userId,
  }) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (ctx) {
        return Comments(
          postId: postId,
          postOwnerId: userId,
          postMediaUrl: mediaUrl,
        );
      },
    ));
  }

  @override
  Widget build(BuildContext context) {
    isLiked = (likes[currentUserId] == true);
    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        postHeader(),
        postImage(),
        postFooter(),
        Divider(
          color: Colors.grey,
        ),
      ],
    );
  }
}
