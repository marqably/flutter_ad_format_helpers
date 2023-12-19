import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class DemoBanner extends StatelessWidget {
  const DemoBanner({
    super.key,
    this.width = 300,
    this.height = 600,
    this.color = Colors.grey,
    this.borderColor = Colors.black,
    required this.loadBanner,
    this.text,
  });

  final double width;
  final double height;
  final Color color;
  final Color borderColor;
  final String? text;
  final VoidCallback loadBanner;

  @override
  Widget build(BuildContext context) {
    SchedulerBinding.instance.addPostFrameCallback(postFrameCallback);

    return Container(
      constraints: BoxConstraints(
        minHeight: height,
        minWidth: width,
        maxHeight: height,
        maxWidth: width,
      ),
      decoration: BoxDecoration(
        color: color,
        border: Border.all(
          color: borderColor.withOpacity(0.8),
          width: 4,
        ),
      ),
      width: width,
      height: height,
      child: Center(
          child: Text(
        text ?? 'Demo Banner',
        style: const TextStyle(fontSize: 30),
      )),
      // child: Center(
      //   child: Image.asset('assets/demo-banner.jpg', width: width, height: height, fit: BoxFit.none,) ,
      // ),
    );
  }

  void postFrameCallback(_) {
    Timer(const Duration(milliseconds: 100), () {
      loadBanner();
    });
  }
}
