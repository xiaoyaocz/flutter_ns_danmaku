import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'transition/position_item_view.dart';
import 'transition/scroll_item_view.dart';

import 'danmaku_controller.dart';
import 'models/danmaku_item.dart';
import 'models/danmaku_option.dart';

class DanmakuView extends StatefulWidget {
  /// 创建View后返回控制器
  final Function(DanmakuController) createdController;
  final DanmakuOption option;
  final Function(bool)? statusChanged;
  const DanmakuView({
    required this.createdController,
    required this.option,
    this.statusChanged,
    Key? key,
  }) : super(key: key);

  @override
  State<DanmakuView> createState() => _DanmakuViewState();
}

class _DanmakuViewState extends State<DanmakuView> {
  //内部时间管理
  late Timer _timer;
  double _runTime = 0;
  late DanmakuController _controller;

  /// 弹幕选项
  DanmakuOption _option = DanmakuOption();

  /// 弹幕集合
  final Map<String, Widget> _scrollWidgets = {};

  final Map<String, Widget> _positionWidgets = {};

  /// 单条弹幕高度
  double _itemHeight = 0;

  /// 视图宽度
  double _viewWidth = 0;

  /// 视图高度
  double _viewHeight = 0;

  /// 最大行数
  int _maxRowNum = 0;

  /// 弹幕动画控制器集合
  final Map<String, AnimationController> _controllers = {};

  /// 滚动弹幕行信息
  List<RowInfo?> _scrollRows = [];

  /// 顶部弹幕每行消失时间
  List<double> _topOutTimes = [];

  /// 底部弹幕每行消失时间
  List<double> _bottomOutTimes = [];

  /// 屏幕中的全部滚动弹幕ID
  final List<String> _scrollIDs = [];

  /// 屏幕中的全部顶部弹幕ID
  final List<String> _topIDs = [];

