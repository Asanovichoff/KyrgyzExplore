import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase init is wrapped in try/catch so the app still runs in dev
  // environments where google-services.json / GoogleService-Info.plist
  // haven't been configured yet.
  try {
    await Firebase.initializeApp();
  } catch (_) {}

  runApp(const ProviderScope(child: KyrgyzExploreApp()));
}
