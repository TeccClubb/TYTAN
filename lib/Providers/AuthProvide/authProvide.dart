// ignore_for_file: use_build_context_synchronously, file_names, unused_local_variable
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart' show Provider;
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tytan/Defaults/utils.dart';
import 'package:tytan/Providers/VpnProvide/vpnProvide.dart';
import 'package:tytan/ReusableWidgets/customSnackBar.dart';
import 'package:tytan/screens/auth/auth_screen.dart';
import 'package:tytan/screens/bottomnavbar/bottomnavbar.dart';

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
          data['message'],
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
      var headers = {'Accept': 'application/json'};
      var response = await http.post(
        Uri.parse(UUtils.forgotPassword),
        headers: headers,
        body: {'email': mailController.text},
      );
      var data = jsonDecode(response.body);
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

      var headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      var request = await http.post(
        Uri.parse(UUtils.googlelogin),
        headers: headers,
        body: jsonEncode({"token": googleToken}),
      );

      var body = request.body;
      var data = jsonDecode(body);

      if (data['status'] == true) {
        String message = data['message']
            .toString()
            .replaceAll('[', '')
            .replaceAll(']', '');
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('logged', true);
        await prefs.setString('name', data['user']['slug']);
        await prefs.setString('email', data['user']['email']);
        await prefs.setString(
          'password',
          'google_password', // Handle case where password might not be available
        );
        await prefs.setString('token', data['access_token']);

        var provider = Provider.of<VpnProvide>(context, listen: false);
        await provider.getServersPlease(true);
        await provider.getUser();
        await provider.getPremium();

        showCustomSnackBar(
          context,
          EvaIcons.chevronRight,
          'Success',
          'Google Sign-In successful',
          Colors.green,
        );

        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const BottomNavBar()));
        log('Google Sign-In successful: $message');

        // Example function to register VPS servers
      } else {
        String message = data['errors'] != null
            ? data['errors'].toString().replaceAll('[', '').replaceAll(']', '')
            : data['message']
                  .toString()
                  .replaceAll('[', '')
                  .replaceAll(']', '');
        showCustomSnackBar(
          context,
          EvaIcons.alertTriangle,
          'Error',
          data['message'],
          Colors.red,
        );
      }
    } catch (e) {
      log('Error in Google Sign-In: $e');
      showCustomSnackBar(
        context,
        EvaIcons.alertCircle,
        'Google Signin Failed',
        e.toString(),
        Colors.red,
      );
    } finally {
      isloading = false;
    }
  }
}
