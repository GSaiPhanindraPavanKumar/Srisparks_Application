# Session-Based Authentication Flow Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         APP START / USER OPENS APP                          │
└────────────────────────────────┬────────────────────────────────────────────┘
                                 │
                                 ▼
                    ┌────────────────────────┐
                    │ Check Existing Session │
                    │  (Valid < 24 hours?)   │
                    └────────┬───────────────┘
                             │
              ┌──────────────┼──────────────┐
              │              │              │
              ▼              ▼              ▼
        ┌─────────┐    ┌──────────┐   ┌─────────┐
        │   NO    │    │ EXPIRED  │   │   YES   │
        │ SESSION │    │ SESSION  │   │ VALID   │
        └────┬────┘    └────┬─────┘   └────┬────┘
             │              │              │
             └──────────────┴──────────────┘
                            │
                            ▼
    ┌───────────────────────────────────────────────────────┐
    │                                                       │
    │  IF NO/EXPIRED → Go to Login Screen                 │
    │  IF VALID → Check Biometric                         │
    │                                                       │
    └───────────────────────────────────────────────────────┘


═══════════════════════════════════════════════════════════════════════════════
                              LOGIN FLOW (First Time)
═══════════════════════════════════════════════════════════════════════════════

    ┌─────────────────┐
    │  LOGIN SCREEN   │
    │                 │
    │  📧 Email       │
    │  🔒 Password    │
    │                 │
    │  [   LOGIN   ]  │
    └────────┬────────┘
             │
             ▼
    ┌────────────────┐
    │ Authenticate   │
    │ with Supabase  │
    └────────┬───────┘
             │
             ▼
    ┌────────────────┐        ┌──────────────┐
    │ Check User     │───NO──▶│ Show Error & │
    │ Status Active? │        │  Sign Out    │
    └────────┬───────┘        └──────────────┘
             │ YES
             ▼
    ┌────────────────────┐
    │   START SESSION    │
    │ Save timestamp to  │
    │ SharedPreferences  │
    └─────────┬──────────┘
              │
              ▼
    ┌────────────────────────────────┐
    │   PERMISSION CHECKS            │
    │                                │
    │  1. 🔔 Notification Permission │
    │     ├─ Check if enabled        │
    │     ├─ Request if needed       │
    │     └─ Show dialog             │
    │                                │
    │  2. 📍 Location Permission     │
    │     ├─ Check if granted        │
    │     ├─ Request if needed       │
    │     └─ Show dialog             │
    │                                │
    │  3. 🔔 Test Notification       │
    │     ├─ Send test notification  │
    │     ├─ Ask: "Did you get it?"  │
    │     └─ If NO → Troubleshoot    │
    └──────────────┬─────────────────┘
                   │
                   ▼
    ┌──────────────────────────────┐
    │   BIOMETRIC SETUP DIALOG     │
    │                              │
    │  "Enable biometric for       │
    │   faster access?"            │
    │                              │
    │  [Not Now]    [Enable]       │
    └──────────────┬───────────────┘
                   │
                   ▼
    ┌──────────────────────┐
    │  NAVIGATE TO         │
    │  USER DASHBOARD      │
    │  (Based on role)     │
    └──────────────────────┘


═══════════════════════════════════════════════════════════════════════════════
                    RETURNING USER FLOW (Within 24 Hours)
═══════════════════════════════════════════════════════════════════════════════

    ┌─────────────────┐
    │   OPEN APP      │
    └────────┬────────┘
             │
             ▼
    ┌────────────────────┐
    │ "Checking          │
    │  session..."       │
    │  [Loading]         │
    └─────────┬──────────┘
              │
              ▼
    ┌─────────────────────────┐
    │  Check Last Activity    │
    │  Time from              │
    │  SharedPreferences      │
    └──────────┬──────────────┘
               │
               ▼
    ┌──────────────────────────┐      ┌──────────────────┐
    │  Time Difference         │─YES─▶│ SESSION EXPIRED  │
    │  > 24 hours?             │      │ Clear Session    │
    └──────────┬───────────────┘      │ Show Login       │
               │ NO                    └──────────────────┘
               │ (Within 24h)
               ▼
    ┌──────────────────────────┐      ┌──────────────────┐
    │  Is Biometric            │─NO──▶│ Continue to      │
    │  Enabled?                │      │ Dashboard        │
    └──────────┬───────────────┘      │ (No biometric)   │
               │ YES                   └──────────────────┘
               ▼
    ┌──────────────────────────────────┐
    │   BIOMETRIC VERIFICATION DIALOG  │
    │                                  │
    │   🔐 Verify Your Identity        │
    │                                  │
    │   [Fingerprint/Face Icon]        │
    │                                  │
    │   "Use your fingerprint or face  │
    │    to continue"                  │
    │                                  │
    │   [Try Again] [Use Password]     │
    │                   [Cancel]       │
    └──────────────┬───────────────────┘
                   │
        ┌──────────┼──────────┐
        │          │          │
        ▼          ▼          ▼
    SUCCESS    FAILURE    CANCEL
        │          │          │
        │          │          │
        ▼          ▼          ▼
    ┌────────┐ ┌────────┐ ┌────────┐
    │Update  │ │Clear   │ │Clear   │
    │Activity│ │Session │ │Session │
    │Time    │ │        │ │        │
    └───┬────┘ └───┬────┘ └───┬────┘
        │          │          │
        ▼          │          │
    ┌────────┐    │          │
    │Go to   │    │          │
    │Dashboard    │          │
    └────────┘    └──────────┴────────▶ ┌──────────────┐
                                        │ Show Login   │
                                        │ Screen       │
                                        └──────────────┘


