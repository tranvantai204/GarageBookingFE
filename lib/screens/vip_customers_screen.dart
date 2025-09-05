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
              final allUsers = userProvider.users
                  .where((u) => u.vaiTro == 'user')
                  .toList();
              if (allUsers.isEmpty) {
                return const Center(child: Text('Chưa có khách hàng'));
              }

              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.stars, color: Colors.amber),
                        const SizedBox(width: 8),
                        Text(
                          'Danh sách khách hàng (${allUsers.length})',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const Spacer(),
                        OutlinedButton.icon(
                          onPressed: () => Provider.of<UserProvider>(
                            context,
                            listen: false,
                          ).loadUsers(),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Tải lại'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 1.4,
                            ),
                        itemCount: allUsers.length,
                        itemBuilder: (context, index) {
                          final u = allUsers[index];
                          final isVip = u.isVip;
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade100),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: isVip
                                          ? Colors.amber.shade100
                                          : Colors.grey.shade200,
                                      child: Icon(
                                        isVip ? Icons.star : Icons.person,
                                        color: isVip
                                            ? Colors.amber.shade700
                                            : Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            u.hoTen,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            u.soDienThoai,
                                            style: TextStyle(
                                              color: Colors.grey.shade700,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Switch(
                                      value: isVip,
                                      onChanged: (v) => _toggleVip(u.id, v),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                Row(
                                  children: [
                                    Chip(
                                      label: Text(isVip ? 'VIP' : 'Thường'),
                                      backgroundColor: isVip
                                          ? Colors.orange.shade50
                                          : Colors.grey.shade200,
                                      labelStyle: TextStyle(
                                        color: isVip
                                            ? Colors.orange
                                            : Colors.grey.shade700,
                                      ),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
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
