# How to Assign Installation Work - Step by Step Guide

## 🎯 **Overview**
This guide explains how to assign installation work to employees using the Installation Management System.

## 📋 **Prerequisites**
1. ✅ Database tables must be created (run the SQL migration scripts)
2. ✅ Customer must be in "installation" phase
3. ✅ Employees with roles "employee" or "lead" must exist in your office
4. ✅ You must be logged in as Manager or Director

## 🚀 **Step-by-Step Process**

### **Step 1: Access Installation Management**
1. **Go to Dashboard** (Manager or Director)
2. **Find customer** in installation phase
3. **Click "Manage Installation"** button

### **Step 2: Create Installation Project (First Time Only)**
1. **Click "Create Installation Project"** if no project exists
2. **Project will be created** with standard work types:
   - Structure Work
   - Solar Panel Installation
   - Inverter & Wiring
   - Earthing System
   - Lightning Arrestor

### **Step 3: Assign Work to Teams**
1. **Click "Assign Work"** button
2. **For each work type**, you'll see an assignment card
3. **Select Team Lead**:
   - Click the dropdown under "Team Lead"
   - Choose an employee (preferably someone with "Lead" role)
   - Lead is marked with ⭐ star icon

4. **Add Team Members**:
   - Click "Add Team Member" button
   - Select from available employees
   - Team members appear as chips
   - Remove by clicking ❌ on the chip

5. **Repeat for all work types**

### **Step 4: Save Assignments**
1. **Ensure each work type has a Team Lead** assigned
2. **Click "Save"** button in the top-right
3. **Wait for confirmation** message

## ⚠️ **Common Issues & Solutions**

### **❌ "No employees available"**
**Cause**: No employees with "employee" or "lead" roles in your office
**Solution**: 
- Add employees to your office in the user management
- Ensure they have correct roles (employee/lead)

### **❌ "Error saving assignments"**
**Cause**: Database column mismatch
**Solution**: 
- Run the database fix script: `comprehensive_installation_fix.sql`
- Ensure all installation tables exist with correct schema

### **❌ "Installation project not found"**
**Cause**: No installation project created for this customer
**Solution**: 
- Click "Create Installation Project" button first
- Wait for confirmation before trying to assign work

### **❌ "Customer not in installation phase"**
**Cause**: Customer phase is not set to "installation"
**Solution**: 
- Update customer phase to "installation" in customer management
- Only customers in installation phase can have work assigned

## 🎯 **Best Practices**

### **👥 Team Composition**
- **Assign experienced employees as Team Leads**
- **Mix experienced and new employees in teams**
- **Keep teams reasonable size (2-5 people per work type)**

### **📋 Work Types Priority**
1. **Structure Work** - Foundation (do first)
2. **Solar Panels** - Main installation
3. **Inverter & Wiring** - Electrical connections
4. **Earthing** - Safety systems
5. **Lightning Arrestor** - Protection systems

### **📍 Location Setup**
- **Ensure accurate site coordinates** are recorded
- **Work location verification** happens within 100m radius
- **GPS accuracy is important** for attendance tracking

## 🔧 **Troubleshooting Database Issues**

If you encounter database errors, run these scripts in order:

1. **For new installations**: `create_installation_tables.sql`
2. **For existing tables**: `comprehensive_installation_fix.sql`
3. **For complete reset**: `recreate_installation_tables.sql` (⚠️ data loss)

## 📱 **After Assignment**

Once work is assigned:
1. **Employees can view their assignments** in their dashboard
2. **Team Leads can start/stop work** with location verification
3. **Managers can track progress** in real-time
4. **Material usage is tracked** automatically

## 💡 **Tips for Success**

- ✅ **Create clear work descriptions** for each type
- ✅ **Assign realistic timeframes** for completion
- ✅ **Monitor progress regularly** through the dashboard
- ✅ **Ensure proper location access** for GPS verification
- ✅ **Have backup team members** in case of absences

## 🔄 **Next Steps After Assignment**

1. **Employees start work** using location verification
2. **Track material usage** during installation
3. **Team Leads verify work completion**
4. **Managers approve completed work**
5. **Directors give final approval**
6. **Project moves to next phase**

---

**Need Help?** Check the database setup documentation or run the diagnostic scripts to ensure your installation management system is properly configured.
