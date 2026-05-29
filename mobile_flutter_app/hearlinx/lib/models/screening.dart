class Screening {
  const Screening({
    this.id = '',
    this.babyId = '',
    this.screeningType = '',
    this.earLeft = '',
    this.earRight = '',
    this.notes,
    this.screenedBy,
    this.screenedAt,
    this.overallResult,
  });

  factory Screening.fromJson(Map<String, dynamic> json) {
    return Screening(
      id: json['id'] as String? ?? '',
      babyId: json['baby_id'] as String? ?? '',
      screeningType: json['screening_type'] as String? ?? '',
      earLeft: json['ear_left'] as String? ?? '',
      earRight: json['ear_right'] as String? ?? '',
      notes: json['notes'] as String?,
      screenedBy: json['screened_by'] as String?,
      screenedAt: json['screened_at'] as String?,
      overallResult: json['overall_result'] as String?,
    );
  }

  final String id;
  final String babyId;
  final String screeningType;
  final String earLeft;
  final String earRight;
  final String? notes;
  final String? screenedBy;
  final String? screenedAt;
  final String? overallResult;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'baby_id': babyId,
      'screening_type': screeningType,
      'ear_left': earLeft,
      'ear_right': earRight,
      if (notes != null) 'notes': notes,
      if (screenedBy != null) 'screened_by': screenedBy,
      if (screenedAt != null) 'screened_at': screenedAt,
      if (overallResult != null) 'overall_result': overallResult,
    };
  }
}
