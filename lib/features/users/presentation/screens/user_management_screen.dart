import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/data/database/app_database.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/user_bloc.dart';

class UserManagementScreen extends StatelessWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<UserBloc, UserState>(
      listener: (context, state) {
        if (state is UserActionSuccess) {
          context.read<UserBloc>().add(LoadUsers());
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        } else if (state is UserError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: const Color(0xFF1E1520),
            ),
          );
          context.read<UserBloc>().add(LoadUsers());
        }
      },
      builder: (context, state) {
        final users = switch (state) {
          UserLoaded(users: final u)        => u,
          UserActionSuccess(users: final u) => u,
          _ => <User>[],
        };
        final roles = switch (state) {
          UserLoaded(roles: final r)        => r,
          UserActionSuccess(roles: final r) => r,
          _ => <Role>[],
        };
        final isLoading = state is UserLoading || state is UserInitial;

        return Scaffold(
          backgroundColor: AppTheme.bgBase,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ─────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(32, 32, 32, 24),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppTheme.borderSubtle)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('User Management',
                        style: TextStyle(color: AppTheme.textPrimary,
                            fontSize: 24, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text('${users.length} account${users.length == 1 ? '' : 's'}',
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                    ]),
                    FilledButton.icon(
                      onPressed: isLoading
                          ? null
                          : () => _showUpsertDialog(context, roles: roles),
                      icon: const Icon(Icons.person_add_rounded, size: 18),
                      label: const Text('Add User'),
                    ),
                  ],
                ),
              ),

              // ── Body ───────────────────────────────────────────────
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                    : users.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.people_outline_rounded,
                                    size: 64, color: AppTheme.textMuted),
                                SizedBox(height: 16),
                                Text('No users found',
                                    style: TextStyle(color: AppTheme.textSecondary,
                                        fontSize: 16)),
                              ],
                            ),
                          )
                        : _UserTable(users: users, roles: roles),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showUpsertDialog(BuildContext context,
      {User? user, required List<Role> roles}) {
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<UserBloc>(),
        child: _UpsertUserDialog(user: user, roles: roles),
      ),
    );
  }
}

// ── Users table ──────────────────────────────────────────────────────────────
class _UserTable extends StatelessWidget {
  final List<User> users;
  final List<Role> roles;
  const _UserTable({required this.users, required this.roles});

  String _roleName(int? roleId) {
    if (roleId == null) return '—';
    try { return roles.firstWhere((r) => r.id == roleId).name; }
    catch (_) { return '—'; }
  }

