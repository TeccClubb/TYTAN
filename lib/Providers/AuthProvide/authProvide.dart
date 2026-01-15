// ignore_for_file: use_build_context_synchronously, file_names, unused_local_variable
import 'dart:convert';
import 'dart:developer';
import 'dart:io' show Platform;
import 'dart:math' show Random;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart' show Provider;
import 'package:tytan/Defaults/utils.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:tytan/Screens/auth/auth_screen.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:tytan/ReusableWidgets/customSnackBar.dart';
import 'package:tytan/Providers/VpnProvide/vpnProvide.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tytan/Screens/bottomnavbar/bottomnavbar.dart';
import 'package:tytan/DataModel/guestModel.dart' show GuestUser;
import 'package:device_info_plus/device_info_plus.dart' show DeviceInfoPlugin;
import 'package:tytan/Screens/welcome/welcome.dart';

class AuthProvide with ChangeNotifier {
  var mailController = TextEditingController();
  var usernameController = TextEditingController();
  var passwordController = TextEditingController();
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  var isloading = false;
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  bool _isGoogleSigningIn = false;
  bool get isGoogleSigningIn => _isGoogleSigningIn;
  GuestUser? _guestUser;
  GuestUser? get guestUser => _guestUser;
  bool _isGuest = false;
  bool get isGuest => _isGuest;

  setGuest(bool value) {
    _isGuest = value;
    notifyListeners();
  }

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
        notifyListeners();
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', jsonEncode(data['user']));
        await prefs.setString('password', passwordController.text);
        await prefs.setString('token', data['access_token']);
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString("name", data['user']['slug']);

        var provider = Provider.of<VpnProvide>(context, listen: false);
        _isGuest = false;
        await prefs.setBool('isGuest', false);
        provider.bottomBarIndex.value = 0;

