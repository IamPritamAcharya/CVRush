import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class AtsPage extends StatefulWidget {
  const AtsPage({super.key});

  @override
  State<AtsPage> createState() => _AtsPageState();
}

class _AtsPageState extends State<AtsPage> {
  final String atsUrl = "https://c637-106-222-184-196.ngrok-free.app";
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000)) 
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            debugPrint('Page loading: $url');
          },
          onPageFinished: (String url) {
            debugPrint('Page finished loading: $url');
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('Page error: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse(atsUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ATS Viewer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _controller.reload(),
          ),
        ],
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        child: WebViewWidget(controller: _controller),
      ),
    );
  }
}
