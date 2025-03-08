import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class ResumeWebView extends StatefulWidget {
  final String url;
  ResumeWebView({required this.url});

  @override
  _ResumeWebViewState createState() => _ResumeWebViewState();
}

class _ResumeWebViewState extends State<ResumeWebView> {
  InAppWebViewController? webViewController;
  bool isLoading = true;
  bool isDesktopView = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1D1E),
        title: Text("Resume Preview"),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isDesktopView
                  ? Icons.desktop_windows_rounded
                  : Icons.smartphone_rounded,
              color: Colors.white,
            ),
            onPressed: _toggleDesktopView,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ElevatedButton(
              onPressed: _reloadPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2C2F30),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                'Reload',
                style: TextStyle(
                  fontFamily: 'ProductSans',
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          InAppWebView(
            initialUrlRequest:
                URLRequest(url: WebUri.uri(Uri.parse(widget.url))),
            onWebViewCreated: (controller) {
              webViewController = controller;
            },
            onLoadStop: (controller, url) {
              _injectViewportMetaTag();
              setState(() {
                isLoading = false;
              });
            },
          ),
          if (isLoading)
            Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                backgroundColor: const Color(0xFF1A1D1E),
              ),
            ),
        ],
      ),
    );
  }

  /// Toggle between mobile and desktop view
  Future<void> _toggleDesktopView() async {
    setState(() {
      isDesktopView = !isDesktopView;
    });
    _injectViewportMetaTag();
  }

  /// Inject viewport meta tag dynamically for responsive design
  Future<void> _injectViewportMetaTag() async {
    if (webViewController == null) return;

    await webViewController!.evaluateJavascript(source: """
      (function() {
        let meta = document.querySelector('meta[name="viewport"]');
        if (!meta) {
          meta = document.createElement('meta');
          meta.name = "viewport";
          document.head.appendChild(meta);
        }
        meta.content = "${isDesktopView ? 'width=1200' : 'width=device-width, initial-scale=1.0'}";
      })();
    """);
  }

  /// Reload the resume web page
  Future<void> _reloadPage() async {
    if (webViewController != null) {
      await webViewController!.reload();
    }
  }
}
