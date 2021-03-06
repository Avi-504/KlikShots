import 'package:KlikShots/widgets/header.dart';
// import 'package:KlikShots/widgets/progress.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final userRef = Firestore.instance.collection('users');

class Timeline extends StatefulWidget {
  @override
  _TimelineState createState() => _TimelineState();
}

class _TimelineState extends State<Timeline> {
  @override
  Widget build(context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: header(context),
      body: Text('TimeLine'),
    );
  }
}
