class PetProfile {
  final int? id;
  final String? name;
  final String? breed;
  final int? age;
  final String? birthdate;
  final String? gender;
  final bool? neutered;
  final String? profileImage;
  final num? weight;

  const PetProfile({
    required this.id,
    required this.name,
    required this.breed,
    required this.age,
    required this.birthdate,
    required this.gender,
    required this.neutered,
    required this.profileImage,
    this.weight,
  });

  static int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v.trim());
    return null;
  }

  static String? _asStr(dynamic v) {
    if (v == null) return null;
    if (v is String) return v;
    return v.toString();
  }

  static bool? _asBool(dynamic v) {
    if (v == null) return null;
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) {
      final t = v.trim().toLowerCase();
      if (t == 'true' || t == '1' || t == 'yes' || t == 'y') return true;
      if (t == 'false' || t == '0' || t == 'no' || t == 'n') return false;
    }
    return null;
  }

  static num? _asNum(dynamic v) {
    if (v == null) return null;
    if (v is num) return v;
    if (v is String) return num.tryParse(v.trim());
    return null;
  }

  static String? _normGender(dynamic v) {
    final s = _asStr(v);
    if (s == null) return null;
    final t = s.trim().toUpperCase();
    if (t == 'M' || t == 'MALE' || t == '남') return 'M';
    if (t == 'F' || t == 'FEMALE' || t == '여') return 'F';
    return t;
  }

  factory PetProfile.fromJson(Map<String, dynamic> j) {
    final m = (j['data'] is Map<String, dynamic>) ? (j['data'] as Map<String, dynamic>) : j;

    return PetProfile(
      id: _asInt(m['id'] ?? m['petId']),
      name: _asStr(m['name'] ?? m['petName']),
      breed: _asStr(m['breed']),
      age: _asInt(m['age']),
      birthdate: _asStr(m['birthdate'] ?? m['birthDay']),
      gender: _normGender(m['gender']),
      neutered: _asBool(m['neutered'] ?? m['isNeutered']),
      profileImage: _asStr(m['profileImage'] ?? m['profileImageUrl'] ?? m['profile_image_url'] ?? m['image']),
      weight: _asNum(m['weight'] ?? m['weightKg'] ?? m['weight_kg'] ?? m['bodyWeight'] ?? m['petWeight']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'breed': breed,
    'age': age,
    'birthdate': birthdate,
    'gender': gender,
    'neutered': neutered,
    'profileImage': profileImage,
    'weight': weight,
  };

  PetProfile copyWith({
    int? id,
    String? name,
    String? breed,
    int? age,
    String? birthdate,
    String? gender,
    bool? neutered,
    String? profileImage,
    num? weight,
  }) {
    return PetProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      breed: breed ?? this.breed,
      age: age ?? this.age,
      birthdate: birthdate ?? this.birthdate,
      gender: gender ?? this.gender,
      neutered: neutered ?? this.neutered,
      profileImage: profileImage ?? this.profileImage,
      weight: weight ?? this.weight,
    );
  }
}
