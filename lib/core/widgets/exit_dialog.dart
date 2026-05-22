import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<bool> showExitConfirmationDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      final colorScheme = Theme.of(ctx).colorScheme;
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.power_settings_new, color: colorScheme.error),
            const SizedBox(width: 10),
            const Text('Quit Application'),
          ],
        ),
        content: const Text(
          'Are you sure you want to close the Islamic Lifestyle Super App?',
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Exit'),
          ),
        ],
      );
    },
  );

  if (result == true) {
    try {
      if (Platform.isAndroid) {
        await SystemNavigator.pop();
      } else {
        exit(0);
      }
    } catch (_) {
      exit(0);
    }
  }
  return result ?? false;
}
