import 'package:flutter/material.dart';
import '../../ui/design_system/components/jm_card.dart';
import '../../ui/design_system/components/jm_button.dart';
import '../../ui/shared_components/jm_notification.dart';
import '../../ui/design_system/tokens/colors.dart';
import '../../ui/design_system/tokens/spacing.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 20),
          const Text(
            'How can we help you?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 30),
          
          // Priority Services
          _buildHelpCard(
            context,
            icon: Icons.priority_high,
            title: 'Priority Services',
            subtitle: 'Get priority support for urgent issues',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PriorityServicesScreen()),
              );
            },
          ),
          
          const SizedBox(height: 16),
          
          // Help Center
          _buildHelpCard(
            context,
            icon: Icons.help_outline,
            title: 'Help Center',
            subtitle: 'Browse FAQs and guides',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HelpCenterScreen()),
              );
            },
          ),
          
          const SizedBox(height: 16),
          
          // Contact Support
          _buildHelpCard(
            context,
            icon: Icons.contact_support,
            title: 'Contact Support',
            subtitle: 'Get in touch with our support team',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ContactSupportScreen()),
              );
            },
          ),
          
          const SizedBox(height: 16),
          
          // WhatsApp Chat
          _buildHelpCard(
            context,
            icon: Icons.chat,
            title: 'WhatsApp Chat',
            subtitle: 'Chat with us on WhatsApp',
            onTap: () {
              _showWhatsAppInfo(context);
            },
          ),
          
          const SizedBox(height: 16),
          
          // Email Support
          _buildHelpCard(
            context,
            icon: Icons.email,
            title: 'Email Support',
            subtitle: 'Send us an email',
            onTap: () {
              _showEmailInfo(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHelpCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                icon,
                size: 40,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  void _showWhatsAppInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('WhatsApp Support'),
        content: const Text(
          'Contact us on WhatsApp:\n+255 700 000 000\n\nAvailable 24/7 for urgent queries',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showEmailInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Email Support'),
        content: const Text(
          'Send us an email:\nsupport@jengamate.com\n\nResponse within 24 hours',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

// Priority Services Screen Implementation
class PriorityServicesScreen extends StatefulWidget {
  const PriorityServicesScreen({Key? key}) : super(key: key);

  @override
  State<PriorityServicesScreen> createState() => _PriorityServicesScreenState();
}

class _PriorityServicesScreenState extends State<PriorityServicesScreen> {
  String _selectedService = '';
  String _urgencyLevel = 'high';
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Priority Services'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            JMCard(
              variant: JMCardVariant.elevated,
              title: 'Priority Support',
              subtitle: 'Get immediate assistance for critical issues',
              leading: Icon(Icons.priority_high, color: JMColors.danger, size: 32),
              child: const Text(
                'Our priority services ensure you get immediate attention for urgent matters. Response time: 30 minutes or less.',
                style: TextStyle(fontSize: 14),
              ),
            ),

            const SizedBox(height: 24),

            // Service Selection
            const Text(
              'Select Service Type',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Urgent Order Issues
            JMCard(
              variant: JMCardVariant.outlined,
              title: 'Urgent Order Issues',
              subtitle: 'Order delays, cancellations, modifications',
              leading: Icon(Icons.shopping_cart, color: JMColors.warning),
              trailing: Radio<String>(
                value: 'order_issues',
                groupValue: _selectedService,
                onChanged: (value) => setState(() => _selectedService = value!),
              ),
              child: const Text(
                'Issues with order processing, delivery delays, or urgent modifications needed.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),

            const SizedBox(height: 12),

            // Payment Problems
            JMCard(
              variant: JMCardVariant.outlined,
              title: 'Payment Problems',
              subtitle: 'Failed payments, refunds, billing issues',
              leading: Icon(Icons.payment, color: JMColors.danger),
              trailing: Radio<String>(
                value: 'payment_problems',
                groupValue: _selectedService,
                onChanged: (value) => setState(() => _selectedService = value!),
              ),
              child: const Text(
                'Payment failures, incorrect charges, refund requests, or billing discrepancies.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),

            const SizedBox(height: 12),

            // Account Security
            JMCard(
              variant: JMCardVariant.outlined,
              title: 'Account Security',
              subtitle: 'Security concerns, unauthorized access',
              leading: Icon(Icons.security, color: JMColors.danger),
              trailing: Radio<String>(
                value: 'account_security',
                groupValue: _selectedService,
                onChanged: (value) => setState(() => _selectedService = value!),
              ),
              child: const Text(
                'Suspicious account activity, security concerns, or unauthorized access issues.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),

            const SizedBox(height: 12),

            // System Outages
            JMCard(
              variant: JMCardVariant.outlined,
              title: 'System Issues',
              subtitle: 'App crashes, login problems, technical issues',
              leading: Icon(Icons.bug_report, color: JMColors.warning),
              trailing: Radio<String>(
                value: 'system_issues',
                groupValue: _selectedService,
                onChanged: (value) => setState(() => _selectedService = value!),
              ),
              child: const Text(
                'Application crashes, login failures, or other technical problems affecting operations.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),

            const SizedBox(height: 24),

            // Urgency Level
            const Text(
              'Urgency Level',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: JMButton(
                    variant: _urgencyLevel == 'critical' ? JMButtonVariant.danger : JMButtonVariant.secondary,
                    label: 'Critical',
                    icon: Icons.warning,
                    onPressed: () => setState(() => _urgencyLevel = 'critical'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: JMButton(
                    variant: _urgencyLevel == 'high' ? JMButtonVariant.warning : JMButtonVariant.secondary,
                    label: 'High',
                    icon: Icons.priority_high,
                    onPressed: () => setState(() => _urgencyLevel = 'high'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: JMButton(
                    variant: _urgencyLevel == 'medium' ? JMButtonVariant.primary : JMButtonVariant.secondary,
                    label: 'Medium',
                    icon: Icons.schedule,
                    onPressed: () => setState(() => _urgencyLevel = 'medium'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Description
            JMCard(
              variant: JMCardVariant.elevated,
              title: 'Describe Your Issue',
              subtitle: 'Please provide detailed information',
              child: TextField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Explain your issue in detail...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Contact Options
            const Text(
              'How would you like to be contacted?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: JMButton(
                    variant: JMButtonVariant.success,
                    label: 'Call Now',
                    icon: Icons.phone,
                    onPressed: () => _initiateCall(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: JMButton(
                    variant: JMButtonVariant.primary,
                    label: 'WhatsApp',
                    icon: Icons.chat,
                    onPressed: () => _initiateWhatsApp(context),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            JMButton(
              variant: JMButtonVariant.secondary,
              label: 'Submit Priority Request',
              icon: Icons.send,
              fullWidth: true,
              onPressed: _selectedService.isNotEmpty ? () => _submitPriorityRequest(context) : null,
            ),

            const SizedBox(height: 24),

            // Response Time Information
            JMCard(
              variant: JMCardVariant.filled,
              title: 'Response Times',
              child: Column(
                children: [
                  _buildResponseTimeItem('Critical Issues', '15 minutes', JMColors.danger),
                  _buildResponseTimeItem('High Priority', '30 minutes', JMColors.warning),
                  _buildResponseTimeItem('Medium Priority', '2 hours', JMColors.info),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponseTimeItem(String priority, String time, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(priority, style: const TextStyle(fontWeight: FontWeight.w500)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              time,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _initiateCall(BuildContext context) {
    context.showSuccess('Calling priority support...', title: 'Initiating Call');
    // In a real app, this would initiate a phone call
  }

  void _initiateWhatsApp(BuildContext context) {
    context.showSuccess('Opening WhatsApp...', title: 'Contacting Support');
    // In a real app, this would open WhatsApp
  }

  void _submitPriorityRequest(BuildContext context) {
    if (_selectedService.isEmpty || _descriptionController.text.isEmpty) {
      context.showError('Please select a service type and provide a description', title: 'Incomplete Request');
      return;
    }

    context.showSuccess(
      'Priority request submitted successfully! Our team will contact you within ${getResponseTime()}',
      title: 'Request Submitted',
    );

    // Reset form
    setState(() {
      _selectedService = '';
      _descriptionController.clear();
    });
  }

  String getResponseTime() {
    switch (_urgencyLevel) {
      case 'critical':
        return '15 minutes';
      case 'high':
        return '30 minutes';
      case 'medium':
        return '2 hours';
      default:
        return '30 minutes';
    }
  }
}

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({Key? key}) : super(key: key);

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'all';
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _faqCategories = [
    {'id': 'all', 'name': 'All Topics', 'icon': Icons.help_outline},
    {'id': 'orders', 'name': 'Orders', 'icon': Icons.shopping_cart},
    {'id': 'payments', 'name': 'Payments', 'icon': Icons.payment},
    {'id': 'account', 'name': 'Account', 'icon': Icons.person},
    {'id': 'products', 'name': 'Products', 'icon': Icons.inventory},
    {'id': 'shipping', 'name': 'Shipping', 'icon': Icons.local_shipping},
  ];

  final List<Map<String, dynamic>> _faqs = [
    {
      'id': '1',
      'category': 'orders',
      'question': 'How do I place a new order?',
      'answer': 'To place a new order, navigate to the Products section, browse or search for items, add them to your cart, then proceed to checkout. You can select your preferred payment method and delivery address during checkout.',
      'tags': ['order', 'purchase', 'checkout'],
    },
    {
      'id': '2',
      'category': 'orders',
      'question': 'How can I track my order?',
      'answer': 'You can track your order by going to the Orders section in your dashboard. Each order has a tracking number and status updates. You will also receive email notifications about order status changes.',
      'tags': ['track', 'status', 'delivery'],
    },
    {
      'id': '3',
      'category': 'payments',
      'question': 'What payment methods are accepted?',
      'answer': 'We accept multiple payment methods including Credit/Debit cards, Mobile Money (M-Pesa, Airtel Money, Tigo Pesa), bank transfers, and cash on delivery for eligible orders.',
      'tags': ['payment', 'methods', 'mpesa'],
    },
    {
      'id': '4',
      'category': 'payments',
      'question': 'How do I request a refund?',
      'answer': 'Refunds can be requested through the Orders section by selecting the order and choosing "Request Refund". Our team will review your request within 24-48 hours and process eligible refunds.',
      'tags': ['refund', 'return', 'money back'],
    },
    {
      'id': '5',
      'category': 'account',
      'question': 'How do I reset my password?',
      'answer': 'Click on "Forgot Password" on the login screen, enter your email address, and follow the instructions sent to your email. You can also reset your password from your account settings.',
      'tags': ['password', 'reset', 'login'],
    },
    {
      'id': '6',
      'category': 'account',
      'question': 'How do I update my profile information?',
      'answer': 'Go to your profile settings by tapping on your avatar or name in the top right corner. You can update your personal information, contact details, and preferences there.',
      'tags': ['profile', 'update', 'settings'],
    },
    {
      'id': '7',
      'category': 'products',
      'question': 'How do I search for products?',
      'answer': 'Use the search bar at the top of the Products screen. You can search by product name, category, or supplier. Advanced filters are available to narrow down results by price, availability, and ratings.',
      'tags': ['search', 'filter', 'find'],
    },
    {
      'id': '8',
      'category': 'products',
      'question': 'What should I do if a product is out of stock?',
      'answer': 'If a product is out of stock, you can set up notifications by tapping the bell icon on the product page. You will be notified when it becomes available again.',
      'tags': ['stock', 'availability', 'notification'],
    },
    {
      'id': '9',
      'category': 'shipping',
      'question': 'What are the shipping costs?',
      'answer': 'Shipping costs vary based on location, weight, and delivery speed. Free shipping is available for orders over TSh 100,000. Express delivery is available for urgent orders with additional charges.',
      'tags': ['shipping', 'cost', 'delivery'],
    },
    {
      'id': '10',
      'category': 'shipping',
      'question': 'How long does delivery take?',
      'answer': 'Standard delivery takes 3-5 business days within Tanzania. Express delivery is available within 24-48 hours. International shipping times vary by destination.',
      'tags': ['delivery', 'time', 'shipping'],
    },
  ];

  List<Map<String, dynamic>> get _filteredFaqs {
    List<Map<String, dynamic>> filtered = _faqs;

    // Filter by category
    if (_selectedCategory != 'all') {
      filtered = filtered.where((faq) => faq['category'] == _selectedCategory).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((faq) {
        final question = faq['question'].toString().toLowerCase();
        final answer = faq['answer'].toString().toLowerCase();
        final tags = (faq['tags'] as List<String>).join(' ').toLowerCase();
        final query = _searchQuery.toLowerCase();

        return question.contains(query) ||
               answer.contains(query) ||
               tags.contains(query);
      }).toList();
    }

    return filtered;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help Center'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'Search FAQs...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Category Filter
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _faqCategories.map((category) {
                      final isSelected = category['id'] == _selectedCategory;
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Row(
                            children: [
                              Icon(category['icon'], size: 16),
                              const SizedBox(width: 4),
                              Text(category['name']),
                            ],
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() => _selectedCategory = category['id']);
                          },
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                          selectedColor: Colors.white.withValues(alpha: 0.2),
                          checkmarkColor: Colors.white,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _filteredFaqs.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredFaqs.length,
              itemBuilder: (context, index) {
                final faq = _filteredFaqs[index];
                return JMCard(
                  variant: JMCardVariant.elevated,
                  title: faq['question'],
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        faq['answer'],
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: (faq['tags'] as List<String>).map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: JMColors.info.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              tag,
                              style: TextStyle(
                                color: JMColors.info,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty
                ? 'No results found for "${_searchQuery}"'
                : 'No FAQs found in this category',
            style: TextStyle(
              fontSize: 18,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try different keywords or check other categories'
                : 'Check other categories for help topics',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          JMButton(
            variant: JMButtonVariant.primary,
            label: 'Contact Support',
            icon: Icons.contact_support,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ContactSupportScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}

class ContactSupportScreen extends StatefulWidget {
  const ContactSupportScreen({Key? key}) : super(key: key);

  @override
  State<ContactSupportScreen> createState() => _ContactSupportScreenState();
}

class _ContactSupportScreenState extends State<ContactSupportScreen> {
  String _selectedCategory = 'general';
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  final List<Map<String, dynamic>> _supportCategories = [
    {'id': 'general', 'name': 'General Inquiry', 'icon': Icons.help_outline, 'color': JMColors.info},
    {'id': 'technical', 'name': 'Technical Issue', 'icon': Icons.bug_report, 'color': JMColors.danger},
    {'id': 'billing', 'name': 'Billing & Payments', 'icon': Icons.payment, 'color': JMColors.success},
    {'id': 'orders', 'name': 'Orders & Delivery', 'icon': Icons.shopping_cart, 'color': JMColors.warning},
    {'id': 'account', 'name': 'Account Issues', 'icon': Icons.person, 'color': JMColors.lightScheme.primary},
    {'id': 'feedback', 'name': 'Feedback & Suggestions', 'icon': Icons.feedback, 'color': JMColors.lightScheme.secondary},
  ];

  final List<Map<String, dynamic>> _contactMethods = [
    {
      'name': 'Live Chat',
      'description': 'Chat with our support team',
      'icon': Icons.chat,
      'color': JMColors.success,
      'availability': 'Available 24/7',
      'responseTime': 'Instant',
    },
    {
      'name': 'WhatsApp',
      'description': 'Message us on WhatsApp',
      'icon': Icons.phone_android,
      'color': JMColors.success,
      'availability': 'Mon-Fri 8AM-6PM',
      'responseTime': '< 30 minutes',
    },
    {
      'name': 'Phone Call',
      'description': 'Speak directly with support',
      'icon': Icons.phone,
      'color': JMColors.info,
      'availability': 'Mon-Fri 9AM-5PM',
      'responseTime': '< 15 minutes',
    },
    {
      'name': 'Email',
      'description': 'Send detailed inquiries',
      'icon': Icons.email,
      'color': JMColors.warning,
      'availability': '24/7',
      'responseTime': '< 24 hours',
    },
  ];

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact Support'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            JMCard(
              variant: JMCardVariant.elevated,
              title: 'Get in Touch',
              subtitle: 'We\'re here to help you',
              leading: Icon(Icons.contact_support, color: JMColors.info, size: 32),
              child: const Text(
                'Choose your preferred contact method or submit a detailed inquiry below. Our support team is ready to assist you.',
                style: TextStyle(fontSize: 14),
              ),
            ),

            const SizedBox(height: 24),

            // Quick Contact Methods
            const Text(
              'Quick Contact',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            ..._contactMethods.map((method) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: JMCard(
                    variant: JMCardVariant.outlined,
                    title: method['name'],
                    subtitle: method['availability'],
                    leading: Icon(method['icon'], color: method['color']),
                    trailing: JMButton(
                      variant: JMButtonVariant.primary,
                      size: JMButtonSize.small,
                      label: 'Contact',
                      onPressed: () => _initiateContact(method['name']),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          method['description'],
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.access_time, size: 16, color: method['color']),
                            const SizedBox(width: 4),
                            Text(
                              'Response: ${method['responseTime']}',
                              style: TextStyle(
                                color: method['color'],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )),

            const SizedBox(height: 24),

            // Detailed Inquiry Form
            const Text(
              'Send Detailed Inquiry',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Category Selection
            JMCard(
              variant: JMCardVariant.elevated,
              title: 'Category',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _supportCategories.map((category) {
                  final isSelected = category['id'] == _selectedCategory;
                  return FilterChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(category['icon'], size: 16, color: isSelected ? Colors.white : category['color']),
                        const SizedBox(width: 4),
                        Text(category['name']),
                      ],
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => _selectedCategory = category['id']);
                    },
                    backgroundColor: Colors.grey.shade100,
                    selectedColor: category['color'],
                    checkmarkColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 16),

            // Subject Field
            JMCard(
              variant: JMCardVariant.elevated,
              title: 'Subject',
              child: TextField(
                controller: _subjectController,
                decoration: InputDecoration(
                  hintText: 'Brief description of your inquiry',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Message Field
            JMCard(
              variant: JMCardVariant.elevated,
              title: 'Message',
              child: TextField(
                controller: _messageController,
                maxLines: 6,
                decoration: InputDecoration(
                  hintText: 'Please provide detailed information about your inquiry...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Submit Button
            JMButton(
              variant: JMButtonVariant.primary,
              label: 'Submit Inquiry',
              icon: Icons.send,
              fullWidth: true,
              onPressed: _submitInquiry,
            ),

            const SizedBox(height: 24),

            // Support Hours
            JMCard(
              variant: JMCardVariant.filled,
              title: 'Support Hours',
              child: Column(
                children: [
                  _buildSupportHours('Live Chat', '24/7', JMColors.success),
                  _buildSupportHours('Phone Support', 'Mon-Fri 9AM-5PM EAT', JMColors.info),
                  _buildSupportHours('WhatsApp', 'Mon-Fri 8AM-6PM EAT', JMColors.success),
                  _buildSupportHours('Email', '24/7 (Response within 24h)', JMColors.warning),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Emergency Contact
            JMCard(
              variant: JMCardVariant.outlined,
              title: 'Emergency Support',
              subtitle: 'For critical system issues',
              leading: Icon(Icons.emergency, color: JMColors.danger),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'If you\'re experiencing a critical system issue that affects your business operations, please contact our emergency line:',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: JMColors.danger.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: JMColors.danger.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.phone, color: JMColors.danger),
                        const SizedBox(width: 12),
                        const Text(
                          '+255 700 000 001 (Emergency)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: JMColors.danger,
                          ),
                        ),
                      ],
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

  Widget _buildSupportHours(String method, String hours, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(method, style: const TextStyle(fontWeight: FontWeight.w500)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              hours,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _initiateContact(String method) {
    String message = '';

    switch (method) {
      case 'Live Chat':
        message = 'Opening live chat...';
        // In a real app, this would open a chat widget
        break;
      case 'WhatsApp':
        message = 'Opening WhatsApp...';
        // In a real app, this would open WhatsApp
        break;
      case 'Phone Call':
        message = 'Initiating phone call...';
        // In a real app, this would initiate a phone call
        break;
      case 'Email':
        message = 'Opening email client...';
        // In a real app, this would open email client
        break;
    }

    context.showSuccess(message, title: 'Contacting Support');
  }

  void _submitInquiry() {
    if (_subjectController.text.isEmpty || _messageController.text.isEmpty) {
      context.showError(
        'Please fill in both subject and message fields',
        title: 'Incomplete Form',
      );
      return;
    }

    context.showSuccess(
      'Your inquiry has been submitted successfully! Our support team will respond within 24 hours.',
      title: 'Inquiry Submitted',
    );

    // Reset form
    setState(() {
      _selectedCategory = 'general';
      _subjectController.clear();
      _messageController.clear();
    });
  }
}