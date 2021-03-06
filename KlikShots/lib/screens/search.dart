import 'package:KlikShots/models/users.dart';
import 'package:KlikShots/screens/profile.dart';
import 'package:KlikShots/widgets/progress.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'home.dart';

class Search extends StatefulWidget {
  @override
  _SearchState createState() => _SearchState();
}

class _SearchState extends State<Search> {
  final searchController = TextEditingController();
  Future<QuerySnapshot> searchUsers;

  void handleSearch(String input) {
    Future<QuerySnapshot> users = userRef
        .where('displayName', isGreaterThanOrEqualTo: input)
        .getDocuments();
    setState(() {
      searchUsers = users;
    });
  }

  Widget searchField() {
    return AppBar(
      backgroundColor: Colors.white,
      title: TextFormField(
        controller: searchController,
        decoration: InputDecoration(
          hintText: 'Search For a User..',
          filled: true,
          prefixIcon: Icon(
            Icons.account_box,
            size: 25,
          ),
          suffixIcon: IconButton(
            icon: Icon(Icons.clear),
            onPressed: searchController.clear,
          ),
        ),
        onFieldSubmitted: handleSearch,
      ),
    );
  }

  Widget noContent() {
    return Container(
      child: Center(
        child: ListView(
          shrinkWrap: true,
          children: <Widget>[
            SvgPicture.asset(
              'assets/images/search.svg',
              height: MediaQuery.of(context).size.height * 0.47,
            ),
            Text(
              'Find Users',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 50.0,
                  fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }

  Widget searchResults() {
    return FutureBuilder(
      future: searchUsers,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }
        final List<UserResult> searchedUsers = [];
        snapshot.data.documents.forEach((doc) {
          User user = User.fromDocument(doc);
          UserResult searchResult = UserResult(user);
          searchedUsers.add(searchResult);
        });
        return ListView(
          children: searchedUsers,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: searchField(),
      body: searchUsers == null ? noContent() : searchResults(),
    );
  }
}

class UserResult extends StatelessWidget {
  final User user;
  UserResult(this.user);
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white10,
      child: Column(
        children: <Widget>[
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => Profile(
                  profileId: user.id,
                ),
              ),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: CachedNetworkImageProvider(user.photoUrl),
                backgroundColor: Colors.black,
              ),
              title: Text(
                user.displayName,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                user.username,
                style: TextStyle(
                  color: Colors.white54,
                ),
              ),
            ),
          ),
          Divider(
            height: 2,
            color: Colors.white38,
          ),
        ],
      ),
    );
  }
}
