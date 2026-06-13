import 'dart:io';

import 'package:path/path.dart' as p;
import '../../core/config/data_namespace.dart';
import 'data/repository/brain_repository_impl.dart';
import 'domain/repository/brain_repository.dart';

String resolveBrainFolderPath() {
  final appData = Platform.environment['APPDATA'] ?? '';
  return p.join(appData, 'Codex', 'brain', kDataNamespace);
}

BrainRepository createBrainRepository() {
  return BrainRepositoryImpl(Directory(resolveBrainFolderPath()));
}
