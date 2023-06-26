import 'package:flutter/material.dart';
import 'package:ns_danmaku/danmaku_border_text.dart';

class PositionItemView extends StatefulWidget {
  final String text;
  final Color color;
  final double fontSize;
  final double y;
  final bool border;
  final bool isTop;
  final double strokeWidth;
  final Function(String)? onComplete;
  final Function(AnimationController)? onCreated;
  const PositionItemView({
    required this.text,
    this.fontSize = 16,
    this.color = Colors.white,
    this.y = 0,
    this.border = true,
    this.isTop = true,
    this.strokeWidth = 2.0,
    this.onComplete,
    this.onCreated,
    required UniqueKey key,
  }) : super(key: key);

  @override
  State<PositionItemView> createState() => _PositionItemViewState();
}

class _PositionItemViewState extends State<PositionItemView>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  bool get isComplete => controller.isCompleted;
  late Animation<RelativeRect> _animation;

  bool isVisiable = true;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    );

    controller.addStatusListener(statusUpdate);

    if (widget.isTop) {
      _animation = RelativeRectTween(
              begin: RelativeRect.fromLTRB(0, widget.y, 0, 0),
              end: RelativeRect.fromLTRB(0, widget.y, 0, 0))
          .animate(controller);
    } else {
      _animation = RelativeRectTween(
              begin: RelativeRect.fromLTRB(0, 0, 0, widget.y),
              end: RelativeRect.fromLTRB(0, 0, 0, widget.y))
          .animate(controller);
    }

    widget.onCreated?.call(controller);
    controller.forward();
  }

  void statusUpdate(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      widget.onComplete?.call(widget.key.toString());
      setState(() {
        //完成动画隐藏弹幕，当DanmakuView SetState时，这个Widget会被移除
        isVisiable = false;
      });
    }
  }

  @override
  void dispose() {
    controller.removeStatusListener(statusUpdate);
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PositionedTransition(
      rect: _animation,
      child: Offstage(
        offstage: !isVisiable,
        child: Container(
          alignment:
              widget.isTop ? Alignment.topCenter : Alignment.bottomCenter,
          child: widget.border
              ? DanmakuBorderText(
                  widget.text,
                  color: widget.color,
                  fontSize: widget.fontSize,
                  strokeWidth: widget.strokeWidth,
                )
              : Text(
                  widget.text,
                  style: TextStyle(
                    color: widget.color,
                    fontSize: widget.fontSize,
                    letterSpacing: 2,
                    overflow: TextOverflow.visible,
                  ),
                ),
        ),
      ),
    );
  }
}
