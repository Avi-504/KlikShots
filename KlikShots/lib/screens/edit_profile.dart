import 'dart:async';
import 'dart:io';
import 'package:KlikShots/models/users.dart';
import 'package:KlikShots/screens/home.dart';
import 'package:KlikShots/widgets/progress.dart';
import 'package:cached_network_image/cached_network_image.dart';
// import 'package:cached_network_image/cached_network_image.dart';
import "package:flutter/material.dart";
// import 'package:flutter/scheduler.dart';
import 'package:image_picker/image_picker.dart';

class EditProfile extends StatefulWidget {
  final currentUserId;
  EditProfile({this.currentUserId});
  @override
  _EditProfileState createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  TextEditingController displayNameController = TextEditingController();
  TextEditingController bioController = TextEditingController();
  var isLoading = false;
  User user;
  final _picker = ImagePicker();
  File file;
  var _validDname = true;
  String userPhotoUrl;
  var isUploading = false;

  void selectImage() async {
    PickedFile galImg = await _picker.getImage(
      source: ImageSource.gallery,
      maxHeight: 675,
      maxWidth: 960,
    );
    setState(() {
      file = File(galImg.path);
    });
  }

  Future<void> uplaodImage() async {
    if (file != null) {
      final uploadTask = storageRef.child('User_${user.id}.jpg').putFile(file);
      final storageSnap = await uploadTask.onComplete;
      final postUrl = await storageSnap.ref.getDownloadURL();
      setState(() {
        userPhotoUrl = postUrl;
        // print(postUrl);
        return;
      });
    } else {
      setState(() {
        userPhotoUrl = user.photoUrl;
        // print('image is null');
      });
      return;
    }
  }

  void getUser() async {
    setState(() {
      isLoading = true;
    });
    final doc = await userRef.document(widget.currentUserId).get();
    user = User.fromDocument(doc);
    displayNameController.text = user.displayName;
    bioController.text = user.bio;
    setState(() {
      isLoading = false;
    });
  }

  @override
  void initState() {
    getUser();
    super.initState();
  }

  Widget displayNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(
            top: 10,
            bottom: 2,
          ),
          child: Text(
            'KlikShort ID',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
        ),
        TextField(
          controller: displayNameController,
          decoration: InputDecoration(
            fillColor: Colors.white54,
            filled: true,
            hintText: 'Update KS ID',
            errorText: _validDname ? null : 'KS ID too short',
          ),
        ),
      ],
    );
  }

  Widget bioField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(
            top: 10,
            bottom: 2,
          ),
          child: Text(
            'Bio',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
        ),
        TextField(
          maxLines: 10,
          keyboardType: TextInputType.multiline,
          controller: bioController,
          decoration: InputDecoration(
            fillColor: Colors.white54,
            filled: true,
            hintText: 'Update Bio ',
          ),
        ),
      ],
    );
  }

  Future<void> updateProfileData() async {
    setState(() {
      if (displayNameController.text.trim().length < 3 ||
          displayNameController.text.isEmpty) {
        _validDname = false;
      }
    });
    if (_validDname) {
      setState(() {
        isUploading = true;
      });
      await uplaodImage();
      await userRef.document(widget.currentUserId).updateData({
        'displayName': displayNameController.text,
        'bio': bioController.text,
        'photoUrl': userPhotoUrl,
      });
      SnackBar snackbar = SnackBar(content: Text('Profile Updated'));
      _scaffoldKey.currentState.showSnackBar(snackbar);
      setState(() {
        isUploading = false;
      });
      Timer(Duration(milliseconds: 1500), () {
        Navigator.of(context).pop(userPhotoUrl);
      });
    }
  }

  Future<bool> backHandler() {
    Navigator.of(context).pop(true);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: backHandler,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.grey[900],
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(
            'Edit Profile',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                Navigator.of(context)
                    .pop(file != null ? userPhotoUrl : user.photoUrl);
              },
            ),
          ],
        ),
        body: isLoading || isUploading
            ? circularProgress()
            : ListView(
                children: [
                  Container(
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                            top: 20,
                            bottom: 10,
                          ),
                          child: GestureDetector(
                            onTap: selectImage,
                            child: CircleAvatar(
                              backgroundColor: Colors.transparent,
                              radius: 50,
                              backgroundImage: file == null
                                  ? CachedNetworkImageProvider(user.photoUrl)
                                  : FileImage(file),
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(10),
                          child: Column(
                            children: [
                              displayNameField(),
                              bioField(),
                            ],
                          ),
                        ),
                        RaisedButton(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          color: Colors.blue,
                          onPressed: updateProfileData,
                          child: Text(
                            'Update Profile',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
