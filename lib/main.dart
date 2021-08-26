import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'EMA.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stress EMA App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'EMA / self-reports'),
      initialRoute: '/',
      routes: {
        EMA.route_name: (context) => EMA(),
      },
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
  int userId;

  @override
  void initState() {
    super.initState();

    SharedPreferences.getInstance().then((prefs) {
      if (prefs.containsKey('userId'))
        setState(() {
          userId = prefs.getInt('userId');
        });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      resizeToAvoidBottomPadding: true,
      body: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (userId == null) Center(child: RaisedButton.icon(onPressed: _loginClick, icon: Icon(Icons.login), label: Text('Login (existing Participant ID)'))),
          if (userId == null) Center(child: RaisedButton.icon(onPressed: _registerClick, icon: Icon(Icons.app_registration), label: Text('Register (new Participant ID)'))),
          if (userId != null) Center(child: GestureDetector(child: Text('Participant ID : $userId'), onTap: _logoutClick)),
          if (userId != null)
            Container(
              margin: EdgeInsets.only(top: 10),
              child: Center(
                  child: RaisedButton.icon(
                onPressed: _submitEmaClick,
                icon: Icon(Icons.create),
                label: Text(
                  'Submit EMA',
                  style: TextStyle(fontSize: 18),
                ),
                padding: EdgeInsets.all(10),
              )),
            ),
        ],
      ),
    );
  }

  void toast(str) {
    Fluttertoast.showToast(msg: str, toastLength: Toast.LENGTH_SHORT, gravity: ToastGravity.CENTER, timeInSecForIosWeb: 1, backgroundColor: Color.fromARGB(256, 4, 4, 4), textColor: Colors.white, fontSize: 16.0);
  }

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
                TextField(
                  onChanged: (value) {},
                  controller: _textFieldController,
                  decoration: InputDecoration(hintText: "e.g. 12"),
                ),
                RaisedButton.icon(
                    onPressed: () {
                      int newUserId = int.tryParse(_textFieldController.text);
                      if (newUserId != null)
                        http
                            .post(
                          Uri.parse('http://165.246.42.172/api/login'),
                          headers: <String, String>{
                            'Content-Type': 'application/json; charset=UTF-8',
                          },
                          body: jsonEncode(<String, String>{
                            'userId': newUserId.toString(),
                          }),
                        )
                            .then((res) {
                          if (res.statusCode == 200) {
                            final js = jsonDecode(res.body);
                            if (js['success']) {
                              setState(() {
                                userId = js['userId'];
                                SharedPreferences.getInstance().then((prefs) {
                                  prefs.setInt('userId', userId);
                                });
                                Navigator.of(context).pop();
                              });
                            } else
                              toast('Failed to login, check your User ID!');
                          }
                        });
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
        SharedPreferences.getInstance().then((prefs) {
          prefs.setInt('userId', userId);
        });
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
                RaisedButton.icon(
                    onPressed: () {
                      SharedPreferences.getInstance().then((prefs) {
                        prefs.remove('userId');
                        setState(() {
                          userId = null;
                        });
                        Navigator.of(context).pop();
                      });
                    },
                    icon: Icon(Icons.logout),
                    label: Text('Logout')),
                RaisedButton.icon(onPressed: () => Navigator.of(context).pop(), icon: Icon(Icons.close), label: Text('Cancel'))
              ],
            ),
          );
        });
  }

  void _submitEmaClick() async {
    await Navigator.of(context).pushNamed(EMA.route_name, arguments: {'userId': userId});
  }
}
