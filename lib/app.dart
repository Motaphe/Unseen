import 'package:flutter/material.dart';
import 'package:unseen/config/theme.dart';
import 'package:unseen/config/routes.dart';

class UnseenApp extends StatelessWidget {
  const UnseenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'UNSEEN',
      debugShowCheckedModeBanner: false,

      // Theme
      theme: UnseenTheme.darkTheme,
      darkTheme: UnseenTheme.darkTheme,
      themeMode: ThemeMode.dark,

      // Router
      routerConfig: AppRouter.router,
    );
  }
}
