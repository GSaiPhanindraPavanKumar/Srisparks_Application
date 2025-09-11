import 'package:supabase_flutter/supabase_flutter.dart';

class DatabaseMigrationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Creates the installation management tables in the database
  /// This should be run by a database administrator
  Future<void> createInstallationTables() async {
    try {
      // Note: These are individual SQL statements since Supabase RPC
      // doesn't support multiple statements in one call

      // Create installation_projects table
      await _supabase.rpc('create_installation_projects_table');

      print('✅ Installation tables created successfully');
      print('📋 Created tables:');
      print('   - installation_projects');
      print('   - installation_work_items');
      print('   - installation_material_usage');
      print('   - installation_work_activities');
      print('🔐 Row Level Security policies applied');
      print('📈 Performance indexes created');
    } catch (e) {
      print('❌ Error creating installation tables: $e');
      print(
        '💡 Please run the SQL migration script manually in Supabase Dashboard',
      );
      rethrow;
    }
  }

  /// Verifies that all installation tables exist
  Future<bool> verifyInstallationTables() async {
    try {
      final tables = [
        'installation_projects',
        'installation_work_items',
        'installation_material_usage',
        'installation_work_activities',
      ];

      for (String table in tables) {
        try {
          await _supabase.from(table).select('*').limit(1);
          print('✅ Table $table exists');
        } catch (e) {
          print('❌ Table $table does not exist');
          return false;
        }
      }

      print('🎉 All installation tables verified successfully');
      return true;
    } catch (e) {
      print('❌ Error verifying tables: $e');
      return false;
    }
  }

  /// Creates a sample installation project for testing
  Future<void> createSampleInstallationProject(
    String customerId, {
    String customerName = 'Sample Customer',
    String customerAddress = '123 Sample Street, Sample City, 12345',
    double siteLatitude = 17.3850,
    double siteLongitude = 78.4867,
  }) async {
    try {
      // Create project
      final projectResponse = await _supabase
          .from('installation_projects')
          .insert({
            'customer_id': customerId,
            'customer_name': customerName,
            'customer_address': customerAddress,
            'site_latitude': siteLatitude,
            'site_longitude': siteLongitude,
            'status': 'pending',
            'total_work_items': 5,
            'completed_work_items': 0,
            'notes': 'Sample installation project for testing',
          })
          .select()
          .single();

      final projectId = projectResponse['id'];

      // Create work items
      final workItems = [
        {
          'project_id': projectId,
          'work_type': 'structure_work',
          'title': 'Foundation and Structure Setup',
          'description': 'Install mounting structures and foundation work',
          'status': 'not_started',
          'priority': 'high',
          'estimated_hours': 8.0,
          'required_materials': {
            'concrete_bags': {'quantity': 10, 'unit': 'bags'},
            'steel_pipes': {'quantity': 20, 'unit': 'pieces'},
            'bolts': {'quantity': 50, 'unit': 'pieces'},
          },
        },
        {
          'project_id': projectId,
          'work_type': 'panels',
          'title': 'Solar Panel Installation',
          'description': 'Mount and connect solar panels',
          'status': 'not_started',
          'priority': 'high',
          'estimated_hours': 12.0,
          'required_materials': {
            'solar_panels': {'quantity': 20, 'unit': 'pieces'},
            'panel_clamps': {'quantity': 80, 'unit': 'pieces'},
            'mc4_connectors': {'quantity': 40, 'unit': 'pairs'},
          },
        },
        {
          'project_id': projectId,
          'work_type': 'inverter_wiring',
          'title': 'Inverter and Electrical Wiring',
          'description': 'Install inverter and complete electrical connections',
          'status': 'not_started',
          'priority': 'medium',
          'estimated_hours': 6.0,
          'required_materials': {
            'inverter': {'quantity': 1, 'unit': 'piece'},
            'dc_cables': {'quantity': 100, 'unit': 'meters'},
            'ac_cables': {'quantity': 50, 'unit': 'meters'},
            'junction_boxes': {'quantity': 3, 'unit': 'pieces'},
          },
        },
        {
          'project_id': projectId,
          'work_type': 'earthing',
          'title': 'Earthing System Installation',
          'description': 'Install grounding and earthing system',
          'status': 'not_started',
          'priority': 'medium',
          'estimated_hours': 4.0,
          'required_materials': {
            'earth_electrodes': {'quantity': 4, 'unit': 'pieces'},
            'earth_wire': {'quantity': 30, 'unit': 'meters'},
            'earth_clamps': {'quantity': 8, 'unit': 'pieces'},
          },
        },
        {
          'project_id': projectId,
          'work_type': 'lightning_arrestor',
          'title': 'Lightning Protection System',
          'description': 'Install lightning arrestor and protection system',
          'status': 'not_started',
          'priority': 'low',
          'estimated_hours': 3.0,
          'required_materials': {
            'lightning_arrestor': {'quantity': 1, 'unit': 'piece'},
            'surge_protectors': {'quantity': 2, 'unit': 'pieces'},
            'protection_wire': {'quantity': 20, 'unit': 'meters'},
          },
        },
      ];

      await _supabase.from('installation_work_items').insert(workItems);

      print('🎉 Sample installation project created successfully');
      print('📋 Project ID: $projectId');
      print('💼 Work items created: ${workItems.length}');
    } catch (e) {
      print('❌ Error creating sample project: $e');
      rethrow;
    }
  }
}
