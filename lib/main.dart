import 'package:flutter/material.dart';
import 'package:horz/Home.dart';

import 'package:horz/signIn.dart';
import 'package:horz/theme/themeProvider.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:provider/provider.dart' as provider;
import 'package:webview_flutter/webview_flutter.dart';

import 'apikeys.dart';
import 'pages/resume/resume_swipe_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: url,
    anonKey: anonKey,
  );

  

  runApp(
    riverpod.ProviderScope(
      child: provider.ChangeNotifierProvider(
        create: (context) => ThemeProvider(),
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: themeProvider.lightTheme,
      darkTheme: themeProvider.darkTheme,
      themeMode: themeProvider.themeMode,
      initialRoute: '/',
      routes: {
        '/': (context) => HomeScreen(),
        '/resume': (context) => ResumeSwipePage(),
        '/projects': (context) => const SignInPage(),
        '/profile': (context) => ResumeSwipePage(),
      },
    );
  }
}
