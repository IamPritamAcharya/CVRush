import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  bool _isLoading = false;

  Future<void> _signInWithGoogle() async {
    try {
      setState(() => _isLoading = true);
      // Use native sign-in on Android; otherwise, use OAuth
      if (!kIsWeb && Platform.isAndroid) {
        await _nativeGoogleSignIn();
      } else {
        await supabase.auth.signInWithOAuth(OAuthProvider.google);
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _nativeGoogleSignIn() async {
    const webClientId =
        '669920565478-rfq2aae8idiuqoif5ft9n361iau629nc.apps.googleusercontent.com';

    final GoogleSignIn googleSignIn = GoogleSignIn(serverClientId: webClientId);
    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      debugPrint("User cancelled Google sign in");
      return;
    }
    final googleAuth = await googleUser.authentication;
    if (googleAuth.idToken == null || googleAuth.accessToken == null) {
      throw Exception("Google Sign-In failed: Missing tokens.");
    }
    await supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: googleAuth.idToken!,
      accessToken: googleAuth.accessToken!,
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Lock Icon
              Icon(Icons.lock_outline_rounded,
                  size: 80, color: Theme.of(context).primaryColor),
              const SizedBox(height: 20),

              // Welcome Text
              Text(
                "Welcome Back!",
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                "Sign in to continue",
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 40),

              // Google Sign-In Button
              InkWell(
                onTap: _isLoading ? null : _signInWithGoogle,
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Google logo via URL
                      Image.network(
                        'https://upload.wikimedia.org/wikipedia/commons/thumb/5/53/Google_%22G%22_Logo.svg/512px-Google_%22G%22_Logo.svg.png',
                        height: 24,
                        width: 24,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.login, size: 24);
                        },
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _isLoading ? "Signing in..." : "Sign in with Google",
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Divider text for alternative login
              Text(
                "Or log in with username & password",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),

              // Username Text Field
              TextField(
                decoration: InputDecoration(
                  labelText: "Username",
                  hintText: "Enter your username",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Password Text Field
              TextField(
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Password",
                  hintText: "Enter your password",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Login Button for username/password (UI only)
              ElevatedButton(
                onPressed: () {
                  // Handle username/password login (UI only)
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      Theme.of(context).primaryColor, // Button background
                  foregroundColor: Colors.white, // Text color
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 4,
                  shadowColor: Colors.black.withOpacity(0.2),
                ),
                child: const Text(
                  "Login",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
