import 'package:flutter/material.dart';

class CustomButton extends StatefulWidget {
  final String textButton;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? fontSize;
  final double? verticalPadding;
  final double? borderRadius;

  const CustomButton({
    super.key,
    required this.textButton,
    required this.onTap,
    this.backgroundColor,
    this.foregroundColor,
    this.fontSize,
    this.verticalPadding,
    this.borderRadius,
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: widget.onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: widget.backgroundColor ?? Colors.pink,
          foregroundColor: widget.foregroundColor ?? Colors.white,
          padding: EdgeInsets.symmetric(vertical: widget.verticalPadding ?? 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(widget.borderRadius ?? 16),
          ),
          elevation: 2,
        ),
        child: Text(
          widget.textButton,
          style: TextStyle(
            fontSize: widget.fontSize ?? 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}
