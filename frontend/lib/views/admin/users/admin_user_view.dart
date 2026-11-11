import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:frontend/services/api_service.dart';

class UserModel {
  final int userId;
  final String username;
  final String email;
  final String displayName;
  String role;
  bool isActive;
  final DateTime createdAt;

  UserModel({
    required this.userId,
    required this.username,
    required this.email,
    required this.displayName,
    required this.role,
    required this.isActive,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['user_id'],
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      displayName: json['display_name'] ?? '',
      role: json['role'] ?? 'user',
      isActive: json['is_active'] == 1 || json['is_active'] == true,
      createdAt: DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now(),
    );
  }
}

class AdminUsersView extends StatefulWidget {
  const AdminUsersView({super.key});

  @override
  State<AdminUsersView> createState() => _AdminUsersViewState();
}

class _AdminUsersViewState extends State<AdminUsersView> {
  late IO.Socket _socket;
  List<UserModel> _allUsers = [];
  bool _isLoading = true;

  final TextEditingController _searchController = TextEditingController();
  String _selectedRoleFilter = 'All';
  String _selectedStatusFilter = 'All';
  String _sortBy = 'latest'; // 'latest' | 'name'

  @override
  void initState() {
    super.initState();
    _fetchUsers();
    _initRealtimeSocket();
  }

