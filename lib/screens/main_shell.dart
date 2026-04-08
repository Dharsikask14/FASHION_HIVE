import 'package:flutter/material.dart';
import '../data/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/outfit_fab.dart';
import 'home_screen.dart';
import 'explore_screen.dart';
import 'cart_screen.dart';
import 'other_screens.dart' show WishlistScreen;
import 'profile_screen.dart';
import 'auth_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  late AppState _appState;
  late PageController _pageController;

  // Lazy loading — only build screens when first visited
  final Set<int> _builtScreens = {0};

  int _lastWishlistCount = 0;
  bool _showWishlistBadge = false;

  @override
  void initState() {
    super.initState();
    _appState = AppState();
    _pageController = PageController(initialPage: 0);
    _appState.addListener(_onStateChanged);
  }

  void _onStateChanged() {
    if (!mounted) return;
    
    // Fix: When logged out, reset the navigation to avoid Home/Profile desync
    if (!_appState.isLoggedIn && _currentIndex != 0) {
      _currentIndex = 0;
      _builtScreens.clear();
      _builtScreens.add(0);
      _pageController.dispose();
      _pageController = PageController(initialPage: 0);
    }
    
    final currentCount = _appState.wishlistProducts.length;
    setState(() {
      if (currentCount > _lastWishlistCount) _showWishlistBadge = true;
      if (currentCount == 0) _showWishlistBadge = false;
      _lastWishlistCount = currentCount;
    });
  }

  void _onTabTapped(int index) {
    if (_currentIndex == index) return;
    setState(() {
      _currentIndex = index;
      _builtScreens.add(index);
      if (index == 3 && _showWishlistBadge) _showWishlistBadge = false;
    });
    _pageController.jumpToPage(index);
  }

  @override
  void dispose() {
    _appState.removeListener(_onStateChanged);
    _appState.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildScreen(int index) {
    if (!_builtScreens.contains(index)) return const SizedBox.shrink();
    switch (index) {
      case 0:  return HomeScreen(appState: _appState);
      case 1:  return ExploreScreen(appState: _appState);
      case 2:  return CartScreen(appState: _appState);
      case 3:  return WishlistScreen(appState: _appState);
      case 4:  return ProfileScreen(appState: _appState);
      default: return const SizedBox.shrink();
    }
  }

  // ── Wishlist badge ────────────────────────────────────────────────────────
  Widget _wishlistBadge(Widget icon, int count) {
    if (count == 0) return icon;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        icon,
        Positioned(
          right: -8, top: -6,
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              color: AppTheme.secondary,
              shape: BoxShape.circle,
            ),
            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
            child: Text(
              '$count',
              style: const TextStyle(
                color: AppTheme.primaryDark,
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  // ── Cart badge ────────────────────────────────────────────────────────────
  Widget _cartBadge(Widget icon) {
    final count = _appState.cartCount;
    if (count == 0) return icon;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        icon,
        Positioned(
          right: -8, top: -6,
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              color: AppTheme.primary,
              shape: BoxShape.circle,
            ),
            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
            child: Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_appState.isLoggedIn) {
      return AuthGateScreen(appState: _appState);
    }

    final wishlistCount = _appState.wishlistProducts.length;

    return Scaffold(
      body: PageView.builder(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 5,
        itemBuilder: (_, index) => _buildScreen(index),
      ),

      // ── Style AI FAB — hidden on Cart tab (index 2) ─────────────────────────
      floatingActionButton: _currentIndex == 2
          ? null
          : OutfitFab(appState: _appState),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      // ── Bottom navigation bar ─────────────────────────────────────────────
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_outlined),
              activeIcon: Icon(Icons.grid_view_rounded),
              label: 'Explore',
            ),
            BottomNavigationBarItem(
              icon: _cartBadge(const Icon(Icons.shopping_bag_outlined)),
              activeIcon: _cartBadge(const Icon(Icons.shopping_bag_rounded)),
              label: 'Cart',
            ),
            BottomNavigationBarItem(
              icon: _wishlistBadge(
                const Icon(Icons.favorite_outline_rounded),
                wishlistCount,
              ),
              activeIcon: _wishlistBadge(
                const Icon(Icons.favorite_rounded),
                wishlistCount,
              ),
              label: 'Wishlist',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
} // end _MainShellState
