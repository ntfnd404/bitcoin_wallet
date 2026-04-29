import 'dart:async';
import 'dart:developer';

import 'package:bitcoin_wallet/app.dart';
import 'package:bitcoin_wallet/core/config/config.dart';
import 'package:bitcoin_wallet/core/di/app_dependencies_builder.dart';
import 'package:flutter/widgets.dart';

void main() => runZonedGuarded(
  () {
    WidgetsFlutterBinding.ensureInitialized();
    final environment = loadEnvironment();

    AppDependenciesBuilder.create(
      environment: environment,
      builder: (dependencies) => runApp(
        App(dependencies: dependencies),
      ),
      onError: (error, stack) => log(
        '$error\n$stack',
        name: 'main',
        level: 1000,
      ),
    );
  },
  (error, stack) => log(
    '$error\n$stack',
    name: 'main',
    level: 1000,
  ),
);
