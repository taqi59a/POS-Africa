import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../data/database/app_database.dart';
import '../di/injection.dart' as di;

class DbBackupUtils {
  static const String _dbFolderName = 'CongoPOS';
  static const String _dbFileName = 'db.sqlite';
  static const String _pendingRestoreFileName = 'pending_restore.sqlite';

  static Future<File> _getDbFile() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    return File(p.join(dbFolder.path, _dbFolderName, _dbFileName));
  }

  static Future<File> _getPendingRestoreFile() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    return File(p.join(dbFolder.path, _dbFolderName, _pendingRestoreFileName));
  }

  static Future<void> _checkpointWalIfAvailable() async {
    if (di.sl.isRegistered<AppDatabase>()) {
      await di.sl<AppDatabase>().customStatement('PRAGMA wal_checkpoint(FULL);');
    }
  }

  static String _timestamp(DateTime now) {
    final mm = now.month.toString().padLeft(2, '0');
    final dd = now.day.toString().padLeft(2, '0');
    final hh = now.hour.toString().padLeft(2, '0');
    final min = now.minute.toString().padLeft(2, '0');
    final ss = now.second.toString().padLeft(2, '0');
    return '${now.year}$mm$dd_$hh$min$ss';
  }

  static Future<String?> createBackup() async {
    final dbFile = await _getDbFile();

    if (!await dbFile.exists()) {
      throw Exception('Database file not found at ${dbFile.path}');
    }

    await _checkpointWalIfAvailable();

    final selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory == null) return null;

    final now = DateTime.now();
    final backupFileName = 'CongoPOS_Backup_${_timestamp(now)}.sqlite';
    final backupFile = File(p.join(selectedDirectory, backupFileName));

    await dbFile.copy(backupFile.path);
    return backupFile.path;
  }

  static Future<String?> stageRestoreBackup() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['sqlite', 'db', 'backup'],
      allowMultiple: false,
    );

    if (result == null || result.files.single.path == null) {
      return null;
    }

    final backupFile = File(result.files.single.path!);
    if (!await backupFile.exists()) {
      throw Exception('Selected backup file does not exist.');
    }

    final stat = await backupFile.stat();
    if (stat.size == 0) {
      throw Exception('Selected backup file is empty.');
    }

    final stagedRestoreFile = await _getPendingRestoreFile();
    await stagedRestoreFile.parent.create(recursive: true);

    if (await stagedRestoreFile.exists()) {
      await stagedRestoreFile.delete();
    }

    await backupFile.copy(stagedRestoreFile.path);
    return stagedRestoreFile.path;
  }

  static Future<bool> applyPendingRestoreIfAny() async {
    final stagedRestoreFile = await _getPendingRestoreFile();
    if (!await stagedRestoreFile.exists()) {
      return false;
    }

    final dbFile = await _getDbFile();
    await dbFile.parent.create(recursive: true);

    final walFile = File('${dbFile.path}-wal');
    final shmFile = File('${dbFile.path}-shm');
    if (await walFile.exists()) await walFile.delete();
    if (await shmFile.exists()) await shmFile.delete();

    if (await dbFile.exists()) {
      await dbFile.delete();
    }

    await stagedRestoreFile.copy(dbFile.path);
    await stagedRestoreFile.delete();

    return true;
  }
}
