# Srisparks Workforce Management App

# 🌟 Sri Sparks Solar Energy Management System

A comprehensive workforce management application designed specifically for solar energy companies to streamline operations across multiple offices, manage customer installations, and track project lifecycles from application to completion.

## 🎯 Overview

Sri Sparks is a Flutter-based mobile and web application that provides complete solar energy project management capabilities with role-based access control, real-time tracking, GPS location verification, and comprehensive approval workflows. Built for organizations with hierarchical structures managing solar installations across multiple locations.

## ✨ Key Features

### 🔐 **Advanced User Management**
- **Role-Based Access Control**: Director, Manager, Lead, Employee hierarchies
- **Approval Workflows**: Automatic approval system based on user roles
- **Secure Authentication**: Email/password with no public registration
- **GPS Location Verification**: 50-meter radius requirement for work operations
- **Multi-Office Support**: Manage operations across multiple office locations

### 🏗️ **Solar Project Management**
- **Complete Lifecycle Tracking**: Application → Amount → Material → Installation → Documentation → Completion
- **Customer Management**: Comprehensive customer database with location tracking
- **Work Assignment & Tracking**: Real-time work status monitoring
- **Material Allocation**: Advanced material planning and stock management
- **Installation Management**: Detailed installation project tracking with photos

### 📊 **Business Intelligence**
- **Real-time Dashboards**: Role-specific performance metrics
- **Activity Logging**: Complete audit trails for compliance
- **Performance Analytics**: Team and individual performance tracking
- **Financial Tracking**: Project costs, payments, and profitability analysis
- **Location Analytics**: GPS-based work verification and reporting

## 🏗️ Architecture

### **Technology Stack**
- **Frontend**: Flutter (Dart) - Cross-platform mobile & web
- **Backend**: Supabase (PostgreSQL + Edge Functions)
- **Database**: PostgreSQL with Row-Level Security (RLS)
- **Authentication**: Supabase Auth with custom Edge Functions
- **Real-time Updates**: Supabase Realtime
- **Location Services**: Geolocator with permission handling
- **State Management**: Flutter StatefulWidgets with Provider pattern

### **Security Features**
- **Row-Level Security**: Database-level access control
- **JWT Authentication**: Secure session management
- **GPS Verification**: Location-based work validation
- **Audit Trails**: Complete activity logging
- **Role-based Permissions**: Granular access control

## 👥 User Roles & Permissions

### 🎯 **Director**
- **Global Authority**: Complete system access across all offices
- **Permissions**:
  - Create and manage all user types
  - Approve/reject user creation requests
  - Manage multiple office operations
  - Access comprehensive analytics and reports
  - Override any workflow or process
  - View all customer projects across offices
  - Manage system-wide settings and configurations

### 👔 **Manager**
- **Office-Level Management**: Manages operations within assigned office
- **Permissions**:
  - Create leads and employees in their office
  - Assign work to team members
  - Verify completed work within office
  - Manage office-specific customers
  - Access office performance reports
  - Approve office-level workflows
  - Handle customer relationships and projects

### 👨‍💼 **Lead (Employee with Leadership)**
- **Team Leadership**: Manages employee teams within office
- **Permissions**:
  - Assign work to direct reports
  - Verify work completed by team members
  - View team performance metrics
  - Manage customer installation projects
  - Handle material allocations for projects
  - **Note**: Lead creation requires director approval

### 👨‍💻 **Employee**
- **Work Execution**: Focuses on completing assigned tasks
- **Permissions**:
  - View and manage assigned work
  - Update work status with GPS verification
  - Track time and completion progress
  - Upload installation photos and documentation
  - Access personal performance dashboard
  - Must be within 50 meters of customer location to start/complete work

## 🔄 Solar Project Lifecycle

### **Phase 1: Application**
- Customer inquiry and initial assessment
- Site survey with GPS coordinates
- Technical feasibility analysis
- Cost estimation and proposal generation
- Application approval workflow

### **Phase 2: Amount & Payment**
- Final pricing confirmation
- Payment processing and tracking
- Contract finalization
- Project scheduling
- Director/Manager approval required

### **Phase 3: Material Allocation**
- **3-Step Workflow**:
  1. **Save as Draft (planned)** - Lead, Manager, Director
  2. **Proceed (allocated)** - Manager, Director only
  3. **Confirm (confirmed)** - Director only
- Stock management with shortage tracking
- Vendor coordination and procurement
- Delivery scheduling and tracking

### **Phase 4: Installation**
- Work assignment to installation teams
- GPS-verified work start/completion
- Real-time progress tracking
- Photo documentation requirements
- Quality assurance checkpoints

### **Phase 5: Documentation**
- Installation completion certificates
- Technical documentation and warranties
- Customer handover processes
- System performance testing
- Final project documentation

### **Phase 6: Completion & Service**
- Project closure and handover
- Customer satisfaction surveys
- Ongoing maintenance scheduling
- Performance monitoring setup
- Long-term service relationships

## 📱 Application Structure

