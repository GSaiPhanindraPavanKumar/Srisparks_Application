# Database-Driven Notification System - Comprehensive Recommendation

## Current System Analysis

### ✅ What's Working (Your Current Approach)
- **Hardcoded schedules:** 9:00 AM and 9:15 AM attendance reminders
- **Local scheduling:** flutter_local_notifications with device-level scheduling
- **Role-based:** Directors excluded, others included
- **Status-aware:** Checks if user already checked in

### ❌ Current Limitations
1. **Inflexible timing:** Can't change reminder times without app update
2. **One-size-fits-all:** All users get same reminders (except directors)
3. **No per-office customization:** Different offices might need different times
4. **No dynamic scheduling:** Can't add new reminder types without code changes
5. **Limited tracking:** No history of which reminders were sent/received
6. **No analytics:** Can't see notification delivery/open rates
7. **No server control:** Can't remotely manage notifications

---

## Recommended Approach: Hybrid Database + Local System

### Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         SUPABASE DATABASE                        │
├─────────────────────────────────────────────────────────────────┤
│  notification_schedules           notification_templates        │
│  ├─ id                            ├─ id                         │
│  ├─ type (attendance/meeting)     ├─ type                       │
│  ├─ time (HH:MM)                  ├─ title_template             │
│  ├─ days (Mon-Sun)                ├─ body_template              │
│  ├─ enabled                       ├─ priority                   │
│  ├─ target_roles                  └─ icon                       │
│  ├─ target_offices                                              │
│  └─ created_at                    notification_history          │
│                                   ├─ id                          │
│  notification_preferences         ├─ user_id                    │
│  ├─ user_id                       ├─ schedule_id                │
│  ├─ schedule_id                   ├─ sent_at                    │
│  ├─ enabled                       ├─ delivered_at               │
│  ├─ custom_time                   ├─ opened_at                  │
│  └─ snooze_until                  ├─ dismissed_at               │
│                                   └─ status                     │
└─────────────────────────────────────────────────────────────────┘
                              ↓
                    Sync on App Start
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                      FLUTTER APP (LOCAL)                         │
├─────────────────────────────────────────────────────────────────┤
│  1. Fetch notification schedules from database                  │
│  2. Apply user preferences                                      │
│  3. Schedule with flutter_local_notifications                   │
│  4. Track delivery and actions                                  │
│  5. Sync history back to database                               │
└─────────────────────────────────────────────────────────────────┘
```

---

## Database Schema Design

### Table 1: `notification_schedules`
**Purpose:** Define when and to whom notifications should be sent

```sql
CREATE TABLE notification_schedules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Schedule details
    type TEXT NOT NULL, -- 'attendance', 'meeting', 'deadline', 'announcement'
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    
    -- Timing
    schedule_time TIME NOT NULL, -- e.g., '09:00:00'
    days_of_week INTEGER[] DEFAULT '{1,2,3,4,5}', -- 1=Mon, 7=Sun (Mon-Fri)
    timezone TEXT DEFAULT 'Asia/Kolkata',
    
    -- Targeting
    target_roles TEXT[] DEFAULT '{}', -- ['manager', 'employee', 'lead']
    target_offices UUID[], -- null = all offices
    target_users UUID[], -- null = all users matching role/office
    
    -- Conditions
    condition_type TEXT, -- 'not_checked_in', 'task_pending', 'approval_pending'
    condition_value JSONB, -- additional condition parameters
    
    -- Control
    enabled BOOLEAN DEFAULT true,
    priority TEXT DEFAULT 'high', -- 'low', 'medium', 'high', 'urgent'
    
    -- Metadata
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Soft delete
    deleted_at TIMESTAMPTZ
);

-- Indexes
CREATE INDEX idx_notification_schedules_enabled ON notification_schedules(enabled) WHERE deleted_at IS NULL;
CREATE INDEX idx_notification_schedules_type ON notification_schedules(type);
```

### Table 2: `notification_templates`
**Purpose:** Reusable templates with dynamic variables

```sql
CREATE TABLE notification_templates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    name TEXT NOT NULL UNIQUE,
    type TEXT NOT NULL,
    
    -- Template with variables
    title_template TEXT NOT NULL, -- '⏰ Attendance Reminder for {user_name}'
    body_template TEXT NOT NULL, -- 'Hi {user_name}, please check in at {office_name}'
    
    -- Variables definition
    variables JSONB, -- ['user_name', 'office_name', 'date', 'time']
    
    -- Display
    icon TEXT DEFAULT 'notifications',
    color TEXT DEFAULT '#2196F3',
    sound TEXT DEFAULT 'default',
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Sample data
INSERT INTO notification_templates (name, type, title_template, body_template, variables) VALUES
('attendance_first_reminder', 'attendance', 
 '⏰ Attendance Reminder', 
 'Hi {user_name}, please check in for today at {office_name}',
 '["user_name", "office_name"]'),
 
