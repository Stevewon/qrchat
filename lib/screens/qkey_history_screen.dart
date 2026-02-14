import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/qkey_transaction.dart';
import '../services/qkey_service.dart';
import '../services/securet_auth_service.dart';

/// 사용자 QKEY 채굴 내역 화면
class QKeyHistoryScreen extends StatefulWidget {
  const QKeyHistoryScreen({super.key});

  @override
  State<QKeyHistoryScreen> createState() => _QKeyHistoryScreenState();
}

class _QKeyHistoryScreenState extends State<QKeyHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _currentUserId;
  int _currentBalance = 0;
  int _totalEarned = 0;
  
  // 필터
  QKeyTransactionType? _filterType;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadUserData();
    
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          switch (_tabController.index) {
            case 0:
              _filterType = null; // 전체
              break;
            case 1:
              _filterType = QKeyTransactionType.earn;
              break;
            case 2:
              _filterType = QKeyTransactionType.withdraw;
              break;
            case 3:
              _filterType = QKeyTransactionType.bonus;
              break;
            case 4:
              _filterType = QKeyTransactionType.penalty;
              break;
          }
        });
      }
    });
  }
  
  Future<void> _loadUserData() async {
    final user = await SecuretAuthService.getCurrentUser();
    if (user != null && mounted) {
      final balance = await QKeyService.getUserBalance(user.id);
      setState(() {
        _currentUserId = user.id;
        _currentBalance = balance;
      });
      
      // 총 적립량 계산 (옵션)
      _calculateTotalEarned();
    }
  }
  
  Future<void> _calculateTotalEarned() async {
    // TODO: Firestore에서 totalQKeyEarned 필드 읽기
    // 현재는 간단히 표시
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
          'QKEY 채굴 내역',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFFFB300),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [
            Tab(text: '전체'),
            Tab(icon: Icon(Icons.add_circle_outline, size: 20), text: '적립'),
            Tab(icon: Icon(Icons.account_balance_wallet, size: 20), text: '출금'),
            Tab(icon: Icon(Icons.card_giftcard, size: 20), text: '보너스'),
            Tab(icon: Icon(Icons.remove_circle_outline, size: 20), text: '차감'),
          ],
        ),
      ),
      body: Column(
        children: [
          // 잔액 카드
          _buildBalanceCard(),
          
          // 채굴 내역 리스트
          Expanded(
            child: _currentUserId == null
                ? const Center(child: CircularProgressIndicator())
                : StreamBuilder<List<QKeyTransaction>>(
                    stream: QKeyService.getUserTransactions(_currentUserId!),
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
                      
                      var transactions = snapshot.data ?? [];
                      
                      // 필터 적용
                      if (_filterType != null) {
                        transactions = transactions
                            .where((t) => t.type == _filterType)
                            .toList();
                      }
                      
                      if (transactions.isEmpty) {
                        return _buildEmptyState();
                      }
                      
                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: transactions.length,
                        itemBuilder: (context, index) {
                          return _buildTransactionCard(transactions[index]);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
  
  /// 잔액 카드
  Widget _buildBalanceCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFB300), Color(0xFFFFA000)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFB300).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '현재 잔액',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _currentBalance.toStringAsFixed(0),
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 6),
                        child: Text(
                          'QKEY',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  size: 40,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  /// 빈 상태 위젯
  Widget _buildEmptyState() {
    String message;
    IconData icon;
    
    if (_filterType == null) {
      message = '채굴 내역이 없습니다';
      icon = Icons.inbox;
    } else {
      switch (_filterType!) {
        case QKeyTransactionType.earn:
          message = '적립 내역이 없습니다';
          icon = Icons.add_circle_outline;
          break;
        case QKeyTransactionType.withdraw:
          message = '출금 내역이 없습니다';
          icon = Icons.account_balance_wallet;
          break;
        case QKeyTransactionType.bonus:
          message = '보너스 내역이 없습니다';
          icon = Icons.card_giftcard;
          break;
        case QKeyTransactionType.penalty:
          message = '차감 내역이 없습니다';
          icon = Icons.remove_circle_outline;
          break;
      }
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
  
  /// 거래 카드
  Widget _buildTransactionCard(QKeyTransaction transaction) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    final isPositive = transaction.amount >= 0;
    final typeColor = _getTypeColor(transaction.type);
    final typeIcon = _getTypeIcon(transaction.type);
    final typeText = _getTypeText(transaction.type);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showTransactionDetail(transaction),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // 아이콘
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(typeIcon, color: typeColor, size: 24),
              ),
              
              const SizedBox(width: 16),
              
              // 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          typeText,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 8),
                        
                        // 출금 상태 (출금인 경우)
                        if (transaction.type == QKeyTransactionType.withdraw &&
                            transaction.withdrawStatus != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _getWithdrawStatusColor(transaction.withdrawStatus!)
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: _getWithdrawStatusColor(transaction.withdrawStatus!),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              _getWithdrawStatusText(transaction.withdrawStatus!),
                              style: TextStyle(
                                fontSize: 11,
                                color: _getWithdrawStatusColor(transaction.withdrawStatus!),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      transaction.description ?? '',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dateFormat.format(transaction.timestamp),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              
              // 금액
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isPositive ? '+' : ''}${transaction.amount} QKEY',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isPositive ? Colors.green : Colors.red,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '잔액 ${transaction.balanceAfter}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// 거래 타입별 색상
  Color _getTypeColor(QKeyTransactionType type) {
    switch (type) {
      case QKeyTransactionType.earn:
        return Colors.green;
      case QKeyTransactionType.withdraw:
        return Colors.blue;
      case QKeyTransactionType.bonus:
        return Colors.purple;
      case QKeyTransactionType.penalty:
        return Colors.red;
    }
  }
  
  /// 거래 타입별 아이콘
  IconData _getTypeIcon(QKeyTransactionType type) {
    switch (type) {
      case QKeyTransactionType.earn:
        return Icons.add_circle;
      case QKeyTransactionType.withdraw:
        return Icons.account_balance_wallet;
      case QKeyTransactionType.bonus:
        return Icons.card_giftcard;
      case QKeyTransactionType.penalty:
        return Icons.remove_circle;
    }
  }
  
  /// 거래 타입별 텍스트
  String _getTypeText(QKeyTransactionType type) {
    switch (type) {
      case QKeyTransactionType.earn:
        return '적립';
      case QKeyTransactionType.withdraw:
        return '출금';
      case QKeyTransactionType.bonus:
        return '보너스';
      case QKeyTransactionType.penalty:
        return '차감';
    }
  }
  
  /// 출금 상태별 색상
  Color _getWithdrawStatusColor(WithdrawStatus status) {
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
  
  /// 출금 상태별 텍스트
  String _getWithdrawStatusText(WithdrawStatus status) {
    switch (status) {
      case WithdrawStatus.pending:
        return '대기중';
      case WithdrawStatus.approved:
        return '승인됨';
      case WithdrawStatus.completed:
        return '완료';
      case WithdrawStatus.rejected:
        return '거부';
    }
  }
  
  /// 거래 상세 보기
  void _showTransactionDetail(QKeyTransaction transaction) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
    final isPositive = transaction.amount >= 0;
    
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
                      '거래 상세',
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
                    // 금액 표시
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isPositive
                                ? [Colors.green.shade400, Colors.green.shade600]
                                : [Colors.red.shade400, Colors.red.shade600],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '${isPositive ? '+' : ''}${transaction.amount}',
                              style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const Text(
                              'QKEY',
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    _buildDetailSection('기본 정보', [
                      _buildDetailItem('거래 ID', transaction.id, copyable: true),
                      _buildDetailItem('거래 유형', _getTypeText(transaction.type)),
                      _buildDetailItem('거래 후 잔액', '${transaction.balanceAfter} QKEY'),
                      _buildDetailItem('거래 시간', dateFormat.format(transaction.timestamp)),
                    ]),
                    
                    if (transaction.description != null &&
                        transaction.description!.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _buildDetailSection('설명', [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            transaction.description!,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ]),
                    ],
                    
                    // 출금 관련 정보
                    if (transaction.type == QKeyTransactionType.withdraw) ...[
                      const SizedBox(height: 24),
                      _buildDetailSection('출금 정보', [
                        _buildDetailItem(
                          '상태',
                          _getWithdrawStatusText(transaction.withdrawStatus!),
                        ),
                        if (transaction.walletAddress != null)
                          _buildDetailItem(
                            '지갑 주소',
                            transaction.walletAddress!,
                            copyable: true,
                          ),
                        if (transaction.processedAt != null)
                          _buildDetailItem(
                            '처리 시간',
                            dateFormat.format(transaction.processedAt!),
                          ),
                        if (transaction.adminNote != null &&
                            transaction.adminNote!.isNotEmpty)
                          _buildDetailItem(
                            '관리자 메모',
                            transaction.adminNote!,
                          ),
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
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('클립보드에 복사되었습니다'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}
