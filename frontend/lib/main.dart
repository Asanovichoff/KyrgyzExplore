import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';

void main() {
  // ensureInitialized() is required before any plugin calls (Firebase, secure storage, etc.)
  WidgetsFlutterBinding.ensureInitialized();

  // ProviderScope is the Riverpod root — every provider is scoped inside it.
  // All state is destroyed when the app exits (no global singletons).
  runApp(const ProviderScope(child: KyrgyzExploreApp()));
}
