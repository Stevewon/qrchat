import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import '../services/securet_auth_service.dart';
import '../models/securet_user.dart';

/// 출금 내역 화면
class WithdrawalHistoryScreen extends StatefulWidget {
  const WithdrawalHistoryScreen({super.key});

  @override
  State<WithdrawalHistoryScreen> createState() => _WithdrawalHistoryScreenState();
}

class _WithdrawalHistoryScreenState extends State<WithdrawalHistoryScreen> {
  SecuretUser? _currentUser;
  bool _isLoading = true;
  List<Map<String, dynamic>> _withdrawals = [];
  String _selectedFilter = 'all'; // all, pending, approved, completed, rejected

  @override
  void initState() {
    super.initState();
    _loadWithdrawalHistory();
  }

  /// 출금 내역 로드
  Future<void> _loadWithdrawalHistory() async {
    try {
      final user = await SecuretAuthService.getCurrentUser();
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('qkey_transactions')
          .where('userId', isEqualTo: user.id)
          .where('type', isEqualTo: 'withdraw')
          .orderBy('timestamp', descending: true)
          .get();

      final withdrawals = snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();

      if (mounted) {
        setState(() {
          _currentUser = user;
          _withdrawals = withdrawals;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('출금 내역 로드 실패: $e')),
        );
      }
    }
  }

  /// 필터링된 출금 내역
  List<Map<String, dynamic>> get _filteredWithdrawals {
    if (_selectedFilter == 'all') return _withdrawals;
    return _withdrawals.where((w) => w['withdrawStatus'] == _selectedFilter).toList();
  }

  /// 상태별 카운트
  int _getStatusCount(String status) {
    if (status == 'all') return _withdrawals.length;
    return _withdrawals.where((w) => w['withdrawStatus'] == status).length;
  }

  /// 상태 뱃지 위젯
  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    String label;
    IconData icon;

