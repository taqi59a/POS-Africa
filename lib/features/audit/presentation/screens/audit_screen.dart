import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/audit_bloc.dart';

class AuditScreen extends StatefulWidget {
  const AuditScreen({super.key});

  @override
  State<AuditScreen> createState() => _AuditScreenState();
}

class _AuditScreenState extends State<AuditScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AuditBloc>().add(LoadAuditLogs());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('System Audit Logs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<AuditBloc>().add(LoadAuditLogs()),
          ),
        ],
      ),
      body: BlocBuilder<AuditBloc, AuditState>(
        builder: (context, state) {
          if (state is AuditLoading) return const Center(child: CircularProgressIndicator());
          if (state is AuditLogsLoaded) {
            if (state.logs.isEmpty) return const Center(child: Text('No logs found.'));
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: state.logs.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final log = state.logs[index];
                return ListTile(
                  leading: _getIconForAction(log.action),
                  title: Text(log.action, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${log.timestamp.day}/${log.timestamp.month}/${log.timestamp.year} ${log.timestamp.hour}:${log.timestamp.minute.toString().padLeft(2, '0')} • User ID: ${log.userId ?? 'System'}'),
                  trailing: log.details != null ? IconButton(
                    icon: const Icon(Icons.info_outline),
                    onPressed: () => _showDetails(context, log.details!),
                  ) : null,
                );
              },
            );
          }
          return const SizedBox();
        },
      ),
    );
  }

  Widget _getIconForAction(String action) {
    if (action.contains('LOGIN')) return const Icon(Icons.login, color: Colors.blue);
    if (action.contains('SALE')) return const Icon(Icons.shopping_cart, color: Colors.green);
    if (action.contains('VOID')) return const Icon(Icons.cancel, color: Colors.red);
    if (action.contains('DELETE')) return const Icon(Icons.delete, color: Colors.red);
    return const Icon(Icons.info, color: Colors.grey);
  }

  void _showDetails(BuildContext context, String details) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Details'),
        content: Text(details),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CLOSE'))],
      ),
    );
  }
}