═══════════════════════════════════════════════════════════════════════════════
                           SESSION TIMELINE DIAGRAM
═══════════════════════════════════════════════════════════════════════════════

    Hour 0          Hour 12         Hour 23         Hour 24         Hour 25
    ├───────────────┼───────────────┼───────────────┼───────────────┤
    │               │               │               │               │
    LOGIN           │               │               │          SESSION
    ✅              │               │               │          EXPIRES
    │               │               │               │               ❌
    │◄─────────────────── VALID SESSION ──────────────────────────▶│
    │                                                               │
    │  Biometric verification required on app open                 │
    │  Session automatically extends with each interaction         │
    │                                                               │
    └───────────────────────────────────────────────────────────────┘
                                                                    │
                                                                    ▼
                                                          Must Login Again
                                                          Email + Password


═══════════════════════════════════════════════════════════════════════════════
                         BIOMETRIC VERIFICATION STATES
═══════════════════════════════════════════════════════════════════════════════

    ┌──────────────────────────────────────────────────────────────┐
    │                    BIOMETRIC DIALOG                          │
    ├──────────────────────────────────────────────────────────────┤
    │                                                              │
    │  STATE 1: VERIFYING                                          │
    │  ┌────────────────────────────────────────────────┐          │
    │  │  [⌛ Loading Spinner]                          │          │
    │  │                                                │          │
    │  │  "Please verify your identity"                 │          │
    │  │  "Use your fingerprint or face to continue"    │          │
    │  │                                                │          │
    │  │                               [Cancel]         │          │
    │  └────────────────────────────────────────────────┘          │
    │                                                              │
    │  STATE 2: ERROR                                              │
    │  ┌────────────────────────────────────────────────┐          │
    │  │  [❌ Error Icon]                               │          │
    │  │                                                │          │
    │  │  "Biometric verification failed.               │          │
    │  │   Please try again."                           │          │
    │  │                                                │          │
    │  │  [Use Password] [Try Again]     [Cancel]       │          │
    │  └────────────────────────────────────────────────┘          │
    │                                                              │
    │  STATE 3: SUCCESS                                            │
    │  ┌────────────────────────────────────────────────┐          │
    │  │  [✅ Success]                                  │          │
    │  │                                                │          │
    │  │  Dialog closes automatically                   │          │
    │  │  User navigates to dashboard                   │          │
    │  └────────────────────────────────────────────────┘          │
    └──────────────────────────────────────────────────────────────┘


═══════════════════════════════════════════════════════════════════════════════
                       PERMISSION CHECK FLOW DIAGRAM
