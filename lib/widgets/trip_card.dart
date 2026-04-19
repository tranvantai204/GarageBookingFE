import 'package:flutter/material.dart';
import '../models/trip.dart';
import '../theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class TripCard extends StatelessWidget {
  final Trip trip;
  final VoidCallback onTap;
  final bool isAdmin;
  final VoidCallback? onDelete;

  const TripCard({
    super.key,
    required this.trip,
    required this.onTap,
    this.isAdmin = false,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final seatsLeft = trip.soGheTrong;
    final isLowSeats = seatsLeft > 0 && seatsLeft <= 5;
    final isFull = seatsLeft == 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
          boxShadow: AppTheme.shadowCard,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Header gradient ───────────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                decoration: const BoxDecoration(
                  gradient: AppTheme.cardGradient,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Route icon
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.directions_bus_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Route name
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      trip.diemDi,
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 6),
                                    child: Icon(
                                      Icons.arrow_forward_rounded,
                                      color: Colors.white.withOpacity(0.85),
                                      size: 14,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      trip.diemDen,
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${trip.gioKhoiHanh} · ${trip.ngayKhoiHanh}',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.88),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Seat indicator row
                    Row(
                      children: [
                        // Seat status badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isFull
                                ? Colors.red.withOpacity(0.85)
                                : isLowSeats
                                    ? Colors.orange.withOpacity(0.85)
                                    : Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(AppTheme.radiusRound),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isFull
                                    ? Icons.block_rounded
                                    : Icons.event_seat_rounded,
                                size: 12,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isFull
                                    ? 'Hết chỗ'
                                    : isLowSeats
                                        ? 'Còn $seatsLeft chỗ'
                                        : '$seatsLeft chỗ trống',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        // Price
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(AppTheme.radiusRound),
                          ),
                          child: Text(
                            _formatPrice(trip.giaVe),
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primary,
                            ),
                          ),
                        ),
                        if (isAdmin && onDelete != null) ...[
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () => _showDeleteConfirmation(context),
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.85),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.delete_outline_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // ─── Body info ────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _infoChip(Icons.person_rounded, trip.taiXe),
                        const SizedBox(width: 8),
                        _infoChip(Icons.directions_car_rounded, trip.bienSoXe),
                        const SizedBox(width: 8),
                        _infoChip(
                          Icons.event_seat_outlined,
                          '${trip.tongSoGhe} ghế',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Book button
                    SizedBox(
                      width: double.infinity,
                      height: 42,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: isFull
                              ? const LinearGradient(
                                  colors: [Color(0xFF94A3B8), Color(0xFF94A3B8)])
                              : AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                        ),
                        child: ElevatedButton(
                          onPressed: isFull ? null : onTap,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                            ),
                          ),
                          child: Text(
                            isFull ? 'Hết chỗ' : 'Xem chi tiết & Đặt vé',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.circular(AppTheme.radiusSM),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: AppTheme.textSecondary),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatPrice(num price) {
    return '${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}đ';
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Bạn có chắc chắn muốn xóa chuyến đi này?'),
            const SizedBox(height: 8),
            Text(
              '${trip.diemDi} → ${trip.diemDen}',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
            Text(
              '${trip.gioKhoiHanh} · ${trip.ngayKhoiHanh}',
              style: GoogleFonts.inter(color: AppTheme.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              onDelete?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}
