import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'providers/auth_provider.dart';
import 'providers/project_provider.dart';
import 'providers/message_provider.dart';

import 'screens/welcome_page.dart';
import 'screens/home_page.dart';
import 'screens/login_page.dart';
import 'screens/register_chooser_page.dart';
import 'screens/register_faculty_page.dart';
import 'screens/create_project_page.dart';
import 'screens/messaging_page.dart';
import 'screens/new_conversation_page.dart';
import 'screens/notifications_page.dart';

import 'services/api_client.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Your project uses a singleton ApiClient with init()
  ApiClient().init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProjectProvider()),
        ChangeNotifierProvider(create: (_) => MessageProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // ✅ Central place for app theme (English UI)
  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF0EA5E9),
        primary: const Color(0xFF0EA5E9),
      ),
      textTheme: GoogleFonts.interTextTheme(),
      scaffoldBackgroundColor: const Color(0xFFF3F4F6),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF111827),
        elevation: 0,
      ),
      cardTheme: const CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          side: BorderSide(color: Color(0xFFE5E7EB)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0EA5E9),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Medipol Project Hub',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),

      // ✅ Default entry
      initialRoute: '/welcome',

      // ✅ Routes (so notifications/messages/create project never “break”)
      routes: {
        '/welcome': (_) => const WelcomePage(),
        '/home': (_) => const HomePage(),
        '/login': (_) => const LoginPage(),
        '/register': (_) => const RegisterChooserPage(),
        '/register-faculty': (_) => const RegisterFacultyPage(),

        '/create-project': (_) => const CreateProjectPage(),

        '/messages': (_) => const MessagingPage(),
        '/new-conversation': (_) => const NewConversationPage(),

        '/notifications': (_) => const NotificationsPage(),
      },

      // ✅ If any page tries to navigate to an undefined route, show a friendly screen instead of crashing.
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Page not found')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Route not found: ${settings.name}\n\nPlease check navigation.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
