import 'package:flutter/material.dart';
import 'package:ns_danmaku/danmaku_border_text.dart';

class ScrollItemView extends StatefulWidget {
  final String text;
  final Color color;
  final double fontSize;
  final double duration;
  final double y;
  final double x;
  final bool border;
  final Size size;
  final Function(String)? onComplete;
  final Function(AnimationController)? onCreated;
  const ScrollItemView({
    required this.text,
    this.fontSize = 16,
    this.duration = 10,
    this.color = Colors.white,
    this.y = 0,
    this.x = 0,
    this.size = Size.zero,
    this.border = true,
    this.onComplete,
    this.onCreated,
    required UniqueKey key,
  }) : super(key: key);

  @override
  _ScrollItemViewState createState() => _ScrollItemViewState();
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

    _animation =
        Tween(begin: Offset(widget.x, widget.y), end: Offset(-1, widget.y))
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
      child: Container(
        height: widget.size.height,
        width: widget.size.width,
        alignment: Alignment.center,
        child: widget.border
            ? DanmakuBorderText(
                widget.text,
                color: widget.color,
                fontSize: widget.fontSize,
              )
            : Text(
                widget.text,
                style: TextStyle(
                  color: widget.color,
                  fontSize: widget.fontSize,
                ),
              ),
      ),
    );
  }
}
