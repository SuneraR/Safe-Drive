import 'package:flutter/material.dart';

class SettingsActionButton extends StatelessWidget {
  const SettingsActionButton({
    super.key,
    required this.text,
    this.onPressed,
    this.textColor,
    this.borderColor,
  });

  final String text;
  final VoidCallback? onPressed;
  final Color? textColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final Color finalTextColor =
        textColor ?? theme.textTheme.bodyLarge!.color!;

    final Color finalBorderColor =
        borderColor ?? theme.dividerColor.withOpacity(0.2);

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton(
        onPressed: onPressed,

        style: OutlinedButton.styleFrom(
          backgroundColor: theme.cardColor,
          side: BorderSide(color: finalBorderColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),

        child: Text(
          text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: finalTextColor,
          ),
        ),
      ),
    );
  }
}