('attendance_final_reminder', 'attendance',
 '🚨 Final Reminder: Check-in Now',
 '{user_name}, this is your last reminder to check in. Office: {office_name}',
 '["user_name", "office_name"]');
```

### Table 3: `notification_preferences`
**Purpose:** User-specific customization

```sql
CREATE TABLE notification_preferences (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) NOT NULL,
    schedule_id UUID REFERENCES notification_schedules(id) NOT NULL,
    
    -- User customization
    enabled BOOLEAN DEFAULT true,
    custom_time TIME, -- override default schedule time
    custom_days INTEGER[], -- override default days
    snooze_until TIMESTAMPTZ,
    
    -- Preferences
    sound_enabled BOOLEAN DEFAULT true,
    vibration_enabled BOOLEAN DEFAULT true,
    priority_override TEXT, -- 'low', 'medium', 'high'
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(user_id, schedule_id)
);
```

### Table 4: `notification_history`
**Purpose:** Track delivery and engagement

```sql
CREATE TABLE notification_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- References
    schedule_id UUID REFERENCES notification_schedules(id),
    user_id UUID REFERENCES users(id) NOT NULL,
    
    -- Content sent
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    type TEXT NOT NULL,
    
    -- Timing
    scheduled_for TIMESTAMPTZ NOT NULL,
    sent_at TIMESTAMPTZ, -- when notification was scheduled locally
    delivered_at TIMESTAMPTZ, -- when device received it
    opened_at TIMESTAMPTZ, -- when user tapped it
    dismissed_at TIMESTAMPTZ, -- when user dismissed it
    
    -- Status
    status TEXT DEFAULT 'scheduled', -- 'scheduled', 'sent', 'delivered', 'opened', 'dismissed', 'failed'
    
    -- Device info
    device_id TEXT,
    platform TEXT, -- 'android', 'ios'
    
    -- Action taken
    action_type TEXT, -- 'opened', 'dismissed', 'snoozed', 'action_button_clicked'
    action_data JSONB,
    
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for analytics
CREATE INDEX idx_notification_history_user ON notification_history(user_id);
CREATE INDEX idx_notification_history_schedule ON notification_history(schedule_id);
CREATE INDEX idx_notification_history_status ON notification_history(status);
CREATE INDEX idx_notification_history_sent_at ON notification_history(sent_at);
```

### Table 5: `notification_sync_log`
**Purpose:** Track when devices synced schedules

```sql
CREATE TABLE notification_sync_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) NOT NULL,
    device_id TEXT NOT NULL,
    
    sync_type TEXT NOT NULL, -- 'full', 'incremental'
    schedules_synced INTEGER DEFAULT 0,
    last_schedule_version TIMESTAMPTZ,
    
    synced_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Track any issues
    error_count INTEGER DEFAULT 0,
    last_error TEXT
);
```

---

## Flutter Implementation

### 1. New Service: `DatabaseNotificationService`

```dart
// lib/services/database_notification_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'notification_service.dart';
import 'auth_service.dart';

class DatabaseNotificationService {
  final _supabase = Supabase.instance.client;
  final _notificationService = NotificationService();
  final _authService = AuthService();
  
  /// Fetch notification schedules from database
  Future<List<NotificationSchedule>> fetchSchedules() async {
    final user = await _authService.getCurrentUser();
    if (user == null) return [];
    
    // Fetch schedules applicable to this user
    final response = await _supabase
        .from('notification_schedules')
        .select()
        .eq('enabled', true)
        .or('target_roles.cs.{${user.role}},target_roles.is.null')
        .is_('deleted_at', null);
    
    return (response as List)
        .map((json) => NotificationSchedule.fromJson(json))
        .toList();
  }
  
