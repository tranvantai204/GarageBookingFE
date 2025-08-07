import 'package:flutter/material.dart';

class PriceManagementScreen extends StatefulWidget {
  const PriceManagementScreen({super.key});

  @override
  State<PriceManagementScreen> createState() => _PriceManagementScreenState();
}

class _PriceManagementScreenState extends State<PriceManagementScreen> {
  final List<RoutePrice> _routePrices = [
    RoutePrice(
      id: '1',
      diemDi: 'TP.HCM',
      diemDen: 'Bình Thuận',
      giaGheNgoi: 250000,
      giaGiuongNam: 350000,
      giaLimousine: 450000,
      khoangCach: 200,
      thoiGianDi: 4.5,
      isActive: true,
    ),
    RoutePrice(
      id: '2',
      diemDi: 'TP.HCM',
      diemDen: 'Đà Lạt',
      giaGheNgoi: 300000,
      giaGiuongNam: 400000,
      giaLimousine: 500000,
      khoangCach: 300,
      thoiGianDi: 6.0,
      isActive: true,
    ),
    RoutePrice(
      id: '3',
      diemDi: 'Bình Thuận',
      diemDen: 'Nha Trang',
      giaGheNgoi: 200000,
      giaGiuongNam: 280000,
      giaLimousine: 380000,
      khoangCach: 150,
      thoiGianDi: 3.5,
      isActive: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý giá vé'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addRoute,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.orange.shade50, Colors.white],
          ),
        ),
        child: Column(
          children: [
            _buildPriceOverview(),
            Expanded(
              child: _buildRouteList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceOverview() {
    final avgGheNgoi = _routePrices.fold(0, (sum, route) => sum + route.giaGheNgoi) / _routePrices.length;
    final avgGiuongNam = _routePrices.fold(0, (sum, route) => sum + route.giaGiuongNam) / _routePrices.length;
    final avgLimousine = _routePrices.fold(0, (sum, route) => sum + route.giaLimousine) / _routePrices.length;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tổng quan giá vé',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildPriceCard(
                  'Ghế ngồi',
                  '${_formatCurrency(avgGheNgoi.round())}đ',
                  Icons.event_seat,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPriceCard(
                  'Giường nằm',
                  '${_formatCurrency(avgGiuongNam.round())}đ',
                  Icons.airline_seat_flat,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPriceCard(
                  'Limousine',
                  '${_formatCurrency(avgLimousine.round())}đ',
                  Icons.airport_shuttle,
                  Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceCard(String title, String price, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              price,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _routePrices.length,
      itemBuilder: (context, index) {
        final route = _routePrices[index];
        return _buildRouteCard(route);
      },
    );
  }

  Widget _buildRouteCard(RoutePrice route) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _editRoute(route),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.route,
                      color: Colors.orange,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${route.diemDi} → ${route.diemDen}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${route.khoangCach}km • ${route.thoiGianDi}h',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: route.isActive ? Colors.green.shade100 : Colors.red.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      route.isActive ? 'Hoạt động' : 'Tạm dừng',
                      style: TextStyle(
                        color: route.isActive ? Colors.green.shade700 : Colors.red.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildPriceItem('Ghế ngồi', route.giaGheNgoi, Colors.blue),
                        _buildPriceItem('Giường nằm', route.giaGiuongNam, Colors.green),
                        _buildPriceItem('Limousine', route.giaLimousine, Colors.purple),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _editRoute(route),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Sửa giá'),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => _toggleRouteStatus(route),
                    icon: Icon(
                      route.isActive ? Icons.pause : Icons.play_arrow,
                      size: 16,
                    ),
                    label: Text(route.isActive ? 'Tạm dừng' : 'Kích hoạt'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriceItem(String type, int price, Color color) {
    return Column(
      children: [
        Text(
          type,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 4),
        Text(
          '${_formatCurrency(price)}đ',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  void _addRoute() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thêm tuyến mới'),
        content: const Text('Chức năng thêm tuyến đang phát triển'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _editRoute(RoutePrice route) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Chỉnh sửa giá vé\n${route.diemDi} → ${route.diemDen}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPriceEditField('Ghế ngồi', route.giaGheNgoi),
            _buildPriceEditField('Giường nằm', route.giaGiuongNam),
            _buildPriceEditField('Limousine', route.giaLimousine),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cập nhật giá thành công')),
              );
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceEditField(String label, int currentPrice) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        initialValue: currentPrice.toString(),
        decoration: InputDecoration(
          labelText: label,
          suffixText: 'đ',
          border: const OutlineInputBorder(),
        ),
        keyboardType: TextInputType.number,
      ),
    );
  }

  void _toggleRouteStatus(RoutePrice route) {
    setState(() {
      route.isActive = !route.isActive;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          route.isActive 
              ? 'Đã kích hoạt tuyến ${route.diemDi} → ${route.diemDen}'
              : 'Đã tạm dừng tuyến ${route.diemDi} → ${route.diemDen}',
        ),
      ),
    );
  }
}

class RoutePrice {
  final String id;
  final String diemDi;
  final String diemDen;
  final int giaGheNgoi;
  final int giaGiuongNam;
  final int giaLimousine;
  final int khoangCach;
  final double thoiGianDi;
  bool isActive;

  RoutePrice({
    required this.id,
    required this.diemDi,
    required this.diemDen,
    required this.giaGheNgoi,
    required this.giaGiuongNam,
    required this.giaLimousine,
    required this.khoangCach,
    required this.thoiGianDi,
    this.isActive = true,
  });
}
