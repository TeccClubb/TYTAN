import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tytan/Providers/AuthProvide/authProvide.dart';
import 'package:tytan/Providers/VpnProvide/vpnProvide.dart';
import 'package:tytan/screens/home/home_screen.dart';
import 'package:tytan/screens/splash/splash_screen.dart';
// import 'package:tytan/screens/splash_screen.dart';
import 'package:tytan/screens/constant/Appconstant.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle.light.copyWith(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: const Color(0xFF1A1A1A),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvide()),
        ChangeNotifierProvider(create: (_) => VpnProvide()),
      ],
      child: MaterialApp(
        title: 'Tytan VPN',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
          scaffoldBackgroundColor: Colors.black,
          useMaterial3: true,
        ),
        home: const SplashScreen(),
        routes: {'/home': (context) => const HomeScreen()},
      ),
    );
  }
}
