import 'package:chopper/chopper.dart';
import 'package:hessflix/jellyfin/jellyfin_open_api.swagger.dart';
import 'package:hessflix/models/favourites_model.dart';
import 'package:hessflix/models/item_base_model.dart';
import 'package:hessflix/models/view_model.dart';
import 'package:hessflix/providers/api_provider.dart';
import 'package:hessflix/providers/views_provider.dart';
import 'package:hessflix/util/item_base_model/item_base_model_extensions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final favouritesProvider = StateNotifierProvider<FavouritesNotifier, FavouritesModel>((ref) {
  return FavouritesNotifier(ref);
});

class FavouritesNotifier extends StateNotifier<FavouritesModel> {
  FavouritesNotifier(this.ref) : super(FavouritesModel());

  final Ref ref;

  late final api = ref.read(jellyApiProvider);

  Future<void> fetchFavourites() async {
    if (state.loading) return;

    state = state.copyWith(loading: true);
    await _fetchMoviesAndSeries();
    await _fetchPeople();
    state = state.copyWith(loading: false);
  }

  Future<void> _fetchMoviesAndSeries() async {
    final views = ref.read(viewsProvider);

    final mappedList = await Future.wait(views.dashboardViews.map((viewModel) => _loadLibrary(viewModel: viewModel)));

    state = state.copyWith(
        favourites: (mappedList
                .expand((innerList) => innerList ?? [])
                .where((item) => item != null)
                .cast<ItemBaseModel>()
                .toList())
            .groupedItems);
  }

  Future<List<ItemBaseModel>?> _loadLibrary({ViewModel? viewModel}) async {
    final response = await api.itemsGet(
      parentId: viewModel?.id,
      isFavorite: true,
      limit: 10,
      sortOrder: [SortOrder.ascending],
      sortBy: [ItemSortBy.seriessortname, ItemSortBy.sortname],
    );
    final response2 = await api.itemsGet(
      parentId: viewModel?.id,
      isFavorite: true,
      recursive: true,
      limit: 10,
      includeItemTypes: [BaseItemKind.photo, BaseItemKind.episode, BaseItemKind.video, BaseItemKind.collectionfolder],
      sortOrder: [SortOrder.ascending],
      sortBy: [ItemSortBy.seriessortname, ItemSortBy.sortname],
    );
    return [...?response.body?.items, ...?response2.body?.items];
  }

  Future<Response<List<ItemBaseModel>>?> _fetchPeople() async {
    final response = await api.personsGet(
      limit: 20,
      isFavorite: true,
    );
    state = state.copyWith(people: response.body ?? []);
    return response;
  }

  void setSearch(String value) {
    state = state.copyWith(searchQuery: value);
  }

  void clear() {
    state = FavouritesModel();
  }
}
