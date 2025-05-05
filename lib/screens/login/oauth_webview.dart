import 'dart:io';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class OAuthWebView extends StatefulWidget {
  final String authorizationUrl;
  final String redirectUrl;

  const OAuthWebView({
    super.key,
    required this.authorizationUrl,
    required this.redirectUrl,
  });

  @override
  State<OAuthWebView> createState() => _OAuthWebViewState();
}

class _OAuthWebViewState extends State<OAuthWebView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) async {
            if (url.contains("/web/index.html")) {
              try {
                final result = await _controller.runJavaScriptReturningResult('''
                  try {
                    JSON.parse(localStorage.getItem("jellyfin_credentials"))?.Servers?.[0]?.AccessToken;
                  } catch (e) {
                    null;
                  }
                ''');

                final token = result?.toString().replaceAll('"', '').trim();

                if (context.mounted) {
                  Navigator.of(context).pop((token != null && token.isNotEmpty) ? token : null);
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.of(context).pop(null);
                }
              }
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.authorizationUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Connexion Hessflix")),
      body: WebViewWidget(controller: _controller),
    );
  }
}
