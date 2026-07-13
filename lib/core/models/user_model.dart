class MkmuUser {
  final String id;
  final String email;
  final String fullName;
  final String? phoneNumber;
  final String mkoa;
  final String? wilaya;
  final String? secretQuestion;
  final String? secretAnswer;
  final String? memberId;
  final String role;
  final String? managedMkoa;
  final String? managedWilaya;
  final String? managedKata;
  final String? image;
  final DateTime createdAt;

  const MkmuUser({
    required this.id,
    required this.email,
    required this.fullName,
    this.phoneNumber,
    this.mkoa = 'Dar es Salaam',
    this.wilaya,
    this.secretQuestion,
    this.secretAnswer,
    this.memberId,
    this.role = 'citizen',
    this.managedMkoa,
    this.managedWilaya,
    this.managedKata,
    this.image,
    required this.createdAt,
  });

  factory MkmuUser.fromJson(Map<String, dynamic> json) {
    return MkmuUser(
      id:             json['id'] as String,
      email:          json['email'] as String,
      fullName:       json['full_name'] as String? ?? json['name'] as String? ?? 'Mtumiaji',
      phoneNumber:    json['phone_number'] as String?,
      mkoa:           json['mkoa'] as String? ?? 'Dar es Salaam',
      wilaya:         json['wilaya'] as String?,
      secretQuestion: json['secret_question'] as String?,
      secretAnswer:   json['secret_answer'] as String?,
      memberId:       json['member_id'] as String?,
      role:           json['role'] as String? ?? 'citizen',
      managedMkoa:    json['managed_mkoa'] as String?,
      managedWilaya:   json['managed_wilaya'] as String?,
      managedKata:     json['managed_kata'] as String?,
      image:          json['image'] as String?,
      createdAt:      DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id':              id,
    'email':           email,
    'full_name':       fullName,
    'phone_number':    phoneNumber,
    'mkoa':            mkoa,
    'wilaya':          wilaya,
    'secret_question': secretQuestion,
    'secret_answer':   secretAnswer,
    'role':            role,
    'managed_mkoa':    managedMkoa,
    'managed_wilaya':  managedWilaya,
    'managed_kata':    managedKata,
    'image':           image,
    'created_at':      createdAt.toIso8601String(),
  };

  MkmuUser copyWith({
    String? fullName,
    String? phoneNumber,
    String? mkoa,
    String? wilaya,
    String? secretQuestion,
    String? secretAnswer,
    String? role,
    String? managedMkoa,
    String? managedWilaya,
    String? managedKata,
    String? image,
  }) {
    return MkmuUser(
      id:             id,
      email:          email,
      fullName:       fullName      ?? this.fullName,
      phoneNumber:    phoneNumber   ?? this.phoneNumber,
      mkoa:           mkoa          ?? this.mkoa,
      wilaya:         wilaya        ?? this.wilaya,
      secretQuestion: secretQuestion ?? this.secretQuestion,
      secretAnswer:   secretAnswer   ?? this.secretAnswer,
      role:           role          ?? this.role,
      managedMkoa:    managedMkoa    ?? this.managedMkoa,
      managedWilaya:  managedWilaya  ?? this.managedWilaya,
      managedKata:    managedKata    ?? this.managedKata,
      image:          image         ?? this.image,
      createdAt:      createdAt,
    );
  }
}