  Future<void> _fetchUsers() async {
    try {
      final response = await ApiService.get('/users');
      if (mounted && response is Map && response['users'] is List) {
        setState(() {
          _allUsers = (response['users'] as List)
              .map((e) => UserModel.fromJson(e))
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _initRealtimeSocket() {
    _socket = IO.io('http://10.0.2.2:3000', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    _socket.on('users_updated', (data) {
      if (mounted && data is List) {
        setState(() {
          _allUsers = data.map((e) => UserModel.fromJson(e)).toList();
        });
      }
    });
  }

  @override
  void dispose() {
    _socket.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<UserModel> get _filteredUsers {
    List<UserModel> list = _allUsers.where((user) {
      final query = _searchController.text.toLowerCase();
      final matchesSearch = user.username.toLowerCase().contains(query) ||
          user.displayName.toLowerCase().contains(query) ||
          user.email.toLowerCase().contains(query);

      final matchesRole = _selectedRoleFilter == 'All' || user.role == _selectedRoleFilter;
      final matchesStatus = _selectedStatusFilter == 'All' ||
          (_selectedStatusFilter == 'Active' && user.isActive) ||
          (_selectedStatusFilter == 'Inactive' && !user.isActive);

      return matchesSearch && matchesRole && matchesStatus;
    }).toList();

    if (_sortBy == 'name') {
      list.sort((a, b) => a.displayName.compareTo(b.displayName));
    } else {
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return list;
  }

  // 1. สลับสถานะ (ห้ามระงับ Admin)[cite: 7]
  Future<void> _toggleActiveStatus(UserModel user, bool newStatus) async {
    if (user.role == 'admin') {
      _showSnackBar('ไม่สามารถระงับการใช้งานบัญชี Admin ได้', Colors.redAccent);
      return;
    }
    try {
      await ApiService.put('/users/${user.userId}/status', {'is_active': newStatus});
    } catch (e) {
      _showSnackBar('เกิดข้อผิดพลาด: $e', Colors.red);
    }
  }

  // 2. เปลี่ยน Role (ห้ามปรับ Admin)[cite: 7]
  Future<void> _toggleRole(UserModel user) async {
    if (user.role == 'admin') {
      _showSnackBar('ไม่สามารถเปลี่ยนบทบาทของบัญชี Admin ได้', Colors.orange);
      return;
    }
    try {
      await ApiService.put('/users/${user.userId}/role', {'role': 'admin'});
    } catch (e) {
      _showSnackBar('เกิดข้อผิดพลาด: $e', Colors.red);
    }
  }

  // 3. แก้ไขข้อมูล Profile[cite: 7]
  void _showEditProfileDialog(UserModel user) {
    final nameCtrl = TextEditingController(text: user.displayName);
    final emailCtrl = TextEditingController(text: user.email);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('แก้ไขข้อมูล: ${user.username}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Display Name')),
            TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ยกเลิก')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFA60C19)),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ApiService.put('/users/${user.userId}/profile', {
                  'display_name': nameCtrl.text.trim(),
                  'email': emailCtrl.text.trim(),
                });
                _showSnackBar('แก้ไขข้อมูลเรียบร้อย', Colors.green);
              } catch (e) {
                _showSnackBar('แก้ไขข้อมูลไม่สำเร็จ', Colors.red);
              }
            },
            child: const Text('บันทึก', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // 4. รีเซ็ตรหัสผ่าน[cite: 7]
  void _showResetPasswordDialog(UserModel user) {
    final pwdCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('รีเซ็ตรหัสผ่าน: ${user.username}'),
        content: TextField(
          controller: pwdCtrl,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'รหัสผ่านใหม่ (อย่างน้อย 6 ตัวอักษร)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ยกเลิก')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFA60C19)),
            onPressed: () async {
              if (pwdCtrl.text.length < 6) return;
              Navigator.pop(ctx);
              try {
                await ApiService.put('/users/${user.userId}/reset-password', {
                  'new_password': pwdCtrl.text.trim(),
                });
                _showSnackBar('ตั้งรหัสผ่านใหม่เรียบร้อยแล้ว', Colors.green);
              } catch (e) {
                _showSnackBar('รีเซ็ตรหัสผ่านไม่สำเร็จ', Colors.red);
              }
            },
            child: const Text('บันทึก', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // 5. ดูประวัติการเติมเงิน[cite: 7]
  void _showHistoryModal(UserModel user) async {
    List history = [];
    try {
      final res = await ApiService.get('/users/${user.userId}/history');
      if (res is Map && res['history'] is List) {
        history = res['history'];
      }
    } catch (_) {}

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ประวัติการสั่งซื้อ: ${user.displayName}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            history.isEmpty
                ? const Padding(padding: EdgeInsets.all(16.0), child: Center(child: Text('ไม่มีประวัติการเติมเงิน')))
                : SizedBox(
                    height: 200,
                    child: ListView.builder(
                      itemCount: history.length,
                      itemBuilder: (ctx, i) {
                        final item = history[i];
                        return ListTile(
                          title: Text(item['game_name_snapshot'] ?? 'Game'),
                          subtitle: Text(item['created_at'].toString().split('T')[0]),
                          trailing: Text('${item['total_amount']} ฿', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = _filteredUsers;
    final total = _allUsers.length;
    final activeCount = _allUsers.where((u) => u.isActive).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('จัดการผู้ใช้งาน (Real-time Full Option)'),
        backgroundColor: const Color(0xFFA60C19),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // 1. Summary Statistics Bar
                  Row(
                    children: [
                      _buildStatCard('ทั้งหมด', '$total', Colors.blue),
                      const SizedBox(width: 8),
                      _buildStatCard('ใช้งานปกติ', '$activeCount', Colors.green),
                      const SizedBox(width: 8),
                      _buildStatCard('ถูกระงับ', '${total - activeCount}', Colors.red),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Search & Sort Bar
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: 'ค้นหาด้วย ชื่อ/อีเมล...',
                            prefixIcon: const Icon(Icons.search),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(_sortBy == 'name' ? Icons.sort_by_alpha : Icons.access_time),
                        onPressed: () {
                          setState(() {
                            _sortBy = _sortBy == 'name' ? 'latest' : 'name';
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Filters
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedRoleFilter,
                          decoration: const InputDecoration(labelText: 'Role', border: OutlineInputBorder()),
                          items: const [
                            DropdownMenuItem(value: 'All', child: Text('ทุก Role')),
                            DropdownMenuItem(value: 'admin', child: Text('Admin')),
                            DropdownMenuItem(value: 'user', child: Text('User')),
                          ],
                          onChanged: (val) => setState(() => _selectedRoleFilter = val!),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedStatusFilter,
                          decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
                          items: const [
                            DropdownMenuItem(value: 'All', child: Text('ทุกสถานะ')),
                            DropdownMenuItem(value: 'Active', child: Text('Active')),
                            DropdownMenuItem(value: 'Inactive', child: Text('Inactive')),
                          ],
                          onChanged: (val) => setState(() => _selectedStatusFilter = val!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // User List View
                  Expanded(
                    child: filteredList.isEmpty
                        ? const Center(child: Text('ไม่พบข้อมูลผู้ใช้งาน'))
                        : ListView.builder(
                            itemCount: filteredList.length,
                            itemBuilder: (context, index) {
                              final user = filteredList[index];
                              final isAdmin = user.role == 'admin';

                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: isAdmin ? Colors.red.shade100 : Colors.blue.shade100,
                                    child: Text(
                                      user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : 'U',
                                      style: TextStyle(color: isAdmin ? Colors.red : Colors.blue, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  title: Text(user.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text('${user.username} • ${user.email}'),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Switch(
                                        value: user.isActive,
                                        activeColor: Colors.green,
                                        onChanged: isAdmin ? null : (val) => _toggleActiveStatus(user, val),
                                      ),
                                      PopupMenuButton<String>(
                                        onSelected: (val) {
                                          if (val == 'edit') _showEditProfileDialog(user);
                                          if (val == 'history') _showHistoryModal(user);
                                          if (val == 'reset') _showResetPasswordDialog(user);
                                          if (val == 'role') _toggleRole(user);
                                        },
                                        itemBuilder: (context) => [
                                          const PopupMenuItem(value: 'edit', child: Text('แก้ไขข้อมูล')),
                                          const PopupMenuItem(value: 'history', child: Text('ดูประวัติการสั่งซื้อ')),
                                          const PopupMenuItem(value: 'reset', child: Text('รีเซ็ตรหัสผ่าน')),
                                          if (!isAdmin)
                                            const PopupMenuItem(value: 'role', child: Text('เปลี่ยนเป็น Admin')),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(String title, String count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(title, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(count, style: TextStyle(fontSize: 18, color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}