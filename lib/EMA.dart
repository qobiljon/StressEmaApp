import 'dart:convert';

import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class EMA extends StatefulWidget {
  static const String route_name = '/ema';

  @override
  State<StatefulWidget> createState() => _EMAState();
}

class _EMAState extends State<EMA> {
  static const ACTIVITIES = {0: 'meeting', 1: 'work', 2: 'drive', 3: 'housework', 4: 'socialize', 5: 'rest', 6: 'exercise', 7: 'entertainment'};
  int _cheerfulValue = 2;
  int _happyValue = 2;
  int _angryValue = 2;
  int _nervousValue = 2;
  int _sadValue = 2;
  int _activityValue = 0;
  int _userId;
  Position _position;

  @override
  void initState() {
    _determinePosition().then((position) => _position = position);

    SharedPreferences.getInstance().then((prefs) {
      if (prefs.containsKey('userId'))
        _userId = prefs.getInt('userId');
      else
        Navigator.of(context).pop();
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(240, 242, 245, 1),
      appBar: AppBar(title: Text('Submit EMA')),
      body: ListView(
        children: [
          Card(
            margin: EdgeInsets.all(10),
            child: Container(
              padding: EdgeInsets.all(16),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text('Cheerful ?', style: TextStyle(fontSize: 24)),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Radio(value: 0, groupValue: _cheerfulValue, onChanged: _cheerfulChange),
                  Radio(value: 1, groupValue: _cheerfulValue, onChanged: _cheerfulChange),
                  Radio(value: 2, groupValue: _cheerfulValue, onChanged: _cheerfulChange),
                  Radio(value: 3, groupValue: _cheerfulValue, onChanged: _cheerfulChange),
                  Radio(value: 4, groupValue: _cheerfulValue, onChanged: _cheerfulChange),
                ]),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Not at all'),
                  Text('Extremely'),
                ])
              ]),
            ),
          ),
          Card(
            margin: EdgeInsets.fromLTRB(10, 16, 10, 10),
            child: Container(
              padding: EdgeInsets.all(16),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text('Happy ?', style: TextStyle(fontSize: 24)),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Radio(value: 0, groupValue: _happyValue, onChanged: _happyChange),
                  Radio(value: 1, groupValue: _happyValue, onChanged: _happyChange),
                  Radio(value: 2, groupValue: _happyValue, onChanged: _happyChange),
                  Radio(value: 3, groupValue: _happyValue, onChanged: _happyChange),
                  Radio(value: 4, groupValue: _happyValue, onChanged: _happyChange),
                ]),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Not at all'),
                  Text('Extremely'),
                ])
              ]),
            ),
          ),
          Card(
            margin: EdgeInsets.fromLTRB(10, 16, 10, 10),
            child: Container(
              padding: EdgeInsets.all(16),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text('Angry / frustrated ?', style: TextStyle(fontSize: 24)),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Radio(value: 0, groupValue: _angryValue, onChanged: _angryChange),
                  Radio(value: 1, groupValue: _angryValue, onChanged: _angryChange),
                  Radio(value: 2, groupValue: _angryValue, onChanged: _angryChange),
                  Radio(value: 3, groupValue: _angryValue, onChanged: _angryChange),
                  Radio(value: 4, groupValue: _angryValue, onChanged: _angryChange),
                ]),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Not at all'),
                  Text('Extremely'),
                ])
              ]),
            ),
          ),
          Card(
            margin: EdgeInsets.fromLTRB(10, 16, 10, 10),
            child: Container(
              padding: EdgeInsets.all(16),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text('Nervous / stressed ?', style: TextStyle(fontSize: 24)),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Radio(value: 0, groupValue: _nervousValue, onChanged: _nervousChange),
                  Radio(value: 1, groupValue: _nervousValue, onChanged: _nervousChange),
                  Radio(value: 2, groupValue: _nervousValue, onChanged: _nervousChange),
                  Radio(value: 3, groupValue: _nervousValue, onChanged: _nervousChange),
                  Radio(value: 4, groupValue: _nervousValue, onChanged: _nervousChange),
                ]),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Not at all'),
                  Text('Extremely'),
                ])
              ]),
            ),
          ),
          Card(
            margin: EdgeInsets.fromLTRB(10, 16, 10, 10),
            child: Container(
              padding: EdgeInsets.all(16),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text('Sad ?', style: TextStyle(fontSize: 24)),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Radio(value: 0, groupValue: _sadValue, onChanged: _sadChange),
                  Radio(value: 1, groupValue: _sadValue, onChanged: _sadChange),
                  Radio(value: 2, groupValue: _sadValue, onChanged: _sadChange),
                  Radio(value: 3, groupValue: _sadValue, onChanged: _sadChange),
                  Radio(value: 4, groupValue: _sadValue, onChanged: _sadChange),
                ]),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Not at all'),
                  Text('Extremely'),
                ])
              ]),
            ),
          ),
          Card(
            margin: EdgeInsets.fromLTRB(10, 16, 10, 10),
            child: Container(
              padding: EdgeInsets.all(16),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(margin: EdgeInsets.only(bottom: 20), child: Text('Current activity', style: TextStyle(fontSize: 24))),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Column(children: [Text('Meeting', style: new TextStyle(fontSize: 14.0)), Radio(value: 0, groupValue: _activityValue, onChanged: _activityChange)]),
                  Column(children: [Text('Work', style: new TextStyle(fontSize: 14.0)), Radio(value: 1, groupValue: _activityValue, onChanged: _activityChange)]),
                  Column(children: [Text('Drive', style: new TextStyle(fontSize: 14.0)), Radio(value: 2, groupValue: _activityValue, onChanged: _activityChange)]),
                  Column(children: [Text('Housework', style: new TextStyle(fontSize: 14.0)), Radio(value: 3, groupValue: _activityValue, onChanged: _activityChange)]),
                ]),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Column(children: [Radio(value: 4, groupValue: _activityValue, onChanged: _activityChange), Text('Socialize', style: new TextStyle(fontSize: 14.0))]),
                  Column(children: [Radio(value: 5, groupValue: _activityValue, onChanged: _activityChange), Text('Rest', style: new TextStyle(fontSize: 14.0))]),
                  Column(children: [Radio(value: 6, groupValue: _activityValue, onChanged: _activityChange), Text('Exercise', style: new TextStyle(fontSize: 14.0))]),
                  Column(children: [Radio(value: 7, groupValue: _activityValue, onChanged: _activityChange), Text('Entertainment', style: new TextStyle(fontSize: 14.0))]),
                ]),
              ]),
            ),
          ),
          Center(
            child: Container(
              margin: EdgeInsets.only(bottom: 20),
              child: RaisedButton.icon(
                color: Colors.green,
                onPressed: _submitClick,
                icon: Icon(Icons.send, color: Colors.white),
                label: Text('Submit', style: TextStyle(fontSize: 18, color: Colors.white)),
                padding: EdgeInsets.fromLTRB(20, 10, 20, 10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void toast(str) {
    Fluttertoast.showToast(msg: str, toastLength: Toast.LENGTH_SHORT, gravity: ToastGravity.CENTER, timeInSecForIosWeb: 1, backgroundColor: Color.fromARGB(256, 4, 4, 4), textColor: Colors.white, fontSize: 16.0);
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied, we cannot request permissions.');
    }

    final location = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    return location;
  }

  void _cheerfulChange(value) {
    setState(() {
      _cheerfulValue = value;
    });
  }

  void _happyChange(value) {
    setState(() {
      _happyValue = value;
    });
  }

  void _angryChange(value) {
    setState(() {
      _angryValue = value;
    });
  }

  void _nervousChange(value) {
    setState(() {
      _nervousValue = value;
    });
  }

  void _sadChange(value) {
    setState(() {
      _sadValue = value;
    });
  }

  void _activityChange(value) {
    setState(() {
      _activityValue = value;
    });
  }

  void _submitClick() {
    if (_userId == null) {
      Navigator.of(context).pop();
      return;
    }

    http
        .post(
      Uri.parse('http://165.246.42.172/api/submit_ema'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'userId': _userId.toString(),
        'response': jsonEncode(<String, dynamic>{
          'fillTimestamp': DateTime.now().millisecondsSinceEpoch,
          'cheerful': _cheerfulValue,
          'happy': _happyValue,
          'angry': _angryValue,
          'nervous': _nervousValue,
          'sad': _sadValue,
          'activity': ACTIVITIES[_activityValue],
          'location': _position != null ? _position.toString() : '',
        }),
      }),
    )
        .then((res) {
      if (res.statusCode == 200) {
        final js = jsonDecode(res.body);
        if (js['success']) {
          toast('Submitted successfully!');
          Navigator.of(context).pop();
        } else
          toast('Failed to submit, please check your internet connection!');
      }
    });
  }
}
