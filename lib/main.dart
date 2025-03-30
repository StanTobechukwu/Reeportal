import 'dart:async';
import 'dart:ui' show PlatformDispatcher;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

// Models
import 'models/document/document.dart';

// Repositories
import 'repositories/auth_repository.dart';
import 'repositories/firestore_repository.dart';
import 'repositories/storage_repository.dart';

// Services
import 'services/audit_service.dart';
import 'services/document_service.dart';
import 'services/report_maker.dart';

// Screens
import 'ui/screens/auth_screen.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/editor_screen.dart';

void main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Crashlytics setup
    FlutterError.onError = (errorDetails) {
      FirebaseCrashlytics.instance.recordFlutterError(errorDetails);
    };
    
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack);
      return true;
    };

    await FirebaseCrashlytics.instance
        .setCrashlyticsCollectionEnabled(!kDebugMode);

    runApp(
      MultiProvider(
        providers: [
          // Repositories (self-initializing)
          Provider(create: (_) => AuthRepository()),
          Provider(create: (_) => FirestoreRepository()),
          Provider(create: (_) => StorageRepository()),

          // Business Logic Services
          ChangeNotifierProvider(create: (_) => AuditService()),
          Provider(create: (_) => ReportMaker()),
          ChangeNotifierProvider(create: (_) => DocumentService()),
        ],
        child: const SmartReporterApp(),
      ),
    );
  }, (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack);
  });
}

class SmartReporterApp extends StatelessWidget {
  const SmartReporterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Reporter Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: Consumer<AuthRepository>(
        builder: (context, authRepo, _) {
          return StreamBuilder<User?>(
            stream: authRepo.authStateChanges,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              return snapshot.hasData ? const HomeScreen() : const AuthScreen();
            },
          );
        },
      ),
      routes: {
        '/home': (_) => const HomeScreen(),
        '/editor': (_) => const DocumentEditorScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/editor/:docId') {
          final docId = settings.arguments as String? ?? '';
          return MaterialPageRoute(
            builder: (_) => DocumentEditorScreen(documentId: docId),
          );
        }
        return null;
      },
    );
  }
}