        await provider.getServersPlease(true);
        await provider.getUser();
        await provider.getPremium(context);
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
          EvaIcons.checkmarkCircle2,
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
      SharedPreferences preferences = await SharedPreferences.getInstance();
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
        _isGuest = false;
        await preferences.setBool('isGuest', false);

        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const AuthScreen()));
        log('Signup successful');
        showCustomSnackBar(
          context,
          EvaIcons.checkmarkCircle2,
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
          EvaIcons.checkmarkCircle2,
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
      _isGoogleSigningIn = true;
      notifyListeners();

      // Sign out first to ensure the account picker banner always shows
      try {
        await _googleSignIn.signOut();
      } catch (e) {
        log('Google signOut before signIn: $e');
      }

      // Initiate Google Sign-In - will now show account picker
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _isGoogleSigningIn = false;
        notifyListeners();
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
        await provider.getPremium(context);
        _isGuest = false;
        await prefs.setBool('isGuest', false);

        // Auto-select fastest free server for new free users
        if (!provider.isPremium && provider.servers.isNotEmpty) {
          await provider.selectFastestServerByHealth(freeOnly: true);
        }

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
      _isGoogleSigningIn = false;
      notifyListeners();
    }
  }

  Future<void> deleteAccount(BuildContext context, String password) async {
    try {
      isloading = true;
      notifyListeners();
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString("token");
      log("Deleting account with token: $token");
      var body = {"password": password};
      var response = await http.delete(
        Uri.parse(UUtils.deleteAccount),
        body: body,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      log("Delete account response: ${response.statusCode} - ${response.body}");
      var data = jsonDecode(response.body);

      log("Data $data");

      if (response.statusCode == 200) {
        isloading = false;
        notifyListeners();
        log("Account deleted successfully");
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        // Navigate to auth screen - successful deletion is implicit
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
          (route) => false,
        );
      } else {
        isloading = false;
        notifyListeners();
        log("Failed to delete account");
        showCustomSnackBar(
          context,
          Icons.error_outline_rounded,
          'Deletion Failed',
          'Failed to delete your account. Please try again later.',
          Colors.red,
        );
      }
    } catch (error) {
      isloading = false;
      notifyListeners();
      log("Some error occured $error");
      showCustomSnackBar(
        context,
        Icons.error_outline_rounded,
        'Error',
        'An error occurred while deleting your account',
        Colors.red,
      );
    }
  }

  String generateRandomEmail() {
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomNumber = random.nextInt(100000); // up to 5 digits
    return "guest${timestamp}_$randomNumber@example.com";
  }

  String generateRandomPassword({int length = 12}) {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGIJKLMNOPQRSTUVWXYZ0123456789!@';
    final random = Random();
    return List.generate(
      length,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
  }

  Future<void> guestlogin(BuildContext context) async {
    try {
      log("Guest login started");
      _isLoading = true;
      notifyListeners();
      var headers = {
        'Accept': 'application/json',
        'x-app-key': '110da8dc-0381-420e-aed9-f87098038bc4',
      };

      // Generate random email and password
      String email = generateRandomEmail();
      String password = generateRandomPassword();

      var body = {"email": email};

      var response = await http.post(
        Uri.parse(UUtils.guestLogin),
        body: body,
        headers: headers,
      );

      log(
        "Guest login response is ${response.statusCode} that ${response.body}",
      );
      var data = jsonDecode(response.body);

      log(
        "Guest login response is ${response.statusCode} that ${response.body}",
      );
      if (response.statusCode == 201) {
        _isGuest = true;
        log(
          "Guest login successful with email: $email and password: $password",
        );

        // Optionally save for reuse
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString("email", email);
        prefs.setString("password", password);
        prefs.setString("name", email);
        prefs.setBool("isGuest", true);

        prefs.setString("app_account_token", data['user']['app_account_token']);
        var vpnProvider = Provider.of<VpnProvide>(context, listen: false);
        await vpnProvider.getServersPlease(true);
        await vpnProvider.getPremium(context);
        // Auto-select fastest free server for guest users
        if (vpnProvider.servers.isNotEmpty) {
          await vpnProvider.selectFastestServerByHealth(freeOnly: true);
        }
        _isLoading = false;
        notifyListeners();

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const BottomNavBar()),
        );
        await getGuestUser();
      } else {
        log("Guest login failed");
        _isLoading = false;
        _isGuest = false;
        notifyListeners();
      }
    } catch (error) {
      log(error.toString());
      _isLoading = false;
      _isGuest = false;
      notifyListeners();
    }
  }

  getGuestUser() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? appAccountToken = prefs.getString("app_account_token");
      log("Account token $appAccountToken ");
      log("${UUtils.getGuestLogin}/$appAccountToken");

      var response = await http.get(
        Uri.parse("${UUtils.getGuestLogin}/$appAccountToken"),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'x-app-key': '110da8dc-0381-420e-aed9-f87098038bc4',
        },
      );

      log(
        "Get guest user status ${response.statusCode} response: ${response.body}",
      );
      var data = jsonDecode(response.body);
      log("Guest user data: $data");
      if (response.statusCode == 200) {
        log("Guest user fetched successfully");
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString("email", data['user']['email']);
        _guestUser = GuestUser.fromJson(data['user']);
        notifyListeners();
        // prefs.setString("name", data['user']['email']);
        // prefs.setString("app_account_token", data['user']['app_account_token']);
      } else {
        log("Fetching guest user failed");
      }
    } catch (error) {
      log(error.toString());
      // showCustomSnackBar(
      //   context,
      //   Icons.error_outline,
      //   'Error',
      //   'Failed to get guest user',
      //   Colors.red,
      // );
    }
  }

  Future<void> createLink(String accesstoken, BuildContext context) async {
    try {
      log("Creating link with access token: $accesstoken");
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String email = prefs.getString("email") ?? '';
      String token = prefs.getString("app_account_token") ?? '';
      log("Email: $email");
      log("App Account Token: $token");
      log("AccessToken: $accesstoken");
      var headers = {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'x-app-key': '110da8dc-0381-420e-aed9-f87098038bc4',
        'Authorization': 'Bearer $accesstoken',
      };
      var response = await http.post(
        Uri.parse(UUtils.linkGuestLogin),
        headers: headers,
        body: jsonEncode({
          "guest_email": email,
          "guest_app_account_token": token,
        }),
      );

      log(
        "Response from createLink: ${response.statusCode} - ${response.body}",
      );
      var data = jsonDecode(response.body);
      log("Data from createLink: $data");
      if (response.statusCode == 200) {
        log("Guest account linked successfully");
        showCustomSnackBar(
          context,
          EvaIcons.checkmarkCircle2Outline,
          'Success',
          'Guest account linked successfully',
          Colors.green,
        );
      } else {
        String message = data['errors'] != null
            ? data['errors'].toString().replaceAll('[', '').replaceAll(']', '')
            : data['message'];
        log("Linking guest account failed: $message");
      }
    } catch (error) {
      log("Error in createLink: $error");
    }
  }

  // Get current user token
  Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString("app_account_token");
    } catch (e) {
      log('Error getting token: $e');
      return null;
    }
  }
}
