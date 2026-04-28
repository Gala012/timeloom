import 'dart:io';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'db_timeloom_entity.dart';
class DbTimeloom extends GetxService {
  static DbTimeloom get to => Get.find();
  late Database _db;
  @override
  Future<void> onInit() async {
    super.onInit();
    await _initDatabase();
  }
  Future<DbTimeloom> init() async {
    await _initDatabase();
    return this;
  }
  Future<void> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    _db = await openDatabase(
      join(dbPath, 'timeloom.db'),
      version: 1,
      onCreate: _onCreate,
    );
  }
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        scheduled_at TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE sticker_records (
        record_id INTEGER PRIMARY KEY,
        text TEXT NOT NULL,
        images TEXT NOT NULL DEFAULT '[]',
        FOREIGN KEY (record_id) REFERENCES records (id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE rich_note_records (
        record_id INTEGER PRIMARY KEY,
        content TEXT NOT NULL,
        FOREIGN KEY (record_id) REFERENCES records (id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE checklist_records (
        record_id INTEGER PRIMARY KEY,
        title TEXT NOT NULL,
        FOREIGN KEY (record_id) REFERENCES records (id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE checklist_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        record_id INTEGER NOT NULL,
        text TEXT NOT NULL,
        is_completed INTEGER NOT NULL DEFAULT 0,
        sort_order INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (record_id) REFERENCES records (id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE mood_records (
        record_id INTEGER PRIMARY KEY,
        sticker_type TEXT NOT NULL,
        sticker_key TEXT NOT NULL,
        text TEXT,
        FOREIGN KEY (record_id) REFERENCES records (id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE media_files (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        record_id INTEGER NOT NULL,
        local_path TEXT NOT NULL,
        media_type TEXT NOT NULL,
        thumbnail TEXT,
        sort_order INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (record_id) REFERENCES records (id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE link_records (
        record_id INTEGER PRIMARY KEY,
        url TEXT NOT NULL,
        display_text TEXT,
        favicon TEXT,
        FOREIGN KEY (record_id) REFERENCES records (id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE attachment_records (
        record_id INTEGER PRIMARY KEY,
        file_name TEXT NOT NULL,
        file_size INTEGER NOT NULL,
        file_type TEXT NOT NULL,
        local_path TEXT NOT NULL,
        FOREIGN KEY (record_id) REFERENCES records (id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE tags (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE
      )
    ''');
    await db.execute('''
      CREATE TABLE record_tags (
        record_id INTEGER NOT NULL,
        tag_id INTEGER NOT NULL,
        PRIMARY KEY (record_id, tag_id),
        FOREIGN KEY (record_id) REFERENCES records (id) ON DELETE CASCADE,
        FOREIGN KEY (tag_id) REFERENCES tags (id) ON DELETE CASCADE
      )
    ''');
  }
  Future<List<RecordEntity>> getRecords({
    RecordType? type,
    String? tagId,
    String? date,
  }) async {
    try {
      if (tagId != null) {
        final results = await _db.rawQuery('''
          SELECT r.* FROM records r
          INNER JOIN record_tags rt ON r.id = rt.record_id
          WHERE rt.tag_id = ?
          ${type != null ? "AND r.type = '${type.value}'" : ''}
          ${date != null ? "AND r.scheduled_at LIKE '$date%'" : ''}
          ORDER BY r.scheduled_at DESC, r.id DESC
        ''', [tagId]);
        return results.map(RecordEntity.fromMap).toList();
      }
      final conditions = <String>[];
      final args = <dynamic>[];
      if (type != null) {
        conditions.add('type = ?');
        args.add(type.value);
      }
      if (date != null) {
        conditions.add("scheduled_at LIKE ?");
        args.add('$date%');
      }
      final results = await _db.query(
        'records',
        where: conditions.isNotEmpty ? conditions.join(' AND ') : null,
        whereArgs: args.isNotEmpty ? args : null,
        orderBy: 'scheduled_at DESC, id DESC',
      );
      return results.map(RecordEntity.fromMap).toList();
    } catch (_) {
      return [];
    }
  }
  Future<RecordEntity?> getRecord(int id) async {
    try {
      final results = await _db.query('records', where: 'id = ?', whereArgs: [id]);
      if (results.isEmpty) return null;
      return RecordEntity.fromMap(results.first);
    } catch (_) {
      return null;
    }
  }
  Future<int> insertRecord(RecordEntity record) async {
    try {
      return await _db.insert('records', record.toMap());
    } catch (_) {
      return -1;
    }
  }
  Future<bool> updateRecord(RecordEntity record) async {
    try {
      final count = await _db.update(
        'records',
        record.toMap(),
        where: 'id = ?',
        whereArgs: [record.id],
      );
      return count > 0;
    } catch (_) {
      return false;
    }
  }
  Future<bool> deleteRecord(int id) async {
    try {
      final count = await _db.delete('records', where: 'id = ?', whereArgs: [id]);
      return count > 0;
    } catch (_) {
      return false;
    }
  }
  Future<void> clearAllData() async {
    final appDir = await getApplicationDocumentsDirectory();
    for (final name in ['note_attachments', 'attachments', 'media_audios']) {
      final d = Directory(join(appDir.path, name));
      if (d.existsSync()) {
        try {
          d.deleteSync(recursive: true);
        } catch (_) {}
      }
    }
    await _db.transaction((txn) async {
      await txn.delete('record_tags');
      await txn.delete('checklist_items');
      await txn.delete('media_files');
      await txn.delete('sticker_records');
      await txn.delete('rich_note_records');
      await txn.delete('checklist_records');
      await txn.delete('mood_records');
      await txn.delete('link_records');
      await txn.delete('attachment_records');
      await txn.delete('records');
      await txn.delete('tags');
    });
  }
  Future<StickerRecordEntity?> getStickerRecord(int recordId) async {
    try {
      final results = await _db.query(
        'sticker_records',
        where: 'record_id = ?',
        whereArgs: [recordId],
      );
      if (results.isEmpty) return null;
      return StickerRecordEntity.fromMap(results.first);
    } catch (_) {
      return null;
    }
  }
  Future<bool> insertStickerRecord(StickerRecordEntity entity) async {
    try {
      await _db.insert('sticker_records', entity.toMap());
      return true;
    } catch (_) {
      return false;
    }
  }
  Future<bool> updateStickerRecord(StickerRecordEntity entity) async {
    try {
      final count = await _db.update(
        'sticker_records',
        entity.toMap(),
        where: 'record_id = ?',
        whereArgs: [entity.recordId],
      );
      return count > 0;
    } catch (_) {
      return false;
    }
  }
  Future<RichNoteRecordEntity?> getRichNoteRecord(int recordId) async {
    try {
      final results = await _db.query(
        'rich_note_records',
        where: 'record_id = ?',
        whereArgs: [recordId],
      );
      if (results.isEmpty) return null;
      return RichNoteRecordEntity.fromMap(results.first);
    } catch (_) {
      return null;
    }
  }
  Future<bool> insertRichNoteRecord(RichNoteRecordEntity entity) async {
    try {
      await _db.insert('rich_note_records', entity.toMap());
      return true;
    } catch (_) {
      return false;
    }
  }
  Future<bool> updateRichNoteRecord(RichNoteRecordEntity entity) async {
    try {
      final count = await _db.update(
        'rich_note_records',
        entity.toMap(),
        where: 'record_id = ?',
        whereArgs: [entity.recordId],
      );
      return count > 0;
    } catch (_) {
      return false;
    }
  }
  Future<ChecklistRecordEntity?> getChecklistRecord(int recordId) async {
    try {
      final results = await _db.query(
        'checklist_records',
        where: 'record_id = ?',
        whereArgs: [recordId],
      );
      if (results.isEmpty) return null;
      return ChecklistRecordEntity.fromMap(results.first);
    } catch (_) {
      return null;
    }
  }
  Future<bool> insertChecklistRecord(ChecklistRecordEntity entity) async {
    try {
      await _db.insert('checklist_records', entity.toMap());
      return true;
    } catch (_) {
      return false;
    }
  }
  Future<bool> updateChecklistRecord(ChecklistRecordEntity entity) async {
    try {
      final count = await _db.update(
        'checklist_records',
        entity.toMap(),
        where: 'record_id = ?',
        whereArgs: [entity.recordId],
      );
      return count > 0;
    } catch (_) {
      return false;
    }
  }
  Future<List<ChecklistItemEntity>> getChecklistItems(int recordId) async {
    try {
      final results = await _db.query(
        'checklist_items',
        where: 'record_id = ?',
        whereArgs: [recordId],
        orderBy: 'sort_order ASC, id ASC',
      );
      return results.map(ChecklistItemEntity.fromMap).toList();
    } catch (_) {
      return [];
    }
  }
  Future<int> insertChecklistItem(ChecklistItemEntity entity) async {
    try {
      return await _db.insert('checklist_items', entity.toMap());
    } catch (_) {
      return -1;
    }
  }
  Future<bool> updateChecklistItem(ChecklistItemEntity entity) async {
    try {
      final count = await _db.update(
        'checklist_items',
        entity.toMap(),
        where: 'id = ?',
        whereArgs: [entity.id],
      );
      return count > 0;
    } catch (_) {
      return false;
    }
  }
  Future<bool> deleteChecklistItem(int id) async {
    try {
      final count = await _db.delete('checklist_items', where: 'id = ?', whereArgs: [id]);
      return count > 0;
    } catch (_) {
      return false;
    }
  }
  Future<bool> deleteChecklistItemsByRecord(int recordId) async {
    try {
      await _db.delete('checklist_items', where: 'record_id = ?', whereArgs: [recordId]);
      return true;
    } catch (_) {
      return false;
    }
  }
  Future<MoodRecordEntity?> getMoodRecord(int recordId) async {
    try {
      final results = await _db.query(
        'mood_records',
        where: 'record_id = ?',
        whereArgs: [recordId],
      );
      if (results.isEmpty) return null;
      return MoodRecordEntity.fromMap(results.first);
    } catch (_) {
      return null;
    }
  }
  Future<bool> insertMoodRecord(MoodRecordEntity entity) async {
    try {
      await _db.insert('mood_records', entity.toMap());
      return true;
    } catch (_) {
      return false;
    }
  }
  Future<bool> updateMoodRecord(MoodRecordEntity entity) async {
    try {
      final count = await _db.update(
        'mood_records',
        entity.toMap(),
        where: 'record_id = ?',
        whereArgs: [entity.recordId],
      );
      return count > 0;
    } catch (_) {
      return false;
    }
  }
  Future<List<MediaFileEntity>> getMediaFiles(int recordId) async {
    try {
      final results = await _db.query(
        'media_files',
        where: 'record_id = ?',
        whereArgs: [recordId],
        orderBy: 'sort_order ASC, id ASC',
      );
      return results.map(MediaFileEntity.fromMap).toList();
    } catch (_) {
      return [];
    }
  }
  Future<int> insertMediaFile(MediaFileEntity entity) async {
    try {
      return await _db.insert('media_files', entity.toMap());
    } catch (_) {
      return -1;
    }
  }
  Future<bool> deleteMediaFile(int id) async {
    try {
      final count = await _db.delete('media_files', where: 'id = ?', whereArgs: [id]);
      return count > 0;
    } catch (_) {
      return false;
    }
  }
  Future<LinkRecordEntity?> getLinkRecord(int recordId) async {
    try {
      final results = await _db.query(
        'link_records',
        where: 'record_id = ?',
        whereArgs: [recordId],
      );
      if (results.isEmpty) return null;
      return LinkRecordEntity.fromMap(results.first);
    } catch (_) {
      return null;
    }
  }
  Future<bool> insertLinkRecord(LinkRecordEntity entity) async {
    try {
      await _db.insert('link_records', entity.toMap());
      return true;
    } catch (_) {
      return false;
    }
  }
  Future<bool> updateLinkRecord(LinkRecordEntity entity) async {
    try {
      final count = await _db.update(
        'link_records',
        entity.toMap(),
        where: 'record_id = ?',
        whereArgs: [entity.recordId],
      );
      return count > 0;
    } catch (_) {
      return false;
    }
  }
  Future<AttachmentRecordEntity?> getAttachmentRecord(int recordId) async {
    try {
      final results = await _db.query(
        'attachment_records',
        where: 'record_id = ?',
        whereArgs: [recordId],
      );
      if (results.isEmpty) return null;
      return AttachmentRecordEntity.fromMap(results.first);
    } catch (_) {
      return null;
    }
  }
  Future<bool> insertAttachmentRecord(AttachmentRecordEntity entity) async {
    try {
      await _db.insert('attachment_records', entity.toMap());
      return true;
    } catch (_) {
      return false;
    }
  }
  Future<bool> updateAttachmentRecord(AttachmentRecordEntity entity) async {
    try {
      final count = await _db.update(
        'attachment_records',
        entity.toMap(),
        where: 'record_id = ?',
        whereArgs: [entity.recordId],
      );
      return count > 0;
    } catch (_) {
      return false;
    }
  }
  Future<List<TagEntity>> getTags() async {
    try {
      final results = await _db.query('tags', orderBy: 'name ASC');
      return results.map(TagEntity.fromMap).toList();
    } catch (_) {
      return [];
    }
  }
  Future<TagEntity?> getTagByName(String name) async {
    try {
      final results = await _db.query(
        'tags',
        where: 'name = ?',
        whereArgs: [name],
        limit: 1,
      );
      if (results.isEmpty) return null;
      return TagEntity.fromMap(results.first);
    } catch (_) {
      return null;
    }
  }
  Future<int?> ensureTagIdByName(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return null;
    var id = await insertTag(TagEntity(name: trimmed));
    if (id <= 0) {
      final existing = await getTagByName(trimmed);
      return existing?.id;
    }
    return id;
  }
  Future<void> replaceRecordTags(int recordId, List<String> tagNames) async {
    await _db.transaction((txn) async {
      await txn.delete(
        'record_tags',
        where: 'record_id = ?',
        whereArgs: [recordId],
      );
      for (final raw in tagNames) {
        final name = raw.trim();
        if (name.isEmpty) continue;
        await txn.insert(
          'tags',
          TagEntity(name: name).toMap(),
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
        final rows = await txn.query(
          'tags',
          where: 'name = ?',
          whereArgs: [name],
          limit: 1,
        );
        if (rows.isEmpty) continue;
        final idVal = rows.first['id'];
        final tagId = idVal is int ? idVal : (idVal as num).toInt();
        await txn.insert(
          'record_tags',
          RecordTagEntity(recordId: recordId, tagId: tagId).toMap(),
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
    });
  }
  Future<List<TagEntity>> getTagsByRecord(int recordId) async {
    try {
      final results = await _db.rawQuery('''
        SELECT t.* FROM tags t
        INNER JOIN record_tags rt ON t.id = rt.tag_id
        WHERE rt.record_id = ?
        ORDER BY t.name ASC
      ''', [recordId]);
      return results.map(TagEntity.fromMap).toList();
    } catch (_) {
      return [];
    }
  }
  Future<int> insertTag(TagEntity entity) async {
    try {
      return await _db.insert('tags', entity.toMap(), conflictAlgorithm: ConflictAlgorithm.ignore);
    } catch (_) {
      return -1;
    }
  }
  Future<bool> deleteTag(int id) async {
    try {
      final count = await _db.delete('tags', where: 'id = ?', whereArgs: [id]);
      return count > 0;
    } catch (_) {
      return false;
    }
  }
  Future<bool> insertRecordTag(RecordTagEntity entity) async {
    try {
      await _db.insert('record_tags', entity.toMap(), conflictAlgorithm: ConflictAlgorithm.ignore);
      return true;
    } catch (_) {
      return false;
    }
  }
  Future<bool> deleteRecordTag(int recordId, int tagId) async {
    try {
      final count = await _db.delete(
        'record_tags',
        where: 'record_id = ? AND tag_id = ?',
        whereArgs: [recordId, tagId],
      );
      return count > 0;
    } catch (_) {
      return false;
    }
  }
  Future<bool> deleteRecordTagsByRecord(int recordId) async {
    try {
      await _db.delete('record_tags', where: 'record_id = ?', whereArgs: [recordId]);
      return true;
    } catch (_) {
      return false;
    }
  }
  Future<List<int>> getRecordDatesInMonth(int year, int month) async {
    try {
      final prefix = '$year-${month.toString().padLeft(2, '0')}-';
      final results = await _db.rawQuery(
        "SELECT DISTINCT CAST(substr(scheduled_at, 9, 2) AS INTEGER) as day FROM records WHERE scheduled_at LIKE ?",
        ['$prefix%'],
      );
      return results
          .map((r) => r['day'] as int)
          .where((d) => d > 0)
          .toList();
    } catch (_) {
      return [];
    }
  }
  Future<List<RecordEntity>> getChecklistRecordsByCompletion({
    required bool allCompleted,
    String? date,
  }) async {
    try {
      final dateClause = date != null ? "AND r.scheduled_at LIKE '$date%'" : '';
      if (allCompleted) {
        final results = await _db.rawQuery('''
          SELECT r.* FROM records r
          WHERE r.type = 'checklist'
            AND NOT EXISTS (
              SELECT 1 FROM checklist_items ci
              WHERE ci.record_id = r.id AND ci.is_completed = 0
            )
            $dateClause
          ORDER BY r.scheduled_at DESC, r.id DESC
        ''');
        return results.map(RecordEntity.fromMap).toList();
      } else {
        final results = await _db.rawQuery('''
          SELECT r.* FROM records r
          WHERE r.type = 'checklist'
            AND EXISTS (
              SELECT 1 FROM checklist_items ci
              WHERE ci.record_id = r.id AND ci.is_completed = 0
            )
            $dateClause
          ORDER BY r.scheduled_at DESC, r.id DESC
        ''');
        return results.map(RecordEntity.fromMap).toList();
      }
    } catch (_) {
      return [];
    }
  }
}
