import 'package:KlikShots/screens/post_screen.dart';
import 'package:KlikShots/screens/profile.dart';
import 'package:KlikShots/widgets/progress.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'home.dart';
import 'package:timeago/timeago.dart' as timeago;

class ActivityFeed extends StatefulWidget {
  @override
  _ActivityFeedState createState() => _ActivityFeedState();
}

class _ActivityFeedState extends State<ActivityFeed> {
  Future<List<ActivityFeedItem>> getActivityFeed() async {
    final snapshot = await activityRef
        .document(currentUser.id)
        .collection('feedItem')
        .orderBy('timestamp', descending: true)
        .limit(25)
        .getDocuments();
    List<ActivityFeedItem> feedItems = [];
    snapshot.documents.forEach((doc) {
      feedItems.add(ActivityFeedItem.fromDocument(doc));
    });

    return feedItems;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Activity'),
        centerTitle: true,
      ),
      backgroundColor: Colors.black87,
      body: Container(
        child: FutureBuilder(
          future: getActivityFeed(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return linearProgress();
            }
            return ListView(
              children: snapshot.data,
            );
          },
        ),
      ),
    );
  }
}

Widget mediaPreview;
String activityItemText;

class ActivityFeedItem extends StatelessWidget {
  final username;
  final userId;
  final timeStamp;
  final type;
  final postId;
  final userProfileImg;
  final mediaUrl;
  final commentData;
  ActivityFeedItem({
    this.username,
    this.userId,
    this.timeStamp,
    this.type,
    this.postId,
    this.userProfileImg,
    this.mediaUrl,
    this.commentData,
  });
  factory ActivityFeedItem.fromDocument(DocumentSnapshot doc) {
    return ActivityFeedItem(
      username: doc['username'],
      userId: doc['userId'],
      timeStamp: doc['timestamp'],
      type: doc['type'],
      postId: doc['postId'],
      userProfileImg: doc['userProfileImg'],
      mediaUrl: doc['mediaUrl'],
      commentData: doc['commentData'],
    );
  }

  void showPost(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => PostScreen(
        postId: postId,
        userId: userId,
      ),
    ));
  }

  void configureMediaPreview(BuildContext ctx) {
    if (type == 'like' || type == 'comment') {
      mediaPreview = GestureDetector(
        onTap: () => showPost(ctx),
        child: Container(
          height: 50,
          width: 50,
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  fit: BoxFit.cover,
                  image: CachedNetworkImageProvider(mediaUrl),
                ),
              ),
            ),
          ),
        ),
      );
    } else {
      mediaPreview = Text('');
    }
    if (type == 'like') {
      activityItemText = 'liked Your Post';
    } else if (type == 'follow') {
      activityItemText = 'started Following you';
    } else if (type == 'comment') {
      activityItemText = 'replied: $commentData';
    }
  }

  void showProfile(BuildContext context, {String profileId}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Profile(
          profileId: profileId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    configureMediaPreview(context);
    return Padding(
      padding: EdgeInsets.only(
        bottom: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            color: Colors.transparent,
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: CachedNetworkImageProvider(userProfileImg),
              ),
              title: GestureDetector(
                onTap: () => showProfile(context, profileId: userId),
                child: RichText(
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                    ),
                    children: [
                      TextSpan(
                        text: username,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: ' $activityItemText',
                      ),
                    ],
                  ),
                ),
              ),
              subtitle: Text(
                timeago.format(timeStamp.toDate()),
                style: TextStyle(
                  color: Colors.grey,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              trailing: mediaPreview,
            ),
          ),
          Divider(
            color: Colors.grey,
          ),
        ],
      ),
    );
  }
}
