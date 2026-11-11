import 'package:flutter/material.dart';

// Model อ้างอิงจากตาราง `users` ใน paygame.sql
class UserModel {
  final int userId;
  final String username;
  final String email;
  final String displayName;
  String role; // 'admin' | 'user'
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
}

class AdminUsersView extends StatefulWidget {
  const AdminUsersView({super.key});

  @override
  State<AdminUsersView> createState() => _AdminUsersViewState();
}

class _AdminUsersViewState extends State<AdminUsersView> {
  // ข้อมูลจำลองตั้งต้นจาก paygame.sql
  final List<UserModel> _allUsers = [
    UserModel(
      userId: 1,
      username: 'Natthawat',
      email: '6731501035@lamduan.mfu.ac.th',
      displayName: 'Test User',
      role: 'admin',
      isActive: true,
      createdAt: DateTime.parse('2026-11-10 22:59:11'),
    ),
    UserModel(
      userId: 2,
      username: 'Chalisa',
      email: '6731901022@lamduan.mfu.ac.th',
      displayName: 'Film',
      role: 'user',
      isActive: true,
      createdAt: DateTime.parse('2026-11-10 23:17:32'),
    ),
    UserModel(
      userId: 3,
      username: 'Napat',
      email: '6731501032@lamduan.mfu.ac.th',
      displayName: 'Mocha',
      role: 'user',
      isActive: false,
      createdAt: DateTime.parse('2026-11-10 23:20:03'),
    ),
  ];

