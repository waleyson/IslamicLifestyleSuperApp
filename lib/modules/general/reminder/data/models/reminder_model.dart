import 'package:hive/hive.dart';

@HiveType(typeId: 1)
class ReminderModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final DateTime scheduledTime;

  @HiveField(3)
  final bool isEnabled;

  @HiveField(4)
  final bool isQuranReminder;

  @HiveField(5)
  final int? surahNumber;

  @HiveField(6)
  final String? surahName;

  @HiveField(7)
  final int? ayahNumber;

  @HiveField(8)
  final String? ayahText;

  @HiveField(9)
  final String? audioUrl;

  ReminderModel({
    required this.id,
    required this.title,
    required this.scheduledTime,
    this.isEnabled = true,
    this.isQuranReminder = false,
    this.surahNumber,
    this.surahName,
    this.ayahNumber,
    this.ayahText,
    this.audioUrl,
  });
}

// Manual Adapter since hive_generator failed
class ReminderModelAdapter extends TypeAdapter<ReminderModel> {
  @override
  final int typeId = 1;

  @override
  ReminderModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ReminderModel(
      id: fields[0] as String,
      title: fields[1] as String,
      scheduledTime: fields[2] as DateTime,
      isEnabled: fields[3] as bool,
      isQuranReminder: fields[4] as bool? ?? false,
      surahNumber: fields[5] as int?,
      surahName: fields[6] as String?,
      ayahNumber: fields[7] as int?,
      ayahText: fields[8] as String?,
      audioUrl: fields[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ReminderModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.scheduledTime)
      ..writeByte(3)
      ..write(obj.isEnabled)
      ..writeByte(4)
      ..write(obj.isQuranReminder)
      ..writeByte(5)
      ..write(obj.surahNumber)
      ..writeByte(6)
      ..write(obj.surahName)
      ..writeByte(7)
      ..write(obj.ayahNumber)
      ..writeByte(8)
      ..write(obj.ayahText)
      ..writeByte(9)
      ..write(obj.audioUrl);
  }
}
