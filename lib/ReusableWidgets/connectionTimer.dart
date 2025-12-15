// ignore_for_file: file_names
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tytan/Providers/VpnProvide/vpnProvide.dart';

class ConnectionTimer extends StatelessWidget {
  const ConnectionTimer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<VpnProvide>(
      builder: (context, provider, child) {
        return Text(
          provider.getFormattedDuration(),
          style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold,),
        );
      },
    );
  }
}
