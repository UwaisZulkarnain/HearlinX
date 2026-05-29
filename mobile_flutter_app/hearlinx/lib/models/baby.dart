class Baby {
  const Baby({
    this.id = '',
    this.systemId = '',
    this.hospitalId = '',
    this.ward = '',
    this.motherIc,
    this.dateOfBirth,
    this.gender,
  });

  factory Baby.fromJson(Map<String, dynamic> json) {
    return Baby(
      id: json['id'] as String? ?? '',
      systemId: json['system_id'] as String? ?? '',
      hospitalId: json['hospital_id'] as String? ?? '',
      ward: json['ward'] as String? ?? '',
      motherIc: json['mother_ic'] as String?,
      dateOfBirth: json['date_of_birth'] as String?,
      gender: json['gender'] as String?,
    );
  }

  final String id;
  final String systemId;
  final String hospitalId;
  final String ward;
  final String? motherIc;
  final String? dateOfBirth;
  final String? gender;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'system_id': systemId,
      'hospital_id': hospitalId,
      'ward': ward,
      if (motherIc != null) 'mother_ic': motherIc,
      if (dateOfBirth != null) 'date_of_birth': dateOfBirth,
      if (gender != null) 'gender': gender,
    };
  }
}
