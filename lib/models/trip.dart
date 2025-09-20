import '../utils/date_utils.dart';

class Seat {
  final String tenGhe;
  final String trangThai; // 'trong', 'dadat'
  final int giaVe;

  Seat({required this.tenGhe, required this.trangThai, required this.giaVe});

  factory Seat.fromJson(Map<String, dynamic> json) {
    return Seat(
      tenGhe: json['tenGhe'] ?? '',
      trangThai: json['trangThai'] ?? 'trong',
      giaVe: json['giaVe'] ?? 0,
    );
  }
}

class Trip {
  final String id;
  final String nhaXe;
  final String diemDi;
  final String diemDen;
  final DateTime thoiGianKhoiHanh;
  final int soGhe;
  final List<Seat> danhSachGhe;
  final String taiXe;
  final String? taiXeId;
  final String bienSoXe;
  final String? loaiXe;
  final DateTime? gioKetThuc;
  final DateTime createdAt;
  final DateTime updatedAt;

  Trip({
    required this.id,
    required this.nhaXe,
    required this.diemDi,
    required this.diemDen,
    required this.thoiGianKhoiHanh,
    required this.soGhe,
    required this.danhSachGhe,
    required this.taiXe,
    this.taiXeId,
    required this.bienSoXe,
    this.loaiXe,
    this.gioKetThuc,
    required this.createdAt,
    required this.updatedAt,
  });

  // Getter để lấy giá vé từ ghế đầu tiên (giả sử tất cả ghế cùng giá)
  int get giaVe => danhSachGhe.isNotEmpty ? danhSachGhe.first.giaVe : 0;

  // Getter để lấy số ghế còn trống
  int get soGheTrong =>
      danhSachGhe.where((ghe) => ghe.trangThai == 'trong').length;

  // Getter để lấy tổng số ghế
  int get tongSoGhe => soGhe;

  // Getter để format thời gian khởi hành
  String get gioKhoiHanh {
    return AppDateUtils.formatVietnameseTime(thoiGianKhoiHanh);
  }

  // Getter để format ngày khởi hành
  String get ngayKhoiHanh {
    return AppDateUtils.formatVietnameseDate(thoiGianKhoiHanh);
  }

  factory Trip.fromJson(Map<String, dynamic> json) {
    try {
      return Trip(
        id: json['_id'] ?? '',
        nhaXe: json['nhaXe'] ?? 'Hà Phương',
        diemDi: json['diemDi'] ?? '',
        diemDen: json['diemDen'] ?? '',
        thoiGianKhoiHanh: AppDateUtils.safeParseDate(json['thoiGianKhoiHanh']),
        soGhe: json['soGhe'] ?? 0,
        danhSachGhe:
            (json['danhSachGhe'] as List<dynamic>?)
                ?.map((seat) => Seat.fromJson(seat))
                .toList() ??
            [],
        taiXe: json['taiXe'] ?? 'Chưa cập nhật',
        taiXeId: json['taiXeId']?.toString(),
        bienSoXe: json['bienSoXe'] ?? 'Chưa cập nhật',
        loaiXe: json['loaiXe'] ?? 'ghe_ngoi',
        gioKetThuc: json['gioKetThuc'] != null
            ? AppDateUtils.safeParseDate(json['gioKetThuc'])
            : null,
        createdAt: AppDateUtils.safeParseDate(json['createdAt']),
        updatedAt: AppDateUtils.safeParseDate(json['updatedAt']),
      );
    } catch (e) {
      print('❌ Error parsing Trip from JSON: $e');
      print('📄 JSON data: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'nhaXe': nhaXe,
      'diemDi': diemDi,
      'diemDen': diemDen,
      'thoiGianKhoiHanh': thoiGianKhoiHanh.toIso8601String(),
      'soGhe': soGhe,
      'danhSachGhe': danhSachGhe
          .map(
            (seat) => {
              'tenGhe': seat.tenGhe,
              'trangThai': seat.trangThai,
              'giaVe': seat.giaVe,
            },
          )
          .toList(),
      'taiXe': taiXe,
      'bienSoXe': bienSoXe,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
