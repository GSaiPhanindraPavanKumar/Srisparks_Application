import 'package:flutter/material.dart';
import '../services/database_migration_service.dart';

class DatabaseSetupScreen extends StatefulWidget {
  const DatabaseSetupScreen({super.key});

  @override
  State<DatabaseSetupScreen> createState() => _DatabaseSetupScreenState();
}

class _DatabaseSetupScreenState extends State<DatabaseSetupScreen> {
  final DatabaseMigrationService _migrationService = DatabaseMigrationService();
  bool _isLoading = false;
  String _statusMessage = '';
  bool _tablesExist = false;

  @override
  void initState() {
    super.initState();
    _checkTables();
  }

  Future<void> _checkTables() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Checking database tables...';
    });

    try {
      final exists = await _migrationService.verifyInstallationTables();
      setState(() {
        _tablesExist = exists;
        _statusMessage = exists
            ? '✅ All installation tables are set up correctly!'
            : '❌ Installation tables are missing. Please run the SQL migration.';
      });
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Error checking tables: $e';
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _createSampleData() async {
    // You would need to provide a valid customer ID here
    // This is just a placeholder
    setState(() {
      _statusMessage =
          '⚠️ Sample data creation requires a valid customer ID. Please implement this feature in your admin panel.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Database Setup'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _tablesExist ? Icons.check_circle : Icons.error,
                          color: _tablesExist ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Installation Database Status',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_isLoading)
                      const Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text('Checking...'),
                        ],
                      )
                    else
                      Text(
                        _statusMessage,
                        style: TextStyle(
                          color: _tablesExist ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Required Tables:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text('• installation_projects'),
                    Text('• installation_work_items'),
                    Text('• installation_material_usage'),
                    Text('• installation_work_activities'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _isLoading ? null : _checkTables,
                  child: const Text('Check Tables'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _tablesExist && !_isLoading
                      ? _createSampleData
                      : null,
                  child: const Text('Create Sample Data'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (!_tablesExist)
              Card(
                color: Colors.orange.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning, color: Colors.orange.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'Setup Required',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'To use the Installation Management System, you need to run the SQL migration script in your Supabase dashboard.',
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Steps:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Text('1. Open Supabase Dashboard'),
                      const Text('2. Go to SQL Editor'),
                      const Text(
                        '3. Run database/migrations/create_installation_tables.sql',
                      ),
                      const Text('4. Come back and click "Check Tables"'),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
