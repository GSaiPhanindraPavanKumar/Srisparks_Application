# Srisparks Workforce Management App

A comprehensive Flutter-based mobile application for managing workforce operations across multiple offices, featuring role-based access control, work assignment tracking, and secure user management.

## 🎯 Overview

The Srisparks Workforce Management App is designed to streamline operations for organizations with multiple offices and hierarchical workforce structures. It enables efficient management of directors, managers, leads, and employees while maintaining strict security and approval workflows.

## 🏗️ Architecture

### Technology Stack
- **Frontend**: Flutter (Dart)
- **Backend**: Supabase (PostgreSQL + Edge Functions)
- **Authentication**: Supabase Auth
- **Database**: PostgreSQL with Row-Level Security (RLS)
- **State Management**: Built-in Flutter state management

### Key Features
- **Role-Based Access Control**: Directors, Managers, Leads, and Employees
- **Secure Authentication**: Email/password-based with no public sign-up
- **Work Assignment & Tracking**: Complete work lifecycle management
- **Approval Workflows**: Hierarchical approval system for user creation
- **Multi-Office Support**: Manage multiple office locations
- **Customer Management**: Track and manage customer relationships
- **Activity Logging**: Comprehensive audit trail
- **Real-time Updates**: Live synchronization across devices

## 👥 User Roles & Permissions

### Director
- **Highest Level Access**: Can manage all users, offices, and operations
- **Permissions**:
  - Create and manage users of all roles
  - Approve/reject user requests
  - Manage office operations
  - View all work assignments and reports
  - Access comprehensive analytics

### Manager
- **Office-Level Management**: Manages operations within their assigned office
- **Permissions**:
  - Create leads and employees
  - Assign work to team members
  - Verify completed work
  - View office-specific reports
  - Manage customers within their office

### Lead
- **Team Leadership**: Manages a team of employees
- **Permissions**:
  - Assign work to direct reports
  - Verify work completed by team members
  - View team performance metrics
  - Manage customer relationships
  - **Note**: Lead creation requires director approval

### Employee
- **Work Execution**: Focuses on completing assigned tasks
- **Permissions**:
  - View and manage assigned work
  - Update work status and progress
  - Track time and performance
  - Access personal dashboard

## 📱 Application Structure

```
lib/
├── main.dart                   # App entry point
├── models/                     # Data models
│   ├── user_model.dart
│   ├── work_model.dart
│   ├── office_model.dart
│   ├── customer_model.dart
│   └── activity_log_model.dart
├── services/                   # Business logic services
│   ├── auth_service.dart
│   ├── user_service.dart
│   ├── work_service.dart
│   ├── office_service.dart
│   └── customer_service.dart
├── screens/                    # UI screens
│   ├── director_dashboard.dart
│   ├── manager_dashboard.dart
│   ├── lead_dashboard.dart
│   ├── employee_dashboard.dart
│   └── my_work_screen.dart
└── auth/
    └── auth_screen.dart        # Authentication screen
```

## 🔐 Security Features

### Authentication Security
- **No Public Sign-up**: Only authorized personnel can create accounts
- **Role-Based Access**: Strict permission controls based on user roles
- **Session Management**: Secure session handling with automatic logout
- **Password Requirements**: Enforced strong password policies

### Database Security
- **Row-Level Security (RLS)**: PostgreSQL policies restrict data access
- **Audit Trails**: Complete activity logging for compliance
- **Data Encryption**: All sensitive data encrypted at rest and in transit
- **API Security**: Secure API endpoints with proper authentication

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (latest stable version)
- Dart SDK
- Android Studio / VS Code
- Supabase account

### Installation

1. **Clone the repository**
```bash
git clone <repository-url>
cd srisparks_app
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Set up Supabase**
   - Create a new Supabase project
   - Set up the database schema (see `database_schema.md`)
   - Configure authentication settings
   - Deploy Edge Functions

4. **Configure app**
   - Update Supabase URL and keys in `main.dart`
   - Configure app permissions and settings

5. **Run the app**
```bash
flutter run
```

### Database Setup

Refer to `database_schema.md` for complete database setup instructions including:
- Table schemas
- Row-Level Security policies
- Database functions
- Edge Functions
- Sample data

## 🔧 Configuration

### Environment Variables
Create a `.env` file in the root directory:
```env
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
```

### App Configuration
- Update `pubspec.yaml` with required dependencies
- Configure platform-specific settings in `android/` and `ios/` directories
- Set up proper app icons and splash screens

## 📊 Key Workflows

### User Creation Workflow
1. **Director/Manager** initiates user creation
2. **System** creates user account via Edge Function
3. **Lead Creation** requires director approval
4. **Employee Creation** is immediately active
5. **Notification** sent to new user

### Work Assignment Workflow
1. **Manager/Lead** creates work assignment
2. **System** assigns to appropriate employee
3. **Employee** receives notification
4. **Employee** starts and completes work
5. **Manager/Lead** verifies completion
6. **System** logs all activities

### Approval Workflow
1. **Manager** creates lead user
2. **System** sets status to "pending_approval"
3. **Director** receives approval request
4. **Director** approves or rejects
5. **System** updates user status
6. **Activity** logged for audit trail

## 🎨 UI/UX Features

### Dashboard Features
- **Role-specific dashboards** with relevant information
- **Real-time metrics** and performance indicators
- **Quick action buttons** for common tasks
- **Responsive design** for various screen sizes

### Work Management
- **Intuitive work cards** with status indicators
- **Filter and search** capabilities
- **Progress tracking** with visual indicators
- **Detailed work views** with complete information

### User Experience
- **Clean, modern interface** with Material Design
- **Consistent navigation** across all screens
- **Offline capability** for core functions
- **Push notifications** for important updates

## 🔍 Testing

### Unit Tests
```bash
flutter test
```

### Integration Tests
```bash
flutter test integration_test
```

### Testing Strategy
- **Model Testing**: Verify data model integrity
- **Service Testing**: Test business logic and API calls
- **UI Testing**: Ensure proper user interface behavior
- **Security Testing**: Validate access controls and permissions

## 📈 Performance Optimization

### App Performance
- **Lazy loading** for large data sets
- **Caching strategies** for frequently accessed data
- **Optimized images** and assets
- **Efficient state management**

### Database Performance
- **Proper indexing** on frequently queried columns
- **Query optimization** for complex operations
- **Connection pooling** for efficient resource usage
- **Data archiving** for historical records

## 🛠️ Maintenance

### Regular Tasks
- **Database backups** and maintenance
- **Security updates** and patches
- **Performance monitoring** and optimization
- **User feedback** integration

### Monitoring
- **Error tracking** and logging
- **Performance metrics** collection
- **User activity** analysis
- **System health** monitoring

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request

### Code Standards
- Follow Flutter/Dart style guide
- Write comprehensive tests
- Document new features
- Maintain security best practices

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

For support and questions:
- Create an issue in the repository
- Contact the development team
- Check the documentation wiki

## 🔄 Version History

- **v1.0.0**: Initial release with core functionality
- **v1.1.0**: Enhanced work management features
- **v1.2.0**: Improved user interface and performance
- **v2.0.0**: Advanced analytics and reporting

## 🔮 Future Enhancements

- **Mobile app notifications**
- **Advanced reporting and analytics**
- **Integration with external systems**
- **Multi-language support**
- **Offline synchronization**
- **File attachment support**
- **Calendar integration**
- **Advanced workflow automation**

---

Built with ❤️ using Flutter and Supabase
