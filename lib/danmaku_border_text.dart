import 'package:flutter/material.dart';

class DanmakuBorderText extends StatelessWidget {
  final String text;
  final TextAlign textAlign;
  final Color color;
  final double fontSize;
  const DanmakuBorderText(
    this.text, {
    this.textAlign = TextAlign.left,
    this.color = Colors.white,
    this.fontSize = 16,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Text(
          text,
          softWrap: false,
          textAlign: textAlign,
          style: TextStyle(
            fontSize: fontSize,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = strokeWidth
              ..strokeCap = StrokeCap.round
              ..strokeJoin = StrokeJoin.round
              ..color = getBorderColor(color),
          ),
        ),
        Text(
          text,
          softWrap: false,
          textAlign: textAlign,
          style: TextStyle(
            fontSize: fontSize,
            color: color,
          ),
        ),
      ],
    );
  }

  double get strokeWidth => (fontSize / 20).ceil() * 2;

  Color getBorderColor(Color color) {
    var brightness =
        ((color.red * 299) + (color.green * 587) + (color.blue * 114)) / 1000;
    return brightness > 70 ? Colors.black : Colors.white;
  }
}
