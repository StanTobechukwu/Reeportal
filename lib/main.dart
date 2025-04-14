import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'repositories/auth_repository.dart';
import 'repositories/firestore_repository.dart';
import 'repositories/storage_repository.dart';
import 'services/document_service.dart';
import 'services/version_service.dart';
import 'ui/screens/auth_screen.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/editor_screen.dart';
import 'ui/screens/preview_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(
    MultiProvider(
      providers: [
        Provider<AuthRepository>(create: (_) => AuthRepository()),
        Provider<FirestoreRepository>(create: (_) => FirestoreRepository()),
        Provider<StorageRepository>(create: (_) => StorageRepository()),
        ChangeNotifierProxyProvider<FirestoreRepository, DocumentService>(
          create: (context) => DocumentService(context.read<FirestoreRepository>()),
          update: (_, repo, service) => service ?? DocumentService(repo),
        ),
        Provider<VersionService>(create: (_) => VersionService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Report App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
      ),
      home: StreamBuilder<User?>(
        stream: context.read<AuthRepository>().authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          return snapshot.hasData ? const HomeScreen() : const AuthScreen();
        },
      ),
      routes: {
        '/editor': (context) => const EditorScreen(),
        // Note: We remove the direct '/preview' route and use onGenerateRoute.
      },
      onGenerateRoute: (settings) {
        // Handle the '/preview' route.
        if (settings.name == '/preview') {
          // Expect that settings.arguments is a Map<String, dynamic> with keys:
          // 'documentId', 'deltaContent', and 'imageColumn'.
          final args = settings.arguments as Map<String, dynamic>? ?? {};
          return MaterialPageRoute(
            builder: (context) => PreviewScreen(
              documentId: args['documentId'] ?? '',
              deltaContent: args['deltaContent'] ?? [{'insert': '\n'}],
              imageColumn: args['imageColumn'] ?? [],
            ),
          );
        }
        return null;
      },
    );
  }
}

