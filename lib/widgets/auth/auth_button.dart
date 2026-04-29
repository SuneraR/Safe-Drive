import 'package:flutter/material.dart';

class AuthButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const AuthButton({
    super.key,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          /// ✅ USE THEME COLOR
          backgroundColor: theme.colorScheme.primary,

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onPressed,

        child: Text(
          text,
          style: TextStyle(
            fontSize: 16,

            /// ✅ AUTO TEXT COLOR (white in dark, black in light if needed)
            color: theme.colorScheme.onPrimary,
          ),
        ),
      ),
    );
  }
}