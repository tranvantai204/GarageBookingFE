import 'package:flutter/material.dart';

class PickupLocationWidget extends StatefulWidget {
  final String selectedType;
  final String? customAddress;
  final String? note;
  final Function(String type, String? address, String? note) onChanged;

  const PickupLocationWidget({
    super.key,
    required this.selectedType,
    this.customAddress,
    this.note,
    required this.onChanged,
  });

  @override
  State<PickupLocationWidget> createState() => _PickupLocationWidgetState();
}

class _PickupLocationWidgetState extends State<PickupLocationWidget> {
  late String _selectedType;
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedType = widget.selectedType;
    _addressController.text = widget.customAddress ?? '';
    _noteController.text = widget.note ?? '';
  }

  @override
  void dispose() {
    _addressController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _updateSelection() {
    widget.onChanged(
      _selectedType,
      _selectedType == 'dia_chi_cu_the' ? _addressController.text : null,
      _noteController.text.isNotEmpty ? _noteController.text : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.location_on,
                color: Colors.blue.shade600,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'Chọn điểm đón',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Option 1: Đón tại bến xe
          _buildPickupOption(
            type: 'ben_xe',
            title: 'Đón tại bến xe',
            subtitle: 'Quý khách tự đến bến xe để lên xe',
            icon: Icons.directions_bus,
            iconColor: Colors.green.shade600,
          ),
          
          const SizedBox(height: 16),
          
          // Option 2: Đón tại địa chỉ cụ thể
          _buildPickupOption(
            type: 'dia_chi_cu_the',
            title: 'Đón tại địa chỉ cụ thể',
            subtitle: 'Xe sẽ đến đón tại địa chỉ bạn cung cấp',
            icon: Icons.home,
            iconColor: Colors.orange.shade600,
          ),
          
          // Địa chỉ cụ thể (hiển thị khi chọn option 2)
          if (_selectedType == 'dia_chi_cu_the') ...[
            const SizedBox(height: 16),
            _buildAddressInput(),
          ],
          
          const SizedBox(height: 16),
          
          // Ghi chú
          _buildNoteInput(),
        ],
      ),
    );
  }

  Widget _buildPickupOption({
    required String type,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
  }) {
    final isSelected = _selectedType == type;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = type;
        });
        _updateSelection();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade50 : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.blue.shade300 : Colors.grey.shade200,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected ? iconColor.withOpacity(0.2) : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? iconColor : Colors.grey.shade600,
                size: 24,
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.blue.shade700 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            
            // Radio button
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.blue.shade600 : Colors.grey.shade400,
                  width: 2,
                ),
                color: isSelected ? Colors.blue.shade600 : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.edit_location,
                color: Colors.orange.shade600,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Địa chỉ đón',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade700,
                ),
              ),
              const Text(
                ' *',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _addressController,
            onChanged: (_) => _updateSelection(),
            decoration: InputDecoration(
              hintText: 'Nhập địa chỉ cụ thể để xe đến đón...',
              hintStyle: TextStyle(color: Colors.grey.shade500),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.orange.shade400),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildNoteInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.note_alt,
              color: Colors.grey.shade600,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Ghi chú thêm',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            Text(
              ' (tùy chọn)',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _noteController,
          onChanged: (_) => _updateSelection(),
          decoration: InputDecoration(
            hintText: 'Ví dụ: Gọi điện trước khi đến, đón tại cổng chính...',
            hintStyle: TextStyle(color: Colors.grey.shade500),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.blue.shade400),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          maxLines: 2,
        ),
      ],
    );
  }
}
