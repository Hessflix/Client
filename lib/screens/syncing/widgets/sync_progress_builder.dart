import 'package:hessflix/models/syncing/download_stream.dart';
import 'package:hessflix/models/syncing/sync_item.dart';
import 'package:hessflix/providers/sync/sync_provider_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SyncProgressBuilder extends ConsumerWidget {
  final SyncedItem item;
  final Widget Function(BuildContext context, DownloadStream? combinedStream) builder;
  const SyncProgressBuilder({required this.item, required this.builder, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncStatus = ref.watch(syncDownloadStatusProvider(item));
    return builder(context, syncStatus);
  }
}
