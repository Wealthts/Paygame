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
      // 💡 แก้จุดการดึงค่า Boolean: รองรับทั้ง int (1/0) และ bool (true/false)[cite: 7]
      isActive:
          json['is_active'] == 1 ||
          json['is_active'] == true ||
          json['is_active'].toString() == '1',
      createdAt:
          DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now(),
    );
  }
}

class AdminUsersView extends StatefulWidget {
  const AdminUsersView({super.key});

  @override
  State<AdminUsersView> createState() => _AdminUsersViewState();
}

class _AdminUsersViewState extends State<AdminUsersView> {
  late IO.Socket socket;
  List<UserModel> allUsers = [];
  bool isLoading = true;

  final TextEditingController searchController = TextEditingController();
  String selectedRoleFilter = 'All';
  String selectedStatusFilter = 'All';

  @override
  void initState() {
    super.initState();
    fetchUsers();
    initRealtimeSocket();
  }

  // ดึงข้อมูลผู้ใช้ทั้งหมดโดยใช้ ApiService (แนบ Bearer Token ให้อัตโนมัติ)[cite: 10]
  Future<void> fetchUsers() async {
    try {
      final response = await ApiService.get('/users');
      if (mounted && response is Map && response['users'] is List) {
        setState(() {
          allUsers = (response['users'] as List)
              .map((e) => UserModel.fromJson(e))
              .toList();
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        _showSnackBar(e.toString(), Colors.red);
      }
    }
  }

  // เชื่อมต่อ Socket.io Real-time
  void initRealtimeSocket() async {
    final token =
        await ApiService.getToken(); // ดึง Token จาก Secure Storage[cite: 10]

    socket = IO.io('http://10.0.2.2:3000', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
      'auth': {'token': token},
    });

    socket.on('users_updated', (data) {
      if (mounted && data is List) {
        setState(() {
          allUsers = data.map((e) => UserModel.fromJson(e)).toList();
        });
      }
    });
  }

  @override
  void dispose() {
    socket.dispose();
    searchController.dispose();
    super.dispose();
  }

  List<UserModel> get _filteredUsers {
    return allUsers.where((user) {
      final query = searchController.text.toLowerCase();
      final matchesSearch =
          user.username.toLowerCase().contains(query) ||
          user.displayName.toLowerCase().contains(query) ||
          user.email.toLowerCase().contains(query);

      final matchesRole =
          selectedRoleFilter == 'All' || user.role == selectedRoleFilter;
      final matchesStatus =
          selectedStatusFilter == 'All' ||
          (selectedStatusFilter == 'Active' && user.isActive) ||
          (selectedStatusFilter == 'Inactive' && !user.isActive);

      return matchesSearch && matchesRole && matchesStatus;
    }).toList();
  }

  Future<void> toggleActiveStatus(UserModel user, bool newStatus) async {
    // 1. ป้องกันไม่ให้กดระงับ Admin
    if (user.role.toString().toLowerCase() == 'admin') {
      _showSnackBar('Cannot suspend Admin account', Colors.redAccent);
      return;
    }

    // เก็บค่าสถานะเดิมไว้ทำ Rollback ถ้า API สั่งทำงานไม่สำเร็จ
    final oldStatus = user.isActive;

    // 2. อัปเดต UI ใน Flutter ทันที (ทำให้สวิตช์ขยับเปลี่ยนสีทันทีที่กด)
    setState(() {
      user.isActive = newStatus;
    });

    try {
      // 3. ยิง API ไปอัปเดตที่ Node.js Backend (ส่งเป็น int 1 หรือ 0)
      await ApiService.put('/users/${user.userId}/status', {
        'is_active': newStatus ? 1 : 0,
      });

      _showSnackBar(
        '${newStatus ? "Activated" : "Suspended"} account ${user.username} successfully',
        newStatus ? Colors.green : Colors.orange,
      );
    } catch (e) {
      // 4. หาก Backend ตอบกลับเป็น Error ให้สั่ง Rollback กลับเป็นค่าเดิม
      if (mounted) {
        setState(() {
          user.isActive = oldStatus;
        });
        _showSnackBar(
          'Error occurred: ${e.toString().replaceAll('Exception: ', '')}',
          Colors.red,
        );
      }
    }
  }

  // ฟังก์ชันเปลี่ยนบทบาท Role
  Future<void> toggleRole(UserModel user) async {
    if (user.role == 'admin') {
      _showSnackBar(
        'Cannot change the role of an Admin account',
        Colors.orange,
      );
      return;
    }

    try {
      await ApiService.put('/users/${user.userId}/role', {'role': 'admin'});
    } catch (e) {
      _showSnackBar('Error occurred: $e', Colors.red);
    }
  }

  void showEditProfileDialog(UserModel user) {
    final nameCtrl = TextEditingController(text: user.displayName);
    final emailCtrl = TextEditingController(text: user.email);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit Profile: ${user.username}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Display Name'),
            ),
            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFA60C19),
            ),
            onPressed: () async {
              final newName = nameCtrl.text.trim();
              final newEmail = emailCtrl.text.trim();

              if (newName.isEmpty || newEmail.isEmpty) return;

              Navigator.pop(ctx);

              try {
                // 1. ยิง API บันทึกชื่อลง MySQL[cite: 7, 10]
                await ApiService.put('/users/${user.userId}/profile', {
                  'display_name': newName,
                  'email': newEmail,
                });

                // 2. อัปเดต UI หน้าจอทันที[cite: 7]
                if (mounted) {
                  setState(() {
                    // สมมุติตัวแปรใน Model คือ displayName หรือ display_name ให้เซ็ตค่านั้น
                    // user.displayName = newName; (หากเป็น final ให้ใช้ _fetchUsers() ด้านล่าง)
                  });

                  // ดึงรายการผู้ใช้ใหม่ทั้งหมดทันที
                  await fetchUsers();
                  _showSnackBar('Edit profile successful', Colors.green);
                }
              } catch (e) {
                if (mounted) {
                  _showSnackBar('Failed to edit profile: $e', Colors.red);
                }
              }
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // รีเซ็ตรหัสผ่าน Dialog
  void showResetPasswordDialog(UserModel user) {
    final pwdCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Reset Password: ${user.username}'),
        content: TextField(
          controller: pwdCtrl,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'new password (min 6 chars)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFA60C19),
            ),
            onPressed: () async {
              if (pwdCtrl.text.length < 6) return;
              Navigator.pop(ctx);
              try {
                await ApiService.put('/users/${user.userId}/reset-password', {
                  'new_password': pwdCtrl.text.trim(),
                });
                _showSnackBar('Reset password successful', Colors.green);
              } catch (e) {
                _showSnackBar(
                  'Error occurred while resetting password',
                  Colors.red,
                );
              }
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = _filteredUsers;
    final total = allUsers.length;
    final activeCount = allUsers.where((u) => u.isActive).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        backgroundColor: const Color(0xFFA60C19),
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Stat Cards
                  Row(
                    children: [
                      _buildStatCard('total', '$total', Colors.blue),
                      const SizedBox(width: 8),
                      _buildStatCard(
                        'active',
                        '$activeCount',
                        Colors.green,
                      ),
                      const SizedBox(width: 8),
                      _buildStatCard(
                        'inactive',
                        '${total - activeCount}',
                        Colors.red,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Search Bar
                  TextField(
                    controller: searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search by Name/Email...',
                      prefixIcon: const Icon(Icons.search),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Filters
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: selectedRoleFilter,
                          decoration: const InputDecoration(
                            labelText: 'Role',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'All',
                              child: Text('All Roles'),
                            ),
                            DropdownMenuItem(
                              value: 'admin',
                              child: Text('Admin'),
                            ),
                            DropdownMenuItem(
                              value: 'user',
                              child: Text('User'),
                            ),
                          ],
                          onChanged: (val) =>
                              setState(() => selectedRoleFilter = val!),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: selectedStatusFilter,
                          decoration: const InputDecoration(
                            labelText: 'Status',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'All',
                              child: Text('All Statuses'),
                            ),
                            DropdownMenuItem(
                              value: 'Active',
                              child: Text('Active'),
                            ),
                            DropdownMenuItem(
                              value: 'Inactive',
                              child: Text('Inactive'),
                            ),
                          ],
                          onChanged: (val) =>
                              setState(() => selectedStatusFilter = val!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // User List View
                  Expanded(
                    child: filteredList.isEmpty
                        ? const Center(child: Text('No user data found'))
                        : ListView.builder(
                            itemCount: filteredList.length,
                            itemBuilder: (context, index) {
                              final user = filteredList[index];
                              final isAdmin = user.role == 'admin';

                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: isAdmin
                                        ? Colors.red.shade100
                                        : Colors.blue.shade100,
                                    child: Text(
                                      user.displayName.isNotEmpty
                                          ? user.displayName[0].toUpperCase()
                                          : 'U',
                                      style: TextStyle(
                                        color: isAdmin
                                            ? Colors.red
                                            : Colors.blue,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    user.displayName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${user.username} • ${user.email}',
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Switch button to toggle active status (green color based on DB)[cite: 7]
                                      Switch(
                                        value: user.isActive,
                                        activeThumbColor: Colors.green,
                                        onChanged: (val) =>
                                            toggleActiveStatus(user, val),
                                      ),
                                      PopupMenuButton<String>(
                                        onSelected: (val) {
                                          if (val == 'edit') {
                                            showEditProfileDialog(user);
                                          }
                                          if (val == 'reset') {
                                            showResetPasswordDialog(user);
                                          }
                                          if (val == 'role') toggleRole(user);
                                        },
                                        itemBuilder: (context) => [
                                          const PopupMenuItem(
                                            value: 'edit',
                                            child: Text('Edit Profile'),
                                          ),
                                          const PopupMenuItem(
                                            value: 'reset',
                                            child: Text('Reset Password'),
                                          ),
                                          if (!isAdmin)
                                            const PopupMenuItem(
                                              value: 'role',
                                              child: Text('Change to Admin'),
                                            ),
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
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              count,
              style: TextStyle(
                fontSize: 18,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
