import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import '../bloc/settings_bloc.dart';
import '../../../../core/utils/db_backup_utils.dart';
import '../../../../core/utils/password_utils.dart';
import '../../../../core/di/injection.dart' as di;
import '../../../../core/data/database/app_database.dart';
import 'package:drift/drift.dart' show Value;

// Supported thermal receipt paper widths (in mm)
const _receiptWidths = [
  _ReceiptWidth('57 mm  (narrow thermal)',   '57'),
  _ReceiptWidth('72 mm  (medium thermal)',   '72'),
  _ReceiptWidth('80 mm  (standard thermal)', '80'),
  _ReceiptWidth('104 mm (wide thermal)',      '104'),
  _ReceiptWidth('A4  (210 mm)',              '210'),
];

class _ReceiptWidth {
  final String label;
  final String valueMm;
  const _ReceiptWidth(this.label, this.valueMm);
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _businessNameController    = TextEditingController();
  final _addressController         = TextEditingController();
  final _phoneController           = TextEditingController();
  final _vatPercentageController   = TextEditingController();
  final _exchangeRateController    = TextEditingController();
  final _receiptFooterController   = TextEditingController();

  bool   _dualCurrencyEnabled = false;
  bool   _vatEnabled          = false;
  String _logoPath            = '';
  String _themeMode           = 'light';   // default light
  String _receiptWidthMm      = '80';      // default 80mm
  bool   _saving              = false;     // true when user clicked Save

  @override
  void initState() {
    super.initState();
    context.read<SettingsBloc>().add(LoadSettings());
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _vatPercentageController.dispose();
    _exchangeRateController.dispose();
    _receiptFooterController.dispose();
    super.dispose();
  }

  void _populateFields(Map<String, String> settings) {
    _businessNameController.text  = settings['business_name']    ?? '';
    _addressController.text       = settings['business_address'] ?? '';
    _phoneController.text         = settings['business_phone']   ?? '';
    _vatPercentageController.text = settings['vat_percentage']   ?? '16';
    _exchangeRateController.text  = settings['usd_exchange_rate'] ?? '2850';
    _receiptFooterController.text = settings['receipt_footer']   ?? 'Thank you for your purchase!';
    _dualCurrencyEnabled = (settings['dual_currency_enabled'] ?? 'false') == 'true';
    _vatEnabled          = (settings['vat_enabled']           ?? 'false') == 'true';
    _logoPath            = settings['business_logo_path'] ?? '';
    _themeMode           = settings['theme_mode']         ?? 'light';
    _receiptWidthMm      = settings['receipt_paper_width_mm'] ?? '80';
  }

  void _onSave() {
    if (_formKey.currentState!.validate()) {
      _saving = true;
      final Map<String, String> updated = {
        'business_name':          _businessNameController.text,
        'business_address':       _addressController.text,
        'business_phone':         _phoneController.text,
        'vat_percentage':         _vatPercentageController.text,
        'usd_exchange_rate':      _exchangeRateController.text,
        'dual_currency_enabled':  _dualCurrencyEnabled.toString(),
        'vat_enabled':            _vatEnabled.toString(),
        'business_logo_path':     _logoPath,
        'receipt_footer':         _receiptFooterController.text,
        'theme_mode':             _themeMode,
        'receipt_paper_width_mm': _receiptWidthMm,
      };
      context.read<SettingsBloc>().add(SaveSettings(updated));
    }
  }