  final TextEditingController _searchController = TextEditingController();
  String _selectedRoleFilter = 'All';
  String _selectedStatusFilter = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ฟังก์ชันกรองข้อมูลตาม Search Query, Role และ Status
  List<UserModel> get _filteredUsers {
    return _allUsers.where((user) {
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
  }

  // 1. ฟังก์ชันสลับบทบาท (Toggle Role)
  void _toggleRole(UserModel user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ยืนยันเปลี่ยนบทบาท'),
        content: Text(
          'ต้องการเปลี่ยนบทบาทของ "${user.displayName}" เป็น "${user.role == 'admin' ? 'User' : 'Admin'}" ใช่หรือไม่?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFA60C19)),
            onPressed: () {
              setState(() {
                user.role = user.role == 'admin' ? 'user' : 'admin';
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('เปลี่ยนบทบาทเป็น ${user.role} สำเร็จ')),
              );
            },
            child: const Text('ยืนยัน', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // 2. ฟังก์ชันเปิด/ปิดการใช้งาน (Toggle Active Status)
  void _toggleActiveStatus(UserModel user, bool newStatus) {
    setState(() {
      user.isActive = newStatus;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${newStatus ? "เปิด" : "ระงับ"} การใช้งานบัญชี ${user.username} เรียบร้อย',
        ),
      ),
    );
  }

  // 3. ฟังก์ชันรีเซ็ตรหัสผ่าน (Reset Password)
  void _showResetPasswordDialog(UserModel user) {
    final passwordController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('ตั้งรหัสผ่านใหม่ (${user.username})'),
        content: TextField(
          controller: passwordController,
          decoration: const InputDecoration(
            labelText: 'รหัสผ่านใหม่',
            hintText: 'อย่างน้อย 8 ตัวอักษร',
          ),
          obscureText: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFA60C19)),
            onPressed: () {
              if (passwordController.text.length < 8) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('รหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร')),
                );
                return;
              }
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('รีเซ็ตรหัสผ่านของ ${user.username} เรียบร้อย')),
              );
            },
            child: const Text('บันทึก', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // 4. ฟังก์ชันแสดงรายละเอียดบัญชี & ประวัติการสั่งซื้อ
  void _showUserDetailsModal(UserModel user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: user.role == 'admin' ? Colors.red.shade100 : Colors.blue.shade100,
                  child: Text(
                    user.displayName[0].toUpperCase(),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: user.role == 'admin' ? Colors.red : Colors.blue,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text('@${user.username} • ID: ${user.userId}', style: const TextStyle(color: Colors.black54)),
                  ],
                ),
              ],
            ),
            const Divider(height: 24),
            _buildDetailRow('อีเมล', user.email),
            _buildDetailRow('บทบาท (Role)', user.role.toUpperCase()),
            _buildDetailRow('สถานะ', user.isActive ? 'เปิดใช้งาน (Active)' : 'ถูกระงับ (Inactive)'),
            _buildDetailRow(
              'วันที่สมัคร',
              '${user.createdAt.day}/${user.createdAt.month}/${user.createdAt.year + 543} ${user.createdAt.hour}:${user.createdAt.minute.toString().padLeft(2, '0')}',
            ),
            const SizedBox(height: 16),
            const Text('ประวัติกิจกรรมการใช้งาน', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('• เติม PUBG 100 UC (Order #1)'),
                      Text('35.00 ฿', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = _filteredUsers;

    return Scaffold(
      appBar: AppBar(
        title: const Text('จัดการผู้ใช้งาน (User Management)'),
        backgroundColor: const Color(0xFFA60C19),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('อัปเดตข้อมูลแล้ว')),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // แถบค้นหาข้อมูล (Search Field)
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'ค้นหาด้วย ชื่อผู้ใช้, ชื่อแสดง หรือ อีเมล...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),

            // แถบ Filter Dropdown เลือก Role และ Status
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedRoleFilter,
                    decoration: const InputDecoration(
                      labelText: 'Role',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'All', child: Text('ทุก Role')),
                      DropdownMenuItem(value: 'admin', child: Text('Admin')),
                      DropdownMenuItem(value: 'user', child: Text('User')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedRoleFilter = val);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedStatusFilter,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'All', child: Text('ทุกสถานะ')),
                      DropdownMenuItem(value: 'Active', child: Text('Active')),
                      DropdownMenuItem(value: 'Inactive', child: Text('Inactive')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedStatusFilter = val);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // แสดงจำนวนผลลัพธ์
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'พบผู้ใช้งานทั้งหมด ${filteredList.length} รายการ',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54),
              ),
            ),
            const SizedBox(height: 8),

            // รายการผู้ใช้ (User List)
            Expanded(
              child: filteredList.isEmpty
                  ? const Center(child: Text('ไม่พบข้อมูลผู้ใช้งาน'))
                  : ListView.builder(
                      itemCount: filteredList.length,
                      itemBuilder: (context, index) {
                        final user = filteredList[index];
                        return Card(
                          elevation: 1.5,
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            onTap: () => _showUserDetailsModal(user),
                            leading: CircleAvatar(
                              backgroundColor:
                                  user.role == 'admin' ? Colors.red.shade100 : Colors.blue.shade100,
                              child: Text(
                                user.displayName[0].toUpperCase(),
                                style: TextStyle(
                                  color: user.role == 'admin' ? Colors.red : Colors.blue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Row(
                              children: [
                                Text(
                                  user.displayName,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 8),
                                Chip(
                                  label: Text(
                                    user.role.toUpperCase(),
                                    style: const TextStyle(fontSize: 10, color: Colors.white),
                                  ),
                                  backgroundColor: user.role == 'admin'
                                      ? const Color(0xFFA60C19)
                                      : Colors.blue,
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                ),
                              ],
                            ),
                            subtitle: Text('${user.username} • ${user.email}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // สวิตช์เปิด/ปิดใช้งาน (is_active)
                                Switch(
                                  value: user.isActive,
                                  activeColor: Colors.green,
                                  onChanged: (val) => _toggleActiveStatus(user, val),
                                ),

                                // เมนูการจัดการ (Actions)
                                PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (value == 'toggle_role') {
                                      _toggleRole(user);
                                    } else if (value == 'reset_pwd') {
                                      _showResetPasswordDialog(user);
                                    } else if (value == 'details') {
                                      _showUserDetailsModal(user);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'details',
                                      child: Text('ดูรายละเอียด & ประวัติ'),
                                    ),
                                    PopupMenuItem(
                                      value: 'toggle_role',
                                      child: Text('เปลี่ยนเป็น ${user.role == 'admin' ? 'User' : 'Admin'}'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'reset_pwd',
                                      child: Text('รีเซ็ตรหัสผ่าน'),
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
}