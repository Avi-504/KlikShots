import 'package:KlikShots/models/users.dart';
import 'package:KlikShots/screens/edit_profile.dart';
import 'package:KlikShots/widgets/post.dart';
import 'package:KlikShots/widgets/post_tile.dart';
import 'package:KlikShots/widgets/progress.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'home.dart';

class Profile extends StatefulWidget {
  final profileId;
  Profile({this.profileId});
  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  var isLoading = false;
  var postCount = 0;
  var followerCount = 0;
  var followingCount = 0;
  var firstLoad = true;
  var oldUrl;
  var postOrientation = 'grid';
  var isFollowing = false;
  List<Post> posts = [];
  bool isProfileOwner;
  @override
  void initState() {
    if (firstLoad) {}

    getProfilePost();
    getFollowers();
    getFollowing();
    checkIfFollowing();
    super.initState();
  }

  void checkIfFollowing() async {
    final follower = await followersRef
        .document(widget.profileId)
        .collection('userFollowers')
        .document(currentUserId)
        .get();
    setState(() {
      isFollowing = follower.exists;
    });
  }

  void getFollowers() async {
    final followers = await followersRef
        .document(widget.profileId)
        .collection('userFollowers')
        .getDocuments();
    setState(() {
      followerCount = followers.documents.length;
    });
  }

  void getFollowing() async {
    final following = await followingRef
        .document(widget.profileId)
        .collection('userFollowing')
        .getDocuments();
    setState(() {
      followingCount = following.documents.length;
    });
  }

  @override
  void didChangeDependencies() {
    if (firstLoad) {
      oldUrl = currentUser.photoUrl;
      firstLoad = false;
    }
    firstLoad = false;
    super.didChangeDependencies();
  }

  User user;

  final currentUserId = currentUser?.id;

  void getProfilePost() async {
    setState(() {
      isLoading = true;
    });
    final snapshot = await postRef
        .document(widget.profileId)
        .collection('userPost')
        .orderBy('timestamp', descending: true)
        .getDocuments();
    setState(() {
      isLoading = false;
      postCount = snapshot.documents.length;
      posts = snapshot.documents.map((doc) => Post.fromDocument(doc)).toList();
    });
  }

