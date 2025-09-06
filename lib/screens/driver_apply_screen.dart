import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/driver_application_service.dart';

class DriverApplyScreen extends StatefulWidget {
  const DriverApplyScreen({super.key});

  @override
  State<DriverApplyScreen> createState() => _DriverApplyScreenState();
}

class _DriverApplyScreenState extends State<DriverApplyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  String? _gplxUrl;
  String? _cccdUrl;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _prefill();
  }

  Future<void> _prefill() async {
    final prefs = await SharedPreferences.getInstance();
    _nameCtrl.text = prefs.getString('hoTen') ?? '';
    _phoneCtrl.text = prefs.getString('soDienThoai') ?? '';
    _emailCtrl.text = prefs.getString('email') ?? '';
    setState(() {});
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  // Upload ảnh đã bỏ theo yêu cầu

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    // Ảnh giấy tờ không bắt buộc nữa theo yêu cầu
    setState(() => _submitting = true);
    try {
      final resp = await DriverApplicationService.submit(
        hoTen: _nameCtrl.text.trim(),
        soDienThoai: _phoneCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        gplxUrl: _gplxUrl,
        cccdUrl: _cccdUrl,
        note: _noteCtrl.text.trim(),
      );
      if (resp['success'] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã gửi đơn, vui lòng chờ Admin xét duyệt'),
          ),
        );
        Navigator.pop(context, true);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resp['message'] ?? 'Gửi đơn thất bại'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng ký làm tài xế'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth < 420
              ? constraints.maxWidth
              : 420.0;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Thông tin cá nhân',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _nameCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Họ và tên',
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Nhập họ tên'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _phoneCtrl,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Số điện thoại',
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Nhập số điện thoại'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            autocorrect: false,
                            textCapitalization: TextCapitalization.none,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                            ),
                            validator: (v) {
                              final value = (v ?? '').trim();
                              if (value.isEmpty) return 'Nhập email';
                              final emailRegex = RegExp(
                                r'^[\w.+\-]+@[\w\-]+(\.[\w\-]+)+$',
                              );
                              return emailRegex.hasMatch(value)
                                  ? null
                                  : 'Email không hợp lệ';
                            },
                          ),
                          const SizedBox(height: 16),
                          // Bỏ phần upload ảnh theo yêu cầu
                          const SizedBox(height: 16),
                          const Text(
                            'Mô tả/Lý do',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _noteCtrl,
                            maxLines: 4,
                            decoration: const InputDecoration(
                              hintText:
                                  'Kinh nghiệm lái xe, thời gian rảnh, lý do muốn làm tài xế...',
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _submitting ? null : _submit,
                              icon: const Icon(Icons.send),
                              label: Text(
                                _submitting ? 'Đang gửi...' : 'Gửi đơn',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
