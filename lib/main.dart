import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:stress_ema_app/EMAReport.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:stress_ema_app/services/LocalNotificationService.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  LocalNotificationService.initialize();
  Firebase.initializeApp().then((_) async {
    if (Platform.isIOS) {
      final res = await FirebaseMessaging.instance.requestPermission(alert: true, announcement: true, badge: true);
      print('User granted permission: ${res.authorizationStatus}');
    }
    FirebaseMessaging.onBackgroundMessage((message) async {
      await Firebase.initializeApp();
      LocalNotificationService.display(message);
    });
    runApp(MyApp());
  });
}

class MyApp extends StatelessWidget {
  @override
  StatelessElement createElement() {
    return super.createElement();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stress EMA App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'EMA / self-reports'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static const ACTIVITIES = {0: 'meeting', 1: 'work', 2: 'drive', 3: 'housework', 4: 'socialize', 5: 'rest', 6: 'exercise', 7: 'entertainment'};
  static int userId;

  // region EMA response values + position
  int _cheerfulValue = -1;
  int _happyValue = -1;
  int _angryValue = -1;
  int _nervousValue = -1;
  int _sadValue = -1;
  int _activityValue = -1;
  Position _position;

  // endregion

  @override
  void initState() {
    super.initState();

    _getGPSPosition().then((position) => _position = position);
    SharedPreferences.getInstance().then((prefs) => (prefs.containsKey('userId') ? setState(() => userId = prefs.getInt('userId')) : null));

    FirebaseMessaging.instance.getInitialMessage();
    FirebaseMessaging.onMessage.listen((message) => LocalNotificationService.display(message));
  }

  @override
  Widget build(BuildContext context) {
    if (userId == null)
      return Scaffold(
        appBar: AppBar(title: Text(widget.title), actions: <Widget>[IconButton(icon: Icon(Icons.logout), onPressed: _logoutClick)]),
        body: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(child: ElevatedButton.icon(onPressed: _loginClick, icon: Icon(Icons.login), label: Text('Login (existing Participant ID)'))),
            Center(child: ElevatedButton.icon(onPressed: _registerClick, icon: Icon(Icons.app_registration), label: Text('Register (new Participant ID)'))),
          ],
        ),
      );
    else
      return Scaffold(
        backgroundColor: Color.fromRGBO(240, 242, 245, 1),
        appBar: AppBar(title: Text('Submit EMA (Participant : $userId)'), actions: <Widget>[IconButton(icon: Icon(Icons.logout), onPressed: _logoutClick)]),
        body: ListView(
          children: [
            Card(
              margin: EdgeInsets.all(10),
              child: Container(
                padding: EdgeInsets.all(16),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('Cheerful ?', style: TextStyle(fontSize: 24)),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Radio(value: 0, groupValue: _cheerfulValue, onChanged: _cheerfulChange), Radio(value: 1, groupValue: _cheerfulValue, onChanged: _cheerfulChange), Radio(value: 2, groupValue: _cheerfulValue, onChanged: _cheerfulChange), Radio(value: 3, groupValue: _cheerfulValue, onChanged: _cheerfulChange), Radio(value: 4, groupValue: _cheerfulValue, onChanged: _cheerfulChange)]),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Not at all'), Text('Extremely')])
                ]),
              ),
            ),
            Card(
              margin: EdgeInsets.fromLTRB(10, 16, 10, 10),
              child: Container(
                padding: EdgeInsets.all(16),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('Happy ?', style: TextStyle(fontSize: 24)),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Radio(value: 0, groupValue: _happyValue, onChanged: _happyChange), Radio(value: 1, groupValue: _happyValue, onChanged: _happyChange), Radio(value: 2, groupValue: _happyValue, onChanged: _happyChange), Radio(value: 3, groupValue: _happyValue, onChanged: _happyChange), Radio(value: 4, groupValue: _happyValue, onChanged: _happyChange)]),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Not at all'), Text('Extremely')])
                ]),
              ),
            ),
            Card(
              margin: EdgeInsets.fromLTRB(10, 16, 10, 10),
              child: Container(
                padding: EdgeInsets.all(16),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('Angry / frustrated ?', style: TextStyle(fontSize: 24)),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Radio(value: 0, groupValue: _angryValue, onChanged: _angryChange), Radio(value: 1, groupValue: _angryValue, onChanged: _angryChange), Radio(value: 2, groupValue: _angryValue, onChanged: _angryChange), Radio(value: 3, groupValue: _angryValue, onChanged: _angryChange), Radio(value: 4, groupValue: _angryValue, onChanged: _angryChange)]),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Not at all'), Text('Extremely')])
                ]),
              ),
            ),
            Card(
              margin: EdgeInsets.fromLTRB(10, 16, 10, 10),
              child: Container(
                padding: EdgeInsets.all(16),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('Nervous / stressed ?', style: TextStyle(fontSize: 24)),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Radio(value: 0, groupValue: _nervousValue, onChanged: _nervousChange), Radio(value: 1, groupValue: _nervousValue, onChanged: _nervousChange), Radio(value: 2, groupValue: _nervousValue, onChanged: _nervousChange), Radio(value: 3, groupValue: _nervousValue, onChanged: _nervousChange), Radio(value: 4, groupValue: _nervousValue, onChanged: _nervousChange)]),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Not at all'), Text('Extremely')])
                ]),
              ),
            ),
            Card(
              margin: EdgeInsets.fromLTRB(10, 16, 10, 10),
              child: Container(
                padding: EdgeInsets.all(16),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('Sad ?', style: TextStyle(fontSize: 24)),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Radio(value: 0, groupValue: _sadValue, onChanged: _sadChange), Radio(value: 1, groupValue: _sadValue, onChanged: _sadChange), Radio(value: 2, groupValue: _sadValue, onChanged: _sadChange), Radio(value: 3, groupValue: _sadValue, onChanged: _sadChange), Radio(value: 4, groupValue: _sadValue, onChanged: _sadChange)]),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Not at all'), Text('Extremely')])
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
            Center(child: Container(margin: EdgeInsets.only(bottom: 20), child: ElevatedButton.icon(onPressed: _submitClick, icon: Icon(Icons.send, color: Colors.white), label: Text('Submit EMA', style: TextStyle(fontSize: 18, color: Colors.white))))),
          ],
        ),
      );
  }

  void toast(str) => Fluttertoast.showToast(msg: str, toastLength: Toast.LENGTH_SHORT, gravity: ToastGravity.CENTER, timeInSecForIosWeb: 1, backgroundColor: Color.fromARGB(256, 4, 4, 4), textColor: Colors.white, fontSize: 16.0);

  void _loginClick() async {
    TextEditingController _textFieldController = TextEditingController();
    await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Login to system'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(onChanged: (value) {}, controller: _textFieldController, decoration: InputDecoration(hintText: "e.g. 12")),
                ElevatedButton.icon(
                    onPressed: () async {
                      int newUserId = int.tryParse(_textFieldController.text);
                      if (newUserId != null) {
                        final res = await http.post(
                          Uri.parse('http://165.246.42.172/api/login'),
                          headers: <String, String>{'Content-Type': 'application/json; charset=UTF-8'},
                          body: jsonEncode(<String, String>{'userId': newUserId.toString()}),
                        );
                        if (res.statusCode == 200) {
                          final js = jsonDecode(res.body);
                          if (js['success']) {
                            setState(() {
                              userId = js['userId'];
                              SharedPreferences.getInstance().then((prefs) => prefs.setInt('userId', userId));
                              _updateFCMToken(userId);
                              Navigator.of(context).pop();
                            });
                          } else
                            toast('Failed to login, check your User ID!');
                        }
                      }
                    },
                    icon: Icon(Icons.login),
                    label: Text('OK'))
              ],
            ),
          );
        });
  }

  void _registerClick() async {
    final res = await http.post(Uri.parse('http://165.246.42.172/api/register'));

    if (res.statusCode == 200) {
      final js = jsonDecode(res.body);
      setState(() {
        userId = js['userId'];
        _updateFCMToken(userId);
        SharedPreferences.getInstance().then((prefs) => prefs.setInt('userId', userId));
      });
    }
  }

  void _logoutClick() async {
    await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Logout from system?'),
            content: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    SharedPreferences.getInstance().then((prefs) {
                      prefs.remove('userId');
                      setState(() => userId = null);
                      Navigator.of(context).pop();
                    });
                  },
                  icon: Icon(Icons.logout),
                  label: Text('Logout'),
                ),
                ElevatedButton.icon(onPressed: () => Navigator.of(context).pop(), icon: Icon(Icons.close), label: Text('Cancel')),
              ],
            ),
          );
        });
  }

  void _cheerfulChange(value) => setState(() => _cheerfulValue = value);

  void _happyChange(value) => setState(() => _happyValue = value);

  void _angryChange(value) => setState(() => _angryValue = value);

  void _nervousChange(value) => setState(() => _nervousValue = value);

  void _sadChange(value) => setState(() => _sadValue = value);

  void _activityChange(value) => setState(() => _activityValue = value);

  void _submitClick() async {
    if (userId == null) {
      Navigator.of(context).pop();
      return;
    }

    final emaResponse = EMAResponse(
      fillTimestamp: DateTime.now().millisecondsSinceEpoch,
      cheerful: _cheerfulValue,
      happy: _happyValue,
      angry: _angryValue,
      nervous: _nervousValue,
      sad: _sadValue,
      activity: ACTIVITIES[_activityValue],
      locationLongitude: _position != null ? _position.longitude : double.nan,
      locationLatitude: _position != null ? _position.latitude : double.nan,
    );

    if (await isConnected()) {
      final res = await http.post(
        Uri.parse('http://165.246.42.172/api/submit_ema'),
        headers: <String, String>{'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(<String, String>{'userId': userId.toString(), 'response': jsonEncode(emaResponse.toMap())}),
      );
      if (res.statusCode == 200) {
        final js = jsonDecode(res.body);
        if (js['success']) {
          toast('Submitted successfully!');
          Navigator.of(context).pop();
        } else
          toast('Failed to submit, please check your internet connection!');
      }
    } else
      emaResponse.saveReport();
  }

  void _updateFCMToken(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    String fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken != null) {
      print('userId($userId), fcmToken($fcmToken)');
      _setFCMTokenOnServer(userId, fcmToken);
    }
  }

  void _setFCMTokenOnServer(int userId, String fcmToken) async {
    final res = await http.post(
      Uri.parse('http://165.246.42.172/api/set_fcm_token'),
      headers: <String, String>{'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode(<String, dynamic>{'userId': userId, 'fcmToken': fcmToken}),
    );
    if (res.statusCode == 200) {
      final js = jsonDecode(res.body);
      if (js['success'])
        toast('Ready to receive EMA notifications!');
      else
        toast('Failed to prepare for EMA notifications !');
    }
  }

  Future<Position> _getGPSPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return Future.error('Location services are disabled.');

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return Future.error('Location permissions are denied');
    } else if (permission == LocationPermission.deniedForever) return Future.error('Location permissions are permanently denied, we cannot request permissions.');

    final location = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    return location;
  }

  Future<bool> isConnected() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }
}
