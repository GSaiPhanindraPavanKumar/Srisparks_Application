# Team Attendance Location Feature - Quick User Guide

## 🎯 How to View Team Member Locations

### Step-by-Step Guide

---

## 📱 **Accessing the Feature**

### For Leads and Managers:

1. **Open the app** and login
2. **Tap menu icon** (☰) in top left
3. **Select "Team Attendance"**
4. You'll see your team's attendance list

---

## 🔍 **Viewing Check-In/Check-Out Locations**

### Basic Flow:

```
1. Find Employee → 2. Tap Card → 3. Expand → 4. Tap Location Button → 5. View on Map
```

### Detailed Steps:

#### **Step 1: Find the Attendance Record**
- Scroll through the attendance list
- Look for the employee you want to check
- Cards show: Name, Time, Status

#### **Step 2: Tap the Card**
- **Tap anywhere on the card** to expand it
- The card will open to show more details
- You'll see a "Location Details" section

#### **Step 3: View Location Options**
Inside the expanded card, you'll see:

**🟢 Locate Check-In** (Green button)
- Shows where employee checked in
- Displays check-in time and coordinates
- Opens in Google Maps

**🟠 Locate Check-Out** (Orange button)
- Shows where employee checked out
- Displays check-out time and coordinates
- Opens in Google Maps

#### **Step 4: Open Location**
- **Tap "Locate Check-In"** or **"Locate Check-Out"**
- A loading message appears briefly
- Maps app opens automatically
- Location shown with a pin/marker

---

## 📍 **What You'll See**

### On the Expanded Card:

```
┌────────────────────────────────────────┐
│  👤 John Doe                    [Late] │
│  🕐 In: 09:15 AM  🕐 Out: 05:30 PM    │
│  ⏱️  Duration: 8h 15m                  │
│  🏷️  EMPLOYEE                    ✅    │
│                                         │
│  📍 Location Details                    │
│  ┌────────────────────────────────┐   │
│  │  🟢 Locate Check-In            │   │
│  └────────────────────────────────┘   │
│  ┌────────────────────────────────┐   │
│  │  🟠 Locate Check-Out           │   │
│  └────────────────────────────────┘   │
└────────────────────────────────────────┘
```

### If Location Not Available:

```
┌────────────────────────────────────────┐
│  📍 Location Details                    │
│  ┌────────────────────────────────┐   │
│  │ 📍❌ Check-in location not     │   │
│  │     available                  │   │
│  └────────────────────────────────┘   │
└────────────────────────────────────────┘
```

---

## 🗺️ **Map Opens Showing:**

- **📍 Pin/Marker**: Exact location of check-in or check-out
- **Address**: Street address (if available)
- **Coordinates**: Precise latitude/longitude
- **Directions**: Tap for navigation (in maps app)

---

## 💡 **Alternative View (If Maps Doesn't Open)**

Sometimes maps app may not open automatically. You'll see a dialog with:

```
┌─────────────────────────────────────┐
│  📍 Locate Check-In                 │
├─────────────────────────────────────┤
│  ⏰ Time: Oct 16, 09:15 AM         │
│                                     │
│  📍 Latitude: 17.385044            │
│  🔍 Longitude: 78.486671           │
│                                     │
│  ┌───────────────────────────────┐ │
│  │ ℹ️  Coordinates:               │ │
│  │    17.385044, 78.486671       │ │
│  └───────────────────────────────┘ │
│                                     │
│  [Close]        [🗺️ Open in Maps] │
└─────────────────────────────────────┘
```

**Actions:**
- **Close**: Return to attendance list
- **Open in Maps**: Try alternative launch methods
- **Copy Coordinates**: Manually paste into maps

---

## 🎯 **Common Use Cases**

### 1️⃣ **Verify On-Site Presence**
**When**: You need to confirm employee was at work location

**How**:
1. Find employee's attendance record
2. Expand card
3. Tap "Locate Check-In"
4. Compare map location with expected work site
5. ✅ Verified if location matches

---

### 2️⃣ **Check Customer Visit**
**When**: Verify employee visited customer location

**How**:
1. Go to specific date in History tab
2. Find employee record
3. Tap to expand
4. Check both Check-In and Check-Out locations
5. Compare with customer address

---

### 3️⃣ **Monitor Field Team**
**When**: Track where team is working today

**How**:
1. Stay on "Today" tab
2. Expand multiple team members' cards
3. Note check-in locations
4. Identify work area patterns
5. Plan visits or support accordingly

