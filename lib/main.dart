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
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: true,
          );
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Crayon',
            theme: baseTheme.copyWith(
              textTheme: GoogleFonts.fredokaTextTheme(baseTheme.textTheme),
            ),
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
