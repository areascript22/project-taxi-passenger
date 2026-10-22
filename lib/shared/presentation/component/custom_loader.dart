import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class CustomLoader extends StatelessWidget {
  final double width;
  final double height;

  const CustomLoader({
    super.key,
    this.width = 60.0,
    this.height = 60.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      clipBehavior: Clip.hardEdge,
      child: Transform.scale(
        scale: 2.1,
        child: Lottie.asset(
          'assets/animations/loading.json',
          fit: BoxFit.fill,
        ),
      ),
    );
  }
}