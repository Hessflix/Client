import 'dart:html' as html;

import 'package:chopper/chopper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:hessflix/models/account_model.dart';
import 'package:hessflix/models/credentials_model.dart';
import 'package:hessflix/models/login_screen_model.dart';
import 'package:hessflix/providers/api_provider.dart';
import 'package:hessflix/providers/dashboard_provider.dart';
import 'package:hessflix/providers/favourites_provider.dart';
import 'package:hessflix/providers/image_provider.dart';
import 'package:hessflix/providers/service_provider.dart';
import 'package:hessflix/providers/shared_provider.dart';
import 'package:hessflix/providers/sync_provider.dart';
import 'package:hessflix/providers/user_provider.dart';
import 'package:hessflix/providers/views_provider.dart';

final authProvider = StateNotifierProvider<AuthNotifier, LoginScreenModel>((ref) {
  return AuthNotifier(ref);
});

class AuthNotifier extends StateNotifier<LoginScreenModel> {
  AuthNotifier(this.ref)
      : super(
          LoginScreenModel(
            accounts: [],
            tempCredentials: CredentialsModel.createNewCredentials(),
            loading: false,
          ),
        );

  final Ref ref;

  late final JellyService api = ref.read(jellyApiProvider);

  void setSessionToken(String token) {
  state = state.copyWith(
    tempCredentials: state.tempCredentials.copyWith(
      token: token,
      server: 'https://backend.hessflix.tv/jellyfin', // 🔧 indispensable
    ),
  );
}


  Future<Response<List<AccountModel>>?> getPublicUsers() async {
    try {
      var response = await api.usersPublicGet(state.tempCredentials);
      if (response.isSuccessful && response.body != null) {
        var models = response.body ?? [];

        return response.copyWith(body: models.toList());
      }
      return response.copyWith(body: []);
    } catch (e) {
      return null;
    }
  }

Future<AccountModel?> loginWithCurrentSession(String token) async {
  try {
    print('🔐 Tentative de connexion avec la session actuelle...');
    print('🔑 Jeton reçu : $token');

    if (token.trim().isEmpty) {
      print('❌ Aucun token reçu depuis la WebView');
      return null;
    }

    // Met à jour les credentials avec le token
    setSessionToken(token);
    final credentials = state.tempCredentials;

    final meResponse = await api.usersMeGet();
    print('📡 usersMeGet status: ${meResponse.statusCode}');
    print('📥 usersMeGet body: ${meResponse.body}');

    if (!meResponse.isSuccessful || meResponse.body == null) {
      print('❌ Échec lors de la récupération de l’utilisateur');
      return null;
    }

    final me = meResponse.body!;
    final imageUrl = ref.read(imageUtilityProvider).getUserImageUrl(me.id ?? "");

    final updatedCredentials = credentials.copyWith(
      token: token,
      serverId: credentials.serverId,
    );

    final account = AccountModel(
      id: me.id ?? "",
      name: me.name ?? "",
      avatar: imageUrl,
      credentials: updatedCredentials,
      lastUsed: DateTime.now(),
    );

    await ref.read(sharedUtilityProvider).addAccount(account);
    ref.read(userProvider.notifier).updateUser(account);

    print('✅ Connexion réussie pour ${account.name}');
    return account;
  } catch (e, stack) {
    print('❌ Exception pendant la connexion avec session : $e\n$stack');
    return null;
  }
}


  Future<Response<AccountModel>?> authenticateByName(String userName, String password) async {
    state = state.copyWith(loading: true);
    clearAllProviders();
    var response = await api.usersAuthenticateByNamePost(userName: userName, password: password);
    CredentialsModel credentials = state.tempCredentials;
    if (response.isSuccessful && (response.body?.accessToken?.isNotEmpty ?? false)) {
      var serverResponse = await api.systemInfoPublicGet();
      credentials = credentials.copyWith(
        token: response.body?.accessToken ?? "",
        serverId: response.body?.serverId,
        serverName: serverResponse.body?.serverName ?? "",
      );
      var imageUrl = ref.read(imageUtilityProvider).getUserImageUrl(response.body?.user?.id ?? "");
      AccountModel newUser = AccountModel(
        name: response.body?.user?.name ?? "",
        id: response.body?.user?.id ?? "",
        avatar: imageUrl,
        credentials: credentials,
        lastUsed: DateTime.now(),
      );
      ref.read(sharedUtilityProvider).addAccount(newUser);
      ref.read(userProvider.notifier).updateUser(newUser);
      state = state.copyWith(loading: false);
      return Response(response.base, newUser);
    }
    state = state.copyWith(loading: false);
    return Response(response.base, null);
  }

  

Future<Response?> logOutUser() async {
  final currentUser = ref.read(userProvider);
  state = state.copyWith(tempCredentials: CredentialsModel.createNewCredentials());
  await ref.read(sharedUtilityProvider).removeAccount(currentUser);
  clearAllProviders();

  if (kIsWeb) {
    // Déconnecte de la session Authentik (popup SSO) et retourne à la page login Flutter Web
    html.window.location.href =
        'https://auth.hessflix.tv/application/o/hessflix/end-session/';
  }

  return null;
}


  Future<void> switchUser() async {
    clearAllProviders();
  }

  void clearAllProviders() {
    ref.read(dashboardProvider.notifier).clear();
    ref.read(viewsProvider.notifier).clear();
    ref.read(favouritesProvider.notifier).clear();
    ref.read(userProvider.notifier).clear();
    ref.read(syncProvider.notifier).setup();
  }

  void setServer(String server) {
    state = state.copyWith(
      tempCredentials: state.tempCredentials.copyWith(server: server),
    );
  }

  List<AccountModel> getSavedAccounts() {
    state = state.copyWith(accounts: ref.read(sharedUtilityProvider).getAccounts());
    return state.accounts;
  }

  void reOrderUsers(int oldIndex, int newIndex) {
    final accounts = state.accounts;
    final original = accounts.elementAt(oldIndex);
    accounts.removeAt(oldIndex);
    accounts.insert(newIndex, original);
    ref.read(sharedUtilityProvider).saveAccounts(accounts);
  }
}
