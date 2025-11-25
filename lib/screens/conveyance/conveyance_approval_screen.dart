import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';

class ConveyanceApprovalScreen extends StatefulWidget {
  const ConveyanceApprovalScreen({super.key});

  @override
  State<ConveyanceApprovalScreen> createState() =>
      _ConveyanceApprovalScreenState();
}

class _ConveyanceApprovalScreenState extends State<ConveyanceApprovalScreen> {
  bool _isLoading = true;
  List<dynamic> _pendingClaims = [];
  final Set<int> _selectedIndices = {};
  String? _searchQuery;

  @override
  void initState() {
    super.initState();
    _loadPendingClaims();
  }

  Future<void> _loadPendingClaims() async {
    setState(() => _isLoading = true);

    try {
      final response = await ApiService.getPendingConveyanceApprovals();

      if (!mounted) return;

      if (response.success) {
        setState(() {
          _pendingClaims = response.data as List<dynamic>? ?? [];
          _selectedIndices.clear();
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load claims: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<dynamic> _getFilteredClaims() {
    if (_searchQuery == null || _searchQuery!.isEmpty) {
      return _pendingClaims;
    }

    return _pendingClaims
        .where((claim) {
          final firstName =
              (claim['userId']?['firstName'] as String? ?? '').toLowerCase();
          final lastName =
              (claim['userId']?['lastName'] as String? ?? '').toLowerCase();
          final searchLower = _searchQuery!.toLowerCase();

          return firstName.contains(searchLower) ||
              lastName.contains(searchLower);
        })
        .toList();
  }

  Future<void> _approveClaim(String claimId, [String? comments]) async {
    try {
      final response = await ApiService.approveConveyanceClaim(
        claimId: claimId,
        comments: comments,
      );

      if (!mounted) return;

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Claim approved successfully'),
            backgroundColor: Color(0xFF5cfbd8),
            duration: Duration(seconds: 2),
          ),
        );
        _loadPendingClaims();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _rejectClaim(String claimId, String comments) async {
    try {
      final response = await ApiService.rejectConveyanceClaim(
        claimId: claimId,
        comments: comments,
      );

      if (!mounted) return;

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Claim rejected successfully'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
        _loadPendingClaims();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showRejectDialog(String claimId) {
    final commentsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Claim'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Please provide a reason for rejection:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: commentsController,
              maxLines: 3,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: 'Enter rejection reason',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final comments = commentsController.text.trim();
              if (comments.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please provide a rejection reason'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              Navigator.pop(context);
              await _rejectClaim(claimId, comments);
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredClaims = _getFilteredClaims();

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF272579), Color(0xFF0071bf)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text('Conveyance Approvals'),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by employee name',
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),
        ),
      ),
      backgroundColor: const Color(0xFFf8f9fa),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0071bf)),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadPendingClaims,
              color: const Color(0xFF0071bf),
              child: filteredClaims.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredClaims.length,
                      itemBuilder: (context, index) {
                        final claim = filteredClaims[index];
                        final isSelected = _selectedIndices.contains(index);

                        return _buildClaimTile(claim, index, isSelected);
                      },
                    ),
            ),
    );
  }

  Widget _buildClaimTile(dynamic claim, int index, bool isSelected) {
    final claimId = claim['_id'] as String?;
    final date = claim['date'] as String?;
    final amount = claim['amount'] as num?;
    final purpose = claim['purpose'] as String?;
    final firstName =
        (claim['userId']?['firstName'] as String? ?? 'Unknown');
    final lastName = (claim['userId']?['lastName'] as String? ?? '');

    DateTime? parsedDate;
    if (date != null) {
      parsedDate = DateTime.tryParse(date);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Employee info and amount
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$firstName $lastName',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF272579),
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (parsedDate != null)
                        Text(
                          DateFormat('dd MMM yyyy, hh:mm a')
                              .format(parsedDate),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
                if (amount != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00b8d9).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '₹${amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF00b8d9),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Purpose
            if (purpose != null && purpose.isNotEmpty) ...[
              Text(
                'Purpose: $purpose',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[800],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
            ],

            // Action buttons
            if (claimId != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _showRejectDialog(claimId),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Reject'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.withValues(alpha: 0.1),
                      foregroundColor: Colors.red,
                      elevation: 0,
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _approveClaim(claimId),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5cfbd8),
                      foregroundColor: const Color(0xFF272579),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'No pending claims',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey[700],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'All conveyance claims have been processed',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