  void _showFactoryResetDialog(BuildContext context) {
    final passwordController = TextEditingController();
    bool obscure = true;
    String? errorText;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setDialogState) => AlertDialog(
          title: const Row(children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Factory Reset', style: TextStyle(color: Colors.red)),
          ]),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'This will permanently DELETE all data including:\n'
                  '• All sales and transaction history\n'
                  '• All inventory and products\n'
                  '• All customers and expenses\n'
                  '• All users (except default admin)\n'
                  '• All settings\n\n'
                  'A backup will be saved before reset. '
                  'You will be asked where to save it.\n\n'
                  'Enter the main admin password to confirm:',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: obscure,
                  decoration: InputDecoration(
                    labelText: 'Admin Password',
                    border: const OutlineInputBorder(),
                    errorText: errorText,
                    suffixIcon: IconButton(
                      icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setDialogState(() => obscure = !obscure),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx2),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
              icon: const Icon(Icons.restart_alt_rounded),
              label: const Text('RESET NOW'),
              onPressed: () async {
                // Verify admin password
                final db = di.sl<AppDatabase>();
                final adminUser = await (db.select(db.users)
                      ..where((t) => t.username.equals('admin')))
                    .getSingleOrNull();

                if (adminUser == null ||
                    !PasswordUtils.verifyPassword(
                        passwordController.text, adminUser.passwordHash)) {
                  setDialogState(() => errorText = 'Incorrect admin password');
                  return;
                }

                Navigator.pop(ctx2);

                // Show progress
                if (!context.mounted) return;
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => const AlertDialog(
                    content: Row(children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 16),
                      Text('Creating backup and resetting...'),
                    ]),
                  ),
                );

                try {
                  final backupPath = await DbBackupUtils.factoryReset();
                  if (backupPath == null) {
                    // User cancelled backup picker
                    if (context.mounted) Navigator.pop(context);
                    return;
                  }
                  if (context.mounted) {
                    Navigator.pop(context); // close progress dialog
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) => AlertDialog(
                        title: const Text('Reset Complete'),
                        content: Text(
                          'Backup saved to:\n$backupPath\n\n'
                          'Please restart the application to complete the factory reset.',
                        ),
                        actions: [
                          ElevatedButton(
                            onPressed: () => exit(0),
                            child: const Text('Exit App'),
                          ),
                        ],
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Reset failed: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _onSave,
            tooltip: 'Save Settings',
          )
        ],
      ),
      body: BlocConsumer<SettingsBloc, SettingsState>(
        listener: (context, state) {
          if (state is SettingsLoaded) {
            _populateFields(state.settings);
            if (_saving) {
              _saving = false;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings saved successfully')),
              );
            }
          } else if (state is SettingsError) {
            _saving = false;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          if (state is SettingsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Business Profile', style: Theme.of(context).textTheme.titleLarge),
                      const Divider(),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _businessNameController,
                        decoration: const InputDecoration(labelText: 'Business Name', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _addressController,
                        maxLines: 2,
                        decoration: const InputDecoration(labelText: 'Address', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 32),

                      // ── Business Logo ──
                      Text('Business Logo', style: Theme.of(context).textTheme.titleLarge),
                      const Divider(),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Preview
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              border: Border.all(color: Theme.of(context).colorScheme.outline),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: _logoPath.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(7),
                                    child: Image.file(
                                      File(_logoPath),
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 40),
                                    ),
                                  )
                                : const Center(child: Icon(Icons.add_a_photo_outlined, size: 40, color: Colors.grey)),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _logoPath.isNotEmpty ? _logoPath : 'No logo selected',
                                  style: Theme.of(context).textTheme.bodySmall,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: () async {
                                        final result = await FilePicker.platform.pickFiles(
                                          type: FileType.image,
                                          allowMultiple: false,
                                          dialogTitle: 'Choose Business Logo',
                                        );
                                        if (result != null && result.files.single.path != null) {
                                          setState(() => _logoPath = result.files.single.path!);
                                        }
                                      },
                                      icon: const Icon(Icons.upload_file),
                                      label: const Text('Choose Logo'),
                                    ),
                                    if (_logoPath.isNotEmpty) ...[  
                                      const SizedBox(width: 8),
                                      TextButton.icon(
                                        onPressed: () => setState(() => _logoPath = ''),
                                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                                        label: const Text('Remove', style: TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'PNG or JPG. Shown on printed receipts.',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),
                      Text('Currency & Exchange', style: Theme.of(context).textTheme.titleLarge),
                      const Divider(),
                      SwitchListTile(
                        title: const Text('Enable Dual Currency (FC/USD)'),
                        value: _dualCurrencyEnabled,
                        onChanged: (val) => setState(() => _dualCurrencyEnabled = val),
                      ),
                      if (_dualCurrencyEnabled) ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _exchangeRateController,
                          decoration: const InputDecoration(
                            labelText: 'USD to FC Exchange Rate (e.g. 2850)',
                            border: OutlineInputBorder(),
                            suffixText: 'FC',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ],
                      const SizedBox(height: 32),

                      Text('VAT Configuration', style: Theme.of(context).textTheme.titleLarge),
                      const Divider(),
                      SwitchListTile(
                        title: const Text('Enable VAT Processing'),
                        value: _vatEnabled,
                        onChanged: (val) => setState(() => _vatEnabled = val),
                      ),
                      if (_vatEnabled) ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _vatPercentageController,
                          decoration: const InputDecoration(
                            labelText: 'VAT Percentage',
                            border: OutlineInputBorder(),
                            suffixText: '%',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ],
                      const SizedBox(height: 32),

                      // ── App Theme ──────────────────────────────────────────
                      Text('App Theme', style: Theme.of(context).textTheme.titleLarge),
                      const Divider(),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _ThemeOption(
                              label: 'Light',
                              icon: Icons.wb_sunny_rounded,
                              selected: _themeMode == 'light',
                              onTap: () => setState(() => _themeMode = 'light'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _ThemeOption(
                              label: 'Dark',
                              icon: Icons.nightlight_round,
                              selected: _themeMode == 'dark',
                              onTap: () => setState(() => _themeMode = 'dark'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Changing the theme takes effect immediately after saving.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 32),

                      // ── Receipt & Printing ─────────────────────────────────
                      Text('Receipt & Printing', style: Theme.of(context).textTheme.titleLarge),
                      const Divider(),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _receiptWidthMm,
                        decoration: const InputDecoration(
                          labelText: 'Thermal Receipt Paper Width',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.receipt_long_outlined),
                          helperText:
                              'Standard is 80 mm. Check your printer\'s paper roll size.',
                        ),
                        items: _receiptWidths
                            .map((w) => DropdownMenuItem(
                                  value: w.valueMm,
                                  child: Text(w.label),
                                ))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _receiptWidthMm = v);
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _receiptFooterController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Receipt Footer Message',
                          border: OutlineInputBorder(),
                          hintText: 'Thank you for your purchase!',
                          prefixIcon: Icon(Icons.comment_outlined),
                        ),
                      ),
                      const SizedBox(height: 32),

                      Text('Data Management', style: Theme.of(context).textTheme.titleLarge),
                      const Divider(),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                try {
                                  final path = await DbBackupUtils.createBackup();
                                  if (path != null) {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Backup saved: $path')));
                                  }
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Backup failed: $e'), backgroundColor: Colors.red));
                                }
                              },
                              icon: const Icon(Icons.backup),
                              label: const Text('MANUAL BACKUP'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                try {
                                  final stagedPath = await DbBackupUtils.stageRestoreBackup();
                                  if (stagedPath != null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Backup staged successfully. Restart the app to complete restore.'),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Restore failed: $e'), backgroundColor: Colors.red));
                                }
                              },
                              icon: const Icon(Icons.restore),
                              label: const Text('RESTORE BACKUP'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // ── Factory Reset ───────────────────────────────────────
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.red.withAlpha(100)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 22),
                              const SizedBox(width: 8),
                              Text('Danger Zone',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.red)),
                            ]),
                            const SizedBox(height: 8),
                            Text(
                              'Factory Reset will erase ALL data (sales, inventory, users, settings) and '
                              'restore the system to its default state. A backup will be created first. '
                              'Only the main admin (username: admin) can perform this action.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () => _showFactoryResetDialog(context),
                                icon: const Icon(Icons.restart_alt_rounded),
                                label: const Text('FACTORY RESET'),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _onSave,
                          icon: const Icon(Icons.save),
                          label: const Text('Save Settings', style: TextStyle(fontSize: 18)),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Theme option card ──────────────────────────────────────────────────────
class _ThemeOption extends StatelessWidget {
  final String    label;
  final IconData  icon;
  final bool      selected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? cs.primary : cs.outline,
            width: selected ? 2 : 1,
          ),
          color: selected ? cs.primaryContainer : cs.surface,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                color: selected ? cs.primary : cs.onSurfaceVariant,
                size: 22),
            const SizedBox(width: 10),
            Text(label,
                style: TextStyle(
                  color: selected ? cs.primary : cs.onSurfaceVariant,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 15,
                )),
          ],
        ),
      ),
    );
  }
}
