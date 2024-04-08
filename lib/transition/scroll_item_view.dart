import 'package:flutter/material.dart';
import 'package:ns_danmaku/danmaku_stroke_text.dart';

class ScrollItemView extends StatefulWidget {
  final String text;
  final Color color;
  final double fontSize;
  final double duration;
  final double y;
  final double begin;
  final double end;
  final bool border;
  final Size size;
  final double strokeWidth;
  final FontWeight fontWeight;
  final Function(String)? onComplete;
  final Function(AnimationController)? onCreated;
  const ScrollItemView({
    required this.text,
    this.fontSize = 16,
    this.duration = 10,
    this.color = Colors.white,
    this.y = 0,
    this.begin = 0,
    this.end = -1,
    this.size = Size.zero,
    this.border = true,
    this.strokeWidth = 2.0,
    this.fontWeight = FontWeight.normal,
    this.onComplete,
    this.onCreated,
    required UniqueKey key,
  }) : super(key: key);

  @override
  State<ScrollItemView> createState() => _ScrollItemViewState();
}

class _ScrollItemViewState extends State<ScrollItemView>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  bool get isComplete => controller.isCompleted;
  late Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      duration: Duration(seconds: widget.duration.floor()),
      vsync: this,
    );

    controller.addStatusListener(statusUpdate);

    _animation = Tween(
            begin: Offset(widget.begin, widget.y),
            end: Offset(widget.end, widget.y))
        .animate(controller);

    widget.onCreated?.call(controller);
    controller.forward();
  }

  void statusUpdate(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      widget.onComplete?.call(widget.key.toString());
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
    return SlideTransition(
      position: _animation,
      child: SizedBox(
        height: widget.size.height,
        width: widget.size.width,
        child: widget.border
            ? DanmakuStrokeText(
                widget.text,
                color: widget.color,
                fontSize: widget.fontSize,
                strokeWidth: widget.strokeWidth,
                fontWeight: widget.fontWeight,
              )
            : Text(
                widget.text,
                softWrap: false,
                overflow: TextOverflow.visible,
                style: TextStyle(
                  color: widget.color,
                  fontSize: widget.fontSize,
                  fontWeight: widget.fontWeight,
                  letterSpacing: 2,
                  overflow: TextOverflow.visible,
                ),
              ),
      ),
    );
  }
}
