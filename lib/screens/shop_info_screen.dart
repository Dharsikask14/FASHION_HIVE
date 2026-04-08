import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/shop_logo.dart';

class ShopInfoScreen extends StatefulWidget {
  const ShopInfoScreen({super.key});

  @override
  State<ShopInfoScreen> createState() => _ShopInfoScreenState();
}

class _ShopInfoScreenState extends State<ShopInfoScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late AnimationController _slideCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // Animated counters
  int _animYears = 0;
  int _animCustomers = 0;
  int _animProducts = 0;
  double _animRating = 0.0;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _slideCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim =
        CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
            begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));
    _fadeCtrl.forward();
    _slideCtrl.forward();
    _startCounters();
  }

  void _startCounters() {
    const duration = Duration(milliseconds: 1800);
    final startTime = DateTime.now();
    void tick(Timer timer) {
      final elapsed = DateTime.now().difference(startTime).inMilliseconds;
      final t = (elapsed / duration.inMilliseconds).clamp(0.0, 1.0);
      final ease = Curves.easeOut.transform(t);
      if (!mounted) { timer.cancel(); return; }
      setState(() {
        _animYears    = (28  * ease).round();
        _animCustomers= (5000 * ease).round();
        _animProducts = (1200 * ease).round();
        _animRating   = 4.5 * ease;
      });
      if (t >= 1.0) timer.cancel();
    }
    Timer.periodic(const Duration(milliseconds: 16), tick);
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _slideCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: CustomScrollView(
            slivers: [
              _buildHeroHeader(context),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    const SizedBox(height: 28),
                    _buildQuickStats(),
                    const SizedBox(height: 28),
                    _buildSection('About Us', _buildAboutContent()),
                    const SizedBox(height: 20),
                    _buildSection('Shop Details', _buildShopDetails()),
                    const SizedBox(height: 20),
                    _buildSection('Our Team', _buildTeamSection()),
                    const SizedBox(height: 20),
                    _buildSection('Visit Us', _buildLocationSection()),
                    const SizedBox(height: 20),
                    _buildSection('Contact', _buildContactSection()),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Hero Header ──────────────────────────────────────────────────────────

  Widget _buildHeroHeader(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: AppTheme.primaryDark,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: Colors.white, size: 18),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryDark,
                AppTheme.primary,
                AppTheme.textLight,
              ],
              stops: [0.0, 0.6, 1.0],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                // Shop logo
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const ShopLogoImage(size: 110),
                ),
                const SizedBox(height: 16),
                const Text(
                  'SIVA SILKS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  child: const Text(
                    'Fashion & Footwear — Muniyappan kovil',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Quick Stats ──────────────────────────────────────────────────────────

  Widget _buildQuickStats() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryDark, AppTheme.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryDark.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _statItem('${_animYears}yrs', 'Experience'),
          _statDivider(),
          _statItem(_animCustomers >= 1000 ? '${(_animCustomers / 1000).toStringAsFixed(1)}K+' : '$_animCustomers', 'Customers'),
          _statDivider(),
          _statItem(_animProducts >= 1000 ? '${(_animProducts / 1000).toStringAsFixed(1)}K+' : '$_animProducts', 'Products'),
          _statDivider(),
          _statItem('${_animRating.toStringAsFixed(1)}★', 'Rating'),
        ],
      ),
    );
  }

  Widget _statItem(String value, String label) => Expanded(
    child: Column(
      children: [
        Text(value,
            style: const TextStyle(
              color: Color(0xFFBF9430),
              fontSize: 22,
              fontWeight: FontWeight.w900,
            )),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            )),
      ],
    ),
  );

  Widget _statDivider() => Container(
    width: 1, height: 36,
    color: Colors.white.withValues(alpha: 0.2),
  );

  // ── Section Wrapper ──────────────────────────────────────────────────────

  Widget _buildSection(String title, Widget content) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryDark,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          content,
        ],
      ),
    );
  }

  // ── About ────────────────────────────────────────────────────────────────

  Widget _buildAboutContent() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: const Text(
        'Siva Silks is a trusted name in traditional fashion and ethnic wear, '
        'founded and managed by Tmt. Velusamy Sivakami in Pallakkapalayam, '
        'Namakkal. For over 25 years, we have been dedicated to bringing our '
        'customers the finest collection of sarees, ethnic wear, and accessories.\n\n'
        'Our commitment to quality, authenticity, and customer satisfaction '
        'has made us a trusted name across Namakkal and the surrounding regions. '
        'We take pride in blending tradition with contemporary style.',
        style: TextStyle(
          fontSize: 13.5,
          color: AppTheme.textSecondary,
          height: 1.7,
        ),
      ),
    );
  }

  // ── Shop Details ─────────────────────────────────────────────────────────

  Widget _buildShopDetails() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        children: [
          _detailRow(Icons.store_rounded, 'Shop Name', 'Siva Silks'),
          _divider(),
          _detailRow(Icons.calendar_today_rounded, 'Established', '2005'),
          _divider(),
          _detailRow(Icons.category_rounded, 'Category',
              'Sarees, Ethnic Wear, Fashion & Footwear'),
          _divider(),
          _detailRow(Icons.access_time_rounded, 'Working Hours',
              'Mon – Sat: 9:00 AM – 8:00 PM\nSunday: 10:00 AM – 6:00 PM'),
          _divider(),
          _detailRow(Icons.verified_rounded, 'GST Registered', 'Yes — GSTIN 33XXXXX1234X'),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppTheme.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textLight,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5)),
                const SizedBox(height: 3),
                Text(value,
                    style: const TextStyle(
                        fontSize: 13.5,
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                        height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() =>
      const Divider(height: 1, color: AppTheme.divider, indent: 68);

  // ── Team ─────────────────────────────────────────────────────────────────

  Widget _buildTeamSection() {
    final team = [
      {
        'name': 'Tmt. Velusamy Sivakami',
        'role': 'Owner & Founder',
        'initials': 'VS',
        'dept': 'Management',
        'since': 'Since 1998',
        'color': 0xFF2E5B8A,
        'isOwner': true,
      },
      {
        'name': 'Mr. Rajesh Kumar',
        'role': 'General Manager',
        'initials': 'RK',
        'dept': 'Operations',
        'since': 'Since 2002',
        'color': 0xFF1C3F66,
        'isOwner': false,
      },
      {
        'name': 'Ms. Priya Devi',
        'role': 'Fashion Advisor',
        'initials': 'PD',
        'dept': 'Sales',
        'since': 'Since 2010',
        'color': 0xFF2A7A5A,
        'isOwner': false,
      },
      {
        'name': 'Mr. Anand Raj',
        'role': 'Senior Sales Executive',
        'initials': 'AR',
        'dept': 'Sales',
        'since': 'Since 2015',
        'color': 0xFFBF7E20,
        'isOwner': false,
      },
      {
        'name': 'Ms. Meena S.',
        'role': 'Customer Care Lead',
        'initials': 'MS',
        'dept': 'Support',
        'since': 'Since 2018',
        'color': 0xFF7B1FA2,
        'isOwner': false,
      },
      {
        'name': 'Mr. Karthik V.',
        'role': 'Accounts Manager',
        'initials': 'KV',
        'dept': 'Finance',
        'since': 'Since 2012',
        'color': 0xFF00796B,
        'isOwner': false,
      },
      {
        'name': 'Ms. Lakshmi R.',
        'role': 'Inventory Manager',
        'initials': 'LR',
        'dept': 'Logistics',
        'since': 'Since 2016',
        'color': 0xFF2A8F8F,
        'isOwner': false,
      },
      {
        'name': 'Mr. Suresh P.',
        'role': 'Store Executive',
        'initials': 'SP',
        'dept': 'Sales',
        'since': 'Since 2020',
        'color': 0xFF37474F,
        'isOwner': false,
      },
    ];

    return Column(
      children: [
        // Owner card - full width, prominent
        _buildOwnerCard(team[0]),
        const SizedBox(height: 12),
        // Staff grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.65,
          ),
          itemCount: team.length - 1,
          itemBuilder: (_, i) => _buildStaffCard(team[i + 1]),
        ),
      ],
    );
  }

  Widget _buildOwnerCard(Map<String, dynamic> m) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E5B8A), Color(0xFF1C3F66)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E5B8A).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.2),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.5), width: 2.5),
            ),
            child: Center(
              child: Text(
                m['initials']!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        m['name']!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.4)),
                      ),
                      child: const Text(
                        'FOUNDER',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  m['role']!,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.business_rounded,
                        size: 12,
                        color: Colors.white.withValues(alpha: 0.7)),
                    const SizedBox(width: 4),
                    Text(
                      m['dept']!,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.schedule_rounded,
                        size: 12,
                        color: Colors.white.withValues(alpha: 0.7)),
                    const SizedBox(width: 4),
                    Text(
                      m['since']!,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffCard(Map<String, dynamic> m) {
    final color = Color(m['color'] as int);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: color.withValues(alpha: 0.12),
                child: Text(
                  m['initials']!,
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m['name']!,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    Text(
                      m['role']!,
                      style: TextStyle(
                        fontSize: 9.5,
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  m['dept']!,
                  style: TextStyle(
                    fontSize: 9,
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                m['since']!,
                style: const TextStyle(
                  fontSize: 9,
                  color: AppTheme.textLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Location ─────────────────────────────────────────────────────────────

  Widget _buildLocationSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        children: [
          // Map placeholder
          Container(
            height: 140,
            decoration: const BoxDecoration(
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(16)),
              gradient: LinearGradient(
                colors: [
                  AppTheme.surfaceVariant,
                  AppTheme.surfaceDark,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withValues(alpha: 0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.store_rounded,
                            color: Colors.white, size: 24),
                      ),
                      const SizedBox(height: 8),
                      const Text('Siva Silks — Pallakkapalayam',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryDark,
                              fontSize: 13)),
                    ],
                  ),
                ),
                // Grid lines for map feel
                CustomPaint(
                  size: const Size(double.infinity, 140),
                  painter: _GridPainter(),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _locationRow(Icons.location_on_rounded,
                    '8/75 MuniyappanKovil, Pallakkapalayam,\nNamakkal, Tamil Nadu – 637 303'),
                const SizedBox(height: 10),
                _locationRow(Icons.directions_bus_rounded,
                    'Near MuniyappanKovil Temple, Pallakkapalayam'),
                const SizedBox(height: 10),
                _locationRow(Icons.local_parking_rounded,
                    'Parking available nearby'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _locationRow(IconData icon, String text) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppTheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                    height: 1.5)),
          ),
        ],
      );

  // ── Contact ──────────────────────────────────────────────────────────────

  Widget _buildContactSection() {
    return Column(
      children: [
        // ── Contact Us ────────────────────────────────────────────────────
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Contact Us',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 10),
            _contactCard(Icons.phone_rounded,
                'Primary', '+91 98765 43210', const Color(0xFF2E5B8A)),
            const SizedBox(height: 8),
            _contactCard(Icons.phone_outlined,
                'Alternate', '+91 98765 43211', const Color(0xFF2A7A5A)),
          ],
        ),
        const SizedBox(height: 16),
        // Store hours
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1C3F66), Color(0xFF2E5B8A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.access_time_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Store Hours',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 13)),
                    SizedBox(height: 3),
                    Text('Mon–Sat: 9:00 AM – 8:00 PM',
                        style: TextStyle(color: Color(0xFFB8D4FF), fontSize: 11)),
                    Text('Sunday: 10:00 AM – 6:00 PM',
                        style: TextStyle(color: Color(0xFFB8D4FF), fontSize: 11)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
                ),
                child: const Text('OPEN',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1)),
              ),
            ],
          ),
        ),
      ],
    );
  }



  Widget _contactCard(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 9,
                        color: AppTheme.textLight,
                        fontWeight: FontWeight.w600)),
                Text(value,
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w700),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }

} // end _ShopInfoScreenState

// ─────────────────────────────────────────────────────────────────────────────
// Top-level helper — MUST remain outside _ShopInfoScreenState
// ─────────────────────────────────────────────────────────────────────────────

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x1F2E5B8A)
      ..strokeWidth = 1;
    const step = 24.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}


