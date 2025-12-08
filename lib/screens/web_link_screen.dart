import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/about.dart';
import '../screens/offline_screen.dart';
import '../api/link.dart';

class WebLinkScreen extends StatefulWidget {
  const WebLinkScreen({super.key});

  @override
  State<WebLinkScreen> createState() => _WebLinkScreenState();
}

class _WebLinkScreenState extends State<WebLinkScreen> {
  late final WebViewController _controller;
  int _progress = 0;
  bool _canGoBack = false;
  bool _canGoForward = false;
  bool _isOffline = false;
  late final Stream<List<ConnectivityResult>> _connectivityStream;

  @override
  void initState() {
    super.initState();
    _connectivityStream = Connectivity().onConnectivityChanged;
    _connectivityStream.listen((results) {
      final offline = results.contains(ConnectivityResult.none);
      if (mounted && offline != _isOffline) {
        setState(() {
          _isOffline = offline;
        });
        if (!offline) {
          _controller.reload();
        }
      }
    });

    _checkInitialConnectivity();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _progress = 0),
          onUrlChange: (_) async {
            await _updateNavAvailability();
          },
          onNavigationRequest: (request) async {
            final uri = Uri.parse(request.url);
            if (uri.scheme != 'http' && uri.scheme != 'https') {
              // Open non-web schemes externally (tel:, mailto:, etc.)
              await _openExternal(request.url);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onPageFinished: (_) async {
            setState(() => _progress = 100);
            await _updateNavAvailability();
          },
          onProgress: (p) => setState(() => _progress = p),
          onWebResourceError: (error) {
            if (mounted) {
              setState(() {
                _isOffline = true;
              });
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(login));
  }

  Future<void> _checkInitialConnectivity() async {
    final current = await Connectivity().checkConnectivity();
    if (mounted) {
      setState(() {
        _isOffline = current == ConnectivityResult.none;
      });
    }
  }

  Future<void> _updateNavAvailability() async {
    final canBack = await _controller.canGoBack();
    final canForward = await _controller.canGoForward();
    if (mounted) {
      setState(() {
        _canGoBack = canBack;
        _canGoForward = canForward;
      });
    }
  }

  Future<void> _openExternal(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      await launchUrl(uri, webOnlyWindowName: '_blank');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isOffline) {
      return OfflineScreen(
        onRetry: () async {
          final current = await Connectivity().checkConnectivity();
          if (current != ConnectivityResult.none) {
            setState(() => _isOffline = false);
            _controller.loadRequest(Uri.parse(login));
          }
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 22, 22, 22),
        title: GestureDetector(
          onTap: () => AboutMe(
            applicationName: 'Clementine\'s Cafe',
            version: '1.0.7',
            description:
                "Experience Clementine's Cafe directly on your mobile device with this native app that provides fast, seamless access to the restaurant's ",
            backgroundColor: const Color.fromARGB(255, 22, 22, 22),
            textColor: Colors.white,
            logo: Image.asset("assets/icon.png"),
          ).showCustomAbout(context),
          child: const Text(
            'Clementine\'s Cafe',
            style: TextStyle(color: Colors.white),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Reload',
            icon: const Icon(
              Icons.refresh,
              color: Color.fromRGBO(195, 28, 36, 1),
            ),
            onPressed: () => _controller.reload(),
          ),
          IconButton(
            tooltip: 'Open home URL',
            icon: const Icon(
              Icons.home_outlined,
              color: Color.fromRGBO(195, 28, 36, 1),
            ),
            onPressed: () => _controller.loadRequest(Uri.parse(home)),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: _progress < 100
              ? LinearProgressIndicator(value: _progress / 100, minHeight: 3)
              : const SizedBox(height: 3),
        ),
      ),
      body: SafeArea(child: WebViewWidget(controller: _controller)),
      bottomNavigationBar: BottomAppBar(
        color: const Color.fromARGB(255, 22, 22, 22),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              tooltip: 'Back',
              icon: const Icon(Icons.arrow_back),
              onPressed: _canGoBack ? () => _controller.goBack() : null,
            ),
            IconButton(
              tooltip: 'Forward',
              icon: const Icon(Icons.arrow_forward),
              onPressed: _canGoForward ? () => _controller.goForward() : null,
            ),
          ],
        ),
      ),
    );
  }
}