---

### 4️⃣ **Investigate Late Arrival**
**When**: Employee marked late, need to verify

**How**:
1. See red "Late" badge on card
2. Expand card
3. Check check-in location
4. Note exact check-in time
5. Discuss with employee if needed

---

## 🚫 **What Each Status Means**

### ✅ **Location Button Available** (Green/Orange)
- GPS coordinates were captured
- Button is clickable
- Will open maps

### ⚠️ **"Location not available"** (Grey box)
- Employee's GPS was off
- Location permission denied
- Technical issue during check-in/out

### ⏳ **"Not checked out yet"** (Grey box)
- Employee is still working
- Check-out hasn't happened
- Check back later

---

## 📊 **Information Displayed**

### Time:
- **Format**: MMM DD, HH:MM AM/PM
- **Example**: Oct 16, 09:15 AM

### Coordinates:
- **Precision**: 6 decimal places
- **Accuracy**: ~11 centimeters
- **Format**: Decimal Degrees (DD)
- **Example**: 17.385044, 78.486671

### Status Indicators:
- **🟢 Green**: Check-in location
- **🟠 Orange**: Check-out location  
- **⚫ Grey**: Location unavailable
- **🔴 Red**: Late arrival indicator

---

## 🔧 **Troubleshooting**

### Problem: Maps Doesn't Open
**Solution**:
1. Use the coordinate dialog that appears
2. Tap "Open in Maps" button
3. Manually copy coordinates
4. Open maps app yourself
5. Paste coordinates in search

### Problem: No Location Button Visible
**Possible Reasons**:
- Employee's GPS was disabled
- Location permission not granted
- Check-in/out happened offline
- Data not synced yet

**Action**:
- Check with employee about GPS settings
- Verify in their "My Attendance"
- Try refreshing the list

### Problem: Wrong Location Shown
**Possible Reasons**:
- GPS accuracy issue
- Indoor location (weak signal)
- Device GPS calibration needed

**Action**:
- Note the issue
- Check pattern over multiple days
- Discuss with employee if persistent

---

## ✨ **Tips for Best Use**

### For Leads:
✅ Check team locations every morning
✅ Verify work sites match assignments
✅ Identify any location patterns
✅ Use for fair performance evaluation
✅ Respect privacy - don't over-monitor

### For Managers:
✅ Review office-wide attendance locations
✅ Compare teams' work areas
✅ Plan field visits based on locations
✅ Identify operational improvements
✅ Use data ethically and responsibly

### Best Practices:
1. **Regular Checks**: Review locations weekly
2. **Pattern Analysis**: Look for trends, not one-offs
3. **Fair Evaluation**: Consider context always
4. **Privacy First**: Don't share locations unnecessarily
5. **Support Team**: Use data to help, not punish

---

## 🎨 **Visual Cues**

### Card States:

**Collapsed** (Default):
```
[👤] John Doe              [Late]
     In: 09:15 AM  Out: 05:30 PM
     Duration: 8h 15m        ✅
     EMPLOYEE
```

**Expanded** (After Tap):
```
[👤] John Doe              [Late]
     In: 09:15 AM  Out: 05:30 PM
     Duration: 8h 15m
     EMPLOYEE               ✅
     ──────────────────────────
     📍 Location Details
     [🟢 Locate Check-In    ]
     [🟠 Locate Check-Out   ]
```

---

## 📝 **Quick Reference**

| Action | Result |
|--------|--------|
| Tap Card | Expand to show locations |
| Tap Green Button | Open check-in on map |
| Tap Orange Button | Open check-out on map |
| Grey Box | Location not available |
| Maps Opens | Shows exact GPS location |
| Dialog Shows | View coordinates & time |

---

## ⚡ **Quick Tips**

- 👆 **Tap once** to expand card
- 👆 **Tap again** to collapse
- 🗺️ **Green = In**, Orange = Out
- ⏰ **Time** shown with location
- 📍 **Precise** to ~11 centimeters
- 🔄 **Pull down** to refresh

---

## 📞 **Need Help?**

If you encounter persistent issues:
1. Check your device's location services
2. Ensure maps app is installed
3. Verify internet connection
4. Contact system administrator
5. Report bugs through help section

---

**Remember**: This feature is designed to improve accountability and team management. Use it responsibly and respect your team members' privacy. The location is captured only during check-in and check-out - not continuously tracked throughout the day.

---

**🎉 You're ready to use the Team Attendance Location feature!**
