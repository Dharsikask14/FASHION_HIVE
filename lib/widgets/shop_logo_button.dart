import 'package:flutter/material.dart';
import '../screens/shop_info_screen.dart';
import 'shop_logo.dart';

class ShopLogoButton extends StatefulWidget {
  const ShopLogoButton({super.key});
  @override
  State<ShopLogoButton> createState() => _ShopLogoButtonState();
}

class _ShopLogoButtonState extends State<ShopLogoButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.07).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _openShopInfo(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, anim, __) => const ShopInfoScreen(),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openShopInfo(context),
      child: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) => Transform.scale(
            scale: _scaleAnim.value,
            child: const ShopLogoImage(size: 40),
          ),
        ),
      ),
    );
  }
}
