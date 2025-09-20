import '../utils/date_utils.dart';

class Booking {
  final String id;
  final String userId;
  final String tripId;
  final List<String> danhSachGhe;
  final int tongTien;
  final String maVe;
  final String trangThaiThanhToan;
  final String? qrCode;
  final String trangThaiCheckIn;
  final DateTime? thoiGianCheckIn;
  final String? nguoiCheckIn;
  final String loaiDiemDon; // 'ben_xe' hoặc 'dia_chi_cu_the'
  final String? diaChiDon; // Địa chỉ cụ thể nếu chọn 'dia_chi_cu_the'
  final String? ghiChuDiemDon; // Ghi chú thêm về điểm đón
  final DateTime createdAt;
  final DateTime updatedAt;

  // Thông tin chuyến đi (từ populate)
  final String? diemDi;
  final String? diemDen;
  final DateTime? thoiGianKhoiHanh;
  final String? taiXe;
  final String? taiXeId;
  final String? bienSoXe;
  final String? loaiXe;
  final List<String> vehicleImages;

  Booking({
    required this.id,
    required this.userId,
    required this.tripId,
    required this.danhSachGhe,
    required this.tongTien,
    required this.maVe,
    required this.trangThaiThanhToan,
    required this.trangThaiCheckIn,
    this.loaiDiemDon = 'ben_xe',
    required this.createdAt,
    required this.updatedAt,
    this.qrCode,
    this.thoiGianCheckIn,
    this.nguoiCheckIn,
    this.diaChiDon,
    this.ghiChuDiemDon,
    this.diemDi,
    this.diemDen,
    this.thoiGianKhoiHanh,
    this.taiXe,
    this.taiXeId,
    this.bienSoXe,
    this.loaiXe,
    this.vehicleImages = const [],
  });

  // Getter để tương thích với code cũ
  int get soLuong => danhSachGhe.length;
  String get trangThai => trangThaiThanhToan;

  factory Booking.fromJson(Map<String, dynamic> json) {
    try {
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
        trangThaiCheckIn: json['trangThaiCheckIn'] ?? 'chua_check_in',
        loaiDiemDon: json['loaiDiemDon'] ?? 'ben_xe',
        qrCode: json['qrCode'],
        thoiGianCheckIn: json['thoiGianCheckIn'] != null
            ? AppDateUtils.safeParseDate(json['thoiGianCheckIn'])
            : null,
        nguoiCheckIn: json['nguoiCheckIn'],
        diaChiDon: json['diaChiDon'],
        ghiChuDiemDon: json['ghiChuDiemDon'],
        createdAt: AppDateUtils.safeParseDate(json['createdAt']),
        updatedAt: AppDateUtils.safeParseDate(json['updatedAt']),
        // Thông tin từ populate tripId
        diemDi: json['tripId'] is Map ? json['tripId']['diemDi'] : null,
        diemDen: json['tripId'] is Map ? json['tripId']['diemDen'] : null,
        thoiGianKhoiHanh:
            json['tripId'] is Map && json['tripId']['thoiGianKhoiHanh'] != null
            ? AppDateUtils.safeParseDate(json['tripId']['thoiGianKhoiHanh'])
            : null,
        taiXe: json['tripId'] is Map ? json['tripId']['taiXe'] : null,
        taiXeId: json['tripId'] is Map ? json['tripId']['taiXeId'] : null,
        bienSoXe: json['tripId'] is Map ? json['tripId']['bienSoXe'] : null,
        loaiXe: json['tripId'] is Map ? json['tripId']['loaiXe'] : null,
        vehicleImages:
            json['vehicleSnapshot'] is Map &&
                json['vehicleSnapshot']['hinhAnh'] is List
            ? List<String>.from(json['vehicleSnapshot']['hinhAnh'])
            : (json['tripId'] is Map &&
                      json['tripId']['vehicleInfo'] is Map &&
                      json['tripId']['vehicleInfo']['hinhAnh'] is List
                  ? List<String>.from(json['tripId']['vehicleInfo']['hinhAnh'])
                  : const []),
      );
    } catch (e) {
      print('❌ Error parsing Booking from JSON: $e');
      print('📄 JSON data: $json');
      rethrow;
    }
  }
}
