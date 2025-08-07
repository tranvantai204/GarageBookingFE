import 'dart:io';

void main() {
  print('🔍 Checking for old constants imports...');
  
  final libDir = Directory('lib');
  final dartFiles = libDir
      .listSync(recursive: true)
      .where((file) => file.path.endsWith('.dart'))
      .cast<File>();

  bool foundOldImports = false;
  
  for (final file in dartFiles) {
    final content = file.readAsStringSync();
    
    if (content.contains("import '../utils/constants.dart'") ||
        content.contains("import '../utils/constants.dart';")) {
      print('❌ Found old import in: ${file.path}');
      foundOldImports = true;
    }
    
    if (content.contains('ApiConstants') && 
        !content.contains("import '../constants/api_constants.dart'") &&
        !content.contains("import '../constants/api_constants.dart';") &&
        !file.path.contains('api_constants.dart')) {
      print('⚠️  Uses ApiConstants but missing import in: ${file.path}');
      foundOldImports = true;
    }
  }
  
  if (!foundOldImports) {
    print('✅ All imports are correct!');
  } else {
    print('❌ Found issues with imports. Please fix them.');
    exit(1);
  }
}
