import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hessflix/models/item_base_model.dart';
import 'package:hessflix/providers/items/item_details_provider.dart';
import 'package:hessflix/routes/auto_router.gr.dart';
import 'package:hessflix/util/hessflix_image.dart';

@RoutePage()
class DetailsScreen extends ConsumerStatefulWidget {
  final String id;
  final ItemBaseModel? item;
  const DetailsScreen({@QueryParam() this.id = '', this.item, super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends ConsumerState<DetailsScreen> {
  late Widget currentWidget = const Center(
    key: Key("progress-indicator"),
    child: CircularProgressIndicator.adaptive(strokeCap: StrokeCap.round),
  );

  @override
  void didUpdateWidget(covariant DetailsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (kIsWeb) {
      updateWidget();
    }
  }

  @override
  void initState() {
    super.initState();
    updateWidget();
  }

  Future<void> updateWidget() async {
    Future.microtask(() async {
      if (widget.item != null) {
        setState(() {
          currentWidget = widget.item!.detailScreenWidget;
        });
      } else {
        final response = await ref.read(itemDetailsProvider.notifier).fetchDetails(widget.id);
        if (context.mounted) {
          if (response != null) {
            setState(() {
              currentWidget = response.detailScreenWidget;
            });
          } else {
            const DashboardRoute().navigate(context);
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      key: Key(widget.id),
      children: [
        Hero(
          tag: widget.id,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withValues(alpha: 1.0),
            ),
            //Small offset to match detailscaffold
            child: Transform.translate(
                offset: const Offset(0, -5), child: HessflixImage(image: widget.item?.getPosters?.primary)),
          ),
        ),
        AnimatedSwitcher(
          duration: const Duration(seconds: 1),
          child: currentWidget,
        )
      ],
    );
  }
}
