import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildContactCard(),
            const SizedBox(height: 20),
            _buildFAQSection(),
            const SizedBox(height: 20),
            _buildQuickLinksSection(),
            const SizedBox(height: 20),
            _buildTroubleshootingSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.support_agent, color: Colors.deepPurple, size: 28),
                SizedBox(width: 12),
                Text(
                  'Contact Support',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Need help? Our support team is here to assist you.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),

            // Contact options
            _buildContactOption(
              icon: Icons.email,
              title: 'Email Support',
              subtitle: 'support@srisparks.com',
              onTap: () => _launchEmail('support@srisparks.com'),
            ),
            const SizedBox(height: 12),
            _buildContactOption(
              icon: Icons.phone,
              title: 'Phone Support',
              subtitle: '+1 (555) 123-4567',
              onTap: () => _launchPhone('+15551234567'),
            ),
            const SizedBox(height: 12),
            _buildContactOption(
              icon: Icons.chat,
              title: 'Live Chat',
              subtitle: 'Available 24/7',
              onTap: () => _showMessage('Live chat feature coming soon'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.deepPurple),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(subtitle, style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.help_outline, color: Colors.deepPurple, size: 28),
                SizedBox(width: 12),
                Text(
                  'Frequently Asked Questions',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildFAQItem(
              question: 'How do I reset my password?',
              answer:
                  'You can reset your password by clicking the "Forgot Password" link on the login screen or by going to Profile > Settings > Change Password.',
            ),
            _buildFAQItem(
              question: 'How do I assign work to team members?',
              answer:
                  'Navigate to the "Assign Work" section from the sidebar. Select the team member, fill in the work details, and click "Assign Work".',
            ),
            _buildFAQItem(
              question: 'How do I track my time?',
              answer:
                  'Go to the "Time Tracking" section to start/stop timers for your assigned work or manually log time entries.',
            ),
            _buildFAQItem(
              question: 'How do I generate reports?',
              answer:
                  'Visit the "Reports" section to view analytics and generate reports based on work completion, time tracking, and team performance.',
            ),
            _buildFAQItem(
              question: 'How do I manage customer information?',
              answer:
                  'Use the "Customers" section to add, edit, and manage customer information and their project details.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem({required String question, required String answer}) {
    return ExpansionTile(
      title: Text(
        question,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(answer, style: const TextStyle(color: Colors.grey)),
        ),
      ],
    );
  }

  Widget _buildQuickLinksSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.link, color: Colors.deepPurple, size: 28),
                SizedBox(width: 12),
                Text(
                  'Quick Links',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildQuickLink(
              icon: Icons.book,
              title: 'User Guide',
              subtitle: 'Complete user manual',
              onTap: () => _showMessage('User guide feature coming soon'),
            ),
            _buildQuickLink(
              icon: Icons.video_library,
              title: 'Video Tutorials',
              subtitle: 'Watch how-to videos',
              onTap: () => _showMessage('Video tutorials feature coming soon'),
            ),
            _buildQuickLink(
              icon: Icons.update,
              title: 'What\'s New',
              subtitle: 'Latest updates and features',
              onTap: () => _showMessage('What\'s new feature coming soon'),
            ),
            _buildQuickLink(
              icon: Icons.bug_report,
              title: 'Report a Bug',
              subtitle: 'Help us improve the app',
              onTap: () => _launchEmail('bugs@srisparks.com'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickLink({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.deepPurple),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildTroubleshootingSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.build, color: Colors.deepPurple, size: 28),
                SizedBox(width: 12),
                Text(
                  'Troubleshooting',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildTroubleshootingItem(
              problem: 'App is running slowly',
              solution:
                  'Try clearing the app cache or restarting the application. If the problem persists, contact support.',
            ),
            _buildTroubleshootingItem(
              problem: 'Cannot login to my account',
              solution:
                  'Check your internet connection and verify your credentials. Use the "Forgot Password" option if needed.',
            ),
            _buildTroubleshootingItem(
              problem: 'Work assignments not loading',
              solution:
                  'Refresh the page or check your internet connection. Contact your manager if assignments are missing.',
            ),
            _buildTroubleshootingItem(
              problem: 'Time tracking not working',
              solution:
                  'Ensure you have proper permissions and your work is in "In Progress" status. Try refreshing the page.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTroubleshootingItem({
    required String problem,
    required String solution,
  }) {
    return ExpansionTile(
      title: Text(problem, style: const TextStyle(fontWeight: FontWeight.w600)),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(solution, style: const TextStyle(color: Colors.grey)),
        ),
      ],
    );
  }

  void _launchEmail(String email) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=Support Request',
    );

    try {
      await launchUrl(emailLaunchUri);
    } catch (e) {
      _showMessage('Could not launch email client');
    }
  }

  void _launchPhone(String phone) async {
    final Uri phoneLaunchUri = Uri(scheme: 'tel', path: phone);

    try {
      await launchUrl(phoneLaunchUri);
    } catch (e) {
      _showMessage('Could not launch phone dialer');
    }
  }

  void _showMessage(String message) {
    // Note: This needs to be called from a widget with context
    // For now, we'll just print the message
    print(message);
  }
}
