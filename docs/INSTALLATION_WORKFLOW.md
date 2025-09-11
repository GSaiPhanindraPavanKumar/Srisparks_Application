# Installation Phase Workflow - Sri Sparks Solar Management App

This document describes the complete Installation Phase workflow for the solar installation management system, including GPS verification, role-based permissions, and comprehensive task tracking.

## Overview

The Installation Phase is a critical component of the solar management system that enables:
- **GPS-verified field work** (within 50m of customer location)
- **Role-based task assignment** (Director/Manager/Lead assign, Employees execute)
- **Sub-task tracking** with 6 installation phases
- **Photo evidence collection** and serial number tracking
- **Verification workflow** for quality assurance

## Installation Sub-Tasks

Every installation is divided into 6 mandatory sub-tasks:

1. **Structure Installation** - Solar panel mounting structure
2. **Panels** - Solar panel installation and alignment
3. **Wiring & Inverter** - Electrical connections and inverter setup
4. **Earthing** - Grounding system installation
5. **Lightning Arrestor** - Lightning protection system
6. **Data Collection** - Serial numbers, final photos, and documentation

## User Roles & Permissions

### Director
- Can assign installations across all offices
- Can verify completed installations
- Full access to installation statistics and management

### Manager
- Can assign installations within their office
- Can verify completed installations in their office
- Access to office-specific installation data

### Lead
- Can assign installations within their office
- Can verify completed installations
- Can supervise installation teams

### Employee
- Can view assigned installation tasks
- Can start/complete sub-tasks with GPS verification
- Must provide photo evidence and serial numbers
- Cannot assign or verify installations

## GPS Verification System

### Requirements
- Employees must be within **50 meters** of customer location
- GPS verification required for:
  - Starting any sub-task
  - Completing any sub-task
- Automatic distance calculation and validation
- Error handling for GPS accuracy and permissions

### Implementation
```dart
// GPS verification is handled automatically by the InstallationService
final isWithinRange = await InstallationService.verifyGPSLocation(
  customerLatitude: customer.latitude,
  customerLongitude: customer.longitude,
  requiredAccuracy: 50.0, // meters
);
```

## Database Schema

### Core Tables

1. **installation_work_assignments**
   - Main assignment record with customer, assigned team, status
   - Tracks assignment → completion → verification lifecycle

2. **installation_assignment_employees**
   - Many-to-many relationship between assignments and employees
   - Supports team-based installations

3. **installation_sub_tasks**
   - Individual task tracking with GPS coordinates
   - Status progression: pending → in_progress → completed

4. **installation_task_photos**
   - Photo evidence for each sub-task
   - File storage integration with Supabase

5. **installation_equipment_serials**
   - Equipment serial numbers by sub-task
   - Manufacturer, model, and specification tracking

6. **installation_task_team_members**
   - Team member assignments per sub-task
   - Role tracking (lead, member, assistant)

### Views and Functions

- `installation_assignment_details` - Complete assignment info with customer data
- `installation_progress_summary` - Real-time completion percentages
- `installation_statistics` - Office and system-wide metrics
- `create_installation_assignment()` - Automated assignment creation
- `get_assignment_completion_percentage()` - Progress calculation

## Screen Navigation & Workflow

### For Directors/Managers/Leads

1. **Installation Assignment Screen** (`installation_assignment_screen.dart`)
   - View customers ready for installation (materials confirmed)
   - Assign installation teams with scheduled dates
   - Monitor active installations with progress tracking
   - Access installation statistics and overview

2. **Installation Verification Screen** (`installation_verification_screen.dart`)
   - Review completed installations
   - Verify installation quality with approve/reject decisions
   - Add verification remarks and feedback

### For Employees

1. **Employee Installation Screen** (`employee_installation_screen.dart`)
   - View assigned installation tasks
   - Search and filter assignments
   - See installation progress and team information

2. **Installation Task Detail Screen** (`installation_task_detail_screen.dart`)
   - Detailed sub-task management
   - GPS-verified start/complete workflows
   - Photo capture and serial number collection
   - Team member selection for each task

## Photo Evidence Requirements

### Mandatory Photos
- **Structure**: Mounting structure installation
- **Panels**: Completed panel installation
- **Wiring & Inverter**: Electrical connections and inverter
- **Earthing**: Grounding system
- **Lightning Arrestor**: Lightning protection installation
- **Data Collection**: Final installation overview

### Photo Specifications
- Minimum resolution handled by `image_picker` plugin
- Automatic file naming with timestamps
- Supabase storage integration
- Progress tracking for upload status

## Serial Number Collection

### Required for Data Collection Phase
- **Solar Panels**: Individual panel serial numbers
- **Inverter**: Main inverter serial number
- **Battery**: Battery system serials (if applicable)
- **Meter**: Net meter or monitoring system serials
- **Additional Equipment**: Any other installed equipment

