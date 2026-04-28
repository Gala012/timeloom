enum RecordType {
  sticker,
  richNote,
  checklist,
  mood,
  media,
  link,
  attachment;
  String get value {
    switch (this) {
      case RecordType.sticker:
        return 'sticker';
      case RecordType.richNote:
        return 'rich_note';
      case RecordType.checklist:
        return 'checklist';
      case RecordType.mood:
        return 'mood';
      case RecordType.media:
        return 'media';
      case RecordType.link:
        return 'link';
      case RecordType.attachment:
        return 'attachment';
    }
  }
  static RecordType fromValue(String value) {
    return RecordType.values.firstWhere((e) => e.value == value);
  }
}
enum StickerType {
  sticker,
  emoji;
  String get value => name;
  static StickerType fromValue(String value) =>
      StickerType.values.firstWhere((e) => e.value == value);
}
enum MediaType {
  image,
  video,
  audio;
  String get value => name;
  static MediaType fromValue(String value) =>
      MediaType.values.firstWhere((e) => e.value == value);
}
class RecordEntity {
  final int? id;
  final RecordType type;
  final String scheduledAt;
  final String createdAt;
  final String updatedAt;
  const RecordEntity({
    this.id,
    required this.type,
    required this.scheduledAt,
    required this.createdAt,
    required this.updatedAt,
  });
  factory RecordEntity.fromMap(Map<String, dynamic> map) {
    return RecordEntity(
      id: map['id'] as int?,
      type: RecordType.fromValue(map['type'] as String),
      scheduledAt: map['scheduled_at'] as String,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
    );
  }
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'type': type.value,
      'scheduled_at': scheduledAt,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
class StickerRecordEntity {
  final int recordId;
  final String text;
  final String images;
  const StickerRecordEntity({
    required this.recordId,
    required this.text,
    required this.images,
  });
  factory StickerRecordEntity.fromMap(Map<String, dynamic> map) {
    return StickerRecordEntity(
      recordId: map['record_id'] as int,
      text: map['text'] as String,
      images: map['images'] as String,
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'record_id': recordId,
      'text': text,
      'images': images,
    };
  }
}
class RichNoteRecordEntity {
  final int recordId;
  final String content;
  const RichNoteRecordEntity({
    required this.recordId,
    required this.content,
  });
  factory RichNoteRecordEntity.fromMap(Map<String, dynamic> map) {
    return RichNoteRecordEntity(
      recordId: map['record_id'] as int,
      content: map['content'] as String,
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'record_id': recordId,
      'content': content,
    };
  }
}
class ChecklistRecordEntity {
  final int recordId;
  final String title;
  const ChecklistRecordEntity({
    required this.recordId,
    required this.title,
  });
  factory ChecklistRecordEntity.fromMap(Map<String, dynamic> map) {
    return ChecklistRecordEntity(
      recordId: map['record_id'] as int,
      title: map['title'] as String,
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'record_id': recordId,
      'title': title,
    };
  }
}
class ChecklistItemEntity {
  final int? id;
  final int recordId;
  final String text;
  final bool isCompleted;
  final int sortOrder;
  const ChecklistItemEntity({
    this.id,
    required this.recordId,
    required this.text,
    required this.isCompleted,
    required this.sortOrder,
  });
  factory ChecklistItemEntity.fromMap(Map<String, dynamic> map) {
    return ChecklistItemEntity(
      id: map['id'] as int?,
      recordId: map['record_id'] as int,
      text: map['text'] as String,
      isCompleted: (map['is_completed'] as int) == 1,
      sortOrder: map['sort_order'] as int,
    );
  }
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'record_id': recordId,
      'text': text,
      'is_completed': isCompleted ? 1 : 0,
      'sort_order': sortOrder,
    };
  }
}
class MoodRecordEntity {
  final int recordId;
  final StickerType stickerType;
  final String stickerKey;
  final String? text;
  const MoodRecordEntity({
    required this.recordId,
    required this.stickerType,
    required this.stickerKey,
    this.text,
  });
  factory MoodRecordEntity.fromMap(Map<String, dynamic> map) {
    return MoodRecordEntity(
      recordId: map['record_id'] as int,
      stickerType: StickerType.fromValue(map['sticker_type'] as String),
      stickerKey: map['sticker_key'] as String,
      text: map['text'] as String?,
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'record_id': recordId,
      'sticker_type': stickerType.value,
      'sticker_key': stickerKey,
      'text': text,
    };
  }
}
class MediaFileEntity {
  final int? id;
  final int recordId;
  final String localPath;
  final MediaType mediaType;
  final String? thumbnail;
  final int sortOrder;
  const MediaFileEntity({
    this.id,
    required this.recordId,
    required this.localPath,
    required this.mediaType,
    this.thumbnail,
    required this.sortOrder,
  });
  factory MediaFileEntity.fromMap(Map<String, dynamic> map) {
    return MediaFileEntity(
      id: map['id'] as int?,
      recordId: map['record_id'] as int,
      localPath: map['local_path'] as String,
      mediaType: MediaType.fromValue(map['media_type'] as String),
      thumbnail: map['thumbnail'] as String?,
      sortOrder: map['sort_order'] as int,
    );
  }
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'record_id': recordId,
      'local_path': localPath,
      'media_type': mediaType.value,
      'thumbnail': thumbnail,
      'sort_order': sortOrder,
    };
  }
}
class LinkRecordEntity {
  final int recordId;
  final String url;
  final String? displayText;
  final String? favicon;
  const LinkRecordEntity({
    required this.recordId,
    required this.url,
    this.displayText,
    this.favicon,
  });
  factory LinkRecordEntity.fromMap(Map<String, dynamic> map) {
    return LinkRecordEntity(
      recordId: map['record_id'] as int,
      url: map['url'] as String,
      displayText: map['display_text'] as String?,
      favicon: map['favicon'] as String?,
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'record_id': recordId,
      'url': url,
      'display_text': displayText,
      'favicon': favicon,
    };
  }
}
class AttachmentRecordEntity {
  final int recordId;
  final String fileName;
  final int fileSize;
  final String fileType;
  final String localPath;
  const AttachmentRecordEntity({
    required this.recordId,
    required this.fileName,
    required this.fileSize,
    required this.fileType,
    required this.localPath,
  });
  factory AttachmentRecordEntity.fromMap(Map<String, dynamic> map) {
    return AttachmentRecordEntity(
      recordId: map['record_id'] as int,
      fileName: map['file_name'] as String,
      fileSize: map['file_size'] as int,
      fileType: map['file_type'] as String,
      localPath: map['local_path'] as String,
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'record_id': recordId,
      'file_name': fileName,
      'file_size': fileSize,
      'file_type': fileType,
      'local_path': localPath,
    };
  }
}
class TagEntity {
  final int? id;
  final String name;
  const TagEntity({
    this.id,
    required this.name,
  });
  factory TagEntity.fromMap(Map<String, dynamic> map) {
    return TagEntity(
      id: map['id'] as int?,
      name: map['name'] as String,
    );
  }
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
    };
  }
}
class RecordTagEntity {
  final int recordId;
  final int tagId;
  const RecordTagEntity({
    required this.recordId,
    required this.tagId,
  });
  factory RecordTagEntity.fromMap(Map<String, dynamic> map) {
    return RecordTagEntity(
      recordId: map['record_id'] as int,
      tagId: map['tag_id'] as int,
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'record_id': recordId,
      'tag_id': tagId,
    };
  }
}