```
lib/
├── main.dart                   # App entry point
├── models/                     # Data models
│   ├── user_model.dart        # User management with approval workflow
│   ├── customer_model.dart    # Complete customer lifecycle
│   ├── work_model.dart        # Work assignment and tracking
│   ├── office_model.dart      # Multi-office management
│   ├── activity_log_model.dart # Audit trail management
│   ├── material_allocation_model.dart # Material planning
│   └── installation_model.dart # Installation project tracking
├── services/                   # Business logic services
│   ├── auth_service.dart      # Authentication with approval workflow
│   ├── user_service.dart      # User management operations
│   ├── customer_service.dart  # Customer lifecycle management
│   ├── work_service.dart      # Work assignment and tracking
│   ├── office_service.dart    # Office management
│   ├── material_service.dart  # Material allocation and tracking
│   └── location_service.dart  # GPS verification services
├── screens/                    # Role-based UI screens
│   ├── director/              # Director-specific screens
│   │   ├── director_dashboard.dart
│   │   ├── manage_users_screen.dart
│   │   ├── manage_offices_screen.dart
│   │   └── material_allocation_plan.dart
│   ├── manager/               # Manager-specific screens
│   │   ├── manager_dashboard.dart
│   │   ├── assign_work_screen.dart
│   │   └── manage_work_screen.dart
│   ├── lead/                  # Lead-specific screens
│   │   ├── lead_dashboard.dart
│   │   └── team_management_screen.dart
│   ├── employee/              # Employee-specific screens
│   │   ├── employee_dashboard.dart
│   │   └── my_work_screen.dart
│   └── shared/                # Shared screens
│       ├── unified_customer_dashboard.dart
│       ├── installation_management_screen.dart
│       └── settings_screen.dart
├── auth/
│   └── auth_screen.dart       # Authentication interface
├── utils/
│   ├── location_utils.dart    # GPS utilities
│   └── app_utils.dart         # Common utilities
└── widgets/                   # Reusable UI components
    ├── custom_sidebar.dart
    ├── work_card.dart
    └── customer_card.dart
```

## 🗄️ Database Schema

### **Core Tables**
- **users** - User management with approval workflow
- **offices** - Multi-office management
- **customers** - Complete customer lifecycle tracking
- **work** - Work assignment and tracking
- **activity_logs** - Comprehensive audit trails
- **installation_projects** - Installation project management
- **installation_work_items** - Detailed work item tracking
- **material_allocations** - Material planning and tracking
- **material_inventory** - Stock management

### **Key Features**
- **Row-Level Security (RLS)**: Database-level access control
- **Audit Trails**: Every action logged with user and timestamp
- **GPS Coordinates**: Location tracking for customers and work
- **JSONB Fields**: Flexible metadata storage
- **Foreign Key Constraints**: Data integrity enforcement

## 🚀 Installation & Setup

### **Prerequisites**
- Flutter SDK (3.8.1+)
- Dart SDK
- Supabase Account
- Android Studio / VS Code
- Git

### **1. Clone Repository**
```bash
git clone https://github.com/GSaiPhanindraPavanKumar/Srisparks_Application.git
cd srisparks_app
```

### **2. Install Dependencies**
```bash
flutter pub get
```

### **3. Supabase Setup**
1. Create new Supabase project
2. Run database setup script:
   ```sql
   -- Copy and execute: database/migrations/add_user_approval_workflow.sql
   -- This creates all tables, functions, and RLS policies
   ```
3. Configure authentication settings
4. Deploy Edge Functions:
   ```bash
   # Deploy create-user function
   supabase functions deploy create-user
   ```

### **4. Configure Environment**
Create `lib/config/supabase_config.dart`:
```dart
class SupabaseConfig {
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
}
```

### **5. Run Application**
```bash
# For mobile
flutter run

# For web
flutter run -d chrome

# For production build
flutter build apk --release
```

## 📊 Key Workflows

### **User Creation & Approval Workflow**
1. **Director/Manager** initiates user creation
2. **System** validates permissions and role hierarchy
3. **Edge Function** creates secure user account
4. **Approval Logic**: 
   - Directors auto-approve all users they create
   - Manager/Lead created users require director approval
5. **Notification** sent to user upon approval
6. **Activity Logging** for complete audit trail

### **Work Assignment & GPS Verification**
1. **Manager/Lead** creates work assignment with customer location
2. **System** assigns to appropriate employee
3. **Employee** receives notification with work details
4. **GPS Verification** required to start work (50-meter radius)
5. **Progress Tracking** with real-time updates
6. **Completion Verification** with photos and documentation
7. **Manager/Lead** verification and approval

### **Material Allocation Workflow**
1. **Lead/Manager** creates material allocation plan
2. **Draft Status**: Initial planning and requirements
3. **Manager Approval**: Proceeds allocation (allocated status)
4. **Director Confirmation**: Final approval (confirmed status)
5. **Stock Deduction**: Only happens on confirmed status
6. **Delivery Tracking**: Real-time material delivery status

