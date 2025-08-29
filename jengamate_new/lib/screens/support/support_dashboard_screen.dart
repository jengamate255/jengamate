import 'package:flutter/material.dart';
import 'package:jengamate/models/support_ticket_model.dart';
import 'package:jengamate/services/database_service.dart';
import 'package:jengamate/services/auth_service.dart';
import 'package:jengamate/utils/responsive.dart';
import 'package:jengamate/utils/logger.dart';
import 'package:intl/intl.dart';

class SupportDashboardScreen extends StatefulWidget {
  final bool isAdminView;
  
  const SupportDashboardScreen({super.key, this.isAdminView = false});

  @override
  State<SupportDashboardScreen> createState() => _SupportDashboardScreenState();
}

class _SupportDashboardScreenState extends State<SupportDashboardScreen> with TickerProviderStateMixin {
  final DatabaseService _databaseService = DatabaseService();
  final AuthService _authService = AuthService();
  late TabController _tabController;
  
  List<SupportTicket> _tickets = [];
  List<FAQItem> _faqs = [];
  bool _isLoading = true;
  String _selectedStatus = 'all';
  String _selectedPriority = 'all';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: widget.isAdminView ? 4 : 3, vsync: this);
    _loadSupportData();
  }

  Future<void> _loadSupportData() async {
    setState(() => _isLoading = true);
    try {
      // Load real support tickets from database
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        if (widget.isAdminView) {
          // Admin can see all tickets
          _tickets = await _databaseService.getAllSupportTickets();
        } else {
          // Regular users see only their tickets
          _tickets = await _databaseService.getUserSupportTickets(currentUser.uid);
        }
      } else {
        _tickets = [];
      }

      // Load FAQs from database
      _faqs = await _databaseService.getFAQs();

      // If no FAQs exist, create default ones
      if (_faqs.isEmpty) {
        await _createDefaultFAQs();
        _faqs = await _databaseService.getFAQs();
      }

      Logger.log('Loaded ${_tickets.length} support tickets and ${_faqs.length} FAQs');
    } catch (e) {
      Logger.logError('Error loading support data', e, StackTrace.current);
      // Fallback to empty lists instead of sample data
      _tickets = [];
      _faqs = [];

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading support data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _createDefaultFAQs() async {
    final defaultFAQs = [
      FAQItem(
        id: '',
        question: 'How do I reset my password?',
        answer: 'You can reset your password by clicking "Forgot Password" on the login screen and following the instructions sent to your email.',
        category: 'account',
        isPopular: true,
      ),
      FAQItem(
        id: '',
        question: 'How are commissions calculated?',
        answer: 'Commissions are calculated based on your tier level and the total value of sales you generate. Higher tiers receive higher commission rates.',
        category: 'commission',
        isPopular: true,
      ),
      FAQItem(
        id: '',
        question: 'How long does it take to process withdrawals?',
        answer: 'Withdrawal requests are typically processed within 3-5 business days. You will receive an email confirmation once processed.',
        category: 'payment',
        isPopular: false,
      ),
      FAQItem(
        id: '',
        question: 'How do I refer new users?',
        answer: 'You can refer new users by sharing your unique referral code found in the Referral Dashboard. You earn bonuses for successful referrals.',
        category: 'referral',
        isPopular: true,
      ),
      FAQItem(
        id: '',
        question: 'How do I submit an RFQ (Request for Quote)?',
        answer: 'Navigate to the product you\'re interested in and click "Request Quote". Fill in your requirements and contact details, and suppliers will respond with quotes.',
        category: 'rfq',
        isPopular: true,
      ),
      FAQItem(
        id: '',
        question: 'What payment methods are accepted?',
        answer: 'We accept M-Pesa, bank transfers, and credit/debit cards. All payments are processed securely through our payment partners.',
        category: 'payment',
        isPopular: true,
      ),
    ];

    try {
      for (final faq in defaultFAQs) {
        await _databaseService.createFAQ(faq);
      }
      Logger.log('Created ${defaultFAQs.length} default FAQs');
    } catch (e) {
      Logger.logError('Error creating default FAQs', e, StackTrace.current);
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isAdminView ? 'Support Management' : 'Support Center'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSupportData,
          ),
          if (!widget.isAdminView)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _showCreateTicketDialog,
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          isScrollable: widget.isAdminView,
          tabs: [
            const Tab(text: 'Tickets', icon: Icon(Icons.support_agent)),
            const Tab(text: 'FAQ', icon: Icon(Icons.help)),
            const Tab(text: 'Guides', icon: Icon(Icons.book)),
            if (widget.isAdminView)
              const Tab(text: 'Analytics', icon: Icon(Icons.analytics)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTicketsTab(),
                _buildFAQTab(),
                _buildGuidesTab(),
                if (widget.isAdminView) _buildAnalyticsTab(),
              ],
            ),
      floatingActionButton: !widget.isAdminView
          ? FloatingActionButton(
              onPressed: _showCreateTicketDialog,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildTicketsTab() {
    return Column(
      children: [
        if (widget.isAdminView) _buildFiltersSection(),
        _buildTicketStats(),
        Expanded(child: _buildTicketsList()),
      ],
    );
  }

  Widget _buildFAQTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSearchBar(),
          const SizedBox(height: 16),
          _buildPopularFAQs(),
          const SizedBox(height: 24),
          _buildFAQCategories(),
        ],
      ),
    );
  }

  Widget _buildGuidesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Help Guides'),
          const SizedBox(height: 16),
          _buildGuidesList(),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Support Analytics'),
          const SizedBox(height: 16),
          _buildSupportMetrics(),
          const SizedBox(height: 24),
          _buildTicketTrends(),
          const SizedBox(height: 24),
          _buildAgentPerformance(),
        ],
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Responsive.isMobile(context)
            ? Column(children: _buildFilterControls())
            : Row(children: _buildFilterControls()),
      ),
    );
  }

  List<Widget> _buildFilterControls() {
    return [
      Expanded(
        child: DropdownButtonFormField<String>(
          value: _selectedStatus,
          decoration: const InputDecoration(
            labelText: 'Status',
            border: OutlineInputBorder(),
          ),
          items: ['all', 'open', 'in_progress', 'resolved', 'closed'].map((status) {
            return DropdownMenuItem(
              value: status,
              child: Text(status == 'all' ? 'All Status' : status.replaceAll('_', ' ').toUpperCase()),
            );
          }).toList(),
          onChanged: (value) {
            setState(() => _selectedStatus = value!);
          },
        ),
      ),
      const SizedBox(width: 16, height: 16),
      Expanded(
        child: DropdownButtonFormField<String>(
          value: _selectedPriority,
          decoration: const InputDecoration(
            labelText: 'Priority',
            border: OutlineInputBorder(),
          ),
          items: ['all', 'low', 'medium', 'high', 'urgent'].map((priority) {
            return DropdownMenuItem(
              value: priority,
              child: Text(priority == 'all' ? 'All Priorities' : priority.toUpperCase()),
            );
          }).toList(),
          onChanged: (value) {
            setState(() => _selectedPriority = value!);
          },
        ),
      ),
    ];
  }

  Widget _buildTicketStats() {
    final openTickets = _tickets.where((t) => t.status == 'open').length;
    final inProgressTickets = _tickets.where((t) => t.status == 'in_progress').length;
    final resolvedTickets = _tickets.where((t) => t.status == 'resolved').length;
    final totalTickets = _tickets.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
      child: Responsive.isMobile(context)
          ? Column(children: _buildStatItems(openTickets, inProgressTickets, resolvedTickets, totalTickets))
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _buildStatItems(openTickets, inProgressTickets, resolvedTickets, totalTickets),
            ),
    );
  }

  List<Widget> _buildStatItems(int open, int inProgress, int resolved, int total) {
    return [
      _buildStatItem('Total', total.toString(), Colors.blue),
      _buildStatItem('Open', open.toString(), Colors.red),
      _buildStatItem('In Progress', inProgress.toString(), Colors.orange),
      _buildStatItem('Resolved', resolved.toString(), Colors.green),
    ];
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildTicketsList() {
    final filteredTickets = _tickets.where((ticket) {
      if (!widget.isAdminView) {
        // For users, only show their own tickets
        final currentUserId = _authService.currentUser?.uid;
        if (ticket.userId != currentUserId) return false;
      }
      
      if (_selectedStatus != 'all' && ticket.status != _selectedStatus) return false;
      if (_selectedPriority != 'all' && ticket.priority != _selectedPriority) return false;
      
      if (_searchController.text.isNotEmpty) {
        final searchTerm = _searchController.text.toLowerCase();
        if (!ticket.subject.toLowerCase().contains(searchTerm) &&
            !ticket.description.toLowerCase().contains(searchTerm)) {
          return false;
        }
      }
      
      return true;
    }).toList();

    if (filteredTickets.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.support_agent, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No tickets found', style: TextStyle(fontSize: 18, color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredTickets.length,
      itemBuilder: (context, index) {
        final ticket = filteredTickets[index];
        return _buildTicketCard(ticket);
      },
    );
  }

  Widget _buildTicketCard(SupportTicket ticket) {
    final statusColor = _getStatusColor(ticket.status);
    final priorityColor = _getPriorityColor(ticket.priority);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withValues(alpha: 0.2),
          child: Icon(_getStatusIcon(ticket.status), color: statusColor, size: 20),
        ),
        title: Text(
          ticket.subject,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.isAdminView) Text('User: ${ticket.userName}'),
            Text(ticket.description, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(
              DateFormat('MMM dd, yyyy HH:mm').format(ticket.createdAt),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildPriorityChip(ticket.priority),
            const SizedBox(height: 4),
            _buildStatusChip(ticket.status),
          ],
        ),
        onTap: () => _showTicketDetails(ticket),
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Search FAQs...',
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      onChanged: (value) => setState(() {}),
    );
  }

  Widget _buildPopularFAQs() {
    final popularFAQs = _faqs.where((faq) => faq.isPopular).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Popular Questions'),
        const SizedBox(height: 16),
        ...popularFAQs.map((faq) => _buildFAQCard(faq)),
      ],
    );
  }

  Widget _buildFAQCategories() {
    final categories = _faqs.map((faq) => faq.category).toSet().toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Browse by Category'),
        const SizedBox(height: 16),
        ...categories.map((category) => _buildCategorySection(category)),
      ],
    );
  }

  Widget _buildCategorySection(String category) {
    final categoryFAQs = _faqs.where((faq) => faq.category == category).toList();
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        title: Text(category.toUpperCase()),
        leading: Icon(_getCategoryIcon(category)),
        children: categoryFAQs.map((faq) => _buildFAQCard(faq)).toList(),
      ),
    );
  }

  Widget _buildFAQCard(FAQItem faq) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ExpansionTile(
        title: Text(faq.question),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(faq.answer),
          ),
        ],
      ),
    );
  }

  Widget _buildGuidesList() {
    final guides = [
      {'title': 'Getting Started Guide', 'description': 'Learn the basics of using JengaMate'},
      {'title': 'Commission System Guide', 'description': 'Understand how commissions work'},
      {'title': 'Referral Program Guide', 'description': 'Maximize your referral earnings'},
      {'title': 'Payment & Withdrawal Guide', 'description': 'Manage your payments and withdrawals'},
    ];

    return Column(
      children: guides.map((guide) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: const Icon(Icons.book),
          title: Text(guide['title']!),
          subtitle: Text(guide['description']!),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () {
            // TODO: Navigate to guide details
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Opening ${guide['title']}')),
            );
          },
        ),
      )).toList(),
    );
  }

  Widget _buildSupportMetrics() {
    return Responsive.isMobile(context)
        ? Column(children: _buildMetricCardsList())
        : Row(children: _buildMetricCardsList().map((card) => Expanded(child: card)).toList());
  }

  List<Widget> _buildMetricCardsList() {
    return [
      _buildMetricCard('Avg Response Time', '2.5 hrs', Icons.schedule, Colors.blue),
      const SizedBox(width: 16, height: 8),
      _buildMetricCard('Resolution Rate', '94%', Icons.check_circle, Colors.green),
      const SizedBox(width: 16, height: 8),
      _buildMetricCard('Customer Satisfaction', '4.8/5', Icons.star, Colors.orange),
      const SizedBox(width: 16, height: 8),
      _buildMetricCard('Active Agents', '5', Icons.people, Colors.purple),
    ];
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
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

  Widget _buildTicketTrends() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ticket Trends (Last 7 Days)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // Placeholder for chart
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text('Ticket trends chart would go here'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgentPerformance() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Agent Performance',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...['Support Agent', 'Senior Support', 'Team Lead'].map((agent) => ListTile(
              leading: CircleAvatar(child: Text(agent[0])),
              title: Text(agent),
              subtitle: const Text('Tickets resolved: 15 | Avg response: 1.2 hrs'),
              trailing: const Text('4.9★'),
            )),
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'open': return Colors.red;
      case 'in_progress': return Colors.orange;
      case 'resolved': return Colors.green;
      case 'closed': return Colors.grey;
      default: return Colors.grey;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'urgent': return Colors.red;
      case 'high': return Colors.orange;
      case 'medium': return Colors.yellow[700]!;
      case 'low': return Colors.green;
      default: return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'open': return Icons.circle;
      case 'in_progress': return Icons.pending;
      case 'resolved': return Icons.check_circle;
      case 'closed': return Icons.cancel;
      default: return Icons.help;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'account': return Icons.person;
      case 'payment': return Icons.payment;
      case 'commission': return Icons.account_balance_wallet;
      case 'referral': return Icons.share;
      default: return Icons.help;
    }
  }

  Widget _buildPriorityChip(String priority) {
    final color = _getPriorityColor(priority);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        priority.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        status.replaceAll('_', ' ').toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w500),
      ),
    );
  }

  void _showCreateTicketDialog() {
    final subjectController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedCategory = 'general';
    String selectedPriority = 'medium';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Support Ticket'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: subjectController,
                decoration: const InputDecoration(labelText: 'Subject'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: const InputDecoration(labelText: 'Category'),
                items: ['general', 'account', 'payment', 'commission', 'technical'].map((cat) {
                  return DropdownMenuItem(value: cat, child: Text(cat.toUpperCase()));
                }).toList(),
                onChanged: (value) => selectedCategory = value!,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedPriority,
                decoration: const InputDecoration(labelText: 'Priority'),
                items: ['low', 'medium', 'high', 'urgent'].map((pri) {
                  return DropdownMenuItem(value: pri, child: Text(pri.toUpperCase()));
                }).toList(),
                onChanged: (value) => selectedPriority = value!,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Support ticket created successfully')),
              );
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showTicketDetails(SupportTicket ticket) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TicketDetailsScreen(ticket: ticket, isAdminView: widget.isAdminView),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}

// Models are now imported from support_ticket_model.dart

// Placeholder for ticket details screen
class TicketDetailsScreen extends StatelessWidget {
  final SupportTicket ticket;
  final bool isAdminView;

  const TicketDetailsScreen({super.key, required this.ticket, required this.isAdminView});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ticket #${ticket.id}'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('Ticket details would be implemented here'),
      ),
    );
  }
}
