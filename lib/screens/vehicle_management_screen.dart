import 'package:flutter/material.dart';
import '../models/vehicle.dart';

class VehicleManagementScreen extends StatefulWidget {
  const VehicleManagementScreen({super.key});

  @override
  State<VehicleManagementScreen> createState() => _VehicleManagementScreenState();
}

class _VehicleManagementScreenState extends State<VehicleManagementScreen> {
  String _selectedFilter = 'all';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Demo data
  final List<Vehicle> _vehicles = [
    Vehicle(
      id: '1',
      bienSoXe: '51A-12345',
      loaiXe: 'limousine',
      soGhe: 22,
      taiXeId: 'driver1',
      tenTaiXe: 'Nguyễn Văn A',
      trangThai: 'hoat_dong',
      ngayBaoTriCuoi: DateTime.now().subtract(const Duration(days: 30)),
      ngayBaoTriTiep: DateTime.now().add(const Duration(days: 60)),
      createdAt: DateTime.now().subtract(const Duration(days: 100)),
      updatedAt: DateTime.now(),
    ),
    Vehicle(
      id: '2',
      bienSoXe: '51B-67890',
      loaiXe: 'giuong_nam',
      soGhe: 40,
      taiXeId: 'driver2',
      tenTaiXe: 'Trần Văn B',
      trangThai: 'bao_tri',
      ngayBaoTriCuoi: DateTime.now().subtract(const Duration(days: 5)),
      ngayBaoTriTiep: DateTime.now().add(const Duration(days: 85)),
      createdAt: DateTime.now().subtract(const Duration(days: 80)),
      updatedAt: DateTime.now(),
    ),
    Vehicle(
      id: '3',
      bienSoXe: '51C-11111',
      loaiXe: 'ghe_ngoi',
      soGhe: 45,
      trangThai: 'hoat_dong',
      ngayBaoTriCuoi: DateTime.now().subtract(const Duration(days: 15)),
      ngayBaoTriTiep: DateTime.now().add(const Duration(days: 75)),
      createdAt: DateTime.now().subtract(const Duration(days: 60)),
      updatedAt: DateTime.now(),
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Vehicle> get _filteredVehicles {
    List<Vehicle> filtered = _vehicles;

    // Filter by status
    if (_selectedFilter != 'all') {
      filtered = filtered.where((vehicle) => vehicle.trangThai == _selectedFilter).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((vehicle) {
        return vehicle.bienSoXe.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               (vehicle.tenTaiXe?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý đội xe'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addVehicle,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: Column(
          children: [
            _buildSearchAndFilter(),
            _buildStatistics(),
            Expanded(
              child: _buildVehicleList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Tìm kiếm theo biển số, tài xế...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('all', 'Tất cả'),
                _buildFilterChip('hoat_dong', 'Hoạt động'),
                _buildFilterChip('bao_tri', 'Bảo trì'),
                _buildFilterChip('ngung_hoat_dong', 'Ngừng hoạt động'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedFilter = value;
          });
        },
        selectedColor: Colors.blue.shade100,
        checkmarkColor: Colors.blue,
      ),
    );
  }

  Widget _buildStatistics() {
    final totalVehicles = _vehicles.length;
    final activeVehicles = _vehicles.where((v) => v.trangThai == 'hoat_dong').length;
    final maintenanceVehicles = _vehicles.where((v) => v.trangThai == 'bao_tri').length;
    final needMaintenanceVehicles = _vehicles.where((v) => v.needMaintenance).length;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard('Tổng xe', totalVehicles.toString(), Icons.directions_bus, Colors.blue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard('Hoạt động', activeVehicles.toString(), Icons.check_circle, Colors.green),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard('Bảo trì', maintenanceVehicles.toString(), Icons.build, Colors.orange),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard('Cần bảo trì', needMaintenanceVehicles.toString(), Icons.warning, Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(12),
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
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleList() {
    final filteredVehicles = _filteredVehicles;

    if (filteredVehicles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.directions_bus, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty || _selectedFilter != 'all'
                  ? 'Không tìm thấy xe phù hợp'
                  : 'Chưa có xe nào',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredVehicles.length,
      itemBuilder: (context, index) {
        final vehicle = filteredVehicles[index];
        return _buildVehicleCard(vehicle);
      },
    );
  }

  Widget _buildVehicleCard(Vehicle vehicle) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _showVehicleDetail(vehicle),
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
                      color: _getStatusColor(vehicle.trangThai).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getVehicleIcon(vehicle.loaiXe),
                      color: _getStatusColor(vehicle.trangThai),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vehicle.bienSoXe,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${vehicle.loaiXeDisplayName} • ${vehicle.soGhe} ghế',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(vehicle.trangThai),
                ],
              ),
              const SizedBox(height: 16),
              if (vehicle.tenTaiXe != null) ...[
                Row(
                  children: [
                    const Icon(Icons.person, color: Colors.blue, size: 16),
                    const SizedBox(width: 8),
                    Text('Tài xế: ${vehicle.tenTaiXe}'),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              if (vehicle.ngayBaoTriTiep != null) ...[
                Row(
                  children: [
                    Icon(
                      Icons.build,
                      color: vehicle.needMaintenance ? Colors.red : Colors.orange,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Bảo trì tiếp: ${_formatDate(vehicle.ngayBaoTriTiep!)}',
                      style: TextStyle(
                        color: vehicle.needMaintenance ? Colors.red : Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _editVehicle(vehicle),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Sửa'),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => _deleteVehicle(vehicle),
                    icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                    label: const Text('Xóa', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color backgroundColor;
    Color textColor;
    String text;

    switch (status) {
      case 'hoat_dong':
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade700;
        text = 'Hoạt động';
        break;
      case 'bao_tri':
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade700;
        text = 'Bảo trì';
        break;
      case 'ngung_hoat_dong':
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade700;
        text = 'Ngừng hoạt động';
        break;
      default:
        backgroundColor = Colors.grey.shade100;
        textColor = Colors.grey.shade700;
        text = 'Không xác định';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'hoat_dong':
        return Colors.green;
      case 'bao_tri':
        return Colors.orange;
      case 'ngung_hoat_dong':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getVehicleIcon(String loaiXe) {
    switch (loaiXe) {
      case 'limousine':
        return Icons.airport_shuttle;
      case 'giuong_nam':
        return Icons.airline_seat_flat;
      case 'ghe_ngoi':
        return Icons.event_seat;
      default:
        return Icons.directions_bus;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showVehicleDetail(Vehicle vehicle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Chi tiết xe ${vehicle.bienSoXe}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Biển số:', vehicle.bienSoXe),
              _buildDetailRow('Loại xe:', vehicle.loaiXeDisplayName),
              _buildDetailRow('Số ghế:', vehicle.soGhe.toString()),
              _buildDetailRow('Trạng thái:', vehicle.trangThaiDisplayName),
              if (vehicle.tenTaiXe != null)
                _buildDetailRow('Tài xế:', vehicle.tenTaiXe!),
              if (vehicle.ngayBaoTriCuoi != null)
                _buildDetailRow('Bảo trì cuối:', _formatDate(vehicle.ngayBaoTriCuoi!)),
              if (vehicle.ngayBaoTriTiep != null)
                _buildDetailRow('Bảo trì tiếp:', _formatDate(vehicle.ngayBaoTriTiep!)),
              if (vehicle.ghiChu != null)
                _buildDetailRow('Ghi chú:', vehicle.ghiChu!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _addVehicle() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chức năng thêm xe đang phát triển')),
    );
  }

  void _editVehicle(Vehicle vehicle) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Chỉnh sửa xe ${vehicle.bienSoXe}')),
    );
  }

  void _deleteVehicle(Vehicle vehicle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa xe "${vehicle.bienSoXe}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _vehicles.removeWhere((v) => v.id == vehicle.id);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Đã xóa xe ${vehicle.bienSoXe}')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
