// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

// Screens
import 'ui/screens/home_screen.dart';
import 'ui/screens/editor_screen.dart';
import 'ui/screens/signature_screen.dart';
import 'ui/screens/image_blank_page_screen.dart';
import 'ui/screens/preview_screen.dart';

// Models
import 'models/document/page_data.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reporter App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // Named routes for core screens
      initialRoute: '/',
      routes: {
        '/': (_) => const HomeScreen(),
        '/editor': (_) => const ReportEditorScreen(),
        '/signature': (_) => const SignatureScreen(),
        '/imageBlank': (_) => const ImageBlankPageScreen(),
      },
      // onGenerateRoute to handle PreviewScreen (requires List<PageData> arg)
      onGenerateRoute: (settings) {
        if (settings.name == '/preview') {
          final pages = settings.arguments as List<PageData>;
          return MaterialPageRoute(
            builder: (_) => PreviewScreen(pages: pages),
          );
        }
        return null;
      },
    );
  }
}
