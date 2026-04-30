import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/settings_bloc.dart';
import '../../../../core/utils/db_backup_utils.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _businessNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _vatPercentageController = TextEditingController();
  final _exchangeRateController = TextEditingController();

  bool _dualCurrencyEnabled = false;
  bool _vatEnabled = false;

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
    super.dispose();
  }

  void _populateFields(Map<String, String> settings) {
    _businessNameController.text = settings['business_name'] ?? '';
    _addressController.text = settings['business_address'] ?? '';
    _phoneController.text = settings['business_phone'] ?? '';
    _vatPercentageController.text = settings['vat_percentage'] ?? '16';
    _exchangeRateController.text = settings['usd_exchange_rate'] ?? '2850';
    _dualCurrencyEnabled = (settings['dual_currency_enabled'] ?? 'false') == 'true';
    _vatEnabled = (settings['vat_enabled'] ?? 'false') == 'true';
  }

  void _onSave() {
    if (_formKey.currentState!.validate()) {
      final Map<String, String> updated = {
        'business_name': _businessNameController.text,
        'business_address': _addressController.text,
        'business_phone': _phoneController.text,
        'vat_percentage': _vatPercentageController.text,
        'usd_exchange_rate': _exchangeRateController.text,
        'dual_currency_enabled': _dualCurrencyEnabled.toString(),
        'vat_enabled': _vatEnabled.toString(),
      };
      context.read<SettingsBloc>().add(SaveSettings(updated));
    }
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
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Settings saved successfully')),
            );
          } else if (state is SettingsError) {
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
                      
                      Text('Currency & Exchange', style: Theme.of(context).textTheme.titleLarge),
                      const Divider(),
                      SwitchListTile(
                        title: const Text('Enable Dual Currency (CDF/USD)'),
                        value: _dualCurrencyEnabled,
                        onChanged: (val) => setState(() => _dualCurrencyEnabled = val),
                      ),
                      if (_dualCurrencyEnabled) ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _exchangeRateController,
                          decoration: const InputDecoration(
                            labelText: 'USD to CDF Exchange Rate (e.g. 2850)',
                            border: OutlineInputBorder(),
                            suffixText: 'CDF',
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
                                  await DbBackupUtils.restoreBackup();
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Database restored! Please restart the app.')));
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
