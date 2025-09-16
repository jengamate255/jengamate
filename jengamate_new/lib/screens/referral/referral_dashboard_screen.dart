import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jengamate/models/referral_model.dart';
import 'package:jengamate/models/user_model.dart';
import 'package:jengamate/services/database_service.dart';
import 'package:jengamate/services/auth_service.dart';
import 'package:jengamate/utils/responsive.dart';
import 'package:jengamate/utils/logger.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart'; // Import url_launcher

class ReferralDashboardScreen extends StatefulWidget {
  const ReferralDashboardScreen({super.key});

  @override
  State<ReferralDashboardScreen> createState() => _ReferralDashboardScreenState();
}

class _ReferralDashboardScreenState extends State<ReferralDashboardScreen> {
  final AuthService _authService = AuthService();
  
  List<ReferralModel> _referrals = [];
  List<UserModel> _referredUsers = [];
  bool _isLoading = true;
  String _referralCode = '';
  double _totalEarnings = 0.0;
  double _pendingEarnings = 0.0;
  int _totalReferrals = 0;
  int _activeReferrals = 0;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    setState(() => _isLoading = true);
    try {
      final user = _authService.currentUser;
      if (user != null) {
        _referralCode = _generateReferralCode(user.uid);
        await _loadReferralData(user.uid);
      }
    } catch (e) {
      Logger.logError('Error initializing referral data', e, StackTrace.current);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _generateReferralCode(String userId) {
    // Generate a simple referral code based on user ID
    return 'REF${userId.substring(0, 6).toUpperCase()}';
  }

  Future<void> _loadReferralData(String userId) async {
    try {
      final dbService = DatabaseService();

      // Load real referral data from database
      final referralData = await dbService.getUserReferrals(userId);
      _referrals = referralData.map((data) => ReferralModel(
        id: data['id'] ?? '',
        referrerId: data['referrerId'] ?? '',
        referredUserId: data['referredUserId'] ?? '',
        bonusAmount: (data['bonusAmount'] ?? 0.0).toDouble(),
        createdAt: data['createdAt'] ?? DateTime.now(),
        status: data['status'] ?? 'pending',
      )).toList();

      // Load referred users details
      final referredUserIds = _referrals.map((r) => r.referredUserId).toList();
      _referredUsers = await dbService.getUsersByIds(referredUserIds);

      _calculateStats();
      Logger.log('Loaded ${_referrals.length} referrals');
    } catch (e) {
      Logger.logError('Error loading referral data', e, StackTrace.current);
      // Set empty lists instead of fallback sample data
      _referrals = [];
      _referredUsers = [];
      _calculateStats();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load referral data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }



  void _calculateStats() {
    _totalReferrals = _referrals.length;
    _activeReferrals = _referrals.where((r) => r.status == 'completed').length;
    _totalEarnings = _referrals
        .where((r) => r.status == 'completed')
        .fold(0.0, (sum, r) => sum + r.bonusAmount);
    _pendingEarnings = _referrals
        .where((r) => r.status == 'pending')
        .fold(0.0, (sum, r) => sum + r.bonusAmount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Referral Dashboard'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadReferralData(_authService.currentUser!.uid),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildReferralCodeCard(),
                  const SizedBox(height: 16),
                  _buildStatsCards(),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Your Referrals'),
                  const SizedBox(height: 8),
                  _buildReferralsList(),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Referral Program Info'),
                  const SizedBox(height: 8),
                  _buildProgramInfoCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildReferralCodeCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.card_giftcard, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Your Referral Code',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _referralCode,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () => _copyReferralCode(),
                    tooltip: 'Copy Code',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _shareReferralCode,
                    icon: const Icon(Icons.share),
                    label: const Text('Share Code'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _inviteFriends,
                    icon: const Icon(Icons.person_add),
                    label: const Text('Invite Friends'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    return Responsive.isMobile(context)
        ? Column(children: _buildStatsCardsList())
        : Row(
            children: _buildStatsCardsList()
                .map((card) => Expanded(child: card))
                .toList(),
          );
  }

  List<Widget> _buildStatsCardsList() {
    final spacing = Responsive.getResponsiveSpacing(context);
    return [
      _buildStatCard('Total Referrals', _totalReferrals.toString(), Icons.people, Colors.blue),
      SizedBox(width: spacing, height: spacing),
      _buildStatCard('Active Referrals', _activeReferrals.toString(), Icons.check_circle, Colors.green),
      SizedBox(width: spacing, height: spacing),
      _buildStatCard('Total Earnings', 'TSH ${_totalEarnings.toStringAsFixed(0)}', Icons.account_balance_wallet, Colors.purple),
      SizedBox(width: spacing, height: spacing),
      _buildStatCard('Pending Earnings', 'TSH ${_pendingEarnings.toStringAsFixed(0)}', Icons.pending, Colors.orange),
    ];
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildReferralsList() {
    if (_referrals.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No referrals yet',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Text(
                'Share your referral code to start earning!',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: _referrals.map((referral) {
        final user = _referredUsers.firstWhere(
          (u) => u.uid == referral.referredUserId,
          orElse: () => UserModel(uid: referral.referredUserId, firstName: 'Unknown', lastName: 'User', email: 'unknown@example.com'),
        );
        return _buildReferralCard(referral, user);
      }).toList(),
    );
  }

  Widget _buildReferralCard(ReferralModel referral, UserModel user) {
    final statusColor = referral.status == 'completed' ? Colors.green : 
                       referral.status == 'pending' ? Colors.orange : Colors.red;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withValues(alpha: 0.2),
          child: Text(
            (user.firstName.isNotEmpty == true ? user.firstName[0] : 'U').toUpperCase(),
            style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text('${user.firstName} ${user.lastName}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email ?? 'No email'),
            Text('Joined: ${DateFormat('MMM dd, yyyy').format(referral.createdAt)}'),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'TSH ${referral.bonusAmount.toStringAsFixed(0)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                referral.status.toUpperCase(),
                style: TextStyle(
                  color: statusColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgramInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'How It Works',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoItem('1. Share your referral code with friends'),
            _buildInfoItem('2. They sign up using your code'),
            _buildInfoItem('3. You earn TSH 25,000 when they make their first purchase'),
            _buildInfoItem('4. They get a 10% discount on their first order'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tip: The more friends you refer, the more you earn! There\'s no limit to your referral earnings.',
                      style: TextStyle(color: Colors.blue[700]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  void _copyReferralCode() {
    Clipboard.setData(ClipboardData(text: _referralCode));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Referral code copied to clipboard!')),
    );
  }

  void _shareReferralCode() {
    final message = 'Join JengaMate using my referral code $_referralCode and get 10% off your first order! '
                   'Download the app and start shopping for quality products.';
    Share.share(message);
  }

  void _inviteFriends() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.email),
                title: const Text('Invite via Email'),
                onTap: () {
                  Navigator.pop(context);
                  _sendEmailInvite();
                },
              ),
              ListTile(
                leading: const Icon(Icons.sms),
                title: const Text('Invite via SMS'),
                onTap: () {
                  Navigator.pop(context);
                  _sendSMSInvite();
                },
              ),
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Share via Other Apps'),
                onTap: () {
                  Navigator.pop(context);
                  _shareReferralCode();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _sendEmailInvite() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: '',
      query: encodeQueryParameters(<String, String>{
        'subject': 'Join JengaMate and Get a Discount!',
        'body': 'Hey! Check out JengaMate and use my referral code $_referralCode to get 10% off your first order. Download the app today!',
      }),
    );
    await launchUrl(emailLaunchUri);
  }

  Future<void> _sendSMSInvite() async {
    final Uri smsLaunchUri = Uri(
      scheme: 'sms',
      path: '',
      queryParameters: <String, String>{
        'body': 'Hey! Join JengaMate using my referral code $_referralCode and get 10% off your first order. Download the app today!',
      },
    );
    await launchUrl(smsLaunchUri);
  }

  String? encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }
}