### Data Structure
```dart
class InstallationEquipmentSerial {
  final String equipmentType; // 'panel', 'inverter', 'battery', 'meter'
  final String serialNumber;
  final String? manufacturer;
  final String? model;
  final Map<String, dynamic>? specifications;
}
```

## Workflow States

### Assignment Status Flow
```
assigned → in_progress → completed → verified
                                  ↓
                              rejected → in_progress
```

### Sub-task Status Flow
```
pending → in_progress → completed
```

## Installation Progress Calculation

Progress is calculated as:
```
Progress % = (Completed Sub-tasks / Total Sub-tasks) × 100
```

All 6 sub-tasks must be completed for an installation to be marked as "completed" and ready for verification.

## Error Handling & Validation

### GPS Validation
- Checks device GPS permissions
- Validates GPS accuracy (minimum 10m accuracy required)
- Calculates distance using Haversine formula
- Provides user-friendly error messages

### Photo Validation
- Ensures photos are captured before task completion
- Validates file upload success
- Handles storage errors gracefully

### Data Validation
- Serial numbers required for data collection phase
- Team member validation for task assignments
- Role-based permission checks throughout workflow

## Integration Points

### Customer Service Integration
```dart
// Customers ready for installation
final readyCustomers = allCustomers.where((customer) => 
  customer.currentPhase == 'material_allocation' && 
  customer.materialAllocationStatus == 'confirmed'
).toList();
```

### User Service Integration
```dart
// Load employees for assignment
final employees = await UserService.getUsersByOffice(
  officeId, 
  role: UserRole.employee
);
```

### Auth Service Integration
- Current user context for role-based permissions
- Office-based data filtering
- Secure operation validation

## File Structure

```
lib/
├── models/
│   └── installation_model.dart          # Complete data models
├── services/
│   └── installation_service.dart        # Business logic & GPS verification
├── screens/
│   ├── employee/
│   │   └── employee_installation_screen.dart
│   └── shared/
│       ├── installation_assignment_screen.dart
│       ├── installation_task_detail_screen.dart
│       └── installation_verification_screen.dart
└── database/
    └── installation_schema.sql          # Complete database schema
```

## Security Features

### Row Level Security (RLS)
- Directors: Access to all installations
- Managers/Leads: Office-specific access
- Employees: Only assigned installations
- Automatic policy enforcement at database level

### GPS Security
- Real-time location verification
- Prevents task manipulation from remote locations
- Audit trail of GPS coordinates for each task

### Photo Security
- Secure file upload to Supabase storage
- Timestamped photo metadata
- Access control based on assignment permissions

## Deployment Checklist

### Database Setup
1. Run `installation_schema.sql` in Supabase
2. Verify RLS policies are active
3. Test row-level security with different user roles
4. Set up database triggers and functions

### App Configuration
1. Configure GPS permissions in `android/app/src/main/AndroidManifest.xml`
2. Set up iOS location permissions in `ios/Runner/Info.plist`
3. Configure Supabase storage bucket for installation photos
4. Test image_picker functionality on target devices

### Testing Scenarios
1. **GPS Verification**: Test within and outside 50m range
2. **Role Permissions**: Verify each role's access levels
3. **Photo Upload**: Test image capture and storage
4. **Serial Number Collection**: Verify data collection workflow
5. **Verification Process**: Test approve/reject workflows

## Future Enhancements

### Planned Features
- **Offline Mode**: Cache data for areas with poor connectivity
- **QR Code Scanning**: Automated serial number collection
- **Time Tracking**: Detailed time logging per sub-task
- **Report Generation**: PDF reports for completed installations
- **Customer Notifications**: Real-time updates to customers
- **Weather Integration**: Track weather conditions during installation

### API Extensions
- Integration with equipment manufacturer APIs
- Automated warranty registration
- Performance monitoring system integration
- Third-party inspection system connectivity

## Support & Troubleshooting

### Common Issues

1. **GPS Not Working**
   - Check device location permissions
   - Ensure GPS is enabled
   - Verify network connectivity for assisted GPS

2. **Photo Upload Failures**
   - Check internet connectivity
   - Verify Supabase storage permissions
   - Ensure sufficient device storage

3. **Permission Errors**
   - Verify user role assignments
   - Check office assignments
   - Validate database RLS policies

### Debug Tools
- Installation service includes detailed logging
- GPS verification provides diagnostic information
- Error messages include context for troubleshooting

## Contact & Maintenance

For issues related to the Installation Phase workflow:
- Check service logs in `InstallationService`
- Verify database constraints and triggers
- Test GPS functionality in target deployment area
- Monitor Supabase storage usage and performance

This workflow system ensures quality, accountability, and efficiency in solar installation management while maintaining strict GPS verification and comprehensive documentation requirements.
