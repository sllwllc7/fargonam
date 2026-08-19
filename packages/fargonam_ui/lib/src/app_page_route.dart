import 'package:flutter/material.dart';

import 'app_motion.dart';

/// Ekran o'tishi — dc.html/5.4: 320ms, standart egri chiziq, translateX(14→0)+fade.
/// `MaterialPageRoute` o'rniga har doim shu ishlatiladi (6-bo'lim taqig'i).
class AppPageRoute<T> extends PageRouteBuilder<T> {
  AppPageRoute({required WidgetBuilder builder})
      : super(
          transitionDuration: AppMotion.screenIn,
          reverseTransitionDuration: AppMotion.screenIn,
          pageBuilder: (context, animation, secondaryAnimation) => builder(context),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(parent: animation, curve: AppMotion.standard);
            return AnimatedBuilder(
              animation: curved,
              child: child,
              builder: (context, child) => Opacity(
                opacity: curved.value,
                child: Transform.translate(
                  offset: Offset((1 - curved.value) * AppMotion.screenInOffset, 0),
                  child: child,
                ),
              ),
            );
          },
        );
}

/// Qulaylik uchun: `Navigator.push(context, AppPageRoute(builder: (_) => Screen()))`
/// o'rniga `pushAppRoute(context, (_) => Screen())`.
Future<T?> pushAppRoute<T>(BuildContext context, WidgetBuilder builder) {
  return Navigator.push<T>(context, AppPageRoute<T>(builder: builder));
}
