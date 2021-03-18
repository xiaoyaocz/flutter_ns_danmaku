A Flutter danmaku package.

## Using

Example:

```dart

import 'package:ns_danmaku/danmaku_controller.dart';
import 'package:ns_danmaku/danmaku_view.dart';
import 'package:ns_danmaku/models/danmaku_option.dart';

class _DanmakuPageState extends State<DanmakuPage> {
  late DanmakuController _controller;
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        //Your container, such as a player
        Container(),
        // Danmaku
        DanmakuView(
          createdController: (e) {
            _controller = e;
          },
          option: DanmakuOption(),
        ),
      ],
    );
}

```

## Reference

[https://zhuanlan.zhihu.com/p/159027974](https://zhuanlan.zhihu.com/p/159027974)
[https://www.zhihu.com/question/370464345](https://www.zhihu.com/question/370464345)
[https://github.com/LaoMengFlutter/flutter-do](https://github.com/LaoMengFlutter/flutter-do/tree/master/flutter_barrage_sample)