import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final TextEditingController _manualCodeController = TextEditingController();
  bool _isScanning = false;
  String _scannedCode = '';

  @override
  void dispose() {
    _manualCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quét mã QR'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelp,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green.shade50, Colors.white],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInstructions(),
              const SizedBox(height: 24),
              _buildQRScannerArea(),
              const SizedBox(height: 24),
              _buildManualInput(),
              const SizedBox(height: 24),
              _buildRecentScans(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.green.withOpacity(0.1), Colors.green.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.info, color: Colors.green, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Hướng dẫn sử dụng',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              '1. Yêu cầu hành khách xuất trình mã QR trên vé điện tử\n'
              '2. Nhấn "Bắt đầu quét" để mở camera\n'
              '3. Hướng camera vào mã QR để quét\n'
              '4. Hoặc nhập mã thủ công nếu không quét được',
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQRScannerArea() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green, width: 2),
                borderRadius: BorderRadius.circular(12),
                color: _isScanning ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
              ),
              child: _isScanning
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(color: Colors.green),
                        const SizedBox(height: 16),
                        const Text(
                          'Đang quét...',
                          style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _stopScanning,
                          child: const Text('Dừng quét'),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.qr_code_scanner,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Vùng quét QR',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isScanning ? null : _startScanning,
                icon: Icon(_isScanning ? Icons.stop : Icons.qr_code_scanner),
                label: Text(_isScanning ? 'Đang quét...' : 'Bắt đầu quét'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManualInput() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nhập mã thủ công',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _manualCodeController,
              decoration: InputDecoration(
                hintText: 'Nhập mã vé (VD: HP240115001)',
                prefixIcon: const Icon(Icons.edit),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => _manualCodeController.clear(),
                ),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pasteFromClipboard,
                    icon: const Icon(Icons.paste),
                    label: const Text('Dán từ clipboard'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _validateManualCode,
                    icon: const Icon(Icons.check),
                    label: const Text('Xác nhận'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentScans() {
    final recentScans = [
      {'code': 'HP240115001', 'passenger': 'Nguyễn Văn A', 'time': '08:30', 'status': 'success'},
      {'code': 'HP240115002', 'passenger': 'Trần Thị B', 'time': '08:25', 'status': 'success'},
      {'code': 'HP240115003', 'passenger': 'Lê Văn C', 'time': '08:20', 'status': 'error'},
    ];

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Lịch sử quét gần đây',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: _clearHistory,
                  child: const Text('Xóa tất cả'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (recentScans.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                child: const Center(
                  child: Text(
                    'Chưa có lịch sử quét',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              Column(
                children: recentScans.map((scan) => _buildScanHistoryItem(scan)).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanHistoryItem(Map<String, String> scan) {
    final isSuccess = scan['status'] == 'success';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSuccess ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSuccess ? Colors.green.shade200 : Colors.red.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isSuccess ? Colors.green : Colors.red,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              isSuccess ? Icons.check : Icons.close,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  scan['code']!,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  scan['passenger']!,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            scan['time']!,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _startScanning() {
    setState(() {
      _isScanning = true;
    });

    // Simulate scanning process
    Future.delayed(const Duration(seconds: 3), () {
      if (_isScanning) {
        _simulateSuccessfulScan();
      }
    });
  }

  void _stopScanning() {
    setState(() {
      _isScanning = false;
    });
  }

  void _simulateSuccessfulScan() {
    setState(() {
      _isScanning = false;
      _scannedCode = 'HP240115004';
    });

    _processScannedCode(_scannedCode);
  }

  void _validateManualCode() {
    final code = _manualCodeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập mã vé'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    _processScannedCode(code);
  }

  void _processScannedCode(String code) {
    // Simulate ticket validation
    final isValid = code.startsWith('HP') && code.length >= 8;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isValid ? Icons.check_circle : Icons.error,
              color: isValid ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            Text(isValid ? 'Vé hợp lệ' : 'Vé không hợp lệ'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mã vé: $code'),
            if (isValid) ...[
              const SizedBox(height: 8),
              const Text('Hành khách: Nguyễn Văn D'),
              const Text('Chuyến: TP.HCM → Bình Thuận'),
              const Text('Ghế: A12'),
              const Text('Trạng thái: Chưa lên xe'),
            ] else ...[
              const SizedBox(height: 8),
              const Text(
                'Vé không tồn tại hoặc đã được sử dụng',
                style: TextStyle(color: Colors.red),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
          if (isValid)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _confirmBoarding(code);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Xác nhận lên xe'),
            ),
        ],
      ),
    );
  }

  void _confirmBoarding(String code) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã xác nhận hành khách lên xe - Mã: $code'),
        backgroundColor: Colors.green,
        action: SnackBarAction(
          label: 'Hoàn tác',
          textColor: Colors.white,
          onPressed: () {
            // Undo boarding confirmation
          },
        ),
      ),
    );

    // Clear manual input
    _manualCodeController.clear();
  }

  void _pasteFromClipboard() async {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    if (clipboardData?.text != null) {
      _manualCodeController.text = clipboardData!.text!;
    }
  }

  void _clearHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa lịch sử'),
        content: const Text('Bạn có chắc chắn muốn xóa tất cả lịch sử quét?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã xóa lịch sử quét')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hướng dẫn chi tiết'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Cách sử dụng máy quét QR:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('1. Yêu cầu hành khách mở ứng dụng và hiển thị mã QR'),
              Text('2. Nhấn "Bắt đầu quét" để kích hoạt camera'),
              Text('3. Hướng camera vào mã QR, giữ ổn định'),
              Text('4. Đợi hệ thống xử lý và hiển thị kết quả'),
              SizedBox(height: 12),
              Text(
                'Nhập mã thủ công:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Sử dụng khi không thể quét được QR'),
              Text('• Mã vé có định dạng: HP + ngày + số thứ tự'),
              Text('• VD: HP240115001 (HP + 24/01/15 + 001)'),
              SizedBox(height: 12),
              Text(
                'Lưu ý:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Mỗi mã QR chỉ được sử dụng một lần'),
              Text('• Kiểm tra thông tin hành khách trước khi xác nhận'),
              Text('• Báo cáo ngay nếu có vé giả hoặc lỗi hệ thống'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đã hiểu'),
          ),
        ],
      ),
    );
  }
}
