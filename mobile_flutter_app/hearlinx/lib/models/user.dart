class User {
  static const roleScreener = 'screener';
  static const roleCoordinator = 'coordinator';
  static const roleUnhsCoordinator = 'unhs_coordinator';
  static const roleMoh = 'moh';

  const User({
    this.id = '',
    this.fullName = '',
    this.email = '',
    this.staffId = '',
    this.role = '',
    this.hospitalId = '',
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      staffId: json['staff_id'] as String? ?? '',
      role: json['role'] as String? ?? '',
      hospitalId: json['hospital_id'] as String? ?? '',
    );
  }

  final String id;
  final String fullName;
  final String email;
  final String staffId;
  final String role;
  final String hospitalId;
}
