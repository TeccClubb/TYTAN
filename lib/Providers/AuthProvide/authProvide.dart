// ignore_for_file: use_build_context_synchronously, file_names, unused_local_variable
import 'dart:convert';
import 'dart:developer';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:tytan/Defaults/utils.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:tytan/screens/auth/auth_screen.dart';
import 'package:provider/provider.dart' show Provider;
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:tytan/ReusableWidgets/customSnackBar.dart';
import 'package:tytan/Providers/VpnProvide/vpnProvide.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tytan/screens/bottomnavbar/bottomnavbar.dart';
import 'package:device_info_plus/device_info_plus.dart' show DeviceInfoPlugin;

class AuthProvide with ChangeNotifier {
  var mailController = TextEditingController();
  var usernameController = TextEditingController();
  var passwordController = TextEditingController();
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  var isloading = false;

  Future<void> login(BuildContext context) async {
    try {
      isloading = true;
      notifyListeners();
      var headers = {
        // 'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      var response = await http.post(
        Uri.parse(UUtils.login),
        headers: headers,
        body: {
          'email': mailController.text,
          'password': passwordController.text,
        },
      );

      var data = jsonDecode(response.body);
      if (data['status'] == true) {
        isloading = true;
        notifyListeners();
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', jsonEncode(data['user']));
        await prefs.setString('password', passwordController.text);
        await prefs.setString('token', data['access_token']);
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString("name", data['user']['slug']);

        var provider = Provider.of<VpnProvide>(context, listen: false);
        await provider.getServersPlease(true);
        await provider.getUser();
        await provider.getPremium();
        mailController.clear();
        passwordController.clear();

        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const BottomNavBar()));
        log('Login successful');
        isloading = false;
        notifyListeners();
        showCustomSnackBar(
          context,
          EvaIcons.chevronRight,
          'Login successful',
          'success',
          Colors.green,
        );
      } else {
        isloading = false;
        notifyListeners();
        showCustomSnackBar(
          context,
          EvaIcons.alertTriangle,
          'Error',
          data['message'],
          Colors.red,
        );
        log('Error: ${data['message']}');
      }
    } catch (error) {
      isloading = false;
      notifyListeners();
      log(error.toString());
    }
  }

  //make me a signup function
  Future<void> signup(BuildContext context) async {
    try {
      isloading = true;
      notifyListeners();
      var headers = {'Accept': 'application/json'};
      var response = await http.post(
        Uri.parse(UUtils.register),
        headers: headers,
        body: {
          'name': usernameController.text,
          'email': mailController.text,
          'password': passwordController.text,
        },
      );
      log("Response ${response.body}");

      var data = jsonDecode(response.body);
      log("Data $data");
      if (data['status'] == true) {
        isloading = false;
        notifyListeners();

        mailController.clear();
        passwordController.clear();
        usernameController.clear();

        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const AuthScreen()));
        log('Signup successful');
        showCustomSnackBar(
          context,
          EvaIcons.chevronRight,
          'Signup successful',
          'success',
          Colors.green,
        );
      } else {
        isloading = false;
        notifyListeners();
        log('Error: ${data['message']}');
        showCustomSnackBar(
          context,
          EvaIcons.alertTriangle,
          'Error',
          data['errors'] != null
              ? data['errors']
                    .toString()
                    .replaceAll('[', '')
                    .replaceAll(']', '')
              : data['message']
                    .toString()
                    .replaceAll('[', '')
                    .replaceAll(']', ''),
          Colors.red,
        );
      }
    } catch (error) {
      isloading = false;
      log(error.toString());
    }
  }

  Future<void> forgotPassword(BuildContext context) async {
    //implement forgot password functionality
    try {
      isloading = true;
      notifyListeners();
      log('Sending password reset request for email: ${mailController.text}');
      var headers = {'Accept': 'application/json'};
      var response = await http.post(
        Uri.parse(UUtils.forgotPassword),
        headers: headers,
        body: {'email': mailController.text},
      );
      log("Response ${response.body}");
      var data = jsonDecode(response.body);
      log("Data $data");
      if (data['status'] == true) {
        isloading = false;
        notifyListeners();
        mailController.clear();
        log('Password reset link sent to your email');
        showCustomSnackBar(
          context,
          EvaIcons.chevronRight,
          'Success',
          'Password reset link sent to your email',
          Colors.green,
        );
      } else {
        isloading = false;
        notifyListeners();
        showCustomSnackBar(
          context,
          EvaIcons.alertTriangle,
          'Error',
          data['message'],
          Colors.red,
        );
        log('Error: ${data['message']}');
      }
    } catch (error) {
      isloading = false;
      notifyListeners();
      showCustomSnackBar(
        context,
        EvaIcons.alertTriangle,
        'Error',
        error.toString(),
        Colors.red,
      );
      log(error.toString());
    }
  }

  Future<String> getDeviceId() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id;
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor ?? 'Unknown-iOS-ID';
    } else if (Platform.isWindows) {
      final windowsInfo = await deviceInfo.windowsInfo;
      return windowsInfo.deviceId;
    } else if (Platform.isMacOS) {
      final macInfo = await deviceInfo.macOsInfo;
      return macInfo.systemGUID ?? 'Unknown-Mac-ID';
    } else if (Platform.isLinux) {
      final linuxInfo = await deviceInfo.linuxInfo;
      return linuxInfo.machineId ?? 'Unknown-Linux-ID';
    } else {
      return 'Unknown Platform';
    }
  }

  Future<String> getDeviceName() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return '${androidInfo.manufacturer} ${androidInfo.model}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return iosInfo.name;
      } else if (Platform.isWindows) {
        final windowsInfo = await deviceInfo.windowsInfo;
        return windowsInfo.computerName;
      } else if (Platform.isMacOS) {
        final macInfo = await deviceInfo.macOsInfo;
        return macInfo.computerName;
      } else if (Platform.isLinux) {
        final linuxInfo = await deviceInfo.linuxInfo;
        return linuxInfo.prettyName;
      } else {
        return 'Unknown Device';
      }
    } catch (e) {
      log('Error getting device name: $e');
      return 'Unknown Device';
    }
  }

  Future<String> getDeviceType() async {
    try {
      if (Platform.isAndroid) {
        return 'Android';
      } else if (Platform.isIOS) {
        return 'iOS';
      } else if (Platform.isWindows) {
        return 'Windows';
      } else if (Platform.isMacOS) {
        return 'macOS';
      } else if (Platform.isLinux) {
        return 'Linux';
      } else {
        return 'Unknown';
      }
    } catch (e) {
      log('Error getting device type: $e');
      return 'Unknown';
    }
  }

  Future<String> getIpAddress() async {
    try {
      // Try to get IP from ip-api.com
      final response = await http
          .get(Uri.parse('http://ip-api.com/json/'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final ip = data['query'];
        if (ip != null && ip.toString().isNotEmpty) {
          log('IP Address from API: $ip');
          return ip.toString();
        }
      }
    } catch (e) {
      log('Error getting IP from API: $e');
    }

    // Fallback to static IP if API fails
    log('Using fallback static IP');
    return '0.0.0.0';
  }

  Future<void> googleSignIn(BuildContext context) async {
    try {
      isloading = true;
      // Initiate Google Sign-In
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        isloading = false;
        return; // User canceled the sign-in
      }

      final GoogleSignInAuthentication token = await googleUser.authentication;
      final String googleToken = token.accessToken!;

      // Gather all device information
      var deviceId = await getDeviceId();
      var deviceName = await getDeviceName();
      var deviceType = await getDeviceType();
      var ipAddress = await getIpAddress();

      log('Device id: $deviceId');
      log('Device name: $deviceName');
      log('Device type: $deviceType');
      log('IP address: $ipAddress');

      var headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      var response = await http.post(
        Uri.parse(UUtils.googlelogin),
        headers: headers,
        body: jsonEncode({
          "token": googleToken,
          "device_id": deviceId,
          "device_name": deviceName,
          "platform": Platform.operatingSystem,
          "device_type": deviceType,
          "ip_address": ipAddress,
        }),
      );

      var body = response.body;
      log("Body $body");
      var data = jsonDecode(body);
      log("Data $data");

      if (data['status'] == true) {
        isloading = true;
        notifyListeners();
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', jsonEncode(data['user']));
        await prefs.setString('password', passwordController.text);
        await prefs.setString('token', data['access_token']);
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString("name", data['user']['slug']);

        var provider = Provider.of<VpnProvide>(context, listen: false);
        await provider.getServersPlease(true);
        await provider.getUser();
        await provider.getPremium();

        showCustomSnackBar(
          context,
          Icons.verified_user_rounded,
          'Welcome!',
          'Google Sign-In successful',
          Colors.green,
        );

        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const BottomNavBar()));
        log('Google Sign-In successful: ');

        // Example function to register VPS servers
      } else {
        _googleSignIn.signOut();
        String message = data['errors'] != null
            ? data['errors'].toString().replaceAll('[', '').replaceAll(']', '')
            : data['message']
                  .toString()
                  .replaceAll('[', '')
                  .replaceAll(']', '');
        showCustomSnackBar(
          context,
          Icons.error_outline_rounded,
          'Sign-In Failed',
          data['message'],
          Colors.red,
        );
      }
    } catch (e) {
      log('Error in Google Sign-In: $e');
      showCustomSnackBar(
        context,
        Icons.error_outline_rounded,
        'Google Sign-In Failed',
        e.toString(),
        Colors.red,
      );
    } finally {
      isloading = false;
    }
  }
}
