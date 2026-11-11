import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

// Model แปลงข้อมูลจากตาราง `users`
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
      username: json['username'],
      email: json['email'],
      displayName: json['display_name'],
      role: json['role'],
      isActive: json['is_active'] == 1 || json['is_active'] == true,
      createdAt: DateTime.parse(json['created_at'].toString()),
    );
  }
}

class AdminUsersView extends StatefulWidget {
  final int currentAdminId; // ID ของ Admin ที่กำลังล็อกอินอยู่ (มาจาก JWT/Session)

  const AdminUsersView({
    super.key,
    this.currentAdminId = 1, // สมมุติ ID 1 ตามตาราง paygame.sql
  });

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

  @override
  void initState() {
    super.initState();
    _initRealtimeSocket();
  }

  void _initRealtimeSocket() {
    // หมายเหตุ: กรณีทดสอบบน Android Emulator ให้ใช้ IP '10.0.2.2:3000' แทน localhost
    _socket = IO.io('http://10.0.2.2:3000', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    _socket.onConnect((_) {
      _socket.emit('get_users');
    });

    // ฟัง Event ข้อมูล Real-time จาก Server Node.js
    _socket.on('users_updated', (data) {
      if (mounted) {
        setState(() {
          _allUsers = (data as List).map((e) => UserModel.fromJson(e)).toList();
          _isLoading = false;
        });
      }
    });

    // ฟัง Event แจ้งเตือนข้อผิดพลาด
    _socket.on('error_message', (msg) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg.toString()), backgroundColor: Colors.red),
        );
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

  // ส่ง Event เปลี่ยนสถานะ active
  void _toggleActiveStatus(UserModel user, bool newStatus) {
    if (user.userId == widget.currentAdminId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('คุณไม่สามารถระงับบัญชีของตนเองได้'), backgroundColor: Colors.orange),
      );
      return;
    }

    _socket.emit('update_user_status', {
      'admin_id': widget.currentAdminId,
      'target_user_id': user.userId,
      'is_active': newStatus ? 1 : 0,
    });
  }

  // ส่ง Event เปลี่ยน role
  void _toggleRole(UserModel user) {
    if (user.userId == widget.currentAdminId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('คุณไม่สามารถเปลี่ยนบทบาทตนเองได้'), backgroundColor: Colors.orange),
      );
      return;
    }

    final newRole = user.role == 'admin' ? 'user' : 'admin';
    _socket.emit('update_user_role', {
      'admin_id': widget.currentAdminId,
      'target_user_id': user.userId,
      'role': newRole,
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = _filteredUsers;

    return Scaffold(
      appBar: AppBar(
        title: const Text('จัดการผู้ใช้งาน (Real-time)'),
        backgroundColor: const Color(0xFFA60C19),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // แถบค้นหา
                  TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'ค้นหาด้วย ชื่อผู้ใช้, ชื่อแสดง หรือ อีเมล...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ตัวกรอง Role และ Status
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
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedRoleFilter = val);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedStatusFilter,
                          decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
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

                  // แสดงผลลัพธ์
                  Expanded(
                    child: filteredList.isEmpty
                        ? const Center(child: Text('ไม่พบข้อมูลผู้ใช้งาน'))
                        : ListView.builder(
                            itemCount: filteredList.length,
                            itemBuilder: (context, index) {
                              final user = filteredList[index];
                              final isSelf = user.userId == widget.currentAdminId;

                              return Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: user.role == 'admin' ? Colors.red.shade100 : Colors.blue.shade100,
                                    child: Text(
                                      user.displayName[0].toUpperCase(),
                                      style: TextStyle(color: user.role == 'admin' ? Colors.red : Colors.blue),
                                    ),
                                  ),
                                  title: Row(
                                    children: [
                                      Text(user.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                      if (isSelf)
                                        Container(
                                          margin: const EdgeInsets.only(left: 6),
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(4)),
                                          child: const Text('คุณ', style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
                                        ),
                                    ],
                                  ),
                                  subtitle: Text('${user.username} • ${user.email}'),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // สวิตช์ปิด/เปิดใช้งาน (Disable หากเป็นบัญชีตนเอง)
                                      Switch(
                                        value: user.isActive,
                                        activeColor: Colors.green,
                                        onChanged: isSelf ? null : (val) => _toggleActiveStatus(user, val),
                                      ),
                                      PopupMenuButton<String>(
                                        onSelected: (val) {
                                          if (val == 'toggle_role') _toggleRole(user);
                                        },
                                        itemBuilder: (context) => [
                                          if (!isSelf)
                                            PopupMenuItem(
                                              value: 'toggle_role',
                                              child: Text('เปลี่ยนเป็น ${user.role == 'admin' ? 'User' : 'Admin'}'),
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