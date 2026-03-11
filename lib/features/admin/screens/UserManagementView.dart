import 'package:flutter/material.dart';
import 'package:signup/features/admin/admin_theme.dart';
import 'package:signup/features/admin/services/user_management_service.dart';
import 'package:intl/intl.dart';

class UserManagementView extends StatefulWidget {
  const UserManagementView({super.key});

  @override
  State<UserManagementView> createState() => _UserManagementViewState();
}

class _UserManagementViewState extends State<UserManagementView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _userService = UserManagementService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: adminBgCanvas,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page header + tabs
          Container(
            color: adminBgCanvas,
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('User & Access Management', style: adminPageTitle()),
                        const SizedBox(height: 2),
                        Text('Manage users, roles, and permissions', style: adminBodyText()),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TabBar(
                  controller: _tabController,
                  labelColor: adminSidebarActive,
                  unselectedLabelColor: adminSidebarLabel,
                  indicatorColor: adminSidebarActive,
                  indicatorWeight: 2,
                  labelStyle: TextStyle(fontFamily: 'DM Sans', fontSize: 13, fontWeight: FontWeight.w500),
                  unselectedLabelStyle:
                      TextStyle(fontFamily: 'DM Sans', fontSize: 13, fontWeight: FontWeight.w400),
                  tabs: const [
                    Tab(text: 'All Users'),
                    Tab(text: 'Role Permissions'),
                    Tab(text: 'Admin Accounts'),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _AllUsersTab(userService: _userService),
                _RolePermissionsTab(userService: _userService),
                _AdminAccountsTab(userService: _userService),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared input helper ──────────────────────────────────────────────────────

Widget _styledInput({
  required TextEditingController controller,
  required String hint,
  int maxLines = 1,
  TextInputType keyboardType = TextInputType.text,
  bool obscureText = false,
  Widget? suffixIcon,
}) {
  return TextField(
    controller: controller,
    maxLines: maxLines,
    keyboardType: keyboardType,
    obscureText: obscureText,
    style: TextStyle(fontFamily: 'DM Sans', fontSize: 13, color: adminTextHeading),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(fontFamily: 'DM Sans', fontSize: 13, color: adminTextMuted),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: adminBgSubtle,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: adminBorderLight)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: adminBorderLight)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: adminAccent)),
    ),
  );
}

Widget _fieldLabel(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text,
          style: TextStyle(fontFamily: 'DM Sans', 
              fontSize: 11, fontWeight: FontWeight.w600, color: adminTextBody)),
    );

// ─── All Users Tab ────────────────────────────────────────────────────────────

class _AllUsersTab extends StatefulWidget {
  final UserManagementService userService;
  const _AllUsersTab({required this.userService});

  @override
  State<_AllUsersTab> createState() => _AllUsersTabState();
}

class _AllUsersTabState extends State<_AllUsersTab> {
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = false;
  int _currentPage = 0;
  static const int _pageSize = 50;

