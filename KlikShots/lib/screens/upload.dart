import 'dart:io';
import 'package:KlikShots/models/users.dart';
import 'package:KlikShots/widgets/progress.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as Img;
import 'package:uuid/uuid.dart';
import 'home.dart';

class Upload extends StatefulWidget {
  final User currentUser;
  Upload({this.currentUser});
  @override
  _UploadState createState() => _UploadState();
}

class _UploadState extends State<Upload> {
  final locationController = TextEditingController();
  final captionController = TextEditingController();
  File file;
  var isUploading = false;
  String postId = Uuid().v4();
  void handleTakePhoto() async {
    Navigator.of(context).pop();
    final _picker = ImagePicker();
    PickedFile camImg = await _picker.getImage(
      source: ImageSource.camera,
      maxHeight: 675,
      maxWidth: 960,
    );
    setState(() {
      file = File(camImg.path);
    });
  }

  void handlePickPhoto() async {
    Navigator.of(context).pop();
    final _picker = ImagePicker();
    PickedFile galImg = await _picker.getImage(
      source: ImageSource.gallery,
      maxHeight: 675,
      maxWidth: 960,
    );
    setState(() {
      file = File(galImg.path);
    });
  }

  Future selectImage(BuildContext ctx) {
    return showDialog(
      context: ctx,
      builder: (context) {
        return SimpleDialog(
          title: Text('Create Post'),
          children: <Widget>[
            SimpleDialogOption(
              child: Text('Use Camera'),
              onPressed: handleTakePhoto,
            ),
            SimpleDialogOption(
              child: Text('Pick from Gallery'),
              onPressed: handlePickPhoto,
            ),
          ],
        );
      },
    );
  }

  Widget buildSplashScreen() {
    return Container(
      color: Colors.black87,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          SvgPicture.asset(
            'assets/images/upload.svg',
            height: MediaQuery.of(context).size.height * 0.47,
          ),
          Padding(
            padding: EdgeInsets.only(
              top: 15,
            ),
            child: RaisedButton(
              color: Colors.blue,
              onPressed: () => selectImage(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  7,
                ),
              ),
              child: Text(
                'Upload Images',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void clearImage() {
    setState(() {
      file = null;
    });
  }

  Future<void> compressImage() async {
    final tempDir = await getTemporaryDirectory();
    final path = tempDir.path;
    Img.Image imageFile = Img.decodeImage(file.readAsBytesSync());
    final compressedImageFile = File('$path/img_$postId.jpg')
      ..writeAsBytesSync(
        Img.encodeJpg(
          imageFile,
          quality: 80,
        ),
      );
    setState(() {
      file = compressedImageFile;
    });
  }

  Future<dynamic> uploadImage(imageFile) async {
    final uploadTask = storageRef.child('post_$postId.jpg').putFile(imageFile);
    final storageSnap = await uploadTask.onComplete;
    final postUrl = await storageSnap.ref.getDownloadURL();
    return postUrl;
  }

  void createPostInFirestore(
      {String mediaUrl, String location, String caption}) {
    postRef
        .document(widget.currentUser.id)
        .collection('userPost')
        .document(postId)
        .setData({
      'postId': postId,
      'userId': widget.currentUser.id,
      'username': widget.currentUser.username,
      'mediaUrl': mediaUrl,
      'caption': caption,
      'timestamp': timestamp,
      'location': location,
      'likes': {},
    });
  }

  void handleSubmit() async {
    setState(() {
      isUploading = true;
    });
    await compressImage();
    var mediaUrl = await uploadImage(file);
    createPostInFirestore(
      mediaUrl: mediaUrl,
      location: locationController.text,
      caption: captionController.text,
    );
    captionController.clear();
    locationController.clear();
    setState(() {
      isUploading = false;
      file = null;
      postId = Uuid().v4();
    });
  }

  Widget buildUploadForm() {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: Colors.white,
            ),
            onPressed: clearImage),
        title: Text(
          'Caption Post',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        actions: <Widget>[
          FlatButton(
            onPressed: isUploading ? null : () => handleSubmit(),
            child: Text(
              'Post',
              style: TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        children: <Widget>[
          if (isUploading) linearProgress(),
          Container(
            height: MediaQuery.of(context).size.height * 0.27,
            width: MediaQuery.of(context).size.width * 0.8,
            child: Center(
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: FileImage(file),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: 15),
          ),
          ListTile(
            leading: CircleAvatar(
              backgroundImage:
                  CachedNetworkImageProvider(widget.currentUser.photoUrl),
            ),
            title: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              child: TextField(
                controller: captionController,
                decoration: InputDecoration(
                  hintText: 'Write a Caption...',
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          Divider(),
          ListTile(
            leading: Icon(
              Icons.pin_drop,
              color: Colors.blue,
              size: 35,
            ),
            title: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              child: TextField(
                controller: locationController,
                decoration: InputDecoration(
                  hintText: 'Add Location',
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          Container(
            width: 220,
            height: 80,
            alignment: Alignment.center,
            child: RaisedButton.icon(
              color: Colors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(3),
              ),
              onPressed: getUserLocation,
              icon: Icon(
                Icons.my_location,
                color: Colors.white,
              ),
              label: Text(
                'Pick Current Location',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void getUserLocation() async {
    final position = await Geolocator()
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    final placeMarks = await Geolocator()
        .placemarkFromCoordinates(position.latitude, position.longitude);
    final placeMark = placeMarks[0];
    final formattedLocation =
        '${placeMark.locality}, ${placeMark.subAdministrativeArea},${placeMark.administrativeArea},${placeMark.country},';
    locationController.text = formattedLocation;
  }

  @override
  Widget build(BuildContext context) {
    return file == null ? buildSplashScreen() : buildUploadForm();
  }
}
