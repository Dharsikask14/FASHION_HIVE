import 'package:flutter/material.dart';
import '../data/app_state.dart';
import '../theme/app_theme.dart';
import '../screens/outfit_recommender_screen.dart';

/// Animated floating Style-AI button.
/// Placed at [FloatingActionButtonLocation.endDocked] in MainShell
/// so it sits at the bottom-RIGHT corner, just above the nav bar.
class OutfitFab extends StatefulWidget {
  final AppState appState;
  const OutfitFab({super.key, required this.appState});

  @override
  State<OutfitFab> createState() => _OutfitFabState();
}

class _OutfitFabState extends State<OutfitFab> with TickerProviderStateMixin {

  // ── Animation controllers ─────────────────────────────────────────────────

  /// Gentle up/down bob
  late final AnimationController _bobCtrl;
  late final Animation<double> _bobAnim;

  /// Expanding halo ring pulse
  late final AnimationController _haloCtrl;
  late final Animation<double> _haloAnim;

  /// Elastic entrance / re-entrance bounce
  late final AnimationController _entranceCtrl;
  late final Animation<double> _entranceAnim;

  /// Slow sparkle icon rotation
  late final AnimationController _sparkleCtrl;
  late final Animation<double> _sparkleAnim;

  bool _pressed = false;

  @override
  void initState() {
    super.initState();

    _bobCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _bobAnim = Tween<double>(begin: 0, end: -8).animate(
      CurvedAnimation(parent: _bobCtrl, curve: Curves.easeInOut),
    );

    _haloCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _haloAnim = Tween<double>(begin: 0.75, end: 1.45).animate(
      CurvedAnimation(parent: _haloCtrl, curve: Curves.easeOut),
    );

    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _entranceAnim = CurvedAnimation(
        parent: _entranceCtrl, curve: Curves.elasticOut);
    _entranceCtrl.forward();

    _sparkleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();
    _sparkleAnim = Tween<double>(begin: 0, end: 1).animate(_sparkleCtrl);
  }

  @override
  void dispose() {
    _bobCtrl.dispose();
    _haloCtrl.dispose();
    _entranceCtrl.dispose();
    _sparkleCtrl.dispose();
    super.dispose();
  }

  // ── Navigation ────────────────────────────────────────────────────────────

  Future<void> _onTap() async {
    setState(() => _pressed = true);
    await Future.delayed(const Duration(milliseconds: 140));
    if (!mounted) return;
    setState(() => _pressed = false);

    _entranceCtrl.reset();

    // OutfitRecommenderScreen pops with an int (tab index) when user taps
    // a bottom-nav icon from within the recommender page.
    // We ignore it here — MainShell's PageView is the source of truth.
    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, anim, __) =>
            OutfitRecommenderScreen(appState: widget.appState),
        transitionsBuilder: (_, anim, __, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: FadeTransition(opacity: anim, child: child),
        ),
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );

    if (mounted) _entranceCtrl.forward();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge(
          [_bobAnim, _entranceAnim, _haloAnim, _sparkleAnim]),
      builder: (context, _) {
        return Transform.translate(
          // Bob up/down
          offset: Offset(0, _bobAnim.value),
          child: Transform.scale(
            // Entrance bounce + press shrink
            scale: _entranceAnim.value * (_pressed ? 0.88 : 1.0),
            child: SizedBox(
              width: 66,
              height: 66,
              child: Stack(
                alignment: Alignment.center,
                children: [

                  // ── Expanding halo ring ──────────────────────────────────
                  Opacity(
                    opacity: (1.45 - _haloAnim.value).clamp(0.0, 0.45),
                    child: Container(
                      width:  66 * _haloAnim.value,
                      height: 66 * _haloAnim.value,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.accent,
                          width: 2.5,
                        ),
                      ),
                    ),
                  ),

                  // ── Main button ──────────────────────────────────────────
                  GestureDetector(
                    onTap: _onTap,
                    child: Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppTheme.accent, AppTheme.primary],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.accent.withValues(alpha: 0.55),
                            blurRadius: 18,
                            spreadRadius: 2,
                            offset: const Offset(0, 4),
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.22),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          RotationTransition(
                            turns: _sparkleAnim,
                            child: const Icon(
                              Icons.auto_awesome_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Style',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.6,
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
        );
      },
    );
  }
} // end _OutfitFabState
