class Vehicle {
  final String id;
  final String bienSoXe;
  final String loaiXe; // 'limousine', 'giuong_nam', 'ghe_ngoi'
  final int soGhe;
  final String? taiXeId;
  final String? tenTaiXe;
  final String trangThai; // 'hoat_dong', 'bao_tri', 'ngung_hoat_dong'
  final DateTime? ngayBaoTriCuoi;
  final DateTime? ngayBaoTriTiep;
  final String? ghiChu;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final String? tenXe;
  final String? hangXe;
  final String? moTa;
  final List<String> hinhAnh;

  Vehicle({
    required this.id,
    required this.bienSoXe,
    required this.loaiXe,
    required this.soGhe,
    this.taiXeId,
    this.tenTaiXe,
    this.trangThai = 'hoat_dong',
    this.ngayBaoTriCuoi,
    this.ngayBaoTriTiep,
    this.ghiChu,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.tenXe,
    this.hangXe,
    this.moTa,
    this.hinhAnh = const [],
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['_id'] ?? json['id'] ?? '',
      bienSoXe: json['bienSoXe'] ?? '',
      loaiXe: json['loaiXe'] ?? 'ghe_ngoi',
      soGhe: json['soGhe'] ?? 45,
      taiXeId: json['taiXeId'],
      tenTaiXe: json['tenTaiXe'],
      trangThai: json['trangThai'] ?? 'hoat_dong',
      ngayBaoTriCuoi: json['ngayBaoTriCuoi'] != null
          ? DateTime.parse(json['ngayBaoTriCuoi'])
          : null,
      ngayBaoTriTiep: json['ngayBaoTriTiep'] != null
          ? DateTime.parse(json['ngayBaoTriTiep'])
          : null,
      ghiChu: json['ghiChu'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      isActive: json['isActive'] ?? true,
      tenXe: json['tenXe'],
      hangXe: json['hangXe'],
      moTa: json['moTa'],
      hinhAnh:
          (json['hinhAnh'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bienSoXe': bienSoXe,
      'loaiXe': loaiXe,
      'soGhe': soGhe,
      'taiXeId': taiXeId,
      'tenTaiXe': tenTaiXe,
      'trangThai': trangThai,
      'ngayBaoTriCuoi': ngayBaoTriCuoi?.toIso8601String(),
      'ngayBaoTriTiep': ngayBaoTriTiep?.toIso8601String(),
      'ghiChu': ghiChu,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isActive': isActive,
      'tenXe': tenXe,
      'hangXe': hangXe,
      'moTa': moTa,
      'hinhAnh': hinhAnh,
    };
  }

  Vehicle copyWith({
    String? id,
    String? bienSoXe,
    String? loaiXe,
    int? soGhe,
    String? taiXeId,
    String? tenTaiXe,
    String? trangThai,
    DateTime? ngayBaoTriCuoi,
    DateTime? ngayBaoTriTiep,
    String? ghiChu,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    String? tenXe,
    String? hangXe,
    String? moTa,
    List<String>? hinhAnh,
  }) {
    return Vehicle(
      id: id ?? this.id,
      bienSoXe: bienSoXe ?? this.bienSoXe,
      loaiXe: loaiXe ?? this.loaiXe,
      soGhe: soGhe ?? this.soGhe,
      taiXeId: taiXeId ?? this.taiXeId,
      tenTaiXe: tenTaiXe ?? this.tenTaiXe,
      trangThai: trangThai ?? this.trangThai,
      ngayBaoTriCuoi: ngayBaoTriCuoi ?? this.ngayBaoTriCuoi,
      ngayBaoTriTiep: ngayBaoTriTiep ?? this.ngayBaoTriTiep,
      ghiChu: ghiChu ?? this.ghiChu,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      tenXe: tenXe ?? this.tenXe,
      hangXe: hangXe ?? this.hangXe,
      moTa: moTa ?? this.moTa,
      hinhAnh: hinhAnh ?? this.hinhAnh,
    );
  }

  // Helper methods
  String get loaiXeDisplayName {
    switch (loaiXe) {
      case 'limousine':
        return 'Limousine';
      case 'giuong_nam':
        return 'Giường nằm';
      case 'ghe_ngoi':
        return 'Ghế ngồi';
      default:
        return 'Không xác định';
    }
  }

  String get trangThaiDisplayName {
    switch (trangThai) {
      case 'hoat_dong':
        return 'Hoạt động';
      case 'bao_tri':
        return 'Bảo trì';
      case 'ngung_hoat_dong':
      case 'ngung':
        return 'Ngừng hoạt động';
      default:
        return 'Không xác định';
    }
  }

  bool get canOperate => trangThai == 'hoat_dong' && isActive;

  bool get needMaintenance {
    if (ngayBaoTriTiep == null) return false;
    return DateTime.now().isAfter(ngayBaoTriTiep!);
  }

  int get daysSinceLastMaintenance {
    if (ngayBaoTriCuoi == null) return 0;
    return DateTime.now().difference(ngayBaoTriCuoi!).inDays;
  }

  @override
  String toString() {
    return 'Vehicle(id: $id, bienSoXe: $bienSoXe, loaiXe: $loaiXe, soGhe: $soGhe)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Vehicle && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
