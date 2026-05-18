import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'providers/auth_provider.dart';
import 'providers/diary_provider.dart';

import 'screens/dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Pre-fetch and cache Google Fonts to prevent unstyled text flash (FOUT) on Web
  GoogleFonts.laBelleAurore();
  GoogleFonts.cormorantGaramond();
  GoogleFonts.dancingScript();
  await GoogleFonts.pendingFonts();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DiaryProvider()..loadDiary()),
      ],
      child: const MyDiaryApp(),
    ),
  );
}

class MyDiaryApp extends StatelessWidget {
  const MyDiaryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        FlutterQuillLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en')],
      theme: ThemeData(
        fontFamilyFallback: const ['Noto Color Emoji', 'Segoe UI Emoji', 'Apple Color Emoji', 'Roboto'],
      ),
      home: const Dashboard(),
    );
  }
}

