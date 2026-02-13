import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/qkey_transaction.dart';
import '../services/qkey_service.dart';
import '../services/securet_auth_service.dart';

/// 관리자 QKEY 출금 승인 화면
class AdminQKeyScreen extends StatefulWidget {
  const AdminQKeyScreen({super.key});

  @override
  State<AdminQKeyScreen> createState() => _AdminQKeyScreenState();
}

class _AdminQKeyScreenState extends State<AdminQKeyScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _currentAdminId;
  
  // 필터 상태
  WithdrawStatus _filterStatus = WithdrawStatus.pending;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAdminId();
    
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          switch (_tabController.index) {
            case 0:
              _filterStatus = WithdrawStatus.pending;
              break;
            case 1:
              _filterStatus = WithdrawStatus.approved;
              break;
            case 2:
              _filterStatus = WithdrawStatus.completed;
              break;
            case 3:
              _filterStatus = WithdrawStatus.rejected;
              break;
          }
        });
      }
    });
  }
  
  Future<void> _loadAdminId() async {
    final user = await SecuretAuthService.getCurrentUser();
    if (mounted) {
      setState(() {
        _currentAdminId = user?.id;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'QKEY 출금 관리',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFFFB300),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(icon: Icon(Icons.pending_actions), text: '대기'),
            Tab(icon: Icon(Icons.check_circle_outline), text: '승인'),
            Tab(icon: Icon(Icons.done_all), text: '완료'),
            Tab(icon: Icon(Icons.cancel_outlined), text: '거부'),
          ],
        ),
      ),
      body: StreamBuilder<List<QKeyTransaction>>(
        stream: QKeyService.getAllWithdrawals(status: _filterStatus),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('오류: ${snapshot.error}'),
                ],
              ),
            );
          }
          
          final withdrawals = snapshot.data ?? [];
          
          if (withdrawals.isEmpty) {
            return _buildEmptyState();
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: withdrawals.length,
            itemBuilder: (context, index) {
              return _buildWithdrawCard(withdrawals[index]);
            },
          );
        },
      ),
    );
  }
  
  /// 빈 상태 위젯
  Widget _buildEmptyState() {
    String message;
    IconData icon;
    
    switch (_filterStatus) {
      case WithdrawStatus.pending:
        message = '대기 중인 출금 신청이 없습니다';
        icon = Icons.inbox;
        break;
      case WithdrawStatus.approved:
        message = '승인된 출금 신청이 없습니다';
        icon = Icons.check_circle_outline;
        break;
      case WithdrawStatus.completed:
        message = '완료된 출금이 없습니다';
        icon = Icons.done_all;
        break;
      case WithdrawStatus.rejected:
        message = '거부된 출금이 없습니다';
        icon = Icons.cancel_outlined;
        break;
    }
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
  
  /// 출금 신청 카드
  Widget _buildWithdrawCard(QKeyTransaction transaction) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    final statusColor = _getStatusColor(transaction.withdrawStatus!);
    final statusText = _getStatusText(transaction.withdrawStatus!);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showWithdrawDetail(transaction),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더: 상태 + 금액
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 상태 뱃지
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor, width: 1.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_getStatusIcon(transaction.withdrawStatus!), 
                             size: 16, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // 출금 금액
                  Text(
                    '${transaction.amount.abs().toStringAsFixed(0)} QKEY',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFFB300),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              
              // 사용자 정보
              _buildInfoRow(
                Icons.person_outline,
                '사용자 ID',
                transaction.userId,
              ),
              
              const SizedBox(height: 8),
              
              // 지갑 주소
              _buildInfoRow(
                Icons.account_balance_wallet,
                '지갑 주소',
                transaction.walletAddress ?? 'N/A',
                isAddress: true,
              ),
              
              const SizedBox(height: 8),
              
              // 신청 시간
              _buildInfoRow(
                Icons.access_time,
                '신청 시간',
                dateFormat.format(transaction.timestamp),
              ),
              
              // 처리 시간 (승인/거부된 경우)
              if (transaction.processedAt != null) ...[
                const SizedBox(height: 8),
                _buildInfoRow(
                  Icons.done,
                  '처리 시간',
                  dateFormat.format(transaction.processedAt!),
                ),
              ],
              
              // 관리자 메모 (있는 경우)
              if (transaction.adminNote != null && transaction.adminNote!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.note, size: 16, color: Colors.orange.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          transaction.adminNote!,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.orange.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              // 대기 중인 경우 액션 버튼
              if (transaction.withdrawStatus == WithdrawStatus.pending) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _processWithdraw(transaction, approve: false),
                        icon: const Icon(Icons.cancel),
                        label: const Text('거부'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _processWithdraw(transaction, approve: true),
                        icon: const Icon(Icons.check_circle),
                        label: const Text('승인'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  /// 정보 행
  Widget _buildInfoRow(IconData icon, String label, String value, {bool isAddress = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            isAddress && value.length > 20
                ? '${value.substring(0, 10)}...${value.substring(value.length - 10)}'
                : value,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
            maxLines: isAddress ? 1 : null,
            overflow: isAddress ? TextOverflow.ellipsis : null,
          ),
        ),
      ],
    );
  }
  
  /// 상태별 색상
  Color _getStatusColor(WithdrawStatus status) {
    switch (status) {
      case WithdrawStatus.pending:
        return Colors.orange;
      case WithdrawStatus.approved:
        return Colors.blue;
      case WithdrawStatus.completed:
        return Colors.green;
      case WithdrawStatus.rejected:
        return Colors.red;
    }
  }
  
  /// 상태별 텍스트
  String _getStatusText(WithdrawStatus status) {
    switch (status) {
      case WithdrawStatus.pending:
        return '대기중';
      case WithdrawStatus.approved:
        return '승인됨';
      case WithdrawStatus.completed:
        return '완료됨';
      case WithdrawStatus.rejected:
        return '거부됨';
    }
  }
  
  /// 상태별 아이콘
  IconData _getStatusIcon(WithdrawStatus status) {
    switch (status) {
      case WithdrawStatus.pending:
        return Icons.pending_actions;
      case WithdrawStatus.approved:
        return Icons.check_circle_outline;
      case WithdrawStatus.completed:
        return Icons.done_all;
      case WithdrawStatus.rejected:
        return Icons.cancel_outlined;
    }
  }
  
  /// 출금 상세 보기
  void _showWithdrawDetail(QKeyTransaction transaction) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // 핸들
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // 타이틀
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    const Text(
                      '출금 신청 상세',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              
              const Divider(height: 1),
              
              // 상세 정보
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    _buildDetailSection('기본 정보', [
                      _buildDetailItem('거래 ID', transaction.id),
                      _buildDetailItem('사용자 ID', transaction.userId),
                      _buildDetailItem('출금 금액', '${transaction.amount.abs()} QKEY'),
                      _buildDetailItem('거래 후 잔액', '${transaction.balanceAfter} QKEY'),
                      _buildDetailItem('상태', _getStatusText(transaction.withdrawStatus!)),
                    ]),
                    
                    const SizedBox(height: 24),
                    
                    _buildDetailSection('지갑 정보', [
                      _buildDetailItem(
                        '지갑 주소',
                        transaction.walletAddress ?? 'N/A',
                        copyable: true,
                      ),
                    ]),
                    
                    const SizedBox(height: 24),
                    
                    _buildDetailSection('시간 정보', [
                      _buildDetailItem('신청 시간', dateFormat.format(transaction.timestamp)),
                      if (transaction.processedAt != null)
                        _buildDetailItem('처리 시간', dateFormat.format(transaction.processedAt!)),
                    ]),
                    
                    if (transaction.adminId != null || transaction.adminNote != null) ...[
                      const SizedBox(height: 24),
                      _buildDetailSection('관리자 정보', [
                        if (transaction.adminId != null)
                          _buildDetailItem('처리 관리자', transaction.adminId!),
                        if (transaction.adminNote != null)
                          _buildDetailItem('관리자 메모', transaction.adminNote!),
                      ]),
                    ],
                    
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildDetailSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            children: items,
          ),
        ),
      ],
    );
  }
  
  Widget _buildDetailItem(String label, String value, {bool copyable = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
          if (copyable)
            IconButton(
              icon: const Icon(Icons.copy, size: 18),
              onPressed: () {
                // TODO: 클립보드 복사
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('클립보드에 복사되었습니다')),
                );
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
  
  /// 출금 승인/거부 처리
  Future<void> _processWithdraw(QKeyTransaction transaction, {required bool approve}) async {
    if (_currentAdminId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('관리자 ID를 불러올 수 없습니다')),
      );
      return;
    }
    
    // 메모 입력 다이얼로그
    String? adminNote;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final noteController = TextEditingController();
        return AlertDialog(
          title: Text(approve ? '출금 승인' : '출금 거부'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                approve
                    ? '이 출금 신청을 승인하시겠습니까?'
                    : '이 출금 신청을 거부하시겠습니까?',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: noteController,
                decoration: InputDecoration(
                  labelText: '관리자 메모 (선택사항)',
                  hintText: approve ? '승인 사유' : '거부 사유',
                  border: const OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () {
                adminNote = noteController.text.trim();
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: approve ? Colors.green : Colors.red,
              ),
              child: Text(approve ? '승인' : '거부'),
            ),
          ],
        );
      },
    );
    
    if (confirmed != true) return;
    
    // 로딩 표시
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
    
    // 처리
    final success = await QKeyService.processWithdraw(
      transactionId: transaction.id,
      adminId: _currentAdminId!,
      approve: approve,
      adminNote: adminNote?.isNotEmpty == true ? adminNote : null,
    );
    
    if (mounted) {
      Navigator.pop(context); // 로딩 닫기
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? (approve ? '출금 신청이 승인되었습니다' : '출금 신청이 거부되었습니다')
                : '처리 중 오류가 발생했습니다',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }
}
