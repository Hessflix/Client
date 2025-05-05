import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hessflix/models/items/images_models.dart';
import 'package:hessflix/util/hessflix_image.dart';

class MediaHeader extends ConsumerWidget {
  final String name;
  final ImageData? logo;
  final Function()? onTap;
  const MediaHeader({
    required this.name,
    required this.logo,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final maxSize = 700.0;
    final textWidget = Container(
      height: 512,
      alignment: Alignment.center,
      child: SelectableText(
        name,
        textAlign: TextAlign.start,
        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontSize: 55,
            ),
      ),
    );

    return Center(
      child: Material(
        elevation: 30,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(150)),
        shadowColor: Colors.black.withValues(alpha: 0.3),
        color: Colors.transparent,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: (MediaQuery.sizeOf(context).height * 0.275).clamp(0, maxSize),
            maxWidth: MediaQuery.sizeOf(context).width.clamp(0, maxSize),
          ),
          child: Stack(
            children: [
              logo != null
                  ? HessflixImage(
                      image: logo,
                      disableBlur: true,
                      alignment: Alignment.bottomCenter,
                      imageErrorBuilder: (context, object, stack) => textWidget,
                      placeHolder: const SizedBox(height: 0),
                      fit: BoxFit.contain,
                    )
                  : textWidget,
              if (onTap != null)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: onTap,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
