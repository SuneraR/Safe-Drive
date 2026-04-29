import 'package:flutter/material.dart';

class AuthTextField extends StatefulWidget {
  final String hint;
  final IconData icon;
  final bool isPassword;
  final TextEditingController? controller;

  const AuthTextField({
    super.key,
    required this.hint,
    required this.icon,
    this.isPassword = false,
    this.controller,
  });

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextField(
      controller: widget.controller,
      obscureText: widget.isPassword ? _obscureText : false,

      /// ✅ TEXT COLOR (auto changes)
      style: TextStyle(
        color: theme.textTheme.bodyLarge!.color,
      ),

      decoration: InputDecoration(
        hintText: widget.hint,

        /// ✅ HINT COLOR
        hintStyle: TextStyle(
          color: theme.textTheme.bodyMedium!.color!.withOpacity(0.6),
        ),

        /// ✅ ICON COLOR
        prefixIcon: Icon(
          widget.icon,
          color: theme.textTheme.bodyMedium!.color,
        ),

        /// 👁 PASSWORD TOGGLE
        suffixIcon: widget.isPassword
            ? IconButton(
                icon: Icon(
                  _obscureText
                      ? Icons.visibility_off
                      : Icons.visibility,
                  color: theme.textTheme.bodyMedium!.color,
                ),
                onPressed: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
              )
            : null,

        /// ✅ BACKGROUND
        filled: true,
        fillColor: theme.cardColor,

        /// ✅ BORDER
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}