  /// Fetch user preferences
  Future<Map<String, NotificationPreference>> fetchUserPreferences() async {
    final user = await _authService.getCurrentUser();
    if (user == null) return {};
    
    final response = await _supabase
        .from('notification_preferences')
        .select()
        .eq('user_id', user.id);
    
    return Map.fromEntries(
      (response as List).map((json) {
        final pref = NotificationPreference.fromJson(json);
        return MapEntry(pref.scheduleId, pref);
      }),
    );
  }
  
  /// Sync schedules from database and schedule locally
  Future<void> syncAndScheduleNotifications() async {
    print('🔄 Syncing notifications from database...');
    
    try {
      // 1. Fetch schedules
      final schedules = await fetchSchedules();
      final preferences = await fetchUserPreferences();
      
      print('📥 Fetched ${schedules.length} schedules');
      
      // 2. Cancel all existing local notifications
      await _notificationService.cancelAllNotifications();
      
      // 3. Schedule each notification locally
      for (final schedule in schedules) {
        final pref = preferences[schedule.id];
        
        // Skip if user disabled this schedule
        if (pref?.enabled == false) continue;
        
        // Use custom time if user set one
        final scheduleTime = pref?.customTime ?? schedule.scheduleTime;
        
        // Check conditions (e.g., only if not checked in)
        if (await _shouldScheduleNotification(schedule)) {
          await _scheduleLocalNotification(schedule, scheduleTime);
        }
      }
      
      print('✅ Notifications synced and scheduled');
      
      // 4. Log sync
      await _logSync(schedules.length);
      
    } catch (e) {
      print('❌ Error syncing notifications: $e');
    }
  }
  
  /// Schedule a single notification locally
  Future<void> _scheduleLocalNotification(
    NotificationSchedule schedule,
    TimeOfDay time,
  ) async {
    final user = await _authService.getCurrentUser();
    
    // Replace template variables
    final title = _replaceVariables(schedule.title, {
      'user_name': user?.fullName ?? 'User',
      'office_name': user?.officeName ?? 'Office',
    });
    
    final body = _replaceVariables(schedule.body, {
      'user_name': user?.fullName ?? 'User',
      'office_name': user?.officeName ?? 'Office',
      'date': DateFormat('MMM dd').format(DateTime.now()),
    });
    
    // Schedule using existing notification service
    await _notificationService.scheduleNotification(
      id: schedule.id.hashCode,
      title: title,
      body: body,
      scheduledTime: time,
      payload: jsonEncode({
        'schedule_id': schedule.id,
        'type': schedule.type,
      }),
    );
    
    // Track in history
    await _trackScheduled(schedule.id, title, body);
  }
  
  /// Replace template variables
  String _replaceVariables(String template, Map<String, String> variables) {
    var result = template;
    variables.forEach((key, value) {
      result = result.replaceAll('{$key}', value);
    });
    return result;
  }
  
  /// Check if notification should be scheduled based on conditions
  Future<bool> _shouldScheduleNotification(NotificationSchedule schedule) async {
    if (schedule.conditionType == null) return true;
    
    switch (schedule.conditionType) {
      case 'not_checked_in':
        final user = await _authService.getCurrentUser();
        if (user == null) return false;
        return !(await _attendanceService.hasCheckedInToday(user.id));
      
      case 'task_pending':
        // Implement task checking logic
        return true;
      
      default:
        return true;
    }
  }
  
  /// Track notification in history
  Future<void> _trackScheduled(String scheduleId, String title, String body) async {
    final user = await _authService.getCurrentUser();
    if (user == null) return;
    
    await _supabase.from('notification_history').insert({
      'schedule_id': scheduleId,
      'user_id': user.id,
      'title': title,
      'body': body,
      'type': 'reminder',
      'scheduled_for': DateTime.now().toIso8601String(),
      'sent_at': DateTime.now().toIso8601String(),
      'status': 'sent',
      'device_id': await _getDeviceId(),
      'platform': Platform.isAndroid ? 'android' : 'ios',
    });
  }
  
  /// Track notification opened
  Future<void> trackNotificationOpened(String scheduleId) async {
    final user = await _authService.getCurrentUser();
    if (user == null) return;
    
    await _supabase
        .from('notification_history')
        .update({
          'opened_at': DateTime.now().toIso8601String(),
          'status': 'opened',
        })
        .eq('schedule_id', scheduleId)
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .limit(1);
  }
  
  /// Log sync operation
  Future<void> _logSync(int schedulesCount) async {
    final user = await _authService.getCurrentUser();
    if (user == null) return;
    
    await _supabase.from('notification_sync_log').insert({
      'user_id': user.id,
      'device_id': await _getDeviceId(),
      'sync_type': 'full',
      'schedules_synced': schedulesCount,
      'last_schedule_version': DateTime.now().toIso8601String(),
    });
  }
  
  Future<String> _getDeviceId() async {
    // Implement device ID retrieval
    final prefs = await SharedPreferences.getInstance();
    var deviceId = prefs.getString('device_id');
    if (deviceId == null) {
      deviceId = Uuid().v4();
      await prefs.setString('device_id', deviceId);
    }
    return deviceId;
  }
}

// Models
class NotificationSchedule {
  final String id;
  final String type;
  final String title;
  final String body;
  final TimeOfDay scheduleTime;
  final List<int> daysOfWeek;
  final List<String> targetRoles;
  final bool enabled;
  final String? conditionType;
  
  NotificationSchedule.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        type = json['type'],
        title = json['title'],
        body = json['body'],
        scheduleTime = _parseTime(json['schedule_time']),
        daysOfWeek = List<int>.from(json['days_of_week'] ?? [1,2,3,4,5]),
        targetRoles = List<String>.from(json['target_roles'] ?? []),
        enabled = json['enabled'] ?? true,
        conditionType = json['condition_type'];
  
  static TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }
}

class NotificationPreference {
  final String userId;
  final String scheduleId;
  final bool enabled;
  final TimeOfDay? customTime;
  
  NotificationPreference.fromJson(Map<String, dynamic> json)
      : userId = json['user_id'],
        scheduleId = json['schedule_id'],
        enabled = json['enabled'] ?? true,
        customTime = json['custom_time'] != null 
            ? NotificationSchedule._parseTime(json['custom_time'])
            : null;
}
```

### 2. Update AuthScreen to sync on login

```dart
// In auth_screen.dart _requestPermissionsIfNeeded()
Future<void> _requestPermissionsIfNeeded() async {
  try {
    // ... existing permission code ...
    
    // NEW: Sync notification schedules from database
    final dbNotificationService = DatabaseNotificationService();
    await dbNotificationService.syncAndScheduleNotifications();
    
    print('Permissions and notifications configured');
  } catch (e) {
    print('Error requesting permissions: $e');
  }
}
```

### 3. Admin Panel (Web/Mobile)

Create an admin interface to manage schedules:

```dart
// lib/screens/admin/notification_schedules_screen.dart
class NotificationSchedulesScreen extends StatefulWidget {
  // CRUD interface for notification_schedules table
  // - List all schedules
  // - Create new schedule
  // - Edit existing schedule
  // - Enable/disable schedule
  // - Preview notification
  // - View analytics (delivery rate, open rate)
}
```

---

## Benefits of Database-Driven Approach

### 1. **Flexibility** 🎯
- ✅ Change reminder times without app update
- ✅ Add new notification types instantly
- ✅ A/B test different notification timings
- ✅ Customize per office/role/user

### 2. **Control** 🎛️
- ✅ Enable/disable notifications remotely
- ✅ Emergency announcements to all users
- ✅ Office-specific notifications
- ✅ Role-based targeting

### 3. **Personalization** 👤
- ✅ Users can customize their reminder times
- ✅ Snooze functionality
- ✅ Different schedules for different days
- ✅ Opt-out of specific reminders

### 4. **Analytics** 📊
- ✅ Track delivery rates
- ✅ Monitor open rates
- ✅ See which reminders are effective
- ✅ Identify users who need follow-up

### 5. **Scalability** 📈
- ✅ Easy to add new notification types
- ✅ Support multiple languages
- ✅ Dynamic templates
- ✅ Condition-based scheduling

### 6. **Reliability** ✅
- ✅ Backup schedules in database
- ✅ Sync on app start
- ✅ Recover from device changes
- ✅ Audit trail

---

## Implementation Phases

### Phase 1: Database Setup (1-2 days)
1. Create tables in Supabase
2. Add sample data
3. Set up RLS (Row Level Security)
4. Create indexes

### Phase 2: Flutter Service (2-3 days)
1. Create `DatabaseNotificationService`
2. Implement sync logic
3. Update `NotificationService` to support dynamic scheduling
4. Add tracking/analytics

### Phase 3: Admin Interface (3-4 days)
1. Create schedule management screen
2. CRUD operations
3. Preview functionality
4. Analytics dashboard

### Phase 4: User Preferences (1-2 days)
1. User settings screen
2. Custom time selection
3. Enable/disable toggles
4. Snooze functionality

### Phase 5: Testing & Migration (2-3 days)
1. Test all scenarios
2. Migrate existing hardcoded reminders
3. User acceptance testing
4. Deploy

**Total: 9-14 days**

---

## Migration Strategy

### Step 1: Keep Current System (Backward Compatible)
```dart
// Hybrid approach - use database if available, fallback to hardcoded
Future<void> scheduleDailyAttendanceReminders() async {
  try {
    // Try database approach first
    await DatabaseNotificationService().syncAndScheduleNotifications();
  } catch (e) {
    // Fallback to hardcoded schedules
    await _scheduleHardcodedReminders();
  }
}
```

### Step 2: Seed Database with Current Logic
```sql
-- Create default attendance reminders matching current system
INSERT INTO notification_schedules 
(type, title, body, schedule_time, days_of_week, target_roles, enabled)
VALUES
('attendance', '⏰ Attendance Reminder', 
 'Please check in for today. Don''t forget to mark your attendance!',
 '09:00:00', '{1,2,3,4,5}', 
 '["manager", "employee", "lead"]', true),
 
