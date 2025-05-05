import 'package:isar/isar.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:hessflix/models/syncing/download_stream.dart';
import 'package:hessflix/models/syncing/i_synced_item.dart';
import 'package:hessflix/models/syncing/sync_item.dart';
import 'package:hessflix/providers/sync_provider.dart';

part 'sync_provider_helpers.g.dart';

@riverpod
class SyncChildren extends _$SyncChildren {
  @override
  List<SyncedItem> build(SyncedItem arg) {
    final syncedItemIsar = ref.watch(syncProvider.notifier).isar;
    final allChildren = <SyncedItem>[];
    List<SyncedItem> toProcess = [arg];
    while (toProcess.isNotEmpty) {
      final currentLevel = toProcess.map(
        (parent) {
          final children = syncedItemIsar?.iSyncedItems.where().parentIdEqualTo(parent.id).sortBySortName().findAll();
          return children?.map((e) => SyncedItem.fromIsar(e, ref.read(syncProvider.notifier).syncPath ?? "")) ??
              <SyncedItem>[];
        },
      );
      allChildren.addAll(currentLevel.expand((list) => list));
      toProcess = currentLevel.expand((list) => list).toList();
    }
    return allChildren;
  }
}

@riverpod
class SyncDownloadStatus extends _$SyncDownloadStatus {
  @override
  DownloadStream? build(SyncedItem arg) {
    final nestedChildren = ref.watch(syncChildrenProvider(arg));

    ref.watch(downloadTasksProvider(arg.id));
    for (var element in nestedChildren) {
      ref.watch(downloadTasksProvider(element.id));
    }

    DownloadStream mainStream = ref.read(downloadTasksProvider(arg.id));
    int downloadCount = 0;
    double fullProgress = mainStream.hasDownload ? mainStream.progress : 0.0;

    for (var i = 0; i < nestedChildren.length; i++) {
      final childItem = nestedChildren[i];
      final downloadStream = ref.read(downloadTasksProvider(childItem.id));
      if (downloadStream.hasDownload) {
        downloadCount++;
        fullProgress += downloadStream.progress;
        mainStream = mainStream.copyWith(status: downloadStream.status);
      }
    }

    return mainStream.copyWith(
      progress: fullProgress / downloadCount.clamp(1, double.infinity).toInt(),
    );
  }
}

@riverpod
class SyncStatuses extends _$SyncStatuses {
  @override
  FutureOr<SyncStatus> build(SyncedItem arg) async {
    final nestedChildren = ref.watch(syncChildrenProvider(arg));

    ref.watch(downloadTasksProvider(arg.id));
    for (var element in nestedChildren) {
      ref.watch(downloadTasksProvider(element.id));
    }

    for (var i = 0; i < nestedChildren.length; i++) {
      final item = nestedChildren[i];
      if (item.hasVideoFile && !await item.videoFile.exists()) {
        return SyncStatus.partially;
      }
    }
    if (arg.hasVideoFile && !await arg.videoFile.exists()) {
      return SyncStatus.partially;
    }
    return SyncStatus.complete;
  }
}

@riverpod
class SyncSize extends _$SyncSize {
  @override
  int? build(SyncedItem arg) {
    final nestedChildren = ref.watch(syncChildrenProvider(arg));

    ref.watch(downloadTasksProvider(arg.id));
    for (var element in nestedChildren) {
      ref.watch(downloadTasksProvider(element.id));
    }
    int size = arg.fileSize ?? 0;
    for (var element in nestedChildren) {
      size += element.fileSize ?? 0;
    }
    return size;
  }
}
