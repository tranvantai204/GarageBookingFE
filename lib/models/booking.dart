class Booking {
  final String id;
  final String userId;
  final String tripId;
  final List<String> danhSachGhe;
  final int tongTien;
  final String maVe;
  final String trangThaiThanhToan;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Thông tin chuyến đi (từ populate)
  final String? diemDi;
  final String? diemDen;
  final DateTime? thoiGianKhoiHanh;

  Booking({
    required this.id,
    required this.userId,
    required this.tripId,
    required this.danhSachGhe,
    required this.tongTien,
    required this.maVe,
    required this.trangThaiThanhToan,
    required this.createdAt,
    required this.updatedAt,
    this.diemDi,
    this.diemDen,
    this.thoiGianKhoiHanh,
  });

  // Getter để tương thích với code cũ
  int get soLuong => danhSachGhe.length;
  String get trangThai => trangThaiThanhToan;

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['_id'] ?? '',
      userId: json['userId'] ?? '',
      tripId: json['tripId'] is String
          ? json['tripId']
          : (json['tripId']?['_id'] ?? ''),
      danhSachGhe: List<String>.from(json['danhSachGhe'] ?? []),
      tongTien: json['tongTien'] ?? 0,
      maVe: json['maVe'] ?? '',
      trangThaiThanhToan: json['trangThaiThanhToan'] ?? 'chua_thanh_toan',
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
      // Thông tin từ populate tripId
      diemDi: json['tripId'] is Map ? json['tripId']['diemDi'] : null,
      diemDen: json['tripId'] is Map ? json['tripId']['diemDen'] : null,
      thoiGianKhoiHanh:
          json['tripId'] is Map && json['tripId']['thoiGianKhoiHanh'] != null
          ? DateTime.parse(json['tripId']['thoiGianKhoiHanh'])
          : null,
    );
  }
}
