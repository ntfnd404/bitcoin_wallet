import 'dart:async';
import 'dart:developer';

import 'package:flutter/widgets.dart';

import 'app.dart';
import 'core/di/app_dependencies_builder.dart';

void main() => runZonedGuarded(
  () {
    WidgetsFlutterBinding.ensureInitialized();
    final dependencies = AppDependenciesBuilder().build();

    runApp(App(dependencies: dependencies));
  },
  (error, stack) => log(
    '$error\n$stack',
    name: 'main',
    level: 1000,
  ),
);
