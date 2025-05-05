import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ClickableText extends ConsumerStatefulWidget {
  final String text;
  final double opacity;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextStyle? style;
  final VoidCallback? onTap;
  const ClickableText(
      {required this.text,
      this.style,
      this.maxLines,
      this.overflow = TextOverflow.ellipsis,
      this.opacity = 1.0,
      this.onTap,
      super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ClickableTextState();
}

class _ClickableTextState extends ConsumerState<ClickableText> {
  bool hovering = false;

  Widget _textWidget(bool showDecoration) {
    return Opacity(
      opacity: widget.opacity,
      child: Text(
        widget.text,
        maxLines: widget.maxLines,
        overflow: widget.overflow,
        style: widget.style?.copyWith(
          color: showDecoration ? Theme.of(context).colorScheme.primary : null,
          decoration: showDecoration ? TextDecoration.underline : TextDecoration.none,
          decorationColor: showDecoration ? Theme.of(context).colorScheme.primary : null,
          decorationThickness: 3,
        ),
      ),
    );
  }

  Widget _buildClickable() {
    final showDecoration = ((widget.onTap != null) && hovering);
    return MouseRegion(
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (event) => setState(() => hovering = true),
      onExit: (event) => setState(() => hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Tooltip(message: widget.text, child: _textWidget(showDecoration)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.onTap != null ? _buildClickable() : _textWidget(false);
  }
}
