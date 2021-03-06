import 'package:KlikShots/screens/post_screen.dart';
import 'package:KlikShots/widgets/custom_image.dart';
import 'package:KlikShots/widgets/post.dart';
import 'package:flutter/material.dart';

class PostTile extends StatelessWidget {
  final Post post;
  PostTile(this.post);
  void showPost(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => PostScreen(
        postId: post.postId,
        userId: post.userId,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showPost(context),
      child: cachedNetworkImage(post.mediaUrl),
    );
  }
}
