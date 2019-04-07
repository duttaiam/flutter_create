import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:collection';
import 'dart:math';

void main() => runApp(MyApp());

class Bubble extends AnimatedWidget {
  final String _text;
  final Tween<Offset> _position;

  Bubble(this._text, this._position, {Key key, Animation<double> animation})
      : super(key: key, listenable: animation);

  Widget build(BuildContext context) {
    if (_text==null) return Container();

    final screen = MediaQuery.of(context);
    final extra = _text.length;

    return Positioned(
      left: _position.evaluate(listenable).dx * screen.size.width,
      top: _position.evaluate(listenable).dy * screen.size.height,
      child: Container(
        height: 100.0 + extra,
        width: 100.0 + extra,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/lantern.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(_text,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Thought Catcher',
      home: MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() {
    return _MainPageState();
  }
}

class _MainPageState extends State<MainPage> with SingleTickerProviderStateMixin {
  final _ref = Firestore.instance.collection("thoughts");
  final _textCtrl = new TextEditingController();
  final _buffer = new Queue();
  final rnd = new Random();
  String _current, _latest;

  Animation<double> _anim;
  AnimationController _ctrl;
  Tween<Offset> _tween;

  Tween<Offset> _buildTween() {
    return Tween<Offset>(begin: Offset(1.0, 0.3+rnd.nextDouble()/5), end: Offset(-0.5, 0.1+rnd.nextDouble()/5));
  }

  @override
  void initState() {
    super.initState();

    _tween = _buildTween();
    _ctrl = AnimationController(duration: const Duration(seconds: 10), vsync: this);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.linear)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed || status == AnimationStatus.dismissed) {
          setState(() {
            _current = null;
            _tween = _buildTween();
          });
          _ctrl.forward(from: 0);
        }
      });
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: _ref.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data.documents.isNotEmpty) {
            String latest = snapshot.data.documents.last.data['content'];
            if (latest != _latest) {
              _latest = latest;
              _buffer.addLast(latest);
            }
            if (_current==null && _buffer.isNotEmpty) _current = _buffer.removeLast();
          }

          return _buildStack();
        },
      ),
    );
  }

  Widget _buildStack() {
    return Stack(
      children: <Widget>[
        Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/scenic.jpg'),
              fit: BoxFit.cover,
            ),
          ),
        ),

        AppBar(
          title: Text('Thought Catcher',
            style: TextStyle(fontFamily: 'Pacifico'),),
          backgroundColor: Colors.transparent,
          elevation: 0.0,
        ),

        Bubble(_current, _tween, animation: _anim),

        Positioned(
          bottom: 20.0,
          left: 10.0,
          right: 10.0,
          child: Card(
            elevation: 8.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24.0),
            ),
            child: _buildTextComposer(),
          ),
        ),
      ],
    );
  }

  Widget _buildTextComposer() {
    return Container(
      margin: const EdgeInsets.only(left: 16.0),
      child: Row(
        children: <Widget>[
          Flexible(
            child: TextField(
              controller: _textCtrl,
              onSubmitted: _submit,
              decoration: InputDecoration.collapsed(
                  hintText: "Post a thought..."),
            ),
          ),
          Container(
            child: IconButton(
                icon: Icon(Icons.send),
                onPressed: () => _submit(_textCtrl.text)),
          ),
        ],
      ),
    );
  }

  void _submit(String msg) {
    _textCtrl.clear();
    if (msg.isNotEmpty) _ref.document().setData({ 'content': msg.substring(0, min(100, msg.length)) });
  }

}