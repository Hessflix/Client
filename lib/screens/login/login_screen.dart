import 'dart:async';

import 'package:flutter/material.dart';

import 'package:auto_route/auto_route.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hessflix/models/account_model.dart';
import 'package:hessflix/providers/auth_provider.dart';
import 'package:hessflix/providers/shared_provider.dart';
import 'package:hessflix/providers/user_provider.dart';
import 'package:hessflix/routes/auto_router.gr.dart';
import 'package:hessflix/screens/login/lock_screen.dart';
import 'package:hessflix/screens/login/login_edit_user.dart';
import 'package:hessflix/screens/login/login_user_grid.dart';
import 'package:hessflix/screens/login/widgets/discover_servers_widget.dart';
import 'package:hessflix/screens/shared/animated_fade_size.dart';
import 'package:hessflix/screens/shared/hessflix_logo.dart';
import 'package:hessflix/screens/shared/hessflix_snackbar.dart';
import 'package:hessflix/screens/shared/outlined_text_field.dart';
import 'package:hessflix/screens/shared/passcode_input.dart';
import 'package:hessflix/util/adaptive_layout.dart';
import 'package:hessflix/util/auth_service.dart';
import 'package:hessflix/util/hessflix_config.dart';
import 'package:hessflix/util/list_padding.dart';
import 'package:hessflix/util/localization_helper.dart';
import 'package:hessflix/util/string_extensions.dart';
import 'package:hessflix/widgets/navigation_scaffold/components/hessflix_app_bar.dart';
import 'package:hessflix/screens/login/oauth_webview.dart';


