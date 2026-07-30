import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_state.dart';
import '../models/user_model.dart';
import 'login_screen.dart';

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
  bool _isLoadingProfile = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final appState = AppState();
    if (appState.authToken != null && appState.authToken!.isNotEmpty) {
      setState(() {
        _isLoadingProfile = true;
      });
      await appState.fetchUserProfile();
      if (mounted) {
        setState(() {
          _isLoadingProfile = false;
        });
      }
    }
  }

  String _formatDate(String? isoString) {
    if (isoString == null || isoString.isEmpty) return 'N/A';
    try {
      final dateTime = DateTime.parse(isoString).toLocal();
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return isoString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppState();
    final user = appState.currentUser;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Account Profile & Settings',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            icon: _isLoadingProfile
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            onPressed: _loadProfile,
            tooltip: 'Fetch Profile API',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadProfile,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
                  border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      child: Text(
                        user != null && user.fullName.isNotEmpty
                            ? user.fullName[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  user?.fullName ?? 'Guest User',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 17,
                                      color: AppColors.textDark),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (user?.isMobileVerified ?? false) ...[
                                const SizedBox(width: 6),
                                const Tooltip(
                                  message: 'Mobile Verified',
                                  child: Icon(Icons.verified, color: Colors.green, size: 18),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user?.email ?? 'No email available',
                            style: const TextStyle(color: AppColors.textLight, fontSize: 13),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user != null && user.mobile.isNotEmpty ? '+91 ${user.mobile}' : 'No mobile registered',
                            style: const TextStyle(color: AppColors.textLight, fontSize: 12),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  (user?.role ?? 'CUSTOMER').toUpperCase(),
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: (user?.isActive ?? true)
                                      ? Colors.green.withValues(alpha: 0.1)
                                      : Colors.red.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  (user?.isActive ?? true) ? 'ACTIVE' : 'INACTIVE',
                                  style: TextStyle(
                                    color: (user?.isActive ?? true) ? Colors.green : Colors.red,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Full Profile API Info Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Full Profile Details (Live API)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark),
                  ),
                  TextButton.icon(
                    onPressed: _loadProfile,
                    icon: const Icon(Icons.sync, size: 16),
                    label: const Text('Refresh', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildProfileDetailRow(
                      icon: Icons.person_outline,
                      label: 'Full Name',
                      value: user?.fullName ?? 'N/A',
                    ),
                    const Divider(height: 1),
                    _buildProfileDetailRow(
                      icon: Icons.email_outlined,
                      label: 'Email Address',
                      value: user?.email ?? 'N/A',
                    ),
                    const Divider(height: 1),
                    _buildProfileDetailRow(
                      icon: Icons.phone_outlined,
                      label: 'Mobile Number',
                      value: user?.mobile != null && user!.mobile.isNotEmpty ? user.mobile : 'N/A',
                    ),
                    const Divider(height: 1),
                    _buildProfileDetailRow(
                      icon: Icons.chat_bubble_outline,
                      label: 'WhatsApp Number',
                      value: user?.whatsappNumber != null && user!.whatsappNumber.isNotEmpty
                          ? user.whatsappNumber
                          : 'N/A',
                    ),
                    const Divider(height: 1),
                    _buildProfileDetailRow(
                      icon: Icons.badge_outlined,
                      label: 'User ID',
                      value: user?.id ?? 'N/A',
                    ),
                    const Divider(height: 1),
                    _buildProfileDetailRow(
                      icon: Icons.admin_panel_settings_outlined,
                      label: 'Role',
                      value: user?.role ?? 'customer',
                    ),
                    const Divider(height: 1),
                    _buildProfileDetailRow(
                      icon: Icons.check_circle_outline,
                      label: 'Mobile Verified',
                      value: (user?.isMobileVerified ?? false) ? 'Yes (Verified)' : 'No',
                      valueColor: (user?.isMobileVerified ?? false) ? Colors.green.shade700 : Colors.red.shade700,
                    ),
                    const Divider(height: 1),
                    _buildProfileDetailRow(
                      icon: Icons.access_time_outlined,
                      label: 'Last Login At',
                      value: _formatDate(user?.lastLoginAt),
                    ),
                    const Divider(height: 1),
                    _buildProfileDetailRow(
                      icon: Icons.calendar_today_outlined,
                      label: 'Created At',
                      value: _formatDate(user?.createdAt),
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
                  border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      activeColor: AppColors.primary,
                      title: const Text('Push Notifications',
                          style: TextStyle(fontSize: 13, color: AppColors.textDark, fontWeight: FontWeight.w600)),
                      subtitle: const Text('Get real-time updates for orders & consultations',
                          style: TextStyle(fontSize: 10)),
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
                      title: const Text('Email Newsletters',
                          style: TextStyle(fontSize: 13, color: AppColors.textDark, fontWeight: FontWeight.w600)),
                      subtitle: const Text('Receive health tips, discount codes & promos',
                          style: TextStyle(fontSize: 10)),
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
                'Security Settings',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      activeColor: AppColors.primary,
                      title: const Text('Biometric Login',
                          style: TextStyle(fontSize: 13, color: AppColors.textDark, fontWeight: FontWeight.w600)),
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
                      title: const Text('Two-Factor Authentication',
                          style: TextStyle(fontSize: 13, color: AppColors.textDark, fontWeight: FontWeight.w600)),
                      subtitle: const Text('Secure login with extra verification codes',
                          style: TextStyle(fontSize: 10)),
                      value: _twoFactor,
                      onChanged: (val) {
                        setState(() {
                          _twoFactor = val;
                        });
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Account Actions
              const Text(
                'Account Actions',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.logout, color: Colors.red),
                      title: const Text(
                        'Sign Out',
                        style: TextStyle(fontSize: 13, color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                      onTap: () async {
                        await AppState().logout();
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Logged out successfully')),
                        );
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                          (route) => false,
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textLight,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 13,
                color: valueColor ?? AppColors.textDark,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