═══════════════════════════════════════════════════════════════════════════════

    After Successful Login
            │
            ▼
    ┌───────────────────────┐
    │  Check Notification   │
    │  Permission           │
    └──────────┬────────────┘
               │
        ┌──────┴──────┐
        │             │
    GRANTED        NOT GRANTED
        │             │
        │             ▼
        │      ┌─────────────────────────┐
        │      │  Show Dialog:           │
        │      │  "Enable Notifications" │
        │      │                         │
        │      │  "This app needs        │
        │      │  notification           │
        │      │  permission..."         │
        │      │                         │
        │      │  [Skip]    [Enable]     │
        │      └──────────┬──────────────┘
        │                 │
        └─────────────────┘
                   │
                   ▼
    ┌───────────────────────┐
    │  Check Location       │
    │  Permission           │
    └──────────┬────────────┘
               │
        ┌──────┴──────┐
        │             │
    GRANTED        NOT GRANTED
        │             │
        │             ▼
        │      ┌─────────────────────────┐
        │      │  Show Dialog:           │
        │      │  "Enable Location"      │
        │      │                         │
        │      │  "This app needs        │
        │      │  location permission    │
        │      │  to verify attendance   │
        │      │  check-in location"     │
        │      │                         │
        │      │  [Skip]    [Enable]     │
        │      └──────────┬──────────────┘
        │                 │
        └─────────────────┘
                   │
                   ▼
    ┌────────────────────────────┐
    │  Send Test Notification    │
    │  "Test Notification -      │
    │   If you can see this,     │
    │   notifications are        │
    │   working correctly!"      │
    └──────────┬─────────────────┘
               │
               ▼
    ┌────────────────────────────┐
    │  Show Confirmation Dialog  │
    │                            │
    │  "We just sent you a test  │
    │   notification.            │
    │   Did you receive it?"     │
    │                            │
    │  [No, I didn't]  [Yes]     │
    └──────────┬─────────────────┘
               │
        ┌──────┴──────┐
        │             │
       YES           NO
        │             │
        │             ▼
        │      ┌─────────────────────────┐
        │      │  "Please check your     │
        │      │   device notification   │
        │      │   settings..."          │
        │      │                         │
        │      │  [OK]                   │
        │      └─────────────────────────┘
        │
        └─────────────────┐
                          │
                          ▼
                   Continue to App


═══════════════════════════════════════════════════════════════════════════════
                            KEY COMPONENTS MAP
═══════════════════════════════════════════════════════════════════════════════

    ┌─────────────────────────────────────────────────────────────────────┐
    │                          AUTH SCREEN                                │
    │  (lib/auth/auth_screen.dart)                                        │
    │                                                                     │
    │  ├─ _initializeAuth()          → Check session on app start        │
    │  ├─ _checkExistingSession()    → Validate 24h session              │
    │  ├─ _continueToUserDashboard() → Navigate without login            │
    │  ├─ _handleSignIn()            → Email/Password login              │
    │  ├─ _checkAndRequestPermissions() → Check notification & location  │
    │  ├─ _sendTestNotificationAndConfirm() → Test notification system   │
    │  └─ _showBiometricSetupDialog() → Offer biometric setup            │
    └─────────────────────────────────────────────────────────────────────┘

    ┌─────────────────────────────────────────────────────────────────────┐
    │                        SESSION SERVICE                              │
    │  (lib/services/session_service.dart)                                │
    │                                                                     │
    │  ├─ startSession(userId)              → Begin 24h session          │
    │  ├─ updateActivity()                  → Extend session             │
    │  ├─ isSessionValid()                  → Check < 24h               │
    │  ├─ isBiometricEnabledForSession()    → Check user preference     │
    │  ├─ enableBiometricForSession()       → Enable biometric           │
    │  ├─ verifyBiometricForSession()       → Verify and update          │
    │  ├─ clearSession()                    → Clean up expired session   │
    │  └─ getTimeUntilExpiry()              → Calculate remaining time   │
    └─────────────────────────────────────────────────────────────────────┘

    ┌─────────────────────────────────────────────────────────────────────┐
    │                  BIOMETRIC VERIFICATION DIALOG                      │
    │  (lib/widgets/biometric_verification_dialog.dart)                   │
    │                                                                     │
    │  ├─ show()               → Static method to display dialog         │
    │  ├─ _verifyBiometric()   → Trigger biometric verification          │
    │  ├─ onSuccess            → Callback on successful verification     │
    │  ├─ onCancel             → Callback on cancellation                │
    │  └─ onFallbackToPassword → Callback for password fallback          │
    └─────────────────────────────────────────────────────────────────────┘

    ┌─────────────────────────────────────────────────────────────────────┐
    │                     NOTIFICATION SERVICE                            │
    │  (lib/services/notification_service.dart)                           │
    │                                                                     │
    │  ├─ initialize()                 → Setup notification system        │
    │  ├─ areNotificationsEnabled()    → Check permission status          │
    │  └─ showTestNotification()       → Send test notification (NEW!)   │
    └─────────────────────────────────────────────────────────────────────┘


═══════════════════════════════════════════════════════════════════════════════
                              DATA FLOW DIAGRAM
═══════════════════════════════════════════════════════════════════════════════

    SharedPreferences                Supabase                  Device Biometric
    (Local Storage)                  (Backend)                 (Hardware)
         │                               │                           │
         ├─ last_activity_time           ├─ auth.currentUser        ├─ Fingerprint
         ├─ session_user_id              ├─ users table             ├─ Face ID
         └─ biometric_enabled_session    └─ activity_log            └─ PIN
         │                               │                           │
         └───────────────┬───────────────┴───────────┬───────────────┘
                         │                           │
                         ▼                           ▼
                 ┌───────────────┐           ┌──────────────┐
                 │ SessionService│           │ BiometricSvc │
                 └───────┬───────┘           └──────┬───────┘
                         │                          │
                         └──────────┬───────────────┘
                                    │
                                    ▼
                            ┌───────────────┐
                            │  AuthScreen   │
                            └───────────────┘
```

**Legend:**
- ✅ Success State
- ❌ Error/Expired State
- 🔔 Notification Related
- 📍 Location Related
- 🔐 Security/Biometric Related
- ⌛ Loading State

**Session Duration:** Exactly 24 hours (86,400 seconds)  
**Biometric Re-auth:** Only inside app (not on login page)  
**Permission Checks:** Notification + Location + Test Notification
