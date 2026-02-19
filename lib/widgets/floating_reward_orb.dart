import 'dart:math';
import 'package:flutter/material.dart';
import '../models/reward_event.dart';
import '../constants/app_colors.dart';

/// 떠다니는 보상 구체 위젯
/// 
/// 화면에 동동 떠다니는 금색 구체 애니메이션
class FloatingRewardOrb extends StatefulWidget {
  /// 보상 이벤트
  final RewardEvent event;

  /// 클릭 콜백
  final VoidCallback onTap;

  const FloatingRewardOrb({
    super.key,
    required this.event,
    required this.onTap,
  });

  @override
  State<FloatingRewardOrb> createState() => _FloatingRewardOrbState();
}

class _FloatingRewardOrbState extends State<FloatingRewardOrb>
    with TickerProviderStateMixin {
  late AnimationController _floatingController;
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late Animation<double> _floatingAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // 상하 떠다니기 애니메이션 (살짝살짝 부드럽게)
    _floatingController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat(reverse: true);

    _floatingAnimation = Tween<double>(
      begin: -8.0,
      end: 8.0,
    ).animate(CurvedAnimation(
      parent: _floatingController,
      curve: Curves.easeInOutCubic, // 매우 부드러운 곡선
    ));

    // 회전 애니메이션 (천천히)
    _rotationController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * pi,
    ).animate(_rotationController);

    // 펄스 (크기 변화) 애니메이션 - 더 섬세하게
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.08,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _floatingController.dispose();
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Positioned(
      left: screenSize.width * widget.event.positionX - 30,
      top: screenSize.height * widget.event.positionY - 30,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _floatingController,
          _rotationController,
          _pulseController,
        ]),
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _floatingAnimation.value),
            child: Transform.scale(
              scale: _pulseAnimation.value,
              child: GestureDetector(
                onTap: widget.onTap,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // 외부 글로우 효과 (더 큰 반경)
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.withOpacity(0.4),
                            blurRadius: 30,
                            spreadRadius: 10,
                          ),
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.3),
                            blurRadius: 40,
                            spreadRadius: 15,
                          ),
                        ],
                      ),
                    ),
                    // 메인 구체
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          center: const Alignment(-0.3, -0.4), // 왼쪽 위에서 빛 들어옴
                          radius: 0.8,
                          colors: [
                            const Color(0xFFFFFFFF), // 하이라이트 (밝은 흰색)
                            const Color(0xFFFFF9C4), // 밝은 노랑
                            Colors.amber[300]!,
                            Colors.amber[600]!,
                            Colors.orange[700]!, // 가장자리 어두운 오렌지
                            Colors.orange[900]!, // 그림자 효과
                          ],
                          stops: const [0.0, 0.15, 0.4, 0.7, 0.9, 1.0],
                        ),
                        boxShadow: [
                          // 아래쪽 그림자 (입체감)
                          BoxShadow(
                            color: Colors.black.withOpacity(0.4),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                            spreadRadius: -3,
                          ),
                          // 골든 글로우
                          BoxShadow(
                            color: Colors.amber.withOpacity(0.6),
                            blurRadius: 25,
                            spreadRadius: 3,
                          ),
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.4),
                            blurRadius: 35,
                            spreadRadius: 8,
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // 반짝이는 효과 (뒤쪽)
                          Transform.rotate(
                            angle: _rotationAnimation.value,
                            child: Icon(
                              Icons.auto_awesome,
                              color: Colors.white.withOpacity(0.6),
                              size: 35,
                            ),
                          ),
                          // 반짝이는 효과 (앞쪽)
                          Transform.rotate(
                            angle: -_rotationAnimation.value * 0.7,
                            child: Icon(
                              Icons.auto_awesome,
                              color: Colors.white.withOpacity(0.4),
                              size: 28,
                            ),
                          ),
                          // 내부 하이라이트 (3D 느낌)
                          Positioned(
                            top: 8,
                            left: 10,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    Colors.white.withOpacity(0.8),
                                    Colors.white.withOpacity(0.0),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // QKEY 금액 표시
                          Text(
                            '${widget.event.rewardAmount}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.6),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                                Shadow(
                                  color: Colors.orange.withOpacity(0.8),
                                  blurRadius: 12,
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
            ),
          );
        },
      ),
    );
  }
}

/// 보상 획득 성공 애니메이션
class RewardClaimedAnimation extends StatefulWidget {
  /// 획득한 QKEY 금액
  final int amount;

  /// 애니메이션 완료 콜백
  final VoidCallback onComplete;

  const RewardClaimedAnimation({
    super.key,
    required this.amount,
    required this.onComplete,
  });

  @override
  State<RewardClaimedAnimation> createState() => _RewardClaimedAnimationState();
}

class _RewardClaimedAnimationState extends State<RewardClaimedAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.5,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
    ));

    _controller.forward().then((_) {
      widget.onComplete();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Center(
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 20,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.amber[400]!,
                      Colors.orange[600]!,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withOpacity(0.5),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.celebration,
                      color: Colors.white,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '+${widget.amount} QKEY 획득!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 구체 생성 파티클 효과
class OrbSpawnParticles extends StatefulWidget {
  /// 구체 위치 X
  final double positionX;

  /// 구체 위치 Y
  final double positionY;

  const OrbSpawnParticles({
    super.key,
    required this.positionX,
    required this.positionY,
  });

  @override
  State<OrbSpawnParticles> createState() => _OrbSpawnParticlesState();
}

class _OrbSpawnParticlesState extends State<OrbSpawnParticles>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Particle> _particles;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // 파티클 생성
    _particles = List.generate(12, (index) {
      final angle = (index / 12) * 2 * pi;
      return _Particle(
        angle: angle,
        distance: Random().nextDouble() * 50 + 30,
      );
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          children: _particles.map((particle) {
            final progress = _controller.value;
            final x = screenSize.width * widget.positionX +
                cos(particle.angle) * particle.distance * progress;
            final y = screenSize.height * widget.positionY +
                sin(particle.angle) * particle.distance * progress;

            return Positioned(
              left: x - 4,
              top: y - 4,
              child: Opacity(
                opacity: 1.0 - progress,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.amber,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withOpacity(0.5),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _Particle {
  final double angle;
  final double distance;

  _Particle({
    required this.angle,
    required this.distance,
  });
}
