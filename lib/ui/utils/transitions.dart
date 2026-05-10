import 'package:flutter/material.dart';

class SmoothRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  SmoothRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 0.05);
            const end = Offset.zero;
            const curve = Curves.easeOutQuart;

            var slideTween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            var fadeTween = Tween<double>(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeOut));
            var scaleTween = Tween<double>(begin: 0.98, end: 1.0).chain(CurveTween(curve: curve));

            return FadeTransition(
              opacity: animation.drive(fadeTween),
              child: SlideTransition(
                position: animation.drive(slideTween),
                child: ScaleTransition(
                  scale: animation.drive(scaleTween),
                  child: child,
                ),
              ),
            );
          },
        );
}
