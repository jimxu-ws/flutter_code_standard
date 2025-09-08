import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:query_provider/query_provider.dart';

import 'models/user.dart';
import 'models/post.dart';
import 'services/api_service.dart';
import 'providers/user_providers.dart';
import 'providers/post_providers.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(
    // Use ProviderScope to ensure all providers share the same container
    // This is critical for QueryClient to properly invalidate providers
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Query Provider Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
