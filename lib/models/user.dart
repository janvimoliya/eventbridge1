class AppUserModel {
  const AppUserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.totalBookings,
    required this.totalSpent,
    this.isBlocked = false,
    this.isOrganizer = false,
    this.isVerifiedOrganizer = false,
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final int totalBookings;
  final double totalSpent;
  final bool isBlocked;
  final bool isOrganizer;
  final bool isVerifiedOrganizer;

  AppUserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    int? totalBookings,
    double? totalSpent,
    bool? isBlocked,
    bool? isOrganizer,
    bool? isVerifiedOrganizer,
  }) {
    return AppUserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      totalBookings: totalBookings ?? this.totalBookings,
      totalSpent: totalSpent ?? this.totalSpent,
      isBlocked: isBlocked ?? this.isBlocked,
      isOrganizer: isOrganizer ?? this.isOrganizer,
      isVerifiedOrganizer: isVerifiedOrganizer ?? this.isVerifiedOrganizer,
    );
  }
}