  String _searchQuery = '';
  String? _roleFilter;
  Map<String, int> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _currentPage = 0; _users = []; });
    final results = await Future.wait([
      widget.userService.getAllUsersDetailed(page: 0, pageSize: _pageSize),
      widget.userService.getUserStats(),
    ]);
    if (mounted) {
      final users = results[0] as List<Map<String, dynamic>>;
      setState(() {
        _users = users;
        _stats = results[1] as Map<String, int>;
        _hasMore = users.length == _pageSize;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreUsers() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);
    try {
      final nextPage = _currentPage + 1;
      final users = await widget.userService.getAllUsersDetailed(
          page: nextPage, pageSize: _pageSize);
      if (mounted) {
        setState(() {
          _users.addAll(users);
          _currentPage = nextPage;
          _hasMore = users.length == _pageSize;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  List<Map<String, dynamic>> get _filteredUsers {
    var filtered = _users;
    if (_roleFilter != null) {
      filtered = filtered.where((u) => u['role'] == _roleFilter).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered.where((u) {
        final email = u['email']?.toString().toLowerCase() ?? '';
        final name = _getUserName(u).toLowerCase();
        return email.contains(q) || name.contains(q);
      }).toList();
    }
    return filtered;
  }

  String _getUserName(Map<String, dynamic> user) {
    final role = user['role'] as String?;
    if (role == 'patient' && user['patients'] != null) {
      return '${user['patients']['first_name']} ${user['patients']['last_name']}';
    }
    if (role == 'doctor' && user['doctors'] != null) {
      return 'Dr. ${user['doctors']['first_name']} ${user['doctors']['last_name']}';
    }
    if (role == 'admin' && user['admins'] != null) {
      return '${user['admins']['first_name']} ${user['admins']['last_name']}';
    }
    return 'N/A';
  }

  Future<void> _deactivateUser(Map<String, dynamic> user) async {
    final confirm = await _adminConfirmDialog(
      context,
      title: 'Deactivate User',
      body: 'Deactivate account for ${_getUserName(user)}?\nThis will prevent them from logging in.',
      confirmLabel: 'Deactivate',
      isDanger: true,
    );
    if (confirm == true) {
      final result = await widget.userService.deactivateUser(user['id']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result['message']),
          backgroundColor: result['success'] ? adminSuccess : adminDanger,
        ));
        if (result['success']) _loadData();
      }
    }
  }

  Future<void> _reactivateUser(Map<String, dynamic> user) async {
    final result = await widget.userService.reactivateUser(user['id']);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result['message']),
        backgroundColor: result['success'] ? adminSuccess : adminDanger,
      ));
      if (result['success']) _loadData();
    }
  }

  Future<void> _resetPassword(Map<String, dynamic> user) async {
    final confirm = await _adminConfirmDialog(
      context,
      title: 'Reset Password',
      body: 'Send password reset email to ${user['email']}?',
      confirmLabel: 'Send Reset Email',
      isDanger: false,
    );
    if (confirm == true) {
      final result = await widget.userService.sendPasswordReset(user['email']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result['message']),
          backgroundColor: result['success'] ? adminSuccess : adminDanger,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(strokeWidth: 2, color: adminAccent));
    }

    return Column(
      children: [
        // Stats + filters bar
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _miniKpi('Total', _stats['total'] ?? 0),
              const SizedBox(width: 10),
              _miniKpi('Admins', _stats['admins'] ?? 0),
              const SizedBox(width: 10),
              _miniKpi('Doctors', _stats['doctors'] ?? 0),
              const SizedBox(width: 10),
              _miniKpi('Patients', _stats['patients'] ?? 0),
              const Spacer(),
              // Role filter
              _filterDropdown<String?>(
                value: _roleFilter,
                items: const [
                  DropdownMenuItem(value: null, child: Text('All Roles')),
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  DropdownMenuItem(value: 'doctor', child: Text('Doctor')),
                  DropdownMenuItem(value: 'patient', child: Text('Patient')),
                ],
                onChanged: (v) => setState(() => _roleFilter = v),
              ),
              const SizedBox(width: 10),
              // Search
              SizedBox(
                width: 220,
                height: 34,
                child: _searchField(
                  hint: 'Search by name or email...',
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _loadData,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: adminBgSurface,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: adminBorderLight),
                  ),
                  alignment: Alignment.center,
                  child: Icon(Icons.refresh, size: 16, color: adminTextBody),
                ),
              ),
            ],
          ),
        ),

        // Table
        Expanded(
          child: _filteredUsers.isEmpty
              ? Center(child: Text('No users found', style: adminBodyText()))
              : Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  decoration: BoxDecoration(
                    color: adminBgSurface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: adminBorderLight),
                  ),
                  child: Column(
                    children: [
                      // Table header
                      Container(
                        height: 36,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: adminBgSubtle,
                          borderRadius:
                              const BorderRadius.vertical(top: Radius.circular(8)),
                          border: Border(bottom: BorderSide(color: adminBorderLight)),
                        ),
                        child: Row(children: [
                          Expanded(flex: 3, child: _th('NAME')),
                          Expanded(flex: 3, child: _th('EMAIL')),
                          SizedBox(width: 80, child: _th('ROLE')),
                          SizedBox(width: 80, child: _th('STATUS')),
                          SizedBox(width: 130, child: Align(alignment: Alignment.centerRight, child: _th('JOINED'))),
                          const SizedBox(width: 80),
                        ]),
                      ),

                      // Rows
                      Expanded(
                        child: ListView.builder(
                          itemCount: _filteredUsers.length +
                              (_hasMore && _searchQuery.isEmpty && _roleFilter == null ? 1 : 0),
                          itemBuilder: (_, index) {
                            if (index == _filteredUsers.length) {
                              return Padding(
                                padding: const EdgeInsets.all(16),
                                child: Center(
                                  child: _isLoadingMore
                                      ? CircularProgressIndicator(
                                          strokeWidth: 2, color: adminAccent)
                                      : adminSecondaryButton(
                                          label: 'Load More',
                                          icon: Icons.expand_more,
                                          onTap: _loadMoreUsers),
                                ),
                              );
                            }

                            final user = _filteredUsers[index];
                            final isLast = index == _filteredUsers.length - 1;
                            return _userRow(user, isLast);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _userRow(Map<String, dynamic> user, bool isLast) {
    final role = user['role'] as String? ?? 'unknown';
    final isActive = user['is_active'] ?? true;
    final createdAt = DateTime.tryParse(user['created_at'] ?? '');
    final name = _getUserName(user);
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: isLast
          ? null
          : BoxDecoration(border: Border(bottom: BorderSide(color: adminBorderLight))),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Container(
                  width: 30, height: 30,
                  decoration: const BoxDecoration(
                      color: adminAccentTint, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: Text(initial,
                      style: TextStyle(fontFamily: 'DM Sans', 
                          fontSize: 12, fontWeight: FontWeight.w600, color: adminAccent)),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(name,
                      style: TextStyle(fontFamily: 'DM Sans', 
                          fontSize: 13, fontWeight: FontWeight.w500, color: adminTextHeading),
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(user['email'] ?? '',
                style: adminBodyText(), overflow: TextOverflow.ellipsis),
          ),
          SizedBox(
            width: 80,
            child: _roleBadge(role),
          ),
          SizedBox(
            width: 80,
            child: _activeChip(isActive),
          ),
          SizedBox(
            width: 130,
            child: Text(
              createdAt != null ? DateFormat('MMM dd, yyyy').format(createdAt) : '—',
              style: adminMetadata(),
              textAlign: TextAlign.right,
            ),
          ),
          SizedBox(
            width: 80,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _iconBtn(Icons.lock_reset_outlined, () => _resetPassword(user)),
                const SizedBox(width: 4),
                if (isActive)
                  _iconBtn(Icons.block_outlined, () => _deactivateUser(user),
                      color: adminDanger)
                else
                  _iconBtn(Icons.check_circle_outline, () => _reactivateUser(user),
                      color: adminSuccess),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniKpi(String label, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: adminBgSurface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: adminBorderLight),
      ),
      child: Column(
        children: [
          Text('$count',
              style: TextStyle(fontFamily: 'IBM Plex Mono', 
                  fontSize: 18, fontWeight: FontWeight.w600, color: adminTextHeading)),
          Text(label, style: TextStyle(fontFamily: 'DM Sans', fontSize: 11, color: adminTextBody)),
        ],
      ),
    );
  }
}

// ─── Role Permissions Tab ─────────────────────────────────────────────────────

class _RolePermissionsTab extends StatefulWidget {
  final UserManagementService userService;
  const _RolePermissionsTab({required this.userService});

  @override
  State<_RolePermissionsTab> createState() => _RolePermissionsTabState();
}

class _RolePermissionsTabState extends State<_RolePermissionsTab> {
  List<Map<String, dynamic>> _permissions = [];
  bool _isLoading = true;
  final _roles = ['admin', 'doctor', 'patient'];

  @override
  void initState() {
    super.initState();
    _loadPermissions();
  }

  Future<void> _loadPermissions() async {
    setState(() => _isLoading = true);
    final permissions = await widget.userService.getRolePermissions();
    if (mounted) setState(() { _permissions = permissions; _isLoading = false; });
  }

  List<String> get _permissionKeys =>
      _permissions.map((p) => p['permission_key'] as String).toSet().toList()..sort();

  bool _isAllowed(String role, String permissionKey) {
    final perm = _permissions.firstWhere(
      (p) => p['role'] == role && p['permission_key'] == permissionKey,
      orElse: () => {'is_allowed': false},
    );
    return perm['is_allowed'] ?? false;
  }

  Future<void> _togglePermission(String role, String permKey, bool value) async {
    final result = await widget.userService.updateRolePermission(role, permKey, value);
    if (mounted) {
      if (result['success']) {
        _loadPermissions();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result['message']),
          backgroundColor: adminDanger,
        ));
      }
    }
  }

  Future<void> _showAddPermissionDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: adminBgSurface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: adminBorderLight),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text('Add Permission Key',
                    style: TextStyle(fontFamily: 'DM Sans', 
                        fontSize: 16, fontWeight: FontWeight.w600, color: adminTextHeading)),
                const Spacer(),
                GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Icon(Icons.close, size: 20, color: adminTextMuted)),
              ]),
              const SizedBox(height: 20),
              _fieldLabel('Permission Key'),
              _styledInput(controller: controller, hint: 'e.g. manage_billing'),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  adminSecondaryButton(
                      label: 'Cancel', onTap: () => Navigator.pop(ctx, false)),
                  const SizedBox(width: 12),
                  adminPrimaryButton(
                    label: 'Add',
                    onTap: () async {
                      if (controller.text.trim().isEmpty) return;
                      final res = await widget.userService
                          .addPermissionKey(controller.text.trim());
                      if (ctx.mounted) Navigator.pop(ctx, res['success']);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (result == true) _loadPermissions();
  }

  String _fmt(String key) => key.replaceAll('_', ' ').split(' ').map((w) =>
      w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(strokeWidth: 2, color: adminAccent));
    }
    final keys = _permissionKeys;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              Text('${keys.length} permissions configured', style: adminBodyText()),
              const Spacer(),
              adminPrimaryButton(
                  label: 'Add Permission',
                  icon: Icons.add,
                  onTap: _showAddPermissionDialog),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: adminBgSurface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: adminBorderLight),
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: adminBgSubtle,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                      border: Border(bottom: BorderSide(color: adminBorderLight)),
                    ),
                    child: Row(children: [
                      Expanded(flex: 3, child: _th('PERMISSION')),
                      ...(_roles.map((r) => SizedBox(width: 100, child: _th(r.toUpperCase())))),
                      const SizedBox(width: 40),
                    ]),
                  ),
                  // Rows
                  Expanded(
                    child: keys.isEmpty
                        ? Center(child: Text('No permissions configured', style: adminBodyText()))
                        : ListView.builder(
                            itemCount: keys.length,
                            itemBuilder: (_, i) {
                              final key = keys[i];
                              final isLast = i == keys.length - 1;
                              return Container(
                                height: 48,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                decoration: isLast
                                    ? null
                                    : BoxDecoration(
                                        border: Border(
                                            bottom: BorderSide(color: adminBorderLight))),
                                child: Row(children: [
                                  Expanded(
                                    flex: 3,
                                    child: Text(_fmt(key),
                                        style: TextStyle(fontFamily: 'DM Sans', 
                                            fontSize: 13, color: adminTextHeading)),
                                  ),
                                  ...(_roles.map((role) => SizedBox(
                                        width: 100,
                                        child: Switch(
                                          value: _isAllowed(role, key),
                                          onChanged: (v) =>
                                              _togglePermission(role, key, v),
                                          activeThumbColor: adminAccent,
                                          materialTapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                      ))),
                                  SizedBox(
                                    width: 40,
                                    child: GestureDetector(
                                      onTap: () async {
                                        final confirm = await _adminConfirmDialog(
                                          context,
                                          title: 'Delete Permission',
                                          body:
                                              'Remove "${_fmt(key)}" for all roles?',
                                          confirmLabel: 'Delete',
                                          isDanger: true,
                                        );
                                        if (confirm == true) {
                                          await widget.userService
                                              .deletePermissionKey(key);
                                          _loadPermissions();
                                        }
                                      },
                                      child: Icon(Icons.delete_outline,
                                          size: 16, color: adminTextMuted),
                                    ),
                                  ),
                                ]),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Admin Accounts Tab ───────────────────────────────────────────────────────

class _AdminAccountsTab extends StatefulWidget {
  final UserManagementService userService;
  const _AdminAccountsTab({required this.userService});

  @override
  State<_AdminAccountsTab> createState() => _AdminAccountsTabState();
}

class _AdminAccountsTabState extends State<_AdminAccountsTab> {
  List<Map<String, dynamic>> _admins = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAdmins();
  }

  Future<void> _loadAdmins() async {
    setState(() => _isLoading = true);
    final admins = await widget.userService.getAdminAccounts();
    if (mounted) setState(() { _admins = admins; _isLoading = false; });
  }

  Future<void> _showCreateAdminDialog() async {
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final firstCtrl = TextEditingController();
    final lastCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    bool obscure = true;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setDs) => Dialog(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Container(
            width: 480,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: adminBgSurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: adminBorderLight),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text('Create Admin Account',
                        style: TextStyle(fontFamily: 'DM Sans', 
                            fontSize: 16, fontWeight: FontWeight.w600, color: adminTextHeading)),
                    const Spacer(),
                    GestureDetector(
                        onTap: () => Navigator.pop(ctx2),
                        child: Icon(Icons.close, size: 20, color: adminTextMuted)),
                  ]),
                  const SizedBox(height: 20),
                  Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _fieldLabel('First Name *'),
                      _styledInput(controller: firstCtrl, hint: 'First name'),
                    ])),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _fieldLabel('Last Name *'),
                      _styledInput(controller: lastCtrl, hint: 'Last name'),
                    ])),
                  ]),
                  const SizedBox(height: 14),
                  _fieldLabel('Email *'),
                  _styledInput(controller: emailCtrl, hint: 'admin@example.com',
                      keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 14),
                  _fieldLabel('Password *'),
                  _styledInput(
                    controller: passCtrl,
                    hint: 'Min 6 characters',
                    obscureText: obscure,
                    suffixIcon: GestureDetector(
                      onTap: () => setDs(() => obscure = !obscure),
                      child: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          size: 18, color: adminTextMuted),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _fieldLabel('Phone (optional)'),
                  _styledInput(controller: phoneCtrl, hint: '+254 ...',
                      keyboardType: TextInputType.phone),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      adminSecondaryButton(label: 'Cancel', onTap: () => Navigator.pop(ctx2, false)),
                      const SizedBox(width: 12),
                      adminPrimaryButton(
                        label: 'Create Admin',
                        onTap: () async {
                          if (firstCtrl.text.trim().isEmpty || lastCtrl.text.trim().isEmpty ||
                              emailCtrl.text.trim().isEmpty || passCtrl.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: const Text('Fill all required fields'),
                                  backgroundColor: adminDanger),
                            );
                            return;
                          }
                          if (passCtrl.text.length < 6) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: const Text('Password must be ≥ 6 characters'),
                                  backgroundColor: adminDanger),
                            );
                            return;
                          }
                          final res = await widget.userService.createAdminAccount(
                            email: emailCtrl.text.trim(),
                            password: passCtrl.text,
                            firstName: firstCtrl.text.trim(),
                            lastName: lastCtrl.text.trim(),
                            phone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                          );
                          if (ctx2.mounted) {
                            ScaffoldMessenger.of(ctx2).showSnackBar(SnackBar(
                              content: Text(res['message']),
                              backgroundColor: res['success'] ? adminSuccess : adminDanger,
                            ));
                            Navigator.pop(ctx2, res['success']);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (result == true) _loadAdmins();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(strokeWidth: 2, color: adminAccent));
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              Text('${_admins.length} admin accounts', style: adminBodyText()),
              const Spacer(),
              adminPrimaryButton(
                  label: 'Create Admin',
                  icon: Icons.person_add_outlined,
                  onTap: _showCreateAdminDialog),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _admins.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.admin_panel_settings_outlined,
                            size: 48, color: adminBorderLight),
                        const SizedBox(height: 12),
                        Text('No admin accounts found', style: adminBodyText()),
                      ],
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: adminBgSurface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: adminBorderLight),
                    ),
                    child: Column(
                      children: [
                        // Header
                        Container(
                          height: 36,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: adminBgSubtle,
                            borderRadius:
                                const BorderRadius.vertical(top: Radius.circular(8)),
                            border: Border(bottom: BorderSide(color: adminBorderLight)),
                          ),
                          child: Row(children: [
                            Expanded(flex: 2, child: _th('NAME')),
                            Expanded(flex: 3, child: _th('EMAIL')),
                            Expanded(child: _th('STATUS')),
                            SizedBox(width: 130, child: Align(alignment: Alignment.centerRight, child: _th('CREATED'))),
                            const SizedBox(width: 48),
                          ]),
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: _admins.length,
                            itemBuilder: (_, i) {
                              final admin = _admins[i];
                              final profile = admin['admins'];
                              final name = profile != null
                                  ? '${profile['first_name']} ${profile['last_name']}'
                                  : 'N/A';
                              final initial =
                                  profile?['first_name']?.substring(0, 1).toUpperCase() ?? 'A';
                              final createdAt = DateTime.tryParse(admin['created_at'] ?? '');
                              final isActive = admin['is_active'] ?? true;
                              final isLast = i == _admins.length - 1;

                              return Container(
                                height: 52,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                decoration: isLast
                                    ? null
                                    : BoxDecoration(
                                        border: Border(
                                            bottom: BorderSide(color: adminBorderLight))),
                                child: Row(children: [
                                  Expanded(
                                    flex: 2,
                                    child: Row(children: [
                                      Container(
                                        width: 30, height: 30,
                                        decoration: const BoxDecoration(
                                            color: adminAccentTint, shape: BoxShape.circle),
                                        alignment: Alignment.center,
                                        child: Text(initial,
                                            style: TextStyle(fontFamily: 'DM Sans', 
                                                fontSize: 12, fontWeight: FontWeight.w600, color: adminAccent)),
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(name,
                                            style: TextStyle(fontFamily: 'DM Sans', 
                                                fontSize: 13, fontWeight: FontWeight.w500, color: adminTextHeading),
                                            overflow: TextOverflow.ellipsis),
                                      ),
                                    ]),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Text(admin['email'] ?? '',
                                        style: adminBodyText(), overflow: TextOverflow.ellipsis),
                                  ),
                                  Expanded(child: _activeChip(isActive)),
                                  SizedBox(
                                    width: 130,
                                    child: Text(
                                      createdAt != null
                                          ? DateFormat('MMM dd, yyyy').format(createdAt)
                                          : '—',
                                      style: adminMetadata(),
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                  SizedBox(
                                    width: 48,
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: _iconBtn(Icons.lock_reset_outlined, () {
                                        final messenger = ScaffoldMessenger.of(context);
                                        widget.userService
                                            .sendPasswordReset(admin['email'])
                                            .then((res) {
                                          if (mounted) {
                                            messenger.showSnackBar(SnackBar(
                                              content: Text(res['message']),
                                              backgroundColor:
                                                  res['success'] ? adminSuccess : adminDanger,
                                            ));
                                          }
                                        });
                                      }),
                                    ),
                                  ),
                                ]),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared helpers ───────────────────────────────────────────────────────────

Widget _th(String text) => Text(text, style: adminTableHeader());

Widget _roleBadge(String role) {
  Color color;
  switch (role) {
    case 'admin': color = adminDanger; break;
    case 'doctor': color = adminAccent; break;
    case 'patient': color = adminSuccess; break;
    default: color = adminNeutral;
  }
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Text(role.toUpperCase(),
        style: TextStyle(fontFamily: 'DM Sans', 
            fontSize: 10, fontWeight: FontWeight.w600, color: color)),
  );
}

Widget _activeChip(bool isActive) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: isActive ? adminSuccessTint : adminDangerTint,
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(
      isActive ? 'Active' : 'Inactive',
      style: TextStyle(fontFamily: 'DM Sans', 
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: isActive ? adminSuccess : adminDanger),
    ),
  );
}

Widget _iconBtn(IconData icon, VoidCallback onTap, {Color? color}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      width: 28, height: 28,
      decoration: BoxDecoration(
        color: adminBgSubtle,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: adminBorderLight),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 14, color: color ?? adminTextBody),
    ),
  );
}

