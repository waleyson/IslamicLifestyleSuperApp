import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:islamic_super_app/core/widgets/exit_dialog.dart';
import 'package:islamic_super_app/modules/business/savings/presentation/screens/savings_dashboard_screen.dart';
import 'package:islamic_super_app/modules/business/investment/data/models/investment_model.dart';
import 'package:islamic_super_app/modules/business/investment/presentation/providers/investment_provider.dart';
import 'package:islamic_super_app/modules/business/loan/data/models/loan_model.dart';
import 'package:islamic_super_app/modules/business/loan/presentation/providers/loan_provider.dart';

class BusinessDashboardScreen extends ConsumerStatefulWidget {
  const BusinessDashboardScreen({super.key});

  @override
  ConsumerState<BusinessDashboardScreen> createState() =>
      _BusinessDashboardScreenState();
}

class _BusinessDashboardScreenState
    extends ConsumerState<BusinessDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging ||
          _tabController.index != _currentTabIndex) {
        setState(() {
          _currentTabIndex = _tabController.index;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Halal Business & Finance'),
        leading: IconButton(
          icon: const Icon(Icons.exit_to_app_outlined),
          tooltip: 'Exit App',
          onPressed: () => showExitConfirmationDialog(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Ethical Guidelines',
            onPressed: () => _showEthicalHub(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: colorScheme.secondary,
          labelColor: colorScheme.secondary,
          unselectedLabelColor: colorScheme.onSurface.withValues(alpha: 0.6),
          tabs: const [
            Tab(
              icon: Icon(Icons.savings_outlined),
              text: 'Savings',
            ),
            Tab(
              icon: Icon(Icons.trending_up),
              text: 'Investment',
            ),
            Tab(
              icon: Icon(Icons.handshake_outlined),
              text: 'Qard (Loan)',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Savings
          const SavingsDashboardScreen(isNested: true),

          // Tab 2: Investment
          _buildInvestmentTab(context, colorScheme),

          // Tab 3: Loan
          _buildLoanTab(context, colorScheme),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(context),
    );
  }

  Widget? _buildFloatingActionButton(BuildContext context) {
    if (_currentTabIndex == 0) {
      return FloatingActionButton.extended(
        onPressed: () {
          // Open new savings goal dialog
          const SavingsDashboardScreen().showAddGoalDialog(context, ref);
        },
        icon: const Icon(Icons.add),
        label: const Text('New Goal'),
      );
    } else if (_currentTabIndex == 1) {
      return FloatingActionButton.extended(
        onPressed: () => _showAddInvestmentDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('New Asset'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      );
    } else if (_currentTabIndex == 2) {
      return FloatingActionButton.extended(
        onPressed: () => _showAddLoanDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('New Qard'),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        foregroundColor: Colors.black87,
      );
    }
    return null;
  }

  void _showEthicalHub(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  const Text('☪️', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Text(
                    'Halal & Ethical Finance Hub',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'According to Islamic traditions, wealth should be managed with strict ethical, social, and religious standards. Here are the core principles driving our financial modules:',
                style: TextStyle(fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 16),
              _buildEthicalSection(
                context,
                title: 'Riba-Free Halal Savings',
                icon: Icons.savings_outlined,
                color: Colors.green,
                description: 'All savings tracked in this app are strictly interest-free (Riba-free). Islamic financial tradition forbids earning or paying interest. Wealth preservation must be grounded in actual value and ethical endeavors.',
              ),
              const SizedBox(height: 12),
              _buildEthicalSection(
                context,
                title: 'Shariah-Compliant Investment',
                icon: Icons.trending_up,
                color: Colors.blue,
                description: 'Ethical investments exclude businesses involved in prohibited activities (e.g. alcohol, gambling, arms, interest-based banking, pork). Shariah screening also checks leverage and cash-to-asset ratios to ensure authentic equity sharing.',
              ),
              const SizedBox(height: 12),
              _buildEthicalSection(
                context,
                title: 'Qard Al-Hasan (Benevolent Loan)',
                icon: Icons.handshake_outlined,
                color: Colors.teal,
                description: 'Lending is considered an act of charity rather than a commercial mechanism in Islam. A Qard loan is strictly interest-free. Creditors are encouraged to show patience and grant extensions if the borrower faces genuine hardship.',
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Understand & Proceed'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEthicalSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required String description,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.4,
                    color: colorScheme.onSurface.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== INVESTMENT TAB BUILDERS ====================

  Widget _buildInvestmentTab(BuildContext context, ColorScheme colorScheme) {
    final investmentsAsync = ref.watch(investmentProvider);

    return investmentsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (assets) {
        final totalInvested = assets.fold(0.0, (s, a) => s + a.amountInvested);
        final totalCurrent = assets.fold(0.0, (s, a) => s + a.currentValue);
        final totalReturn = totalCurrent - totalInvested;
        final returnPercentage =
            totalInvested > 0 ? (totalReturn / totalInvested) * 100 : 0.0;

        return CustomScrollView(
          slivers: [
            // Summary Card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primaryContainer,
                        colorScheme.primary
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Investment Portfolio',
                        style: TextStyle(
                          color: colorScheme.onPrimaryContainer
                              .withValues(alpha: 0.8),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '\$${totalCurrent.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: colorScheme.onPrimaryContainer,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'Invested: \$${totalInvested.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: colorScheme.onPrimaryContainer
                                  .withValues(alpha: 0.7),
                              fontSize: 13,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: totalReturn >= 0
                                  ? Colors.green.shade800.withValues(alpha: 0.2)
                                  : Colors.red.shade800.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  totalReturn >= 0
                                      ? Icons.trending_up
                                      : Icons.trending_down,
                                  size: 14,
                                  color: totalReturn >= 0
                                      ? Colors.green.shade400
                                      : Colors.red.shade400,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${totalReturn >= 0 ? "+" : ""}${returnPercentage.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    color: totalReturn >= 0
                                        ? Colors.green.shade400
                                        : Colors.red.shade400,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 8)),

            // Investment List Title
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Your Assets',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ),

            // Investment Cards
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final asset = assets[index];
                    final isProfit = asset.returnAmount >= 0;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(asset.emoji,
                                    style: const TextStyle(fontSize: 28)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        asset.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: colorScheme
                                              .surfaceContainerHighest,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          asset.category.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit_note, size: 22),
                                  tooltip: 'Adjust Value',
                                  onPressed: () =>
                                      _showUpdateValueDialog(context, asset),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Divider(height: 1),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Amount Invested',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: colorScheme.onSurface
                                            .withValues(alpha: 0.5),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '\$${asset.amountInvested.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Current Value',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: colorScheme.onSurface
                                            .withValues(alpha: 0.5),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '\$${asset.currentValue.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Net Return',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: colorScheme.onSurface
                                            .withValues(alpha: 0.5),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${isProfit ? "+" : ""}\$${asset.returnAmount.toStringAsFixed(2)} (${isProfit ? "+" : ""}${asset.returnPercentage.toStringAsFixed(1)}%)',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: isProfit
                                            ? Colors.green.shade600
                                            : Colors.red.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: assets.length,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showUpdateValueDialog(BuildContext context, InvestmentAsset asset) {
    final controller =
        TextEditingController(text: asset.currentValue.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Adjust current value of ${asset.name}'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'New Current Value (USD)',
            prefixText: '\$ ',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(controller.text) ?? 0.0;
              if (val > 0) {
                ref
                    .read(investmentProvider.notifier)
                    .updateCurrentValue(asset.id, val);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showAddInvestmentDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final amtCtrl = TextEditingController();
    final valCtrl = TextEditingController();
    String category = 'Equity';
    final categories = ['Equity', 'Sukuk', 'Real Estate'];
    final categoryEmojis = {
      'Equity': '💼',
      'Sukuk': '📈',
      'Real Estate': '🏢',
    };

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateBuilder) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Add Ethical Investment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration: const InputDecoration(
                    labelText: 'Asset Category',
                    border: OutlineInputBorder(),
                  ),
                  items: categories.map((cat) {
                    return DropdownMenuItem<String>(
                      value: cat,
                      child: Text(cat),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setStateBuilder(() {
                        category = val;
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Asset Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amtCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Initial Invested Amount (USD)',
                    prefixText: '\$ ',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: valCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Current Value (USD)',
                    prefixText: '\$ ',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                final amt = double.tryParse(amtCtrl.text) ?? 0.0;
                final val = double.tryParse(valCtrl.text) ?? 0.0;
                if (name.isNotEmpty && amt > 0 && val > 0) {
                  ref.read(investmentProvider.notifier).addInvestment(
                        InvestmentAsset(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          name: name,
                          category: category,
                          amountInvested: amt,
                          currentValue: val,
                          purchaseDate: DateTime.now(),
                          emoji: categoryEmojis[category] ?? '💰',
                        ),
                      );
                }
                Navigator.pop(ctx);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== LOAN TAB BUILDERS ====================

  Widget _buildLoanTab(BuildContext context, ColorScheme colorScheme) {
    final loansAsync = ref.watch(loanProvider);

    return loansAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (loans) {
        final totalLentRemaining = loans
            .where((l) => l.type == LoanType.lent)
            .fold(0.0, (s, l) => s + l.remainingAmount);
        final totalBorrowedRemaining = loans
            .where((l) => l.type == LoanType.borrowed)
            .fold(0.0, (s, l) => s + l.remainingAmount);

        return CustomScrollView(
          slivers: [
            // Loan Summary Stats
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color:
                                  colorScheme.outline.withValues(alpha: 0.15)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Lent (To Receive)',
                              style: TextStyle(
                                fontSize: 11,
                                color: colorScheme.onSurface
                                    .withValues(alpha: 0.6),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '\$${totalLentRemaining.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color:
                                  colorScheme.outline.withValues(alpha: 0.15)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Borrowed (To Pay)',
                              style: TextStyle(
                                fontSize: 11,
                                color: colorScheme.onSurface
                                    .withValues(alpha: 0.6),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '\$${totalBorrowedRemaining.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 8)),

            // Loan List Title
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Active Qards (Loans)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ),

            // Loan List
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
              sliver: loans.isEmpty
                  ? const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 40.0),
                        child: Center(
                          child: Text('No active interest-free loans logged.'),
                        ),
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final loan = loans[index];
                          final isLent = loan.type == LoanType.lent;
                          final isSettled = loan.isSettled;

                          return Dismissible(
                            key: Key(loan.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.shade200,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              alignment: Alignment.centerRight,
                              child:
                                  const Icon(Icons.delete, color: Colors.white),
                            ),
                            onDismissed: (_) {
                              ref
                                  .read(loanProvider.notifier)
                                  .deleteLoan(loan.id);
                            },
                            child: Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: isSettled
                                              ? Colors.grey
                                                  .withValues(alpha: 0.15)
                                              : (isLent
                                                  ? Colors.green
                                                      .withValues(alpha: 0.15)
                                                  : Colors.orange
                                                      .withValues(alpha: 0.15)),
                                          foregroundColor: isSettled
                                              ? Colors.grey
                                              : (isLent
                                                  ? Colors.green.shade700
                                                  : Colors.orange.shade700),
                                          child: Icon(
                                            isSettled
                                                ? Icons.check
                                                : (isLent
                                                    ? Icons.arrow_outward
                                                    : Icons.arrow_downward),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                loan.personName,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                  decoration: isSettled
                                                      ? TextDecoration
                                                          .lineThrough
                                                      : null,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                isSettled
                                                    ? 'Settled'
                                                    : (isLent
                                                        ? 'Lent (You gave interest-free)'
                                                        : 'Borrowed (Interest-free)'),
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: colorScheme.onSurface
                                                      .withValues(alpha: 0.55),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (!isSettled)
                                          TextButton.icon(
                                            onPressed: () =>
                                                _showRepaymentDialog(
                                                    context, loan),
                                            icon: const Icon(Icons.payment,
                                                size: 14),
                                            label: Text(
                                                isLent ? 'Receive' : 'Pay'),
                                            style: TextButton.styleFrom(
                                              foregroundColor: isLent
                                                  ? Colors.green.shade700
                                                  : Colors.orange.shade800,
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    const Divider(height: 1),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Total Qard',
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  color: colorScheme.onSurface
                                                      .withValues(alpha: 0.45)),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '\$${loan.amount.toStringAsFixed(2)}',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                                color: isSettled
                                                    ? Colors.grey
                                                    : colorScheme.onSurface,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Repaid',
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  color: colorScheme.onSurface
                                                      .withValues(alpha: 0.45)),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '\$${loan.repaidAmount.toStringAsFixed(2)}',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: isSettled
                                                    ? Colors.grey
                                                    : colorScheme.onSurface,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              'Remaining Balance',
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  color: colorScheme.onSurface
                                                      .withValues(alpha: 0.45)),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '\$${loan.remainingAmount.toStringAsFixed(2)}',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                                color: isSettled
                                                    ? Colors.grey
                                                    : (isLent
                                                        ? Colors.green.shade600
                                                        : Colors
                                                            .orange.shade700),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    if (loan.notes.isNotEmpty) ...[
                                      const SizedBox(height: 10),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: colorScheme
                                              .surfaceContainerHighest
                                              .withValues(alpha: 0.4),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          loan.notes,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontStyle: FontStyle.italic,
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                        childCount: loans.length,
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  void _showRepaymentDialog(BuildContext context, LoanModel loan) {
    final controller = TextEditingController();
    final isLent = loan.type == LoanType.lent;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isLent
            ? 'Record repayment from ${loan.personName}'
            : 'Record payment to ${loan.personName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Remaining balance: \$${loan.remainingAmount.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Payment Amount (USD)',
                prefixText: '\$ ',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final amt = double.tryParse(controller.text) ?? 0.0;
              if (amt > 0) {
                ref.read(loanProvider.notifier).recordRepayment(loan.id, amt);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _showAddLoanDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final amtCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    LoanType type = LoanType.lent;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateBuilder) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Log Benevolent Qard'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SegmentedButton<LoanType>(
                  segments: const [
                    ButtonSegment<LoanType>(
                      value: LoanType.lent,
                      label: Text('Lent'),
                      icon: Icon(Icons.arrow_outward),
                    ),
                    ButtonSegment<LoanType>(
                      value: LoanType.borrowed,
                      label: Text('Borrowed'),
                      icon: Icon(Icons.arrow_downward),
                    ),
                  ],
                  selected: {type},
                  onSelectionChanged: (set) {
                    setStateBuilder(() {
                      type = set.first;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: type == LoanType.lent
                        ? 'Lent to (Person Name)'
                        : 'Borrowed from (Person Name)',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amtCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Loan Amount (USD)',
                    prefixText: '\$ ',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Notes / Purpose',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                final amt = double.tryParse(amtCtrl.text) ?? 0.0;
                final notes = notesCtrl.text.trim();
                if (name.isNotEmpty && amt > 0) {
                  ref.read(loanProvider.notifier).addLoan(
                        LoanModel(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          personName: name,
                          type: type,
                          amount: amt,
                          repaidAmount: 0.0,
                          dueDate: DateTime.now().add(const Duration(days: 30)),
                          notes: notes,
                        ),
                      );
                }
                Navigator.pop(ctx);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}
