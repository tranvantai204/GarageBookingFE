import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'driver_profile_update_screen.dart';
import 'admin_user_management_screen.dart';
import '../utils/event_bus.dart';
import 'wallet_screen.dart';
import 'driver_apply_screen.dart';
import '../theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileScreen extends StatefulWidget {
  final bool showAppBar;

  const ProfileScreen({super.key, this.showAppBar = true});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userName = '';
  String _userRole = '';
  String _userPhone = '';
  int _walletBalance = 0;
  bool _autoOpenChatOnForeground = true;
  bool _showAdminTicker = true;
  bool _callSystemPopupOnly = false;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    EventBus().stream.listen((event) {
      if (event == Events.walletUpdated) _loadUserInfo();
    });
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('hoTen') ?? '';
      _userRole = prefs.getString('vaiTro') ?? 'user';
      _userPhone = prefs.getString('soDienThoai') ?? '';
      _walletBalance = prefs.getInt('viSoDu') ?? 0;
      _autoOpenChatOnForeground = prefs.getBool('autoOpenChatOnForeground') ?? true;
      _showAdminTicker = prefs.getBool('showAdminTicker') ?? true;
      _callSystemPopupOnly = prefs.getBool('callSystemPopupOnly') ?? false;
    });
  }

  String _getRoleDisplayName() {
    switch (_userRole) {
      case 'admin': return 'QUẢN TRỊ VIÊN';
      case 'driver':
      case 'tai_xe': return 'TÀI XẾ';
      case 'user':
      default: return 'KHÁCH HÀNG';
    }
  }

  Color _getRoleColor() {
    switch (_userRole) {
      case 'admin': return AppTheme.error;
      case 'driver':
      case 'tai_xe': return AppTheme.info;
      case 'user':
      default: return AppTheme.success;
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Xác nhận đăng xuất',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Bạn có chắc chắn muốn đăng xuất không?',
          style: GoogleFonts.inter(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Đã đăng xuất thành công'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (_) {
      if (mounted) Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = SingleChildScrollView(
      child: Column(
        children: [
          // ─── Hero Header ────────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: AppTheme.primaryGradient,
            ),
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
            child: Column(
              children: [
                // Avatar
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(
                    _userRole == 'admin'
                        ? Icons.admin_panel_settings_rounded
                        : _userRole == 'driver' || _userRole == 'tai_xe'
                            ? Icons.drive_eta_rounded
                            : Icons.person_rounded,
                    size: 44,
                    color: _getRoleColor(),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  _userName.isNotEmpty ? _userName : 'Người dùng',
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(AppTheme.radiusRound),
                    border: Border.all(color: Colors.white.withOpacity(0.4)),
                  ),
                  child: Text(
                    _getRoleDisplayName(),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                if (_userPhone.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.phone_rounded,
                        size: 13,
                        color: Colors.white.withOpacity(0.8),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _userPhone,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                // Wallet balance card
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.account_balance_wallet_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Số dư ví: ',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.85),
                        ),
                      ),
                      Text(
                        '${_formatCurrency(_walletBalance)}đ',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ─── Menu Sections ──────────────────────────────────────────
          const SizedBox(height: 16),

          // Tài khoản section
          _sectionTitle('Tài khoản'),
          _menuCard([
            _menuItem(
              icon: Icons.account_balance_wallet_rounded,
              iconColor: const Color(0xFF0D9488),
              title: 'Ví của tôi',
              subtitle: 'Số dư: ${_formatCurrency(_walletBalance)}đ',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WalletScreen()),
              ).then((_) => _loadUserInfo()),
            ),
            if (_userRole == 'user') ...[
              _divider(),
              _menuItem(
                icon: Icons.drive_eta_rounded,
                iconColor: const Color(0xFF3B82F6),
                title: 'Đăng ký làm tài xế',
                subtitle: 'Trở thành đối tác lái xe',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DriverApplyScreen()),
                ),
              ),
            ],
            _divider(),
            _menuItem(
              icon: Icons.history_rounded,
              iconColor: const Color(0xFFF59E0B),
              title: 'Lịch sử đặt vé',
              subtitle: 'Xem các vé đã đặt',
              onTap: () => Navigator.pushNamed(context, '/booking_history'),
            ),
          ]),

          if (_userRole == 'admin') ...[
            _sectionTitle('Quản trị'),
            _menuCard([
              _menuItem(
                icon: Icons.add_box_rounded,
                iconColor: const Color(0xFF10B981),
                title: 'Tạo chuyến đi',
                subtitle: 'Thêm chuyến xe mới',
                onTap: () => Navigator.pushNamed(context, '/create_trip'),
              ),
              _divider(),
              _menuItem(
                icon: Icons.people_rounded,
                iconColor: const Color(0xFF6366F1),
                title: 'Quản lý người dùng',
                subtitle: 'Xem và quản lý tài khoản',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminUserManagementScreen(),
                  ),
                ),
              ),
            ]),
          ],

          if (_userRole == 'driver' || _userRole == 'tai_xe') ...[
            _sectionTitle('Tài xế'),
            _menuCard([
              _menuItem(
                icon: Icons.edit_rounded,
                iconColor: const Color(0xFF3B82F6),
                title: 'Cập nhật thông tin tài xế',
                subtitle: 'Chỉnh sửa hồ sơ lái xe',
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const DriverProfileUpdateScreen(),
                    ),
                  );
                  if (result == true) _loadUserInfo();
                },
              ),
              _divider(),
              _menuItem(
                icon: Icons.qr_code_scanner_rounded,
                iconColor: const Color(0xFF0D9488),
                title: 'Quét mã QR',
                subtitle: 'Xác nhận vé hành khách',
                onTap: () => Navigator.pushNamed(context, '/qr_scanner'),
              ),
            ]),
          ],

          _sectionTitle('Cài đặt'),
          _menuCard([
            _switchItem(
              icon: Icons.chat_bubble_outline_rounded,
              iconColor: const Color(0xFF8B5CF6),
              title: 'Tự mở chat khi có tin nhắn',
              subtitle: 'Khi app đang mở',
              value: _autoOpenChatOnForeground,
              onChanged: (v) async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('autoOpenChatOnForeground', v);
                setState(() => _autoOpenChatOnForeground = v);
                EventBus().emit(Events.settingsChanged);
              },
            ),
            _divider(),
            _switchItem(
              icon: Icons.campaign_outlined,
              iconColor: const Color(0xFFF59E0B),
              title: 'Hiển thị ticker thông báo',
              subtitle: 'Thanh thông báo Admin',
              value: _showAdminTicker,
              onChanged: (v) async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('showAdminTicker', v);
                setState(() => _showAdminTicker = v);
                EventBus().emit(Events.settingsChanged);
              },
            ),
            _divider(),
            _switchItem(
              icon: Icons.call_rounded,
              iconColor: const Color(0xFFEF4444),
              title: 'Popup hệ thống cho cuộc gọi',
              subtitle: 'Tránh đơ máy khi hiển thị overlay',
              value: _callSystemPopupOnly,
              onChanged: (v) async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('callSystemPopupOnly', v);
                setState(() => _callSystemPopupOnly = v);
              },
            ),
          ]),

          _sectionTitle('Khác'),
          _menuCard([
            _menuItem(
              icon: Icons.info_outline_rounded,
              iconColor: const Color(0xFF6B7280),
              title: 'Thông tin ứng dụng',
              subtitle: 'v1.0.0 · Nhà xe Hà Phương',
              onTap: () => showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(
                    'Thông tin ứng dụng',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ứng dụng đặt xe Hà Phương',
                          style: GoogleFonts.inter()),
                      Text('Phiên bản: 1.0.0', style: GoogleFonts.inter()),
                      Text('Phát triển bởi: Tran Van Tai Development',
                          style: GoogleFonts.inter()),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Đóng'),
                    ),
                  ],
                ),
              ),
            ),
          ]),

          // Logout button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: Text(
                  'Đăng xuất',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.error,
                  side: BorderSide(color: AppTheme.error.withOpacity(0.5), width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusXXL),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (widget.showAppBar) {
      return Scaffold(
        appBar: AppBar(title: const Text('Tài khoản')),
        body: content,
      );
    }
    return content;
  }

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Text(
          title.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppTheme.textTertiary,
            letterSpacing: 0.8,
          ),
        ),
      );

  Widget _menuCard(List<Widget> children) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
          boxShadow: AppTheme.shadowCard,
        ),
        child: Column(children: children),
      );

  Widget _divider() => const Divider(height: 1, indent: 56, endIndent: 16);

  Widget _menuItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusLG),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.textTertiary,
                      ),
                    ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.textTertiary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _switchItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppTheme.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }
}
