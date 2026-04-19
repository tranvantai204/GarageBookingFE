import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/booking.dart';
import '../theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class BookingCard extends StatelessWidget {
  final Booking booking;
  final VoidCallback? onTap;
  final VoidCallback? onCancel;
  final VoidCallback? onShowQR;

  const BookingCard({
    super.key,
    required this.booking,
    this.onTap,
    this.onCancel,
    this.onShowQR,
  });

  @override
  Widget build(BuildContext context) {
    final isPaid = booking.trangThaiThanhToan == 'da_thanh_toan';
    final isExpired = booking.thoiGianKhoiHanh != null &&
        booking.thoiGianKhoiHanh!.isBefore(DateTime.now());

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
            children: [
              // ─── Header ─────────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                decoration: BoxDecoration(
                  gradient: isExpired
                      ? const LinearGradient(
                          colors: [Color(0xFF6B7280), Color(0xFF9CA3AF)],
                        )
                      : AppTheme.primaryGradient,
                ),
                child: Row(
                  children: [
                    // Route info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (booking.diemDi != null && booking.diemDen != null)
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    booking.diemDi!,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 6),
                                  child: Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 14,
                                    color: Colors.white.withOpacity(0.85),
                                  ),
                                ),
                                Flexible(
                                  child: Text(
                                    booking.diemDen!,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 2),
                          Text(
                            booking.thoiGianKhoiHanh != null
                                ? DateFormat('dd/MM/yyyy HH:mm')
                                    .format(booking.thoiGianKhoiHanh!)
                                : 'Chưa có thông tin giờ',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.88),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Status badge
                    _buildStatusChip(),
                  ],
                ),
              ),
              // ─── Body ───────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                child: Column(
                  children: [
                    // Info row
                    Row(
                      children: [
                        _infoItem(
                          Icons.confirmation_number_rounded,
                          booking.maVe,
                        ),
                        const SizedBox(width: 8),
                        _infoItem(
                          Icons.event_seat_rounded,
                          '${booking.danhSachGhe.length} ghế',
                        ),
                        const Spacer(),
                        Text(
                          '${_formatCurrency(booking.tongTien)}đ',
                          style: GoogleFonts.inter(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                    // Seat list
                    if (booking.danhSachGhe.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Ghế: ${booking.danhSachGhe.join(", ")}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ],
                    // Action buttons
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (onShowQR != null)
                          Expanded(
                            child: SizedBox(
                              height: 38,
                              child: ElevatedButton.icon(
                                onPressed: onShowQR,
                                icon: const Icon(
                                  Icons.qr_code_rounded,
                                  size: 16,
                                ),
                                label: Text(
                                  'Xem QR',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primary,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        if (onShowQR != null &&
                            onCancel != null &&
                            _canCancelBooking())
                          const SizedBox(width: 10),
                        if (onCancel != null && _canCancelBooking())
                          Expanded(
                            child: SizedBox(
                              height: 38,
                              child: OutlinedButton.icon(
                                onPressed: onCancel,
                                icon: const Icon(
                                  Icons.cancel_outlined,
                                  size: 16,
                                ),
                                label: Text(
                                  'Hủy vé',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.error,
                                  side: BorderSide(
                                    color: AppTheme.error.withOpacity(0.6),
                                  ),
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
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

  Widget _infoItem(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(AppTheme.radiusSM),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppTheme.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip() {
    Color color;
    String text;
    IconData icon;

    switch (booking.trangThaiThanhToan) {
      case 'da_thanh_toan':
        color = AppTheme.success;
        text = 'Đã TT';
        icon = Icons.check_circle_rounded;
        break;
      case 'chua_thanh_toan':
        color = AppTheme.warning;
        text = 'Chưa TT';
        icon = Icons.access_time_rounded;
        break;
      default:
        color = AppTheme.textTertiary;
        text = 'N/A';
        icon = Icons.help_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(AppTheme.radiusRound),
        border: Border.all(color: Colors.white.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  bool _canCancelBooking() {
    if (booking.thoiGianKhoiHanh == null) return false;
    final now = DateTime.now();
    final departureTime = booking.thoiGianKhoiHanh!;
    if (departureTime.isBefore(now)) return false;
    if (now.isAfter(departureTime.subtract(const Duration(hours: 2)))) {
      return false;
    }
    if (booking.trangThaiThanhToan == 'da_thanh_toan') return false;
    return true;
  }
}
