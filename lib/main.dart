import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'src/services/audio_service.dart';
import 'src/services/firebase_service.dart';
import 'src/services/storage_service.dart';
import 'src/state/app_state.dart';
import 'src/ui/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CrayonApp());
}

class CrayonApp extends StatelessWidget {
  const CrayonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AppState(
            storageService: StorageService(),
            audioService: AudioService(),
            firebaseService: FirebaseService(),
          ),
        ),
      ],
      child: Builder(
        builder: (context) {
          final baseTheme = ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFFF7BAC),
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: Colors.transparent,
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent,
              elevation: 0,
              foregroundColor: Colors.white,
              centerTitle: true,
            ),
            textTheme: GoogleFonts.fredokaTextTheme(),
          );
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Crayon',
            theme: baseTheme.copyWith(
              textTheme: GoogleFonts.fredokaTextTheme(baseTheme.textTheme).apply(
                bodyColor: Colors.white,
                displayColor: Colors.white,
              ),
            ),
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
