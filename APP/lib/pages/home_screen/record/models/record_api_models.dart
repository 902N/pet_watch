class MonthRecordsResponse {
  final List<DailyRecord> dailyRecords;
  MonthRecordsResponse({required this.dailyRecords});
  factory MonthRecordsResponse.fromJson(Map<String, dynamic> json) {
    final list = (json['dailyRecords'] as List? ?? const []);
    return MonthRecordsResponse(
      dailyRecords: list.map((item) => DailyRecord.fromJson(item as Map<String, dynamic>)).toList(),
    );
  }
}

class DailyRecord {
  final String date;
  final bool mealRecord;
  final bool walkRecord;
  final bool excretionRecord;
  final bool healthRecord;
  final bool freeRecord;
  final String? imgUrl;
  DailyRecord({
    required this.date,
    required this.mealRecord,
    required this.walkRecord,
    required this.excretionRecord,
    required this.healthRecord,
    required this.freeRecord,
    this.imgUrl,
  });
  factory DailyRecord.fromJson(Map<String, dynamic> json) {
    return DailyRecord(
      date: json['date'] as String? ?? '',
      mealRecord: json['mealRecord'] as bool? ?? false,
      walkRecord: json['walkRecord'] as bool? ?? false,
      excretionRecord: json['excretionRecord'] as bool? ?? false,
      healthRecord: json['healthRecord'] as bool? ?? false,
      freeRecord: json['freeRecord'] as bool? ?? false,
      imgUrl: json['imgUrl'] as String?,
    );
  }
  bool get hasAnyRecord => mealRecord || walkRecord || excretionRecord || healthRecord || freeRecord;
  List<String> get recordedCategories {
    final categories = <String>[];
    if (mealRecord) categories.add('meal');
    if (walkRecord) categories.add('walk');
    if (excretionRecord) categories.add('toilet');
    if (healthRecord) categories.add('health');
    if (freeRecord) categories.add('memo');
    return categories;
  }
}

class DayRecordsResponse {
  final String date;
  final List<MealRecordData> mealRecords;
  final List<WalkRecordData> walkRecords;
  final List<ExcretionRecordData> excretionRecords;
  final List<HealthRecordData> healthRecords;
  final List<FreeRecordData> freeRecords;

  DayRecordsResponse({
    required this.date,
    required this.mealRecords,
    required this.walkRecords,
    required this.excretionRecords,
    required this.healthRecords,
    required this.freeRecords,
  });

  factory DayRecordsResponse.fromJson(Map<String, dynamic> json) {
    final meals = (json['mealRecords'] as List? ?? const []);
    final walks = (json['walkRecords'] as List? ?? const []);
    final excre = (json['excretionRecords'] as List? ?? const []);
    final health = (json['healthRecords'] as List? ?? const []);
    List freeArr = [];
    if (json['freeRecords'] is List) freeArr = json['freeRecords'];
    else if (json['freeRecord'] is Map) freeArr = [json['freeRecord']];

    return DayRecordsResponse(
      date: json['date'] as String? ?? '',
      mealRecords: meals.map((e) => MealRecordData.fromJson(e as Map<String, dynamic>)).toList(),
      walkRecords: walks.map((e) => WalkRecordData.fromJson(e as Map<String, dynamic>)).toList(),
      excretionRecords: excre.map((e) => ExcretionRecordData.fromJson(e as Map<String, dynamic>)).toList(),
      healthRecords: health.map((e) => HealthRecordData.fromJson(e as Map<String, dynamic>)).toList(),
      freeRecords: freeArr.map((e) => FreeRecordData.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class MealRecordData {
  final int id;
  final String type;
  final String detail;
  final int amount;
  final String? recordTime;
  MealRecordData({required this.id, required this.type, required this.detail, required this.amount, this.recordTime});
  factory MealRecordData.fromJson(Map<String, dynamic> json) {
    return MealRecordData(
      id: json['id'] as int,
      type: json['type'] as String? ?? '',
      detail: json['detail'] as String? ?? '',
      amount: json['amount'] is int ? json['amount'] as int : int.tryParse('${json['amount']}') ?? 0,
      recordTime: json['recordTime'] as String?,
    );
  }
}

class WalkRecordData {
  final int id;
  final int duration;
  final String intensity;
  final String? recordTime;
  WalkRecordData({required this.id, required this.duration, required this.intensity, this.recordTime});
  factory WalkRecordData.fromJson(Map<String, dynamic> json) {
    return WalkRecordData(
      id: json['id'] as int,
      duration: json['duration'] is int ? json['duration'] as int : int.tryParse('${json['duration']}') ?? 0,
      intensity: json['intensity'] as String? ?? '',
      recordTime: json['recordTime'] as String?,
    );
  }
}

class ExcretionRecordData {
  final int id;
  final String type;
  final String condition;
  final String? imageUrl;
  final String? recordTime;
  ExcretionRecordData({required this.id, required this.type, required this.condition, this.imageUrl, this.recordTime});
  factory ExcretionRecordData.fromJson(Map<String, dynamic> json) {
    return ExcretionRecordData(
      id: json['id'] as int,
      type: json['type'] as String? ?? '',
      condition: json['condition'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      recordTime: json['recordTime'] as String?,
    );
  }
}

class HealthRecordData {
  final int id;
  final String symptomDescription;
  final String? imgUrl;
  final String? recordTime;
  HealthRecordData({required this.id, required this.symptomDescription, this.imgUrl, this.recordTime});
  factory HealthRecordData.fromJson(Map<String, dynamic> json) {
    return HealthRecordData(
      id: json['id'] as int,
      symptomDescription: json['symptomDescription'] as String? ?? '',
      imgUrl: json['imgUrl'] as String?,
      recordTime: json['recordTime'] as String?,
    );
  }
}

class FreeRecordData {
  final int id;
  final String content;
  final String? imgUrl;
  final String? recordTime;
  FreeRecordData({required this.id, required this.content, this.imgUrl, this.recordTime});
  factory FreeRecordData.fromJson(Map<String, dynamic> json) {
    return FreeRecordData(
      id: json['id'] as int,
      content: json['content'] as String? ?? '',
      imgUrl: json['imgUrl'] as String?,
      recordTime: json['recordTime'] as String?,
    );
  }
}
