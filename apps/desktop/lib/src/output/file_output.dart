import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:scanbridge_domain/scanbridge_domain.dart';
import 'package:scanbridge_template_engine/scanbridge_template_engine.dart';

/// Appends template rows to files confined to one approved directory.
class FileOutput implements CsvLookupSource {
  FileOutput(this.baseDirectory);

  /// Approved root; paths resolving outside it are rejected (no traversal).
  String baseDirectory;

  /// Returns the absolute path or null when it escapes [baseDirectory].
  String? resolve(String path) {
    if (path.trim().isEmpty) return null;
    final base = p.normalize(p.absolute(baseDirectory));
    final full = p.normalize(p.isAbsolute(path) ? path : p.join(base, path));
    return p.isWithin(base, full) ? full : null;
  }

  /// Appends one row under an exclusive file lock; returns an error or null.
  Future<String?> append(FileAppendAction a, CsvOptions options) async {
    final path = resolve(a.path);
    if (path == null) return 'Path "${a.path}" is outside the output folder $baseDirectory.';
    try {
      final file = File(path);
      await file.parent.create(recursive: true);
      final raf = await file.open(mode: FileMode.append);
      try {
        await raf.lock(FileLock.blockingExclusive);
        final isNew = await raf.length() == 0;
        final b = StringBuffer();
        if (a.csv) {
          final enc = CsvEncoder(options);
          if (isNew && options.utf8Bom) b.write('﻿');
          if (isNew && a.header != null) b..write(enc.encodeRow(a.header!))..write(options.newline);
          b..write(enc.encodeRow(a.cells))..write(options.newline);
        } else {
          b..write(a.cells.join())..write(options.newline);
        }
        await raf.writeFrom(utf8.encode(b.toString()));
        await raf.flush();
      } finally {
        await raf.unlock();
        await raf.close();
      }
      return null;
    } on FileSystemException catch (e) {
      return 'Could not write ${p.basename(path)}: ${e.osError?.message ?? e.message}';
    }
  }

  /// Writes an export atomically (temp file + rename).
  static Future<void> writeAtomic(String path, String content) async {
    final tmp = File('$path.tmp');
    await tmp.writeAsString(content, flush: true);
    final target = File(path);
    if (await target.exists()) await target.delete();
    await tmp.rename(path);
  }

  @override
  Future<String?> lookup({required String path, required String keyColumn, required String key, required String valueColumn}) async {
    final resolved = resolve(path);
    if (resolved == null || !File(resolved).existsSync()) return null;
    final rows = decodeCsv(await File(resolved).readAsString());
    if (rows.isEmpty) return null;
    int col(String c) => int.tryParse(c) ?? rows.first.indexOf(c);
    final k = col(keyColumn);
    final v = col(valueColumn);
    if (k < 0 || v < 0) return null;
    for (final r in rows) {
      if (r.length > k && r.length > v && r[k] == key) return r[v];
    }
    return null;
  }
}
