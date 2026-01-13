import 'package:flutter/material.dart';

class TestSaveButton extends StatelessWidget {
  const TestSaveButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        debugPrint(
            '🚨🚨🚨 TEST BUTTON CLICKED! This proves button clicks work! 🚨🚨🚨',);
      },
      child: const Text('TEST SAVE'),
    );
  }
}

