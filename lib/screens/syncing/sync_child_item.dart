import 'package:hessflix/models/items/season_model.dart';
import 'package:hessflix/models/syncing/sync_item.dart';
import 'package:hessflix/screens/syncing/widgets/synced_season_poster.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hessflix/models/items/episode_model.dart';
import 'package:hessflix/providers/sync_provider.dart';

import 'widgets/synced_episode_item.dart';

class ChildSyncWidget extends ConsumerStatefulWidget {
  final SyncedItem syncedChild;
  const ChildSyncWidget({
    required this.syncedChild,
    super.key,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ChildSyncWidgetState();
}

class _ChildSyncWidgetState extends ConsumerState<ChildSyncWidget> {
  late SyncedItem syncedItem = widget.syncedChild;

  @override
  Widget build(BuildContext context) {
    final baseItem = ref.read(syncProvider.notifier).getItem(syncedItem);
    final hasFile = syncedItem.videoFile.existsSync();
    if (baseItem == null) {
      return Container();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Card(
        child: InkWell(
          onTap: () {
            Navigator.of(context).pop();
            baseItem.navigateTo(context);
          },
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Flexible(
                  child: switch (baseItem) {
                    SeasonModel season => SyncedSeasonPoster(
                        syncedItem: syncedItem,
                        season: season,
                      ),
                    EpisodeModel episode => SyncedEpisodeItem(
                        episode: episode,
                        syncedItem: syncedItem,
                        hasFile: hasFile,
                      ),
                    _ => Container(),
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
