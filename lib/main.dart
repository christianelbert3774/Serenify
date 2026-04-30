import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/storage/preset_repository.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Init Hive for local storage
  await Hive.initFlutter();
  await PresetRepository.init();

  runApp(const ProviderScope(child: SerenifyApp()));
}