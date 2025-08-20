class User {
  final String id;
  final String hoTen;
  final String soDienThoai;
  final String email;
  final String vaiTro; // 'admin', 'driver', 'user'
  final String? diaChi;
  final String? bienSoXe; // Chỉ dành cho tài xế
  final String? gplx; // Giấy phép lái xe - chỉ dành cho tài xế
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final bool isVip;

  User({
    required this.id,
    required this.hoTen,
    required this.soDienThoai,
    required this.email,
    required this.vaiTro,
    this.diaChi,
    this.bienSoXe,
    this.gplx,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.isVip = false,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? json['id'] ?? '',
      hoTen: json['hoTen'] ?? json['fullName'] ?? '',
      soDienThoai: json['soDienThoai'] ?? json['phoneNumber'] ?? '',
      email: json['email'] ?? '',
      vaiTro: json['vaiTro'] ?? json['role'] ?? 'user',
      diaChi: json['diaChi'] ?? json['address'],
      bienSoXe: json['bienSoXe'] ?? json['vehicleNumber'],
      gplx: json['gplx'] ?? json['licenseNumber'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      isActive: json['isActive'] ?? true,
      isVip: json['isVip'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hoTen': hoTen,
      'soDienThoai': soDienThoai,
      'email': email,
      'vaiTro': vaiTro,
      'diaChi': diaChi,
      'bienSoXe': bienSoXe,
      'gplx': gplx,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isActive': isActive,
      'isVip': isVip,
    };
  }

  User copyWith({
    String? id,
    String? hoTen,
    String? soDienThoai,
    String? email,
    String? vaiTro,
    String? diaChi,
    String? bienSoXe,
    String? gplx,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return User(
      id: id ?? this.id,
      hoTen: hoTen ?? this.hoTen,
      soDienThoai: soDienThoai ?? this.soDienThoai,
      email: email ?? this.email,
      vaiTro: vaiTro ?? this.vaiTro,
      diaChi: diaChi ?? this.diaChi,
      bienSoXe: bienSoXe ?? this.bienSoXe,
      gplx: gplx ?? this.gplx,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, hoTen: $hoTen, soDienThoai: $soDienThoai, vaiTro: $vaiTro)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  // Helper methods
  bool get isAdmin => vaiTro == 'admin';
  bool get isDriver => vaiTro == 'driver';
  bool get isUser => vaiTro == 'user';

  String get roleDisplayName {
    switch (vaiTro) {
      case 'admin':
        return 'Quản trị viên';
      case 'driver':
        return 'Tài xế';
      case 'user':
        return 'Khách hàng';
      default:
        return 'Không xác định';
    }
  }

  // Validation methods
  bool get isValidDriver {
    return isDriver && bienSoXe != null && bienSoXe!.isNotEmpty;
  }

  bool get hasCompleteInfo {
    return hoTen.isNotEmpty && soDienThoai.isNotEmpty && email.isNotEmpty;
  }
}
