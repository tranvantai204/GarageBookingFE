import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../api/admin_service.dart';

class VipCustomersScreen extends StatefulWidget {
  const VipCustomersScreen({super.key});

  @override
  State<VipCustomersScreen> createState() => _VipCustomersScreenState();
}

class _VipCustomersScreenState extends State<VipCustomersScreen> {
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserProvider>(context, listen: false).loadUsers();
    });
  }

  Future<void> _toggleVip(String id, bool isVip) async {
    setState(() => _loading = true);
    try {
      await AdminService.setVip(id, isVip);
      if (mounted) {
        await Provider.of<UserProvider>(context, listen: false).loadUsers();
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Khách hàng VIP'),
        backgroundColor: Colors.amber.shade700,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          Consumer<UserProvider>(
            builder: (context, userProvider, child) {
              final users = userProvider.users
                  .where((u) => u.vaiTro == 'user')
                  .toList();
              if (users.isEmpty)
                return const Center(child: Text('Chưa có khách hàng'));
              return ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: users.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final u = users[index];
                  final isVip = u.isVip;
                  return Card(
                    child: ListTile(
                      leading: Icon(
                        isVip ? Icons.star : Icons.person,
                        color: isVip ? Colors.amber : Colors.grey,
                      ),
                      title: Text(u.hoTen),
                      subtitle: Text(u.soDienThoai),
                      trailing: Switch(
                        value: isVip,
                        onChanged: (v) => _toggleVip(u.id, v),
                      ),
                    ),
                  );
                },
              );
            },
          ),
          if (_loading)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
