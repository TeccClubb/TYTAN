// ignore_for_file: file_names
import 'package:flutter/material.dart';

void showCustomSnackBar(
  BuildContext context,
  IconData icon,
  String title,
  String subtitle,
  Color color,
) {
  final snackBar = SnackBar(
    backgroundColor: color,
    duration: const Duration(milliseconds: 2000),
    behavior: SnackBarBehavior.floating,
    margin: const EdgeInsets.all(20),
    content: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(snackBar);
}
