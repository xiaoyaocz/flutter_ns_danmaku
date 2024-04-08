import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:ns_danmaku/ns_danmaku.dart';

import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await SystemChrome.setPreferredOrientations(
  //   [
  //     DeviceOrientation.landscapeRight,
  //     DeviceOrientation.landscapeLeft,
  //   ],
  // );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NSDanmaku Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late DanmakuController _controller;
  var _key = new GlobalKey<ScaffoldState>();

  final _danmuKey = GlobalKey();

  bool _running = true;
  bool _hideTop = false;
  bool _hideBottom = false;
  bool _hideScroll = false;
  bool _strokeText = true;
  double _opacity = 1.0;
  double _duration = 8;
  double _fontSize = (Platform.isIOS || Platform.isAndroid) ? 16 : 25;
  FontWeight _fontWeight = FontWeight.normal;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _key,
      appBar: AppBar(
        title: Text('Demo'),
        actions: [
          Center(child: Text("running : $_running")),
          IconButton(
            icon: Icon(Icons.add),
            tooltip: 'Add',
            onPressed: () {
              _controller.addItems([
                DanmakuItem(
                    "这是一条超长弹幕ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789这是一条超长的弹幕，这条弹幕会超出屏幕宽度"),
                DanmakuItem("这是一条测试弹幕"),
                DanmakuItem(
                  "这是一条测试弹幕",
                  type: DanmakuItemType.top,
                  color: Colors.red,
                ),
                DanmakuItem(
                  "这是一条测试弹幕",
                  type: DanmakuItemType.bottom,
                  color: Colors.blue,
                ),
              ]);
            },
          ),
          IconButton(
            icon: Icon(Icons.play_circle_outline_outlined),
            onPressed: startPlay,
            tooltip: 'Start Player',
          ),
          IconButton(
            icon: Icon(Icons.pause),
            onPressed: () {
              _controller.pause();
            },
            tooltip: 'Pause',
          ),
          IconButton(
            icon: Icon(Icons.play_arrow),
            onPressed: () {
              _controller.resume();
            },
            tooltip: 'Resume',
          ),
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              _key.currentState?.openEndDrawer();
            },
            tooltip: 'Settings',
          ),
        ],
      ),
      backgroundColor: Colors.grey,
      body: DanmakuView(
        key: _danmuKey,
        createdController: (DanmakuController e) {
          _controller = e;
        },
        option: DanmakuOption(
          opacity: _opacity,
          fontSize: _fontSize,
          duration: _duration,
          strokeText: _strokeText,
          fontWeight: _fontWeight,
        ),
        statusChanged: (e) {
          setState(() {
            _running = e;
          });
        },
      ),
      endDrawer: Drawer(
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.all(8),
            children: [
              Text("Opacity : $_opacity"),
              Slider(
                value: _opacity,
                max: 1.0,
                min: 0.1,
                divisions: 9,
                onChanged: (e) {
                  setState(() {
                    _opacity = e;
                  });
                  _controller
                      .updateOption(_controller.option.copyWith(opacity: e));
                },
              ),
              Text("FontSize : $_fontSize"),
              Slider(
                value: _fontSize,
                min: 8,
                max: 36,
                divisions: 14,
                onChanged: (e) {
                  setState(() {
                    _fontSize = e;
                  });
                  _controller
                      .updateOption(_controller.option.copyWith(fontSize: e));
                },
              ),
              Text("FontWidght : $_fontWeight"),
              Slider(
                value: _fontWeight.index.toDouble(),
                min: 0,
                max: 8,
                divisions: 8,
                onChanged: (e) {
                  setState(() {
                    _fontWeight = FontWeight.values[e.toInt()];
                  });
                  _controller.updateOption(
                      _controller.option.copyWith(fontWeight: _fontWeight));
                },
              ),
              Text("Duration : $_duration"),
              Slider(
                value: _duration,
                min: 4,
                max: 20,
                divisions: 16,
                onChanged: (e) {
                  setState(() {
                    _duration = e;
                  });
                  _controller
                      .updateOption(_controller.option.copyWith(duration: e));
                },
              ),
              SwitchListTile(
                title: Text("Stroke Text"),
                value: _strokeText,
                onChanged: (e) {
                  setState(() {
                    _strokeText = e;
                  });
                  _controller
                      .updateOption(_controller.option.copyWith(borderText: e));
                },
              ),
              SwitchListTile(
                title: Text("Hide Top"),
                value: _hideTop,
                onChanged: (e) {
                  setState(() {
                    _hideTop = e;
                  });
                  _controller
                      .updateOption(_controller.option.copyWith(hideTop: e));
                },
              ),
              SwitchListTile(
                title: Text("Hide Bottom"),
                value: _hideBottom,
                onChanged: (e) {
                  setState(() {
                    _hideBottom = e;
                  });
                  _controller
                      .updateOption(_controller.option.copyWith(hideBottom: e));
                },
              ),
              SwitchListTile(
                title: Text("Hide Scroll"),
                value: _hideScroll,
                onChanged: (e) {
                  setState(() {
                    _hideScroll = e;
                  });
                  _controller
                      .updateOption(_controller.option.copyWith(hideScroll: e));
                },
              ),
              ListTile(
                title: Text("Clear"),
                onTap: () {
                  _controller.clear();
                },
              )
            ],
          ),
        ),
      ),
    );
  }

  Timer? timer;
  int sec = 0;
  Map<int, List<DanmakuItem>> _danmuItems = {};
  void startPlay() async {
    String data = await rootBundle.loadString('assets/132590001.json');
    List<DanmakuItem> _items = [];
    var jsonMap = json.decode(data);
    for (var item in jsonMap['comments']) {
      var p = item["p"].toString().split(',');
      var mode = int.parse(p[1]);
      DanmakuItemType type = DanmakuItemType.scroll;
      if (mode == 5) {
        type = DanmakuItemType.top;
      } else if (mode == 4) {
        type = DanmakuItemType.bottom;
      }
      var color = int.parse(p[2]).toRadixString(16).padLeft(6, "0");

      _items.add(DanmakuItem(
        item['m'],
        time: double.parse(p[0]).toInt(),
        color: Color(int.parse("FF" + color, radix: 16)),
        type: type,
      ));
    }
    _danmuItems = groupBy(_items, (DanmakuItem obj) => obj.time);
    sec = 0;
    if (timer == null) {
      timer = Timer.periodic(Duration(seconds: 1), (timer) {
        if (!_controller.running) return;
        if (_danmuItems.containsKey(sec))
          _controller.addItems(_danmuItems[sec]!);
        sec++;
      });
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }
}
