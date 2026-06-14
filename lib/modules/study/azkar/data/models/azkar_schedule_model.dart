import 'package:hive/hive.dart';

@HiveType(typeId: 2)
class AzkarScheduleModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final int chapterId;

  @HiveField(2)
  final String chapterName;

  @HiveField(3)
  final int hour;

  @HiveField(4)
  final int minute;

  @HiveField(5)
  final bool isEnabled;

  @HiveField(6)
  final int notificationId;

  AzkarScheduleModel({
    required this.id,
    required this.chapterId,
    required this.chapterName,
    required this.hour,
    required this.minute,
    this.isEnabled = true,
    required this.notificationId,
  });

  AzkarScheduleModel copyWith({
    String? id,
    int? chapterId,
    String? chapterName,
    int? hour,
    int? minute,
    bool? isEnabled,
    int? notificationId,
  }) {
    return AzkarScheduleModel(
      id: id ?? this.id,
      chapterId: chapterId ?? this.chapterId,
      chapterName: chapterName ?? this.chapterName,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      isEnabled: isEnabled ?? this.isEnabled,
      notificationId: notificationId ?? this.notificationId,
    );
  }
}

/// Manual TypeAdapter to persist AzkarScheduleModel in Hive.
class AzkarScheduleModelAdapter extends TypeAdapter<AzkarScheduleModel> {
  @override
  final int typeId = 2;

  @override
  AzkarScheduleModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AzkarScheduleModel(
      id: fields[0] as String,
      chapterId: fields[1] as int,
      chapterName: fields[2] as String,
      hour: fields[3] as int,
      minute: fields[4] as int,
      isEnabled: fields[5] as bool? ?? true,
      notificationId: fields[6] as int,
    );
  }

  @override
  void write(BinaryWriter writer, AzkarScheduleModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.chapterId)
      ..writeByte(2)
      ..write(obj.chapterName)
      ..writeByte(3)
      ..write(obj.hour)
      ..writeByte(4)
      ..write(obj.minute)
      ..writeByte(5)
      ..write(obj.isEnabled)
      ..writeByte(6)
      ..write(obj.notificationId);
  }
}
