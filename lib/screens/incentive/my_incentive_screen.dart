import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/crm_colors.dart';
import '../../config/crm_design_system.dart';
import '../../providers/incentive_provider.dart';
import '../../models/employee_incentive.dart';
import '../../models/incentive_template.dart';
import '../../widgets/loading_widget.dart';

class MyIncentiveScreen extends StatefulWidget {
  const MyIncentiveScreen({super.key});

  @override
  State<MyIncentiveScreen> createState() => _MyIncentiveScreenState();
}

class _MyIncentiveScreenState extends State<MyIncentiveScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<IncentiveProvider>().fetchMyIncentive();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CrmColors.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [CrmColors.brand, CrmColors.primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Row(
          children: [
            Icon(Icons.trending_up_rounded, color: Colors.white, size: 24),
            SizedBox(width: 12),
            Text(
              'My Incentive',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        foregroundColor: Colors.white,
      ),
      body: Consumer<IncentiveProvider>(
        builder: (context, provider, child) {
          if (provider.isMyIncentiveLoading) {
            return const LoadingWidget(message: 'Loading incentive...');
          }

          if (!provider.hasMyIncentive) {
            return _buildNoIncentiveAssigned(
              error: provider.myIncentiveError,
              onRetry: () => provider.fetchMyIncentive(forceRefresh: true),
            );
          }

          final incentive = provider.myIncentive!;
          return RefreshIndicator(
            onRefresh: () => provider.fetchMyIncentive(forceRefresh: true),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(CrmDesignSystem.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCurrentBracketCard(incentive),
                  // Show commission rates only if template is loaded, otherwise show loading
                  if (incentive.currentTemplate != null) ...[
                    SizedBox(height: CrmDesignSystem.lg),
                    _buildCommissionRatesCard(incentive.currentTemplate!),
                  ] else if (provider.isTemplateLoading) ...[
                    SizedBox(height: CrmDesignSystem.lg),
                    _buildTemplateLoadingCard(),
                  ],
                  SizedBox(height: CrmDesignSystem.lg),
                  _buildEarningsCard(incentive),
                  if (incentive.nextTemplate != null) ...[
                    SizedBox(height: CrmDesignSystem.lg),
                    _buildNextBracketCard(incentive.nextTemplate!),
                  ],
                  SizedBox(height: CrmDesignSystem.xxl),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNoIncentiveAssigned({
    String? error,
    VoidCallback? onRetry,
  }) {
    final hasError = error != null && error.isNotEmpty;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(CrmDesignSystem.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(CrmDesignSystem.xl),
              decoration: BoxDecoration(
                color: hasError
                    ? CrmColors.errorColor.withValues(alpha: 0.1)
                    : CrmColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(CrmDesignSystem.radiusMax),
              ),
              child: Icon(
                hasError ? Icons.error_outline : Icons.trending_up_rounded,
                size: 64,
                color: hasError
                    ? CrmColors.errorColor.withValues(alpha: 0.5)
                    : CrmColors.primary.withValues(alpha: 0.5),
              ),
            ),
            SizedBox(height: CrmDesignSystem.xl),
            Text(
              hasError ? 'Error Loading Incentive' : 'No Incentive Assigned',
              style: CrmDesignSystem.headlineMedium.copyWith(
                color: CrmColors.textDark,
              ),
            ),
            SizedBox(height: CrmDesignSystem.sm),
            Text(
              hasError
                  ? 'There was a problem loading your incentive data. Please try again.'
                  : 'Contact your manager to get assigned to an incentive bracket.',
              textAlign: TextAlign.center,
              style: CrmDesignSystem.bodyMedium.copyWith(
                color: CrmColors.textLight,
              ),
            ),
            if (hasError && onRetry != null) ...[
              SizedBox(height: CrmDesignSystem.lg),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: CrmColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentBracketCard(EmployeeIncentive incentive) {
    // Handle null template case
    if (incentive.currentTemplate == null) {
      return _buildTemplateLoadingOrMissingCard();
    }

    final template = incentive.currentTemplate!;
    final isEligibleForPromotion = incentive.pendingPromotion.isEligible;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [CrmColors.brand, CrmColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(CrmDesignSystem.radiusLarge),
        boxShadow: CrmDesignSystem.elevationMedium,
      ),
      padding: EdgeInsets.all(CrmDesignSystem.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(CrmDesignSystem.sm),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(CrmDesignSystem.radiusMedium),
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              SizedBox(width: CrmDesignSystem.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Bracket',
                      style: CrmDesignSystem.labelSmall.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                    Text(
                      template.name,
                      style: CrmDesignSystem.headlineMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isEligibleForPromotion) ...[
            SizedBox(height: CrmDesignSystem.md),
            Container(
              padding: EdgeInsets.all(CrmDesignSystem.sm),
              decoration: BoxDecoration(
                color: CrmColors.success.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(CrmDesignSystem.radiusMedium),
              ),
              child: Row(
                children: [
                  const Icon(Icons.celebration_rounded, color: Colors.white, size: 18),
                  SizedBox(width: CrmDesignSystem.sm),
                  Expanded(
                    child: Text(
                      'Eligible for promotion! Awaiting approval.',
                      style: CrmDesignSystem.labelSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCommissionRatesCard(IncentiveTemplate template) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(CrmDesignSystem.radiusLarge),
        boxShadow: CrmDesignSystem.elevationSmall,
      ),
      padding: EdgeInsets.all(CrmDesignSystem.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.percent_rounded, color: CrmColors.primary, size: 20),
              SizedBox(width: CrmDesignSystem.sm),
              Text(
                'Commission Rates',
                style: CrmDesignSystem.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: CrmDesignSystem.lg),
          _buildRateRow(
            'Life Insurance',
            '${template.commissionRates.lifeInsurance}%',
            CrmColors.primary,
          ),
          Divider(height: CrmDesignSystem.lg),
          _buildRateRow(
            'General Insurance',
            '${template.commissionRates.generalInsurance}%',
            CrmColors.secondary,
          ),
          Divider(height: CrmDesignSystem.lg),
          _buildRateRow(
            'Mutual Funds',
            '${template.commissionRates.mutualFunds}%',
            CrmColors.success,
          ),
        ],
      ),
    );
  }

  Widget _buildRateRow(String label, String rate, Color color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 32,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(width: CrmDesignSystem.md),
        Expanded(
          child: Text(
            label,
            style: CrmDesignSystem.bodyMedium.copyWith(
              color: CrmColors.textLight,
            ),
          ),
        ),
        Text(
          rate,
          style: CrmDesignSystem.titleMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildEarningsCard(EmployeeIncentive incentive) {
    final progress = incentive.currentMonthProgress;
    final summary = progress?.salesSummary;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(CrmDesignSystem.radiusLarge),
        boxShadow: CrmDesignSystem.elevationSmall,
      ),
      padding: EdgeInsets.all(CrmDesignSystem.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance_wallet_rounded, color: CrmColors.success, size: 20),
              SizedBox(width: CrmDesignSystem.sm),
              Text(
                'This Month\'s Earnings',
                style: CrmDesignSystem.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: CrmDesignSystem.lg),
          _buildEarningRow(
            'Life Insurance',
            summary?.lifeInsurance.count ?? 0,
            summary?.lifeInsurance.commission ?? 0,
            CrmColors.primary,
          ),
          Divider(height: CrmDesignSystem.lg),
          _buildEarningRow(
            'General Insurance',
            summary?.generalInsurance.count ?? 0,
            summary?.generalInsurance.commission ?? 0,
            CrmColors.secondary,
          ),
          Divider(height: CrmDesignSystem.lg),
          _buildEarningRow(
            'Mutual Funds',
            summary?.mutualFunds.count ?? 0,
            summary?.mutualFunds.commission ?? 0,
            CrmColors.success,
          ),
          Divider(height: CrmDesignSystem.lg),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Total Commission',
                  style: CrmDesignSystem.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                _formatAmount(progress?.totalCommission ?? 0),
                style: CrmDesignSystem.headlineMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: CrmColors.textDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEarningRow(String label, int count, double commission, Color color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 32,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(width: CrmDesignSystem.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: CrmDesignSystem.bodyMedium.copyWith(
                  color: CrmColors.textLight,
                ),
              ),
              Text(
                '$count sale${count != 1 ? 's' : ''}',
                style: CrmDesignSystem.labelSmall.copyWith(
                  color: CrmColors.textLight,
                ),
              ),
            ],
          ),
        ),
        Text(
          _formatAmount(commission),
          style: CrmDesignSystem.titleMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildNextBracketCard(IncentiveTemplate nextTemplate) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(CrmDesignSystem.radiusLarge),
        border: Border.all(
          color: CrmColors.secondary.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: CrmDesignSystem.elevationSmall,
      ),
      padding: EdgeInsets.all(CrmDesignSystem.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(CrmDesignSystem.sm),
                decoration: BoxDecoration(
                  color: CrmColors.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(CrmDesignSystem.radiusMedium),
                ),
                child: Icon(
                  Icons.arrow_upward_rounded,
                  color: CrmColors.secondary,
                  size: 20,
                ),
              ),
              SizedBox(width: CrmDesignSystem.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Next Bracket',
                      style: CrmDesignSystem.labelSmall.copyWith(
                        color: CrmColors.textLight,
                      ),
                    ),
                    Text(
                      nextTemplate.name,
                      style: CrmDesignSystem.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: CrmColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: CrmDesignSystem.md),
          Container(
            padding: EdgeInsets.all(CrmDesignSystem.md),
            decoration: BoxDecoration(
              color: CrmColors.secondary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(CrmDesignSystem.radiusMedium),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNextRateItem('Life', '${nextTemplate.commissionRates.lifeInsurance}%'),
                Container(width: 1, height: 30, color: CrmColors.secondary.withValues(alpha: 0.2)),
                _buildNextRateItem('General', '${nextTemplate.commissionRates.generalInsurance}%'),
                Container(width: 1, height: 30, color: CrmColors.secondary.withValues(alpha: 0.2)),
                _buildNextRateItem('MF', '${nextTemplate.commissionRates.mutualFunds}%'),
              ],
            ),
          ),
          SizedBox(height: CrmDesignSystem.sm),
          Center(
            child: Text(
              'Complete current targets to unlock!',
              style: CrmDesignSystem.labelSmall.copyWith(
                color: CrmColors.secondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextRateItem(String label, String rate) {
    return Column(
      children: [
        Text(
          label,
          style: CrmDesignSystem.labelSmall.copyWith(
            color: CrmColors.textLight,
          ),
        ),
        SizedBox(height: CrmDesignSystem.xs),
        Text(
          rate,
          style: CrmDesignSystem.titleMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: CrmColors.secondary,
          ),
        ),
      ],
    );
  }

  Widget _buildTemplateLoadingCard() {
    return Container(
      padding: EdgeInsets.all(CrmDesignSystem.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(CrmDesignSystem.radiusMedium),
        boxShadow: CrmDesignSystem.elevationSmall,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(CrmColors.primary),
            ),
            SizedBox(height: CrmDesignSystem.md),
            Text(
              'Loading bracket details...',
              style: CrmDesignSystem.bodyMedium.copyWith(
                color: CrmColors.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateLoadingOrMissingCard() {
    final provider = context.read<IncentiveProvider>();

    if (provider.isTemplateLoading) {
      return _buildTemplateLoadingCard();
    }

    // Template loading is complete but template is still null
    return Container(
      padding: EdgeInsets.all(CrmDesignSystem.lg),
      decoration: BoxDecoration(
        color: CrmColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(CrmDesignSystem.radiusLarge),
        gradient: LinearGradient(
          colors: [
            CrmColors.brand.withValues(alpha: 0.05),
            CrmColors.primary.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: CrmDesignSystem.elevationSmall,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(CrmDesignSystem.sm),
                decoration: BoxDecoration(
                  color: CrmColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(CrmDesignSystem.radiusMedium),
                ),
                child: Icon(
                  Icons.info_rounded,
                  color: CrmColors.primary,
                  size: 20,
                ),
              ),
              SizedBox(width: CrmDesignSystem.md),
              Expanded(
                child: Text(
                  'Current Bracket',
                  style: CrmDesignSystem.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: CrmDesignSystem.md),
          Text(
            'Bracket info unavailable',
            style: CrmDesignSystem.bodyMedium.copyWith(
              color: CrmColors.textLight,
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(2)}L';
    } else if (amount >= 1000) {
      return '₹${(amount / 1000).toStringAsFixed(2)}K';
    }
    return '₹${amount.toStringAsFixed(0)}';
  }
}