### **Customer Lifecycle Management**
1. **Application Phase**: Initial customer inquiry and assessment
2. **Amount Phase**: Pricing, payment processing, contract signing
3. **Material Phase**: Procurement, allocation, delivery scheduling
4. **Installation Phase**: Team assignment, GPS-verified installation
5. **Documentation Phase**: Completion certificates, handover
6. **Service Phase**: Ongoing maintenance and support

## 🔧 Advanced Features

### **GPS Location Verification**
- **50-meter radius requirement** for work operations
- **Automatic location detection** with permission handling
- **Location audit trails** for compliance
- **Offline location caching** for poor network areas
- **Location-based work assignment** optimization

### **Approval Workflows**
- **Hierarchical approval system** based on roles
- **Auto-approval logic** for directors
- **Pending approval management** with notification badges
- **Rejection reason tracking** for compliance
- **Approval history and audit trails**

### **Real-time Updates**
- **Live dashboard updates** across all devices
- **Work status synchronization** in real-time
- **Notification system** for critical updates
- **Offline capability** with sync when online
- **Background refresh** for latest data

### **Material Management**
- **Advanced allocation planning** with 3-step workflow
- **Stock shortage tracking** with negative inventory
- **Vendor integration** for procurement
- **Delivery scheduling** and tracking
- **Cost analysis** and profitability reporting

## 🔒 Security Features

### **Authentication & Authorization**
- **JWT-based authentication** with Supabase
- **Role-based access control** at database level
- **Session management** with automatic refresh
- **Secure password policies** and encryption
- **Multi-factor authentication** support ready

### **Data Protection**
- **Row-Level Security** in PostgreSQL
- **Encrypted data transmission** via HTTPS
- **Personal data protection** compliance ready
- **Activity logging** for security audits
- **Backup and recovery** procedures

### **Location Security**
- **GPS coordinate encryption** in database
- **Location permission management**
- **Privacy controls** for location sharing
- **Geofencing** for work area verification
- **Location history** with privacy controls

## 📈 Performance & Scalability

### **Optimization Features**
- **Lazy loading** for large datasets
- **Pagination** for efficient data retrieval
- **Image compression** for photos and documents
- **Caching strategies** for offline capability
- **Background sync** for improved performance

### **Scalability Considerations**
- **Horizontal scaling** with Supabase
- **Load balancing** for high availability
- **Database indexing** for query optimization
- **CDN integration** for asset delivery
- **Monitoring and analytics** for performance tracking

## 🧪 Testing

### **Testing Strategy**
```bash
# Run unit tests
flutter test

# Run integration tests
flutter test integration_test/

# Run widget tests
flutter test test/widget_test.dart
```

### **Test Coverage**
- **Unit Tests**: Service layer and business logic
- **Widget Tests**: UI components and screens
- **Integration Tests**: Complete workflow testing
- **Performance Tests**: Load and stress testing
- **Security Tests**: Authentication and authorization

## 📦 Deployment

### **Mobile Deployment**
```bash
# Android APK
flutter build apk --release

# iOS IPA (requires macOS and Xcode)
flutter build ios --release

# Android App Bundle
flutter build appbundle --release
```

### **Web Deployment**
```bash
# Build web version
flutter build web --release

# Deploy to hosting service
# Copy build/web/* to your web server
```

### **Production Considerations**
- **Environment configuration** for prod/staging/dev
- **API key management** and security
- **Database migrations** and version control
- **Monitoring and logging** setup
- **Backup and disaster recovery** procedures

## 🤝 Contributing

### **Development Guidelines**
1. **Fork** the repository
2. **Create feature branch** from master
3. **Follow Flutter best practices** and code standards
4. **Write tests** for new features
5. **Submit pull request** with detailed description

### **Code Standards**
- **Dart style guide** compliance
- **Meaningful variable names** and comments
- **Error handling** and validation
- **Performance optimization** considerations
- **Security best practices** implementation

## 📞 Support & Contact

### **Technical Support**
- **Documentation**: Comprehensive guides in `/docs` folder
- **Issue Tracking**: GitHub Issues for bug reports
- **Feature Requests**: GitHub Discussions for enhancements
- **Community Support**: Developer forums and chat

### **Business Contact**
- **Project Owner**: GSaiPhanindraPavanKumar
- **Repository**: [Sri Sparks Application](https://github.com/GSaiPhanindraPavanKumar/Srisparks_Application)
- **License**: Private/Commercial License

## 📄 License

This project is proprietary software developed for Sri Sparks Solar Energy Management. All rights reserved. Unauthorized copying, distribution, or modification is strictly prohibited.

## 🎉 Acknowledgments

- **Flutter Team** for the amazing framework
- **Supabase Team** for the backend-as-a-service platform
- **Open Source Community** for various packages and tools
- **Solar Energy Industry** for domain expertise and requirements

---

**Built with ❤️ for Solar Energy Management | Sri Sparks Team**

*Last Updated: September 22, 2025*

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