  /// 屏幕中的全部底部弹幕ID
  final List<String> _bottomIDs = [];
  @override
  void initState() {
    _option = widget.option;
    _controller = DanmakuController(
      onAddItems: addItems,
      onUpdateOption: updateOption,
      onPause: pause,
      onResume: resume,
      onClear: clear,
    );
    _controller.option = _option;
    widget.createdController.call(
      _controller,
    );
    _timer = Timer.periodic(const Duration(milliseconds: 1), (e) {
      if (_controller.running) {
        _runTime += 0.001;
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    _timer.cancel();
    clear(needSetState: false);
    super.dispose();
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  void addItems(List<DanmakuItem> items) {
    for (var item in items) {
      switch (item.type) {
        case DanmakuItemType.scroll:
          addScrollDanmu(UniqueKey(), item);
          break;
        case DanmakuItemType.top:
        case DanmakuItemType.bottom:
          addPositionDanmu(UniqueKey(), item);
          break;

        default:
      }
    }

    setState(() {});
  }

  /// 添加滚动弹幕
  void addScrollDanmu(UniqueKey key, DanmakuItem e) {
    if (_option.hideScroll) {
      return;
    }
    //计算此弹幕尺寸
    var danmuSize = calculateTextSize(
        e.text, _option.fontSize, _option.strokeWidth, _option.fontWeight);
    //初始x坐标为0,即在屏幕的最左侧
    //x坐标为1时是弹幕自身宽度的1倍
    //将弹幕起始位置设置在屏幕的最右侧，x=容器宽度/弹幕宽度
    var begin = _viewWidth / danmuSize.width;
    double end = -1;
    if (begin < 1) {
      begin = 1;
      end = -(danmuSize.width / _viewWidth);
    }
    //路程
    var distance = _viewWidth + danmuSize.width;

    //速度
    var speed = distance / _option.duration;

    //出站时间,即弹幕已经完全从右侧移出
    var outboundTime =
        _runTime + (_option.duration * (danmuSize.width / distance));

    var y = commputeScrollAvailableRow(
      RowInfo(
        distance: distance,
        joinTime: _runTime,
        outTime: outboundTime,
        speed: speed,
        width: danmuSize.width,
      ),
    );

    //没有合适的行可用，抛弃掉
    if (y == -1) {
      return;
    }

    var id = key.hashCode.toString();
    _scrollIDs.add(id);

    _scrollWidgets.addAll({
      id: ScrollItemView(
        text: e.text,
        duration: _option.duration,
        strokeWidth: _option.strokeWidth,
        begin: begin,
        // 增加5%防止弹幕刚好完全移出屏幕时还未消失
        end: end * 1.05,
        y: y.toDouble() * _option.lineHeight,
        size: Size(danmuSize.width, _itemHeight),
        color: e.color,
        fontSize: _option.fontSize,
        fontWeight: _option.fontWeight,
        onComplete: onItemComplete,
        border: _option.strokeText,
        onCreated: (e) {
          _controllers.addAll({id: e});
        },
        key: key,
      )
    });
  }

  void addPositionDanmu(UniqueKey key, DanmakuItem item) {
    if (item.type == DanmakuItemType.top && _option.hideTop) {
      return;
    }
    if (item.type == DanmakuItemType.bottom && _option.hideBottom) {
      return;
    }

    // 生成一个唯一ID
    var id = key.hashCode.toString();
    double top = 0.0;
    if (item.type == DanmakuItemType.top) {
      top = computeTopAvailableRow(item);
    } else {
      top = computeBottomAvailableRow(item);
    }

    // 当top为-1时插入弹幕会引起重叠
    if (top != -1) {
      if (item.type == DanmakuItemType.top) {
        _topIDs.add(id);
      } else {
        _bottomIDs.add(id);
      }

      _positionWidgets.addAll({
        id: PositionItemView(
          key: key,
          text: item.text,
          color: item.color,
          strokeWidth: _option.strokeWidth,
          fontSize: _option.fontSize,
          isTop: item.type == DanmakuItemType.top,
          fontWeight: _option.fontWeight,
          strokeText: _option.strokeText,
          onComplete: onItemComplete,
          y: top,
          onCreated: (e) {
            _controllers.addAll({id: e});
          },
        )
      });
    }
  }

  int commputeScrollAvailableRow(RowInfo newItem) {
    for (var i = 0; i < _scrollRows.length; i++) {
      var lastItem = _scrollRows[i];
      //此行没有弹幕
      if (lastItem == null ||
          _runTime >= lastItem.joinTime + _option.duration) {
        _scrollRows[i] = newItem;
        return i;
      }

      //前弹幕必须已经完全从右侧移动完毕
      if (_runTime > lastItem.outTime) {
        //后弹幕速度小于等于前弹幕速度

        if (newItem.speed <= lastItem.speed) {
          _scrollRows[i] = newItem;
          return i;
        } else {
          //已走距离
          var runDistance = lastItem.distance *
              ((_runTime - lastItem.joinTime) / _option.duration);
          //两条弹幕相遇时间
          var t1 =
              (runDistance - newItem.width) / (newItem.speed - lastItem.speed);
          //前弹幕移出屏幕时间
          var t2 = (lastItem.distance - runDistance) / lastItem.speed;
          //当t1>t2时，两条弹幕不会重叠
          if (t1 > t2) {
            _scrollRows[i] = newItem;
            return i;
          }
        }
      }
    }
    return -1;
  }

  double computeTopAvailableRow(DanmakuItem item) {
    var danmuSize = calculateTextSize(
      item.text,
      _option.fontSize,
      _option.strokeWidth,
      _option.fontWeight,
    );
    // 哪一行可以加入弹幕
    var row = _topOutTimes.indexWhere((e) => e <= _runTime);
    if (row == -1) {
      return -1;
    }
    //设置行弹幕最后消失时间
    _topOutTimes[row] = _runTime + 5;
    return danmuSize.height * _option.lineHeight * row;
  }

  double computeBottomAvailableRow(DanmakuItem item) {
    var danmuSize = calculateTextSize(
      item.text,
      _option.fontSize,
      _option.strokeWidth,
      _option.fontWeight,
    );
    // 哪一行可以加入弹幕
    var row = _bottomOutTimes.indexWhere((e) => e < _runTime);
    if (row == -1) {
      return -1;
    }
    //设置行弹幕最后消失时间
    _bottomOutTimes[row] = _runTime + 5;
    return danmuSize.height * _option.lineHeight * row;
  }

  /// 更新弹幕设置
  void updateOption(DanmakuOption option) {
    _viewHeight = 0.0;
    // 弹幕屏蔽处理
    if (_option.hideBottom != option.hideBottom && option.hideBottom) {
      clearBottom(needSetState: false);
    }
    if (_option.hideScroll != option.hideScroll && option.hideScroll) {
      clearScroll(needSetState: false);
    }
    if (_option.hideTop != option.hideTop && option.hideTop) {
      clearTop(needSetState: false);
    }
    //速度处理
    if (_option.duration != option.duration) {
      for (var item in _controllers.keys) {
        //print(controllers[item].);
        _controllers[item]?.duration =
            Duration(milliseconds: (option.duration * 1000).floor());
        if (_controller.running) {
          _controllers[item]?.forward();
        } else {
          _controllers[item]?.stop();
        }
      }
    }
    if (_option.lineHeight != option.lineHeight) {
      calculateRowNum(_viewHeight);
    }
    _option = option;
    _controller.option = _option;
    setState(() {});
  }

  /// 暂停
  void pause() {
    for (var item in _controllers.keys) {
      _controllers[item]?.stop();
    }
    _controller.running = false;
    widget.statusChanged?.call(false);
  }

  /// 继续
  void resume() {
    for (var item in _controllers.keys) {
      _controllers[item]?.forward();
    }
    _controller.running = true;
    widget.statusChanged?.call(true);
  }

  /// 清空全部弹幕
  void clear({needSetState = true}) {
    clearScroll(needSetState: false);
    clearTop(needSetState: false);
    clearBottom(needSetState: false);
    if (needSetState) {
      setState(() {});
    }
  }

  /// 清空滚动弹幕
  void clearScroll({bool needSetState = true}) {
    for (var i = 0; i < _scrollIDs.length; i++) {
      var key = _scrollIDs[i];
      _scrollWidgets.remove(key);
      _controllers.remove(key);
    }
    _scrollIDs.clear();
    for (var i = 0; i < _scrollRows.length; i++) {
      _scrollRows[i] = null;
    }
    if (needSetState) {
      setState(() {});
    }
  }

  /// 清空顶部弹幕
  void clearTop({bool needSetState = true}) {
    for (var i = 0; i < _topIDs.length; i++) {
      var key = _topIDs[i];
      _positionWidgets.remove(key);
      _controllers.remove(key);
    }
    _topIDs.clear();
    for (var i = 0; i < _topOutTimes.length; i++) {
      _topOutTimes[i] = 0;
    }
    if (needSetState) {
      setState(() {});
    }
  }

  /// 清空底部弹幕
  void clearBottom({bool needSetState = true}) {
    for (var i = 0; i < _bottomIDs.length; i++) {
      var key = _bottomIDs[i];
      _positionWidgets.remove(key);
      _controllers.remove(key);
    }
    _bottomIDs.clear();
    for (var i = 0; i < _bottomOutTimes.length; i++) {
      _bottomOutTimes[i] = 0;
    }
    if (needSetState) {
      setState(() {});
    }
  }

  /// 弹幕动画运行完成
  void onItemComplete(String id) {
    _scrollWidgets.remove(id);
    _positionWidgets.remove(id);
    _controllers.remove(id);
    _scrollIDs.remove(id);
    _topIDs.remove(id);
    _bottomIDs.remove(id);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxHeight != _viewHeight) {
          _viewHeight = constraints.maxHeight;
          calculateRowNum(_viewHeight);
        }
        if (constraints.maxWidth != _viewWidth) {
          _viewWidth = constraints.maxWidth;
        }
        //加上ClipRect防止超出边界显示
        return ClipRect(
          child: Opacity(
            opacity: _option.opacity,
            child: Stack(
              children: [
                Stack(
                  children: _scrollWidgets.values.toList(),
                ),
                //无法设置z-index,所以把滚动弹幕及位置弹幕分开，防止滚动弹幕重叠固定弹幕
                Stack(
                  children: _positionWidgets.values.toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void calculateRowNum(double height) {
    var itemSize = calculateTextSize(
      '测试vjgpqa',
      _option.fontSize,
      _option.strokeWidth,
      _option.fontWeight,
    );
    _itemHeight = itemSize.height;

    //计算最大行数
    var maxRow =
        ((height / (_itemHeight * _option.lineHeight)) * _option.area).floor();
    if (_maxRowNum != maxRow) {
      _scrollRows = List.generate(maxRow, (_) => null);
      _topOutTimes = List.generate(maxRow ~/ 2, (_) => 0);
      _bottomOutTimes = List.generate(maxRow ~/ 2, (_) => 0);
      _maxRowNum = maxRow;
      if (kDebugMode) {
        print("弹幕最大行数:$_maxRowNum");
      }
    }
  }

  /// 计算文本尺寸
  Size calculateTextSize(
    String value,
    double fontSize,
    double strokeWidth,
    FontWeight fontWeight,
  ) {
    //var letterSpacing = (fontSize / 20).ceil() * 2.0;
    TextPainter painter = TextPainter(
      locale: Localizations.localeOf(context),
      maxLines: 1,
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.of(context).textScaler,
      text: TextSpan(
        text: value,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          // letterSpacing: letterSpacing,
          overflow: TextOverflow.visible,
          foreground: Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeWidth
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..color = Colors.black,
        ),
      ),
    );
    painter.layout();

    return Size(painter.width, painter.height);
  }
}

class RowInfo {
  final double speed;
  final double joinTime;
  final double outTime;
  final double width;
  final double distance;
  RowInfo({
    required this.distance,
    required this.joinTime,
    required this.outTime,
    required this.speed,
    required this.width,
  });
}