Widget _searchField({required String hint, required ValueChanged<String> onChanged}) {
  return Container(
    decoration: BoxDecoration(
      color: adminBgSurface,
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: adminBorderLight),
    ),
    child: Row(children: [
      const SizedBox(width: 8),
      Icon(Icons.search, size: 15, color: adminTextMuted),
      const SizedBox(width: 6),
      Expanded(
        child: TextField(
          onChanged: onChanged,
          style: TextStyle(fontFamily: 'DM Sans', fontSize: 13, color: adminTextHeading),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(fontFamily: 'DM Sans', fontSize: 13, color: adminTextMuted),
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ),
      const SizedBox(width: 8),
    ]),
  );
}

Widget _filterDropdown<T>({
  required T value,
  required List<DropdownMenuItem<T>> items,
  required ValueChanged<T?> onChanged,
}) {
  return Container(
    height: 34,
    padding: const EdgeInsets.symmetric(horizontal: 10),
    decoration: BoxDecoration(
      color: adminBgSurface,
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: adminBorderLight),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<T>(
        value: value,
        items: items,
        onChanged: onChanged,
        isDense: true,
        style: TextStyle(fontFamily: 'DM Sans', fontSize: 13, color: adminTextHeading),
        icon: Icon(Icons.keyboard_arrow_down, size: 16, color: adminTextMuted),
      ),
    ),
  );
}

Future<bool?> _adminConfirmDialog(
  BuildContext context, {
  required String title,
  required String body,
  required String confirmLabel,
  required bool isDanger,
}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => Dialog(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Container(
        width: 380,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: adminBgSurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: adminBorderLight),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(fontFamily: 'DM Sans', 
                    fontSize: 16, fontWeight: FontWeight.w600, color: adminTextHeading)),
            const SizedBox(height: 8),
            Text(body, style: adminBodyText()),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                adminSecondaryButton(
                    label: 'Cancel', onTap: () => Navigator.pop(ctx, false)),
                const SizedBox(width: 12),
                isDanger
                    ? adminDangerButton(
                        label: confirmLabel, onTap: () => Navigator.pop(ctx, true))
                    : adminPrimaryButton(
                        label: confirmLabel, onTap: () => Navigator.pop(ctx, true)),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