  Color _roleColor(String name) {
    switch (name.toLowerCase()) {
      case 'admin':       return AppTheme.accentRed;
      case 'manager':     return AppTheme.accentOrange;
      case 'cashier':     return AppTheme.accentGreen;
      case 'stock clerk': return AppTheme.accentViolet;
      default:            return AppTheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      itemCount: users.length,
      itemBuilder: (_, i) {
        final u   = users[i];
        final rn  = _roleName(u.roleId);
        final col = _roleColor(rn);

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color:        AppTheme.bgCard,
            borderRadius: BorderRadius.circular(12),
            border:       Border.all(color: AppTheme.borderSubtle),
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: CircleAvatar(
              radius: 20,
              backgroundColor: AppTheme.primaryGlow,
              child: Text(
                u.username.isNotEmpty ? u.username[0].toUpperCase() : '?',
                style: const TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
            title: Row(children: [
              Text(u.username,
                style: const TextStyle(color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600, fontSize: 15)),
              const SizedBox(width: 10),
              _RoleBadge(rn, col),
              if (!u.isActive) ...[
                const SizedBox(width: 8),
                _StatusBadge('Inactive', AppTheme.textMuted),
              ],
              if (u.requirePasswordChange) ...[
                const SizedBox(width: 8),
                _StatusBadge('Must Change Password', AppTheme.accentOrange),
              ],
            ]),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                u.lastLoginAt != null
                    ? 'Last login: ${_fmt(u.lastLoginAt!)}'
                    : 'Never logged in',
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
              ),
            ),
            trailing: _UserActions(user: u, roles: roles),
          ),
        );
      },
    );
  }

  String _fmt(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/${dt.year}  '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _RoleBadge extends StatelessWidget {
  final String label;
  final Color  color;
  const _RoleBadge(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color:        color.withAlpha(30),
        borderRadius: BorderRadius.circular(6),
        border:       Border.all(color: color.withAlpha(60)),
      ),
      child: Text(label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color  color;
  const _StatusBadge(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color:        color.withAlpha(20),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

// ── Per-row action menu ───────────────────────────────────────────────────────
class _UserActions extends StatelessWidget {
  final User       user;
  final List<Role> roles;
  const _UserActions({required this.user, required this.roles});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      color:        AppTheme.bgCardHover,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppTheme.borderDefault),
      ),
      icon: const Icon(Icons.more_vert_rounded, color: AppTheme.textSecondary),
      onSelected: (action) => _handle(context, action),
      itemBuilder: (_) => [
        _menuItem('edit',   Icons.edit_rounded,         'Edit User'),
        _menuItem('reset',  Icons.lock_reset_rounded,    'Reset Password'),
        _menuItem(
          user.isActive ? 'deactivate' : 'activate',
          user.isActive ? Icons.block_rounded : Icons.check_circle_outline_rounded,
          user.isActive ? 'Deactivate' : 'Activate',
        ),
        if (user.username != 'admin')
          _menuItem('delete', Icons.delete_outline_rounded, 'Delete', isRed: true),
      ],
    );
  }

  PopupMenuItem<String> _menuItem(String value, IconData icon, String label,
      {bool isRed = false}) {
    return PopupMenuItem(
      value: value,
      child: Row(children: [
        Icon(icon,
            color: isRed ? AppTheme.accentRed : AppTheme.textSecondary, size: 18),
        const SizedBox(width: 10),
        Text(label,
          style: TextStyle(
            color: isRed ? AppTheme.accentRed : AppTheme.textPrimary,
            fontSize: 14,
          )),
      ]),
    );
  }

  void _handle(BuildContext context, String action) {
    switch (action) {
      case 'edit':
        showDialog(
          context: context,
          builder: (_) => BlocProvider.value(
            value: context.read<UserBloc>(),
            child: _UpsertUserDialog(user: user, roles: roles),
          ),
        );
      case 'reset':
        showDialog(
          context: context,
          builder: (_) => BlocProvider.value(
            value: context.read<UserBloc>(),
            child: _ResetPasswordDialog(user: user),
          ),
        );
      case 'activate':
        context.read<UserBloc>().add(ToggleUserActive(user.id, true));
      case 'deactivate':
        context.read<UserBloc>().add(ToggleUserActive(user.id, false));
      case 'delete':
        _confirmDelete(context);
    }
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete User'),
        content: Text(
          'Are you sure you want to delete "${user.username}"?\nThis cannot be undone.',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.accentRed),
            onPressed: () {
              context.read<UserBloc>().add(DeleteUser(user.id));
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ── Create / Edit user dialog ────────────────────────────────────────────────
class _UpsertUserDialog extends StatefulWidget {
  final User?      user;
  final List<Role> roles;
  const _UpsertUserDialog({this.user, required this.roles});

  @override
  State<_UpsertUserDialog> createState() => _UpsertUserDialogState();
}

class _UpsertUserDialogState extends State<_UpsertUserDialog> {
  final _formKey    = GlobalKey<FormState>();
  final _userCtrl   = TextEditingController();
  final _passCtrl   = TextEditingController();
  int?   _roleId;
  bool   _requireChange = true;
  bool   _obscure       = true;
  bool   get _isEdit  => widget.user != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _userCtrl.text = widget.user!.username;
      _roleId        = widget.user!.roleId;
      _requireChange = widget.user!.requirePasswordChange;
    } else {
      _roleId = widget.roles.isNotEmpty ? widget.roles.first.id : null;
    }
  }

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _onSave() {
    if (!_formKey.currentState!.validate()) return;
    if (_isEdit) {
      context.read<UserBloc>().add(UpdateUser(
        widget.user!.id,
        UsersCompanion(
          username:              Value(_userCtrl.text.trim()),
          roleId:                Value(_roleId!),
          requirePasswordChange: Value(_requireChange),
        ),
      ));
    } else {
      context.read<UserBloc>().add(CreateUser(
        username:             _userCtrl.text.trim(),
        password:             _passCtrl.text,
        roleId:               _roleId!,
        requirePasswordChange: _requireChange,
      ));
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEdit ? 'Edit User' : 'Create New User'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Username
              TextFormField(
                controller: _userCtrl,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Username',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // Password (only required on create)
              if (!_isEdit) ...[
                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscure,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (v.length < 4) return 'Min 4 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],

              // Role
              DropdownButtonFormField<int>(
                value: _roleId,
                style: const TextStyle(color: AppTheme.textPrimary),
                dropdownColor: AppTheme.bgCardHover,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                items: widget.roles.map((r) => DropdownMenuItem(
                  value: r.id,
                  child: Text(r.name),
                )).toList(),
                onChanged: (v) => setState(() => _roleId = v),
                validator: (v) => v == null ? 'Select a role' : null,
              ),
              const SizedBox(height: 8),

              // Require password change
              CheckboxListTile(
                value:   _requireChange,
                onChanged: (v) => setState(() => _requireChange = v ?? true),
                title: const Text('Require password change on first login',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                activeColor: AppTheme.primary,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _onSave,
          child: Text(_isEdit ? 'Save Changes' : 'Create User'),
        ),
      ],
    );
  }
}

// ── Reset password dialog ─────────────────────────────────────────────────────
class _ResetPasswordDialog extends StatefulWidget {
  final User user;
  const _ResetPasswordDialog({required this.user});

  @override
  State<_ResetPasswordDialog> createState() => _ResetPasswordDialogState();
}

class _ResetPasswordDialogState extends State<_ResetPasswordDialog> {
  final _ctrl    = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool  _obscure = true;

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Reset Password for "${widget.user.username}"'),
      content: SizedBox(
        width: 380,
        child: Form(
          key: _formKey,
          child: TextFormField(
            controller: _ctrl,
            obscureText: _obscure,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: InputDecoration(
              labelText: 'New Password',
              prefixIcon: const Icon(Icons.lock_reset_rounded),
              suffixIcon: IconButton(
                icon: Icon(_obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Required';
              if (v.length < 4) return 'Min 4 characters';
              return null;
            },
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              context.read<UserBloc>().add(
                  ResetUserPassword(widget.user.id, _ctrl.text));
              Navigator.pop(context);
            }
          },
          child: const Text('Reset Password'),
        ),
      ],
    );
  }
}
