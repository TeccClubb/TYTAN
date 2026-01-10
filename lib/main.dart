// ignore_for_file: use_super_parameters
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tytan/Screens/home/home_screen.dart';
import 'package:tytan/Screens/splash/splash_screen.dart';
import 'package:tytan/Screens/constant/Appconstant.dart';
import 'package:tytan/Providers/VpnProvide/vpnProvide.dart';
import 'package:tytan/Providers/AuthProvide/authProvide.dart';
import 'package:tytan/Providers/LanguageProvide/languageProvide.dart';
import 'package:provider/provider.dart'
    show MultiProvider, ChangeNotifierProvider, Consumer;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.white,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // We move MultiProvider to the top level
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvide()),
        ChangeNotifierProvider(create: (_) => VpnProvide()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ],
      // Consumer listens for changes in LanguageProvider
      child: Consumer<LanguageProvider>(
        builder: (context, languageProvider, child) {
          return MaterialApp(
            title: 'Tytan VPN',
            debugShowCheckedModeBanner: false,

            locale: Locale(languageProvider.currentLanguage.code),
            builder: (context, child) {
              return Directionality(
                textDirection: languageProvider.isRtl
                    ? TextDirection.rtl
                    : TextDirection.ltr,
                child: child!,
              );
            },

            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
              scaffoldBackgroundColor: Colors.black,
              useMaterial3: true,
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
              scaffoldBackgroundColor: Colors.black,
              useMaterial3: true,
            ),
            themeMode: ThemeMode.dark,
            home: const SplashScreen(),
            routes: {'/home': (context) => const HomeScreen()},
          );
        },
      ),
    );
  }
}
