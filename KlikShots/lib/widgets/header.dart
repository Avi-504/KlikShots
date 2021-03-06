import 'package:flutter/material.dart';

AppBar header(BuildContext context) {
  return AppBar(
    automaticallyImplyLeading: false,
    title: Text(
      'KlikShots',
      style: TextStyle(
        fontFamily: 'Signatra',
        fontSize: 40,
        color: Colors.white,
      ),
    ),
    centerTitle: true,
    backgroundColor: Theme.of(context).primaryColor,
  );
}
