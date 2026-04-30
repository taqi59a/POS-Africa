import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';

class DbBackupUtils {
  static Future<String?> createBackup() async {
    try {
      final dbFolder = await getApplicationDocumentsDirectory();
      final dbFile = File(p.join(dbFolder.path, 'CongoPOS', 'db.sqlite'));

      if (!await dbFile.exists()) {
        throw Exception('Database file not found at ${dbFile.path}');
      }

      // Let user pick destination
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
      if (selectedDirectory == null) return null;

      final now = DateTime.now();
      final backupFileName = 'CongoPOS_Backup_${now.year}${now.month}${now.day}_${now.hour}${now.minute}.sqlite';
      final backupFile = File(p.join(selectedDirectory, backupFileName));

      await dbFile.copy(backupFile.path);
      return backupFile.path;
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> restoreBackup() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any, // .sqlite might not be in the default list
      );

      if (result == null || result.files.single.path == null) return;

      final backupFile = File(result.files.single.path!);
      final dbFolder = await getApplicationDocumentsDirectory();
      final dbFile = File(p.join(dbFolder.path, 'CongoPOS', 'db.sqlite'));

      // Ensure directory exists
      await dbFile.parent.create(recursive: true);
      
      // Overwrite current DB
      await backupFile.copy(dbFile.path);
    } catch (e) {
      rethrow;
    }
  }
}