    switch (status) {
      case 'pending':
        bgColor = Colors.orange.shade50;
        textColor = Colors.orange.shade700;
        label = '대기중';
        icon = Icons.pending_outlined;
        break;
      case 'approved':
        bgColor = Colors.blue.shade50;
        textColor = Colors.blue.shade700;
        label = '승인됨';
        icon = Icons.check_circle_outline;
        break;
      case 'completed':
        bgColor = Colors.green.shade50;
        textColor = Colors.green.shade700;
        label = '완료';
        icon = Icons.check_circle;
        break;
      case 'rejected':
        bgColor = Colors.red.shade50;
        textColor = Colors.red.shade700;
        label = '거부됨';
        icon = Icons.cancel_outlined;
        break;
      default:
        bgColor = Colors.grey.shade50;
        textColor = Colors.grey.shade700;
        label = '알 수 없음';
        icon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// 출금 항목 카드
  Widget _buildWithdrawalCard(Map<String, dynamic> withdrawal) {
    final timestamp = (withdrawal['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
    final amount = (withdrawal['amount'] as num?)?.abs() ?? 0;
    final status = withdrawal['withdrawStatus'] as String? ?? 'pending';
    final walletAddress = withdrawal['walletAddress'] as String? ?? '';
    final processedAt = (withdrawal['processedAt'] as Timestamp?)?.toDate();
    final adminNote = withdrawal['adminNote'] as String?;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showWithdrawalDetail(withdrawal),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더 (금액 + 상태)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${amount.toInt().toStringAsFixed(0)} QKEY',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1976D2),
                    ),
                  ),
                  _buildStatusBadge(status),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // 신청 시간
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    '신청: ${_formatDateTime(timestamp)}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // 지갑 주소
              Row(
                children: [
                  const Icon(Icons.account_balance_wallet, size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      walletAddress.isNotEmpty 
                          ? '${walletAddress.substring(0, walletAddress.length > 20 ? 20 : walletAddress.length)}...'
                          : '지갑 주소 없음',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontFamily: 'monospace',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              
              // 처리 시간 (승인/완료된 경우)
              if (processedAt != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.done_all, size: 16, color: Colors.green),
                    const SizedBox(width: 6),
                    Text(
                      '처리: ${_formatDateTime(processedAt)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
              ],
              
              // 관리자 메모 (있는 경우)
              if (adminNote != null && adminNote.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.note, size: 16, color: Colors.grey),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          adminNote,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 날짜/시간 포맷
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// 출금 상세 다이얼로그
  void _showWithdrawalDetail(Map<String, dynamic> withdrawal) {
    final timestamp = (withdrawal['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
    final amount = (withdrawal['amount'] as num?)?.abs() ?? 0;
    final status = withdrawal['withdrawStatus'] as String? ?? 'pending';
    final walletAddress = withdrawal['walletAddress'] as String? ?? '';
    final processedAt = (withdrawal['processedAt'] as Timestamp?)?.toDate();
    final adminNote = withdrawal['adminNote'] as String?;
    final balanceAfter = (withdrawal['balanceAfter'] as num?)?.toInt() ?? 0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          '출금 상세 정보',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상태
              _buildDetailRow('상태', '', customWidget: _buildStatusBadge(status)),
              
              const Divider(height: 24),
              
              // 출금 금액
              _buildDetailRow('출금 금액', '${amount.toInt()} QKEY'),
              
              // 신청 후 잔액
              _buildDetailRow('신청 후 잔액', '$balanceAfter QKEY'),
              
              // 신청 시간
              _buildDetailRow('신청 시간', _formatDateTime(timestamp)),
              
              // 처리 시간
              if (processedAt != null)
                _buildDetailRow('처리 시간', _formatDateTime(processedAt)),
              
              const Divider(height: 24),
              
              // 지갑 주소
              const Text(
                '지갑 주소',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: SelectableText(
                        walletAddress.isNotEmpty ? walletAddress : '지갑 주소 없음',
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    if (walletAddress.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.copy, size: 18),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: walletAddress));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('📋 지갑 주소가 복사되었습니다')),
                          );
                        },
                        tooltip: '복사',
                      ),
                  ],
                ),
              ),
              
              // 관리자 메모
              if (adminNote != null && adminNote.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  '관리자 메모',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Text(
                    adminNote,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.blue.shade900,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  /// 상세 정보 행
  Widget _buildDetailRow(String label, String value, {Widget? customWidget}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (customWidget != null)
            customWidget
          else
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
        ],
      ),
    );
  }

  /// 필터 칩
  Widget _buildFilterChip(String filter, String label, IconData icon) {
    final isSelected = _selectedFilter == filter;
    final count = _getStatusCount(filter);
    
    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: isSelected ? Colors.white : Colors.grey.shade700,
          ),
          const SizedBox(width: 4),
          Text(
            '$label ($count)',
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? Colors.white : Colors.grey.shade700,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
      onSelected: (selected) {
        setState(() {
          _selectedFilter = filter;
        });
      },
      selectedColor: const Color(0xFF1976D2),
      backgroundColor: Colors.grey.shade200,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          '출금 내역',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black87),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadWithdrawalHistory();
            },
            tooltip: '새로고침',
          ),
        ],
      ),
      body: Column(
        children: [
          // 필터 칩 영역
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  const SizedBox(width: 4),
                  _buildFilterChip('all', '전체', Icons.all_inclusive),
                  const SizedBox(width: 6),
                  _buildFilterChip('pending', '대기중', Icons.pending_outlined),
                  const SizedBox(width: 6),
                  _buildFilterChip('approved', '승인됨', Icons.check_circle_outline),
                  const SizedBox(width: 6),
                  _buildFilterChip('completed', '완료', Icons.check_circle),
                  const SizedBox(width: 6),
                  _buildFilterChip('rejected', '거부됨', Icons.cancel_outlined),
                  const SizedBox(width: 4),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // 출금 목록
          Expanded(
            child: _filteredWithdrawals.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.account_balance_wallet_outlined,
                          size: 80,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '출금 내역이 없습니다',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'QKEY 출금 신청 시 여기에 표시됩니다',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredWithdrawals.length,
                    itemBuilder: (context, index) {
                      return _buildWithdrawalCard(_filteredWithdrawals[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
