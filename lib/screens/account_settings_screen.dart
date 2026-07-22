import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  bool _pushNotifications = true;
  bool _emailUpdates = true;
  bool _biometrics = true;
  bool _twoFactor = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Account Settings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Information Header Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.backgroundLight,
                    child: Icon(Icons.person, color: AppColors.primary, size: 30),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Rahul Sharma',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'rahul@example.com',
                          style: TextStyle(color: AppColors.textLight, fontSize: 11),
                        ),
                        SizedBox(height: 2),
                        Text(
                          '+91 98765 43210',
                          style: TextStyle(color: AppColors.textLight, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Edit profile coming soon!')),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      minimumSize: Size.zero,
                    ),
                    child: const Text('Edit', style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Notification preferences group
            const Text(
              'Notification Preferences',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border.withOpacity(0.5)),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    activeColor: AppColors.primary,
                    title: const Text('Push Notifications', style: TextStyle(fontSize: 13, color: AppColors.textDark, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Get real-time updates for orders & consultations', style: TextStyle(fontSize: 10)),
                    value: _pushNotifications,
                    onChanged: (val) {
                      setState(() {
                        _pushNotifications = val;
                      });
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    activeColor: AppColors.primary,
                    title: const Text('Email Newsletters', style: TextStyle(fontSize: 13, color: AppColors.textDark, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Receive health tips, discount codes & promos', style: TextStyle(fontSize: 10)),
                    value: _emailUpdates,
                    onChanged: (val) {
                      setState(() {
                        _emailUpdates = val;
                      });
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Security group
            const Text(
              'Security settings',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border.withOpacity(0.5)),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    activeColor: AppColors.primary,
                    title: const Text('Biometric Login', style: TextStyle(fontSize: 13, color: AppColors.textDark, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Use Face ID / Fingerprint to log in', style: TextStyle(fontSize: 10)),
                    value: _biometrics,
                    onChanged: (val) {
                      setState(() {
                        _biometrics = val;
                      });
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    activeColor: AppColors.primary,
                    title: const Text('Two-Factor Authentication', style: TextStyle(fontSize: 13, color: AppColors.textDark, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Secure login with extra verification codes', style: TextStyle(fontSize: 10)),
                    value: _twoFactor,
                    onChanged: (val) {
                      setState(() {
                        _twoFactor = val;
                      });
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Change Password', style: TextStyle(fontSize: 13, color: AppColors.textDark, fontWeight: FontWeight.w600)),
                    trailing: const Icon(Icons.chevron_right, size: 18),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Password modification flow')),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Help and privacy information
            const Text(
              'Legal & Info',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border.withOpacity(0.5)),
              ),
              child: Column(
                children: [
                  ListTile(
                    title: const Text('Privacy Policy', style: TextStyle(fontSize: 13, color: AppColors.textDark, fontWeight: FontWeight.w600)),
                    trailing: const Icon(Icons.chevron_right, size: 18),
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Terms of Service', style: TextStyle(fontSize: 13, color: AppColors.textDark, fontWeight: FontWeight.w600)),
                    trailing: const Icon(Icons.chevron_right, size: 18),
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  const ListTile(
                    title: Text('App Version', style: TextStyle(fontSize: 13, color: AppColors.textDark, fontWeight: FontWeight.w600)),
                    trailing: Text('v1.0.0', style: TextStyle(color: AppColors.textLight, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