('attendance', '🚨 Last Reminder: Attendance Check-in',
 'You haven''t checked in yet! Please mark your attendance now.',
 '09:15:00', '{1,2,3,4,5}',
 '["manager", "employee", "lead"]', true);
```

### Step 3: Gradual Rollout
1. Week 1: Internal testing with database system
2. Week 2: Rollout to 10% of users
3. Week 3: Rollout to 50% of users
4. Week 4: Full rollout
5. Week 5: Remove hardcoded fallback

---

## Alternative: Simpler Hybrid Approach

If full database-driven system is too complex, here's a **simpler middle-ground**:

### Minimal Database Schema
```sql
-- Just one table for user preferences
CREATE TABLE notification_preferences (
    user_id UUID PRIMARY KEY REFERENCES users(id),
    
    -- Attendance reminders
    attendance_enabled BOOLEAN DEFAULT true,
    attendance_first_time TIME DEFAULT '09:00:00',
    attendance_second_time TIME DEFAULT '09:15:00',
    attendance_days INTEGER[] DEFAULT '{1,2,3,4,5}',
    
    -- Other preferences
    sound_enabled BOOLEAN DEFAULT true,
    vibration_enabled BOOLEAN DEFAULT true,
    
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

### Simpler Implementation
```dart
// Fetch user preferences on login
final prefs = await _supabase
    .from('notification_preferences')
    .select()
    .eq('user_id', user.id)
    .single();

// Use custom times or defaults
final firstTime = prefs['attendance_first_time'] ?? '09:00:00';
final secondTime = prefs['attendance_second_time'] ?? '09:15:00';

// Schedule with user's preferred times
await _scheduleAttendanceReminder(id: 100, time: firstTime);
await _scheduleAttendanceReminder(id: 101, time: secondTime);
```

**Benefits:**
- ✅ User customization
- ✅ Much simpler implementation
- ✅ Can be done in 1-2 days
- ✅ Easy to understand and maintain

---

## My Recommendation

### For Your Current Stage: **Simpler Hybrid Approach**

**Why:**
1. ✅ **Quick to implement** (1-2 days vs 9-14 days)
2. ✅ **Solves key pain point** (users can customize times)
3. ✅ **Low risk** (minimal changes to existing system)
4. ✅ **Easy to extend later** (can add more features gradually)

### Implementation Steps:
1. Add `notification_preferences` table
2. Create user settings screen for customization
3. Fetch preferences on login and schedule accordingly
4. Done! Users happy, you happy

### Future Enhancements:
- Add more notification types (meetings, deadlines)
- Add office-specific schedules
- Add analytics tracking
- Build admin panel

**Start simple, iterate based on feedback!** 🚀

---

## Conclusion

Your current system works well! The database-driven approach would add:
- **Flexibility:** Change schedules remotely
- **Personalization:** Users customize their reminders
- **Analytics:** Track what's working
- **Scalability:** Easy to add new notifications

**My advice:** Start with the **simpler hybrid approach** (user preferences table) and evolve to full database-driven system if needed based on usage patterns and feedback.

Would you like me to help implement the simpler approach first? 🎯
