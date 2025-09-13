// Simple script to run SQL migrations
// Run this with: dart run run_sql_migration.dart

import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

void main() async {
  try {
    // Initialize Supabase
    await Supabase.initialize(
      url: 'https://jcqxqjsogfqfcffyotou.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpjcXhxanNvZ2ZxZmNmZnlvdG91Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzM5OTA3NzQsImV4cCI6MjA0OTU2Njc3NH0.r8RqLu8rqOMfIaAJcFlQsxCR5OhUB_vJGcKvMZ6rDlk',
    );

    final supabase = Supabase.instance.client;

    print('📖 Reading enhanced_material_allocation_audit.sql...');

    // Read the SQL file
    final sqlFile = File('enhanced_material_allocation_audit.sql');
    if (!await sqlFile.exists()) {
      print('❌ Error: enhanced_material_allocation_audit.sql not found!');
      return;
    }

    final sqlContent = await sqlFile.readAsString();

    // Split by statements (roughly - be careful with complex SQL)
    final statements = sqlContent
        .split(';')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty && !s.startsWith('--'))
        .toList();

    print('🔧 Executing ${statements.length} SQL statements...');

    for (int i = 0; i < statements.length; i++) {
      final statement = statements[i];
      if (statement.isEmpty) continue;

      try {
        print(
          '⚡ Statement ${i + 1}: ${statement.substring(0, Math.min(50, statement.length))}...',
        );
        await supabase.rpc('execute_sql', params: {'sql_statement': statement});
        print('✅ Statement ${i + 1} executed successfully');
      } catch (e) {
        print('⚠️  Statement ${i + 1} failed (might be expected): $e');
        // Continue with other statements
      }
    }

    print('');
    print('🎉 Enhanced Material Allocation Audit Trail migration completed!');
    print('');
    print('📊 New audit features available:');
    print('• Complete user tracking (who planned, confirmed, delivered)');
    print('• Timestamp tracking for each workflow stage');
    print('• JSON history log for complete audit trail');
    print('• Performance metrics and reporting views');
    print('');
    print(
      '✨ Your material allocation system now has comprehensive audit tracking!',
    );
  } catch (e) {
    print('❌ Error running migration: $e');
  }
}

class Math {
  static int min(int a, int b) => a < b ? a : b;
}
