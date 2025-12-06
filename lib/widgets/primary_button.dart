import 'package:flutter/material.dart';

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const PrimaryButton({required this.label, required this.onTap, Key? key})
    : super(key: key);
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14.0),
        child: Text(
          label,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
