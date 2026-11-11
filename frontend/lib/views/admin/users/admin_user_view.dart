import 'package:flutter/material.dart';
import 'package:frontend/services/order_service.dart';
import 'package:frontend/services/user_service.dart';

class AdminUsersView extends StatefulWidget {
  const AdminUsersView({super.key});

  @override
  State<AdminUsersView> createState() => _AdminUsersViewState();
}

class _AdminUsersViewState extends State<AdminUsersView> {
  static const Color _red = Color(0xFFA60C19);

  List<UserModel> _allUsers = [];
  bool _loading = true;
  String? _error;

  final TextEditingController _searchController = TextEditingController();
  String _selectedRoleFilter = 'All';
  String _selectedStatusFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // โหลดรายชื่อผู้ใช้จากฐานข้อมูล
  Future<void> _loadUsers() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final users = await UserService.list();
      if (!mounted) return;
      setState(() {
        _allUsers = users;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  void _showMessage(String message, {Color? color}) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  // กรองข้อมูลตามคำค้นหา, Role และ Status
  List<UserModel> get _filteredUsers {
    final query = _searchController.text.toLowerCase();
    return _allUsers.where((user) {
      final matchesSearch =
          user.username.toLowerCase().contains(query) ||
          user.displayName.toLowerCase().contains(query) ||
          user.email.toLowerCase().contains(query);
      final matchesRole =
          _selectedRoleFilter == 'All' || user.role == _selectedRoleFilter;
      final matchesStatus =
          _selectedStatusFilter == 'All' ||
          (_selectedStatusFilter == 'Active' && user.isActive) ||
          (_selectedStatusFilter == 'Inactive' && !user.isActive);
      return matchesSearch && matchesRole && matchesStatus;
    }).toList();
  }

  // 1. เปลี่ยนบทบาทเป็น Admin (บัญชี Admin เปลี่ยนกลับไม่ได้)
  void _toggleRole(UserModel user) {
    if (user.role == 'admin') {
      _showMessage(
        'ไม่สามารถเปลี่ยนบทบาทของบัญชี Admin ได้',
        color: Colors.orange,
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ยืนยันเปลี่ยนบทบาท'),
        content: Text(
          'ต้องการเปลี่ยนบทบาทของ "${user.displayName}" เป็น "Admin" ใช่หรือไม่?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _red),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await UserService.makeAdmin(user.userId);
                if (!mounted) return;
                setState(() => user.role = 'admin');
                _showMessage('เปลี่ยนบทบาทเป็น Admin สำเร็จ');
              } catch (error) {
                if (mounted) _showMessage(error.toString(), color: Colors.red);
              }
            },
            child: const Text('ยืนยัน', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // 2. เปิด/ปิดการใช้งานบัญชี (ระงับบัญชี Admin ไม่ได้)
  Future<void> _toggleActiveStatus(UserModel user, bool newStatus) async {
    if (user.role == 'admin') {
      _showMessage(
        'ไม่สามารถระงับการใช้งานบัญชี Admin ได้',
        color: Colors.redAccent,
      );
      return;
    }

    try {
      await UserService.setActive(user.userId, newStatus);
      if (!mounted) return;
      setState(() => user.isActive = newStatus);
      _showMessage(
        '${newStatus ? "เปิด" : "ระงับ"}การใช้งานบัญชี ${user.username} เรียบร้อย',
      );
    } catch (error) {
      if (mounted) _showMessage(error.toString(), color: Colors.red);
    }
  }

  // 3. ตั้งรหัสผ่านใหม่
  void _showResetPasswordDialog(UserModel user) {
    showDialog(
      context: context,
      builder: (ctx) => _ResetPasswordDialog(
        user: user,
        onSave: (password) async {
          try {
            await UserService.setPassword(user.userId, password);
            if (mounted) {
              _showMessage('รีเซ็ตรหัสผ่านของ ${user.username} เรียบร้อย');
            }
          } catch (error) {
            if (mounted) _showMessage(error.toString(), color: Colors.red);
          }
        },
      ),
    );
  }

  // 4. รายละเอียดบัญชี + ประวัติการสั่งซื้อจริงจากฐานข้อมูล
  void _showUserDetailsModal(UserModel user) {
    final orders = OrderService.list().then(
      (all) => all
          .where((order) => order['user_id'].toString() == '${user.userId}')
          .toList(),
    );
    final created = user.createdAt;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
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
                _Avatar(user: user, radius: 24, fontSize: 20),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '@${user.username} • ID: ${user.userId}',
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 24),
            _buildDetailRow('อีเมล', user.email),
            _buildDetailRow('บทบาท (Role)', user.role.toUpperCase()),
            _buildDetailRow(
              'สถานะ',
              user.isActive ? 'เปิดใช้งาน (Active)' : 'ถูกระงับ (Inactive)',
            ),
            _buildDetailRow(
              'วันที่สมัคร',
              '${created.day}/${created.month}/${created.year + 543} '
                  '${created.hour}:${created.minute.toString().padLeft(2, '0')}',
            ),
            const SizedBox(height: 16),
            const Text(
              'ประวัติการสั่งซื้อ',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxHeight: 240),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: orders,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Text('โหลดประวัติไม่สำเร็จ: ${snapshot.error}');
                  }
                  final list = snapshot.data ?? [];
                  if (list.isEmpty) return const Text('ยังไม่มีการสั่งซื้อ');
                  return ListView(
                    shrinkWrap: true,
                    children: list.map(_buildOrderRow).toList(),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderRow(Map<String, dynamic> order) {
    final total = double.tryParse('${order['total_amount']}') ?? 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '• ${order['game_name_snapshot']} ${order['package_name_snapshot']} '
              '(Order #${order['order_id']}, ${order['status']})',
            ),
          ),
          Text(
            '${total.toStringAsFixed(2)} ฿',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('จัดการผู้ใช้งาน (User Management)'),
        backgroundColor: _red,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _loadUsers,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSearchField(),
            const SizedBox(height: 12),
            _buildFilters(),
            const SizedBox(height: 16),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  // ช่องค้นหา
  Widget _buildSearchField() {
    return TextField(
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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }

  // ตัวกรอง Role และ Status
  Widget _buildFilters() {
    return Row(
      children: [
        Expanded(
          child: _buildDropdown(
            label: 'Role',
            value: _selectedRoleFilter,
            items: const {'All': 'ทุก Role', 'admin': 'Admin', 'user': 'User'},
            onChanged: (val) => setState(() => _selectedRoleFilter = val),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildDropdown(
            label: 'Status',
            value: _selectedStatusFilter,
            items: const {
              'All': 'ทุกสถานะ',
              'Active': 'Active',
              'Inactive': 'Inactive',
            },
            onChanged: (val) => setState(() => _selectedStatusFilter = val),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required Map<String, String> items,
    required ValueChanged<String> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: const OutlineInputBorder(),
      ),
      items: items.entries
          .map(
            (item) =>
                DropdownMenuItem(value: item.key, child: Text(item.value)),
          )
          .toList(),
      onChanged: (val) {
        if (val != null) onChanged(val);
      },
    );
  }

  // รายการผู้ใช้ (หรือสถานะกำลังโหลด / error)
  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _red));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: _loadUsers, child: const Text('ลองใหม่')),
          ],
        ),
      );
    }

    final filteredList = _filteredUsers;

    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'พบผู้ใช้งานทั้งหมด ${filteredList.length} รายการ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: filteredList.isEmpty
              ? const Center(child: Text('ไม่พบข้อมูลผู้ใช้งาน'))
              : RefreshIndicator(
                  onRefresh: _loadUsers,
                  child: ListView.builder(
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) =>
                        _buildUserCard(filteredList[index]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildUserCard(UserModel user) {
    final isAdmin = user.role == 'admin';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: () => _showUserDetailsModal(user),
        leading: _Avatar(user: user),
        title: Row(
          children: [
            Flexible(
              child: Text(
                user.displayName,
                style: const TextStyle(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Chip(
              label: Text(
                user.role.toUpperCase(),
                style: const TextStyle(fontSize: 10, color: Colors.white),
              ),
              backgroundColor: isAdmin ? _red : Colors.blue,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
            ),
          ],
        ),
        subtitle: Text('${user.username} • ${user.email}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // เปิด/ปิดใช้งาน (กดไม่ได้ถ้าเป็น Admin)
            Switch(
              value: user.isActive,
              activeThumbColor: Colors.green,
              onChanged: isAdmin
                  ? null
                  : (val) => _toggleActiveStatus(user, val),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'details':
                    _showUserDetailsModal(user);
                  case 'toggle_role':
                    _toggleRole(user);
                  case 'reset_pwd':
                    _showResetPasswordDialog(user);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'details',
                  child: Text('ดูรายละเอียด & ประวัติ'),
                ),
                if (!isAdmin) ...const [
                  PopupMenuItem(
                    value: 'toggle_role',
                    child: Text('เปลี่ยนเป็น Admin'),
                  ),
                  PopupMenuItem(
                    value: 'reset_pwd',
                    child: Text('รีเซ็ตรหัสผ่าน'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Round avatar with the user's first letter (red for admin, blue for user).
class _Avatar extends StatelessWidget {
  const _Avatar({required this.user, this.radius, this.fontSize});

  final UserModel user;
  final double? radius;
  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    final isAdmin = user.role == 'admin';
    return CircleAvatar(
      radius: radius,
      backgroundColor: isAdmin ? Colors.red.shade100 : Colors.blue.shade100,
      child: Text(
        user.initial,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: isAdmin ? Colors.red : Colors.blue,
        ),
      ),
    );
  }
}

/// Dialog for setting a new password. Owns its text controller so it is
/// disposed only after the dialog is gone.
class _ResetPasswordDialog extends StatefulWidget {
  const _ResetPasswordDialog({required this.user, required this.onSave});

  final UserModel user;
  final ValueChanged<String> onSave;

  @override
  State<_ResetPasswordDialog> createState() => _ResetPasswordDialogState();
}

class _ResetPasswordDialogState extends State<_ResetPasswordDialog> {
  final _passwordController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _save() {
    final password = _passwordController.text;
    if (password.length < 6) {
      setState(() => _error = 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร');
      return;
    }
    Navigator.pop(context);
    widget.onSave(password);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('ตั้งรหัสผ่านใหม่ (${widget.user.username})'),
      content: TextField(
        controller: _passwordController,
        obscureText: true,
        autofocus: true,
        onSubmitted: (_) => _save(),
        decoration: InputDecoration(
          labelText: 'รหัสผ่านใหม่',
          hintText: 'อย่างน้อย 6 ตัวอักษร',
          errorText: _error,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('ยกเลิก'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _AdminUsersViewState._red,
          ),
          onPressed: _save,
          child: const Text('บันทึก', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