@RoutePage()
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginScreen> {
  List<AccountModel> users = const [];
  bool loading = false;
  String? invalidUrl = "";
  bool startCheckingForErrors = false;
  bool addingNewUser = false;
  bool editingUsers = false;
  late final TextEditingController serverTextController = TextEditingController(text: '');

  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final FocusNode focusNode = FocusNode();

  void startAddingNewUser() {
    setState(() {
      addingNewUser = true;
      editingUsers = false;
    });
    if (HessflixConfig.baseUrl != null) {
      serverTextController.text = HessflixConfig.baseUrl!;
      _parseUrl(HessflixConfig.baseUrl!);
      retrieveListOfUsers();
    }
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(userProvider.notifier).clear();
      final currentAccounts = ref.read(authProvider.notifier).getSavedAccounts();
      addingNewUser = currentAccounts.isEmpty;
      ref.read(lockScreenActiveProvider.notifier).update((state) => true);
      if (HessflixConfig.baseUrl != null) {
        serverTextController.text = HessflixConfig.baseUrl!;
        _parseUrl(HessflixConfig.baseUrl!);
        retrieveListOfUsers();
      }
    });
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: const HessflixAppBar(),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const HessflixLogo(),
            const SizedBox(height: 32),
            FilledButton.icon(
              icon: const Icon(Icons.login),
              label: const Text("Se connecter avec Hessflix"),
              onPressed: () async {
                // 🔐 Étape 1 : Lancer l'auth via Authentik + Jellyfin
                final token = await Navigator.of(context).push<String?>(
                  MaterialPageRoute(
                    builder: (_) => const OAuthLocalServerPage(),
                  ),
                );

                // ✅ Étape 2 : Récupération du token Jellyfin via localStorage
                if (token != null && token.isNotEmpty) {
                  ref.read(authProvider.notifier).setSessionToken(token);

                  final user = await ref.read(authProvider.notifier).loginWithCurrentSession(token);

                  if (context.mounted && user != null) {
                    context.router.replaceAll([const DashboardRoute()]);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Échec de la connexion à Hessflix.")),
                    );
                  }
                } else {
                  // ❌ Aucun token trouvé
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Session Jellyfin introuvable.")),
                  );
                }
              },
            ),
          ],
        ),
      ),
    ),
  );
}


  void _parseUrl(String url) {
    setState(() {
      ref.read(authProvider.notifier).setServer("");
      users = [];

      if (url.isEmpty) {
        invalidUrl = "";
        return;
      }
      if (!Uri.parse(url).isAbsolute) {
        invalidUrl = context.localized.invalidUrl;
        return;
      }

      if (!url.startsWith('https://') && !url.startsWith('http://')) {
        invalidUrl = context.localized.invalidUrlDesc;
        return;
      }

      invalidUrl = null;

      if (invalidUrl == null) {
        ref.read(authProvider.notifier).setServer(url.rtrim('/'));
      }
    });
  }

  void openUserEditDialogue(BuildContext context, AccountModel user) {
    showDialog(
      context: context,
      builder: (context) => LoginEditUser(
        user: user,
        onTapServer: (value) {
          setState(() {
            _parseUrl(value);
            serverTextController.text = value;
            startAddingNewUser();
          });
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void tapLoggedInAccount(AccountModel user) async {
    switch (user.authMethod) {
      case Authentication.autoLogin:
        handleLogin(user);
        break;
      case Authentication.biometrics:
        final authenticated = await AuthService.authenticateUser(context, user);
        if (authenticated) {
          handleLogin(user);
        }
        break;
      case Authentication.passcode:
        if (context.mounted) {
          showPassCodeDialog(context, (newPin) {
            if (newPin == user.localPin) {
              handleLogin(user);
            } else {
              hessflixSnackbar(context, title: context.localized.incorrectPinTryAgain);
            }
          });
        }
        break;
      case Authentication.none:
        handleLogin(user);
        break;
    }
  }

  Future<void> handleLogin(AccountModel user) async {
    await ref.read(authProvider.notifier).switchUser();
    await ref.read(sharedUtilityProvider).updateAccountInfo(user.copyWith(
          lastUsed: DateTime.now(),
        ));
    ref.read(userProvider.notifier).updateUser(user.copyWith(lastUsed: DateTime.now()));

    loggedInGoToHome();
  }

  void loggedInGoToHome() {
    ref.read(lockScreenActiveProvider.notifier).update((state) => false);
    if (context.mounted) {
      context.router.replaceAll([const DashboardRoute()]);
    }
  }

  Future<Null> Function()? get enterCredentialsTryLogin => emptyFields()
      ? null
      : () async {
          serverTextController.text = serverTextController.text.rtrim('/');
          ref.read(authProvider.notifier).setServer(serverTextController.text.rtrim('/'));
          final response = await ref.read(authProvider.notifier).authenticateByName(
                usernameController.text,
                passwordController.text,
              );
          if (response?.isSuccessful == false) {
            hessflixSnackbar(context,
                title:
                    "(${response?.base.statusCode}) ${response?.base.reasonPhrase ?? context.localized.somethingWentWrongPasswordCheck}");
          } else if (response?.body != null) {
            loggedInGoToHome();
          }
        };

  bool emptyFields() => usernameController.text.isEmpty;

  void retrieveListOfUsers() async {
    serverTextController.text = serverTextController.text.rtrim('/');
    ref.read(authProvider.notifier).setServer(serverTextController.text);
    setState(() => loading = true);
    final response = await ref.read(authProvider.notifier).getPublicUsers();
    if ((response == null || response.isSuccessful == false) && context.mounted) {
      hessflixSnackbar(context, title: response?.base.reasonPhrase ?? context.localized.unableToConnectHost);
      setState(() => startCheckingForErrors = true);
    }
    if (response?.body?.isEmpty == true) {
      await Future.delayed(const Duration(seconds: 1));
    }
    setState(() {
      users = response?.body ?? [];
      loading = false;
    });
  }

  Widget addUserFields(List<AccountModel> accounts, bool authLoading) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (accounts.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: IconButton.filledTonal(
                  onPressed: () {
                    setState(() {
                      addingNewUser = false;
                      loading = false;
                      startCheckingForErrors = false;
                      serverTextController.text = "";
                      usernameController.text = "";
                      passwordController.text = "";
                      invalidUrl = "";
                    });
                    ref.read(authProvider.notifier).setServer("");
                  },
                  icon: const Icon(
                    IconsaxPlusLinear.arrow_left_2,
                  ),
                ),
              ),
            if (HessflixConfig.baseUrl == null) ...[
              Flexible(
                child: OutlinedTextField(
                  controller: serverTextController,
                  onChanged: _parseUrl,
                  onSubmitted: (value) => retrieveListOfUsers(),
                  autoFillHints: const [AutofillHints.url],
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  textInputAction: TextInputAction.go,
                  label: context.localized.server,
                  errorText: (invalidUrl == null || serverTextController.text.isEmpty || !startCheckingForErrors)
                      ? null
                      : invalidUrl,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Tooltip(
                  message: context.localized.retrievePublicListOfUsers,
                  waitDuration: const Duration(seconds: 1),
                  child: IconButton.filled(
                    onPressed: () => retrieveListOfUsers(),
                    icon: const Icon(
                      IconsaxPlusLinear.refresh,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        AnimatedFadeSize(
          child: invalidUrl == null
              ? Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (loading || users.isNotEmpty)
                      AnimatedFadeSize(
                        duration: const Duration(milliseconds: 250),
                        child: loading
                            ? CircularProgressIndicator(key: UniqueKey(), strokeCap: StrokeCap.round)
                            : LoginUserGrid(
                                users: users,
                                onPressed: (value) {
                                  usernameController.text = value.name;
                                  passwordController.text = "";
                                  focusNode.requestFocus();
                                },
                              ),
                      ),
                    AutofillGroup(
                      child: Column(
                        children: [
                          OutlinedTextField(
                            controller: usernameController,
                            autoFillHints: const [AutofillHints.username],
                            textInputAction: TextInputAction.next,
                            autocorrect: false,
                            onChanged: (value) => setState(() {}),
                            label: context.localized.userName,
                          ),
                          OutlinedTextField(
                            controller: passwordController,
                            autoFillHints: const [AutofillHints.password],
                            keyboardType: TextInputType.visiblePassword,
                            focusNode: focusNode,
                            autocorrect: false,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (value) => enterCredentialsTryLogin?.call(),
                            onChanged: (value) => setState(() {}),
                            label: context.localized.password,
                          ),
                          FilledButton(
                            onPressed: enterCredentialsTryLogin,
                            child: authLoading
                                ? SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        color: Theme.of(context).colorScheme.inversePrimary,
                                        strokeCap: StrokeCap.round),
                                  )
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(context.localized.login),
                                      const SizedBox(width: 8),
                                      const Icon(IconsaxPlusBold.send_1),
                                    ],
                                  ),
                          ),
                        ].addPadding(const EdgeInsets.symmetric(vertical: 4)),
                      ),
                    ),
                  ].addPadding(const EdgeInsets.symmetric(vertical: 10)),
                )
              : DiscoverServersWidget(
                  serverCredentials: accounts.map((e) => e.credentials).toList(),
                  onPressed: (server) {
                    serverTextController.text = server.address;
                    _parseUrl(server.address);
                    retrieveListOfUsers();
                  },
                ),
        )
      ].addPadding(const EdgeInsets.symmetric(vertical: 8)),
    );
  }
}
