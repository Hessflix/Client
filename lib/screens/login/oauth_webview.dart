import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart' as shelf;
import 'package:url_launcher/url_launcher.dart';

class OAuthLocalServerPage extends StatefulWidget {
  const OAuthLocalServerPage({super.key});

  @override
  State<OAuthLocalServerPage> createState() => _OAuthLocalServerPageState();
}

class _OAuthLocalServerPageState extends State<OAuthLocalServerPage> {
  HttpServer? _server;

  @override
  void initState() {
    super.initState();
    _startLocalServer();
    _openBrowser();
  }

  Future<void> _startLocalServer() async {
    final router = shelf.Router()
      ..get('/callback', (Request req) {
        final token = req.url.queryParameters['access_token'];
        if (token != null && token.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pop(token);
          });
        }
        return Response.ok('Connexion réussie, vous pouvez fermer cette fenêtre.');
      });

    _server = await io.serve(router, 'localhost', 3000);
    print('✅ Serveur OAuth lancé sur http://localhost:3000/callback');
  }

  Future<void> _openBrowser() async {
    final redirectUri = Uri.encodeComponent('http://localhost:3000/callback');
    final authUrl = Uri.parse('https://hessflix.tv/jellyfin/SSO/oid/p/Hessflix?redirect_uri=$redirectUri');

    if (!await launchUrl(authUrl, mode: LaunchMode.externalApplication)) {
      throw 'Impossible d’ouvrir le navigateur.';
    }
  }

  @override
  void dispose() {
    _server?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text("En attente de la connexion OAuth...")),
    );
  }
}