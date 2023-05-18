library more_popup;

import 'dart:async';

import 'package:flutter/material.dart';

extension _SizeLayoutContext on BuildContext {
  Size get appSize => MediaQuery.of(this).size;
}

class ShowMoreTextPopup extends StatefulWidget {
  const ShowMoreTextPopup({
    super.key,
    this.width,
    this.onDismiss,
    this.backgroundColor,
    this.borderRadius,
    this.padding,
    required this.child,
    required this.childPopup,
    this.center = false,
    this.paddingPopup = 0,
  });
  final Widget child;
  final Widget childPopup;
  final bool center;
  final double? width;
  final double paddingPopup;
  final VoidCallback? onDismiss;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;

  @override
  State<ShowMoreTextPopup> createState() => _ShowMoreTextPopupState();
}

class _ShowMoreTextPopupState extends State<ShowMoreTextPopup> {
  late double _popupWidth;

  late Color _backgroundColor;

  late BorderRadius _borderRadius;
  late EdgeInsetsGeometry _padding;
  double arrowHeight = 10.0;

  bool _isDownArrow = true;

  bool _isVisible = false;

  late OverlayEntry _entry;

  late Offset _offset;

  late Rect _showRect;

  late Size _screenSize;

  final keyChild = GlobalKey();

  @override
  void initState() {
    super.initState();
    _popupWidth = widget.width ?? 200;
    _backgroundColor = widget.backgroundColor ?? const Color(0xFFFFA500);
    _borderRadius = widget.borderRadius ?? BorderRadius.circular(10.0);
    _padding = widget.padding ?? const EdgeInsets.all(4.0);
  }

  /// Shows a popup near a widget with key [widgetKey] or [rect].
  void show({required BuildContext context}) {
    _show.sink.add(true);
    _showRect = _getWidgetGlobalRect(keyChild);
    final view = WidgetsBinding.instance.platformDispatcher.implicitView;
    _screenSize =
        (view?.physicalSize ?? Size.zero) / (view?.devicePixelRatio ?? 1);

    _calculatePosition(context);

    _entry = OverlayEntry(builder: (context) {
      return buildPopupLayout(_offset);
    });

    Overlay.of(context).insert(_entry);
    _isVisible = true;
  }

  void _calculatePosition(BuildContext context) {
    _offset = _calculateOffset(context);
  }

  /// Returns globalRect of widget with key [key]
  Rect _getWidgetGlobalRect(GlobalKey key) {
    final renderBox = key.currentContext!.findRenderObject() as RenderBox?;
    final offset = renderBox?.localToGlobal(Offset.zero);
    return Rect.fromLTWH(
      offset?.dx ?? 1,
      offset?.dy ?? 1,
      renderBox?.size.width ?? 1,
      renderBox?.size.height ?? 1,
    );
  }

  /// Returns calculated widget offset using [context]
  Offset _calculateOffset(BuildContext context) {
    double dx = _showRect.left + _showRect.width / 2.0 - _popupWidth / 2.0;
    if (dx < 10.0) {
      dx = 10.0;
    }

    if (dx + _popupWidth > _screenSize.width && dx > 10.0) {
      final tempDx = _screenSize.width - _popupWidth - 10;
      if (tempDx > 10) dx = tempDx;
    }

    double dy = _showRect.top;
    if (dy <= (MediaQuery.of(context).size.height / 2)) {
      // not enough space above, show popup under the widget.
      dy = arrowHeight + _showRect.height + _showRect.top;
      _isDownArrow = false;
    } else {
      dy -= arrowHeight;
      _isDownArrow = true;
    }

    return Offset(dx, dy);
  }

  /// Builds Layout of popup for specific [offset]
  LayoutBuilder buildPopupLayout(Offset offset) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            dismiss();
          },
          child: Material(
            color: Colors.transparent,
            child: Stack(
              children: <Widget>[
                // popup content
                Positioned(
                  left: widget.center
                      ? (context.appSize.width - _popupWidth) / 2
                      : offset.dx,
                  bottom: _isDownArrow
                      ? context.appSize.height -
                          (offset.dy - widget.paddingPopup)
                      : null,
                  top: _isDownArrow
                      ? null
                      : offset.dy -
                          arrowHeight +
                          arrowHeight +
                          widget.paddingPopup,
                  child: Stack(
                    children: [
                      Container(
                        padding: _padding,
                        width: _popupWidth,
                        decoration: BoxDecoration(
                          color: _backgroundColor,
                          borderRadius: _borderRadius,
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0xFF808080),
                              blurRadius: 1.0,
                            ),
                          ],
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(11),
                          child: widget.childPopup,
                        ),
                      ),
                    ],
                  ),
                ), // triangle arrow
                Positioned(
                  left: _showRect.left + _showRect.width / 2.0 - 7.5,
                  top: _isDownArrow
                      ? offset.dy - widget.paddingPopup
                      : offset.dy - arrowHeight + widget.paddingPopup,
                  child: CustomPaint(
                    size: Size(15.0, arrowHeight),
                    painter: TrianglePainter(
                      isDownArrow: _isDownArrow,
                      color: _backgroundColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Dismisses the popup
  void dismiss() {
    _show.sink.add(false);
    if (!_isVisible) {
      return;
    }
    _entry.remove();
    _isVisible = false;
    widget.onDismiss?.call();
  }

  final _show = StreamController<bool>();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
        initialData: false,
        stream: _show.stream,
        builder: (context, snapshot) {
          return GestureDetector(
            key: keyChild,
            onTap: () {
              if (snapshot.data!) {
                dismiss();
              } else {
                show(context: context);
              }
            },
            child: widget.child,
          );
        });
  }
}

class TrianglePainter extends CustomPainter {
  TrianglePainter({this.isDownArrow = true, required this.color});
  bool isDownArrow;
  Color color;

  /// Draws the triangle of specific [size] on [canvas]
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    final paint = Paint();
    paint.strokeWidth = 2.0;
    paint.color = color;
    paint.style = PaintingStyle.fill;

    if (isDownArrow) {
      path.moveTo(0.0, -1.0);
      path.lineTo(size.width, -1.0);
      path.lineTo(size.width / 2.0, size.height);
    } else {
      path.moveTo(size.width / 2.0, 0.0);
      path.lineTo(0.0, size.height + 1);
      path.lineTo(size.width, size.height + 1);
    }

    canvas.drawPath(path, paint);
  }

  /// Specifies to redraw for [customPainter]
  @override
  bool shouldRepaint(CustomPainter customPainter) {
    return true;
  }
}
