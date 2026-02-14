import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../services/securet_auth_service.dart';
import 'home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _nicknameController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  String _appVersion = ''; // 앱 버전

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }
  
  /// 앱 버전 로드
  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';
      });
    }
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final nickname = _nicknameController.text.trim();
    final password = _passwordController.text;

    if (nickname.isEmpty) {
      setState(() {
        _errorMessage = '닉네임을 입력해주세요';
      });
      return;
    }

    if (password.isEmpty) {
      setState(() {
        _errorMessage = '비밀번호를 입력해주세요';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final success = await SecuretAuthService.login(nickname, password);

      if (mounted) {
        if (success) {
          // 로그인 성공 시 바로 홈 화면으로 이동 (SnackBar 제거)
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        } else {
          // 로그인 실패 - F12 Console에 상세 로그가 표시됨
          setState(() {
            _isLoading = false;
            _errorMessage = '❌ 로그인 실패\n\nFirestore에서 사용자를 찾을 수 없거나\n비밀번호가 일치하지 않습니다.\n\n💡 F12 → Console에서 상세 로그를 확인하세요';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = '❌ 로그인 오류\n\n$e';
        });
      }
    }
  }

  Future<void> _findNickname() async {
    final qrUrlController = TextEditingController();
    
    final qrUrl = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('닉네임 찾기'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '가입 시 사용한 QR 주소를 입력하세요',
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: qrUrlController,
              decoration: InputDecoration(
                labelText: 'QR 주소',
                hintText: 'https://securet.kr/...',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              keyboardType: TextInputType.url,
              autocorrect: false,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, qrUrlController.text.trim()),
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('찾기'),
          ),
        ],
      ),
    );

    if (qrUrl == null || qrUrl.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final nickname = await SecuretAuthService.findNicknameByQrUrl(qrUrl);
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (nickname != null && nickname.isNotEmpty) {
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('✅ 닉네임을 찾았습니다'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('가입된 닉네임:'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      nickname,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {
                      _nicknameController.text = nickname;
                    });
                  },
                  child: const Text('입력하고 닫기'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('확인'),
                ),
              ],
            ),
          );
        } else {
          setState(() {
            _errorMessage = '❌ 해당 QR 주소로 가입된 계정을 찾을 수 없습니다';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = '❌ 닉네임 찾기 오류\n\n$e';
        });
      }
    }
  }

  Future<void> _findPassword() async {
    final qrUrlController = TextEditingController();
    
    final qrUrl = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('비밀번호 찾기'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '가입 시 사용한 QR 주소를 입력하세요',
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: qrUrlController,
              decoration: InputDecoration(
                labelText: 'QR 주소',
                hintText: 'https://securet.kr/...',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              keyboardType: TextInputType.url,
              autocorrect: false,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, qrUrlController.text.trim()),
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('찾기'),
          ),
        ],
      ),
    );

    if (qrUrl == null || qrUrl.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final password = await SecuretAuthService.findPasswordByQrUrl(qrUrl);
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (password != null && password.isNotEmpty) {
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('✅ 비밀번호를 찾았습니다'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('가입된 비밀번호:'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      password,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {
                      _passwordController.text = password;
                    });
                  },
                  child: const Text('입력하고 닫기'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('확인'),
                ),
              ],
            ),
          );
        } else {
          setState(() {
            _errorMessage = '❌ 해당 QR 주소로 가입된 계정을 찾을 수 없습니다';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = '❌ 비밀번호 찾기 오류\n\n$e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 키보드 높이 감지
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardVisible = keyboardHeight > 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('로그인'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // 키보드 올라오면 로고/타이틀 축소
              if (!isKeyboardVisible) const SizedBox(height: 40),
              
              // App Logo (키보드 시 축소)
              Icon(
                Icons.qr_code_2,
                size: isKeyboardVisible ? 50 : 100,
                color: Theme.of(context).colorScheme.primary,
              ),
              SizedBox(height: isKeyboardVisible ? 12 : 24),
              
              // Title (키보드 시 축소)
              Text(
                'QRChat',
                style: TextStyle(
                  fontSize: isKeyboardVisible ? 24 : 36,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              SizedBox(height: isKeyboardVisible ? 4 : 8),
              Text(
                '로그인',
                style: TextStyle(
                  fontSize: isKeyboardVisible ? 14 : 18,
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              SizedBox(height: isKeyboardVisible ? 24 : 48),

              // Nickname Input
              TextField(
                controller: _nicknameController,
                decoration: InputDecoration(
                  labelText: '닉네임',
                  hintText: '가입한 닉네임을 입력하세요',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.person),
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),

              // Password Input
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: '비밀번호',
                  hintText: '비밀번호를 입력하세요',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _login(),
              ),
              const SizedBox(height: 16),

              // Error Message
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),

              // Login Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          '로그인',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // Find Nickname/Password Links
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : _findNickname,
                    child: const Text('닉네임 찾기'),
                  ),
                  Text(
                    '|',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  TextButton(
                    onPressed: _isLoading ? null : _findPassword,
                    child: const Text('비밀번호 찾기'),
                  ),
                ],
              ),

              // Register Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '계정이 없으신가요?',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const RegisterScreen()),
                      );
                    },
                    child: const Text('회원가입'),
                  ),
                ],
              ),
              
              // Version Display
              const SizedBox(height: 8),
              Text(
                _appVersion.isEmpty ? '' : 'Version $_appVersion',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),

              // 키보드 높이만큼 여백 추가 (로그인 버튼이 항상 보이도록)
              SizedBox(height: keyboardHeight),
            ],
          ),
        ),
      ),
    );
  }
}
