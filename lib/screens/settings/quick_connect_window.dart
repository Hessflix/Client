import 'package:hessflix/providers/user_provider.dart';
import 'package:hessflix/screens/login/widgets/login_icon.dart';
import 'package:hessflix/screens/shared/outlined_text_field.dart';
import 'package:hessflix/util/list_padding.dart';
import 'package:hessflix/util/localization_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> openQuickConnectDialog(
  BuildContext context,
) async {
  return showDialog(context: context, builder: (context) => const QuickConnectDialog());
}

class QuickConnectDialog extends ConsumerStatefulWidget {
  const QuickConnectDialog({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _QuickConnectDialogState();
}

class _QuickConnectDialogState extends ConsumerState<QuickConnectDialog> {
  final controller = TextEditingController();
  bool loading = false;
  String? error;
  String? success;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    return AlertDialog(
      title: Text(context.localized.quickConnectTitle),
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(context.localized.quickConnectAction),
          if (user != null) SizedBox(child: LoginIcon(user: user)),
          Flexible(
            child: OutlinedTextField(
              label: context.localized.code,
              controller: controller,
              keyboardType: TextInputType.number,
              onChanged: (value) {
                if (value.isNotEmpty) {
                  setState(() {
                    error = null;
                    success = null;
                  });
                }
              },
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            child: error != null || success != null
                ? Card(
                    key: Key(context.localized.error),
                    color: success == null ? Theme.of(context).colorScheme.errorContainer : Theme.of(context).colorScheme.surfaceContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        success ?? error ?? "",
                        style: TextStyle(
                            color:
                                success == null ? Theme.of(context).colorScheme.onErrorContainer : Theme.of(context).colorScheme.onSurface),
                      ),
                    ),
                  )
                : null,
          ),
          ElevatedButton(
            onPressed: loading
                ? null
                : () async {
                    setState(() {
                      error = null;
                      loading = true;
                    });
                    final response = await ref.read(userProvider.notifier).quickConnect(controller.text);
                    if (response.isSuccessful) {
                      setState(
                        () {
                          error = null;
                          success = context.localized.loggedIn;
                        },
                      );
                      await Future.delayed(const Duration(seconds: 2));
                      Navigator.of(context).pop();
                    } else {
                      if (controller.text.isEmpty) {
                        error = context.localized.quickConnectInputACode;
                      } else {
                        error = context.localized.quickConnectWrongCode;
                      }
                    }
                    loading = false;
                    setState(
                      () {},
                    );
                    controller.text = "";
                  },
            child: loading
                ? const SizedBox.square(
                    child: CircularProgressIndicator(),
                    dimension: 16.0,
                  )
                : Text(context.localized.login),
          )
        ].addInBetween(const SizedBox(height: 16)),
      ),
    );
  }
}