  Widget countColumn(String label, int count) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Container(
          margin: EdgeInsets.only(
            top: 4,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 15,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  void editProfile() {
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) => EditProfile(currentUserId: currentUserId),
      ),
    )
        .then((value) {
      setState(() {
        currentUser.photoUrl = value;
      });
    });
  }

  Widget profileButton() {
    isProfileOwner = currentUserId == widget.profileId;
    if (isProfileOwner) {
      return button(
        label: 'Edit Profile',
        function: editProfile,
      );
    } else if (isFollowing) {
      return button(
        label: 'Unfollow',
        function: unFollowUser,
      );
    } else if (!isFollowing) {
      return button(
        label: 'Follow',
        function: followUser,
      );
    }
    return Text('');
  }

  void unFollowUser() {
    setState(() {
      isFollowing = false;
    });
    followersRef
        .document(widget.profileId)
        .collection('userFollowers')
        .document(currentUserId)
        .get()
        .then((value) {
      if (value.exists) {
        value.reference.delete();
      }
    });
    followingRef
        .document(currentUserId)
        .collection('UserFollowing')
        .document(widget.profileId)
        .get()
        .then((value) {
      if (value.exists) {
        value.reference.delete();
      }
    });
    activityRef
        .document(widget.profileId)
        .collection('feedItem')
        .document(currentUserId)
        .get()
        .then((value) {
      if (value.exists) {
        value.reference.delete();
      }
    });
  }

  void followUser() {
    setState(() {
      isFollowing = true;
    });
    followersRef
        .document(widget.profileId)
        .collection('userFollowers')
        .document(currentUserId)
        .setData({});
    followingRef
        .document(currentUserId)
        .collection('UserFollowing')
        .document(widget.profileId)
        .setData({});
    activityRef
        .document(widget.profileId)
        .collection('feedItem')
        .document(currentUserId)
        .setData({
      'type': 'follow',
      'ownerId': widget.profileId,
      'username': currentUser.username,
      'userId': currentUserId,
      'userProfileImg': currentUser.photoUrl,
      'timestamp': DateTime.now(),
    });
  }

  Widget button({String label, Function function}) {
    isProfileOwner = currentUserId == widget.profileId;
    return Container(
      padding: EdgeInsets.only(top: 2),
      child: FlatButton(
        onPressed: function,
        child: Container(
          width: 250,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isProfileOwner ? Colors.transparent : Colors.blue,
            border: isProfileOwner
                ? Border.all(color: Colors.grey)
                : Border.all(color: Colors.white),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget buildProfileHeader() {
    return FutureBuilder(
      future: userRef.document(widget.profileId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }
        user = User.fromDocument(snapshot.data);
        return Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.transparent,
                    backgroundImage: CachedNetworkImageProvider(
                      currentUser.photoUrl != null
                          ? currentUser.photoUrl
                          : oldUrl,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            countColumn('Post', postCount),
                            countColumn('Followers', followerCount),
                            countColumn('Following', followingCount),
                          ],
                        )
                      ],
                    ),
                    flex: 1,
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  profileButton(),
                ],
              ),
              Container(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.only(top: 7),
                child: Text(
                  user.username,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
              ),
              Container(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.only(top: 3),
                child: Text(
                  user.displayName,
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.w400,
                    fontSize: 16,
                  ),
                ),
              ),
              Container(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.only(top: 2),
                child: Text(
                  user.bio,
                  softWrap: true,
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget buildProfilePost() {
    if (isLoading) {
      return circularProgress();
    } else if (posts.isEmpty) {
      return Container(
        color: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SvgPicture.asset(
              'assets/images/no_content.svg',
              height: MediaQuery.of(context).size.height * 0.25,
            ),
            Padding(
              padding: EdgeInsets.only(
                top: 15,
              ),
              child: Text(
                'No Posts',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    } else if (postOrientation == 'grid') {
      List<GridTile> gridTile = [];
      posts.forEach((post) {
        gridTile.add(
          GridTile(
            child: PostTile(post),
          ),
        );
      });
      return GridView.count(
        crossAxisCount: 3,
        childAspectRatio: 1,
        mainAxisSpacing: 1.5,
        crossAxisSpacing: 1.5,
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        children: gridTile,
      );
    } else {
      return Column(
        children: posts,
      );
    }
  }

  void setPostOrientation(String orientation) {
    setState(() {
      postOrientation = orientation;
    });
  }

  Widget buildTogglePostOrientation() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
            icon: Icon(
              Icons.grid_on,
              color: Colors.white,
            ),
            onPressed: () => setPostOrientation('grid')),
        IconButton(
            icon: Icon(
              Icons.list,
              color: Colors.white,
            ),
            onPressed: () => setPostOrientation('list')),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    isProfileOwner = currentUserId == widget.profileId;
    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        title: Text(
          'Profile',
          style: TextStyle(
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      drawer: isProfileOwner
          ? Drawer(
              child: Container(
                color: Colors.black87,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: Text(
                              '@${currentUser.username}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Divider(
                            color: Colors.grey,
                          ),
                          ListTile(
                            leading: Text(
                              'Got Issues?',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            onTap: () {},
                          ),
                          Divider(),
                        ],
                      ),
                    ),
                    ListTile(
                      leading: Icon(
                        Icons.exit_to_app,
                        color: Colors.white,
                        size: 25,
                      ),
                      title: Text(
                        'Logout',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      onTap: () {
                        googleSignIn.signOut();
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => Home(),
                        ));
                      },
                    ),
                  ],
                ),
              ),
            )
          : null,
      body: ListView(
        children: [
          buildProfileHeader(),
          Divider(
            height: 0.0,
          ),
          buildTogglePostOrientation(),
          Divider(),
          buildProfilePost(),
        ],
      ),
    );
  }
}
