import 'dart:io';

/// Small, dependency-free desktop integrations.
abstract final class PlatformActions {
  static Future<bool> revealFile(String filePath) async {
    try {
      final ProcessResult result;
      if (Platform.isMacOS) {
        result = await Process.run('open', <String>['-R', filePath]);
      } else if (Platform.isWindows) {
        result = await Process.run('explorer.exe', <String>[
          '/select,',
          filePath,
        ]);
      } else if (Platform.isLinux) {
        result = await Process.run('xdg-open', <String>[
          File(filePath).parent.path,
        ]);
      } else {
        return false;
      }
      return result.exitCode == 0;
    } on ProcessException {
      return false;
    }
  }

  static Future<bool> openDirectory(String directoryPath) async {
    try {
      final ProcessResult result;
      if (Platform.isMacOS) {
        result = await Process.run('open', <String>[directoryPath]);
      } else if (Platform.isWindows) {
        result = await Process.run('explorer.exe', <String>[directoryPath]);
      } else if (Platform.isLinux) {
        result = await Process.run('xdg-open', <String>[directoryPath]);
      } else {
        return false;
      }
      return result.exitCode == 0;
    } on ProcessException {
      return false;
    }
  }
}
