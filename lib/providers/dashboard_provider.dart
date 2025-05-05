import 'package:hessflix/jellyfin/jellyfin_open_api.enums.swagger.dart';
import 'package:hessflix/models/home_model.dart';
import 'package:hessflix/models/item_base_model.dart';
import 'package:hessflix/providers/api_provider.dart';
import 'package:hessflix/providers/service_provider.dart';
import 'package:hessflix/providers/settings/client_settings_provider.dart';
import 'package:hessflix/providers/views_provider.dart';
import 'package:hessflix/util/list_extensions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final dashboardProvider = StateNotifierProvider<DashboardNotifier, HomeModel>((ref) {
  return DashboardNotifier(ref);
});

class DashboardNotifier extends StateNotifier<HomeModel> {
  DashboardNotifier(this.ref) : super(HomeModel());

  final Ref ref;

  late final JellyService api = ref.read(jellyApiProvider);

  Future<void> fetchNextUpAndResume() async {
    if (state.loading) return;
    state = state.copyWith(loading: true);
    final viewTypes =
        ref.read(viewsProvider.select((value) => value.dashboardViews)).map((e) => e.collectionType).toSet().toList();

    if (viewTypes.containsAny([CollectionType.movies, CollectionType.tvshows])) {
      final resumeVideoResponse = await api.usersUserIdItemsResumeGet(
        limit: 16,
        fields: [
          ItemFields.parentid,
          ItemFields.mediastreams,
          ItemFields.mediasources,
          ItemFields.candelete,
          ItemFields.candownload,
        ],
        mediaTypes: [MediaType.video],
        enableTotalRecordCount: false,
      );

      state = state.copyWith(
        resumeVideo: resumeVideoResponse.body?.items?.map((e) => ItemBaseModel.fromBaseDto(e, ref)).toList(),
      );
    }

    if (viewTypes.contains(CollectionType.music)) {
      final resumeAudioResponse = await api.usersUserIdItemsResumeGet(
        limit: 16,
        fields: [
          ItemFields.parentid,
          ItemFields.mediastreams,
          ItemFields.mediasources,
          ItemFields.candelete,
          ItemFields.candownload,
        ],
        mediaTypes: [MediaType.audio],
        enableTotalRecordCount: false,
      );

      state = state.copyWith(
        resumeAudio: resumeAudioResponse.body?.items?.map((e) => ItemBaseModel.fromBaseDto(e, ref)).toList(),
      );
    }

    if (viewTypes.contains(CollectionType.books)) {
      final resumeBookResponse = await api.usersUserIdItemsResumeGet(
        limit: 16,
        fields: [
          ItemFields.parentid,
          ItemFields.mediastreams,
          ItemFields.mediasources,
          ItemFields.candelete,
          ItemFields.candownload,
        ],
        mediaTypes: [MediaType.book],
        enableTotalRecordCount: false,
      );

      state = state.copyWith(
        resumeBooks: resumeBookResponse.body?.items?.map((e) => ItemBaseModel.fromBaseDto(e, ref)).toList(),
      );
    }

    final nextResponse = await api.showsNextUpGet(
      limit: 16,
      nextUpDateCutoff: DateTime.now()
          .subtract(ref.read(clientSettingsProvider.select((value) => value.nextUpDateCutoff ?? const Duration(days: 28)))),
      fields: [
        ItemFields.parentid,
        ItemFields.mediastreams,
        ItemFields.mediasources,
        ItemFields.candelete,
        ItemFields.candownload,
      ],
    );

    final next = nextResponse.body?.items
            ?.map(
              (e) => ItemBaseModel.fromBaseDto(e, ref),
            )
            .toList() ??
        [];

    state = state.copyWith(nextUp: next, loading: false);
  }

  void clear() {
    state = HomeModel();
  }
}
