import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:journaling_app_rewrite/hive/hive_registrar.g.dart';
import 'package:journaling_app_rewrite/routing/app_router.dart';

void main() async {
  await Hive.initFlutter();

  Hive
    ..init('.')
    ..registerAdapters();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Journaling App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      routerConfig: appRouter,
    );
  }
}
