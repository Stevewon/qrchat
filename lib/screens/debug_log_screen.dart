import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 디버그 로그 화면
class DebugLogScreen extends StatefulWidget {
  const DebugLogScreen({super.key});

  @override
  State<DebugLogScreen> createState() => _DebugLogScreenState();
}

class _DebugLogScreenState extends State<DebugLogScreen> {
  final List<String> _logs = [];
  
  @override
  void initState() {
    super.initState();
    // 기존 로그 가져오기
    _logs.addAll(DebugLogger.logs);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('디버그 로그'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: _copyLogs,
            tooltip: '로그 복사',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _clearLogs,
            tooltip: '로그 지우기',
          ),
        ],
      ),
      body: _logs.isEmpty
          ? const Center(
              child: Text('로그가 없습니다'),
            )
          : ListView.builder(
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                final log = _logs[index];
                Color textColor = Colors.black;
                
                if (log.contains('❌') || log.contains('실패')) {
                  textColor = Colors.red;
                } else if (log.contains('✅') || log.contains('완료')) {
                  textColor = Colors.green;
                } else if (log.contains('⚠️')) {
                  textColor = Colors.orange;
                } else if (log.contains('📊') || log.contains('📖')) {
                  textColor = Colors.blue;
                }
                
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  child: Text(
                    log,
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      color: textColor,
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _logs.clear();
            _logs.addAll(DebugLogger.logs);
          });
        },
        child: const Icon(Icons.refresh),
        tooltip: '새로고침',
      ),
    );
  }

  void _copyLogs() {
    final logText = _logs.join('\n');
    Clipboard.setData(ClipboardData(text: logText));
    // 로그 복사 성공 시 스낵바 제거 - 클립보드에 즉시 복사됨
  }

  void _clearLogs() {
    setState(() {
      DebugLogger.clear();
      _logs.clear();
    });
    // 로그 삭제 성공 시 스낵바 제거 - 화면에서 즉시 사라짐
  }
}

/// 전역 로그 수집기
class DebugLogger {
  static final List<String> logs = [];
  static const int maxLogs = 500;

  static void log(String message) {
    final timestamp = DateTime.now().toString().substring(11, 19);
    final logMessage = '[$timestamp] $message';
    
    logs.add(logMessage);
    
    // 최대 로그 수 제한
    if (logs.length > maxLogs) {
      logs.removeAt(0);
    }
    
    // 콘솔에도 출력
    debugPrint(logMessage);
  }

  static void clear() {
    logs.clear();
  }
}
