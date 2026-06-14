import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/main_display_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(const BlinkBoardApp());
}

class BlinkBoardApp extends StatelessWidget {
  const BlinkBoardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Blink Board',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00E5FF),
          secondary: Color(0xFFFFD700),
          surface: Color(0xFF0D0D2B),
        ),
        scaffoldBackgroundColor: const Color(0xFF050516),
        useMaterial3: true,
      ),
      builder: kIsWeb
          ? (context, child) => Scaffold(
                backgroundColor: Colors.black,
                body: Center(
                  child: AspectRatio(
                    aspectRatio: 9 / 16,
                    child: child!,
                  ),
                ),
              )
          : null,
      home: const MainDisplayScreen(),
    );
  }
}
