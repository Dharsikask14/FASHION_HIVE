// ignore_for_file: library_private_types_in_public_api, deprecated_member_use, prefer_const_constructors

import 'dart:math';
import 'package:flutter/material.dart';
import '../data/app_state.dart' show AppState;
import '../models/models.dart';
import '../theme/app_theme.dart';
import 'product_detail_screen.dart';

// ═══════════════════════════════════════════════════════════════
//  ENUMS  (public so OutfitRecommendation can use them cleanly)
// ═══════════════════════════════════════════════════════════════

enum StyleGroup { traditional, sports, formal, casual, western, kids }

enum WearType { topwear, bottomwear, footwear, fullwear, accessory }

// ─── Gender ──────────────────────────────────────────────────────────────────
//  Detected purely from tags/name. Used to filter recommendations so
//  a men's garment only suggests men's / unisex items and vice-versa.
enum _Gender { men, women, kids, unisex }

_Gender _detectGender(Product p) {
  final t = '${p.tags.join(' ')} ${p.category} ${p.name}'.toLowerCase();
  if (t.contains('boys') ||
      t.contains('girls') ||
      t.contains('kids') ||
      t.contains('baby') ||
      t.contains('children')) {
    return _Gender.kids;
  }
  final isMens = t.contains('mens') ||
      t.contains("men's") ||
      t.contains('sherwani') ||
      t.contains('dhoti') ||
      t.contains('bandhgala') ||
      t.contains('pathani') ||
      t.contains('nehru') ||
      t.contains('mojari') ||
      t.contains('nagra') ||
      t.contains('kurta pyjama');
  final isWomens = t.contains('ladies') ||
      t.contains('womens') ||
      t.contains("women's") ||
      t.contains('saree') ||
      t.contains('lehenga') ||
      t.contains('dupatta') ||
      t.contains('heels') ||
      t.contains('wedges') ||
      t.contains('kurti') ||
      t.contains('salwar') ||
      t.contains('anarkali') ||
      t.contains('blouse') ||
      t.contains('pavadai') ||
      t.contains('pattu') ||
      t.contains('churidar') ||
      t.contains('patiala') ||
      t.contains('jhumka') ||
      t.contains('bangle') ||
      t.contains('necklace');
  if (isMens && !isWomens) return _Gender.men;
  if (isWomens && !isMens) return _Gender.women;
  return _Gender.unisex;
}

bool _genderCompatible(_Gender srcGender, _Gender candGender) {
  if (srcGender == _Gender.unisex || candGender == _Gender.unisex) return true;
  return srcGender == candGender;
}

// ─── Style group ─────────────────────────────────────────────────────────────

StyleGroup detectStyle(Product p) {
  final t = '${p.tags.join(' ')} ${p.category} ${p.name}'.toLowerCase();
  if (t.contains('sport') ||
      t.contains('running') ||
      t.contains('athletic') ||
      t.contains('gym') ||
      t.contains('track') ||
      t.contains('jogger')) {
    return StyleGroup.sports;
  }
  if (t.contains('kids') ||
      t.contains('boys') ||
      t.contains('girls') ||
      t.contains('baby') ||
      t.contains('children')) {
    return StyleGroup.kids;
  }
  if (t.contains('traditional') ||
      t.contains('ethnic') ||
      t.contains('bridal') ||
      t.contains('silk') ||
      t.contains('wedding') ||
      t.contains('festive') ||
      t.contains('dhoti') ||
      t.contains('kurta') ||
      t.contains('kurti') ||
      t.contains('sherwani') ||
      t.contains('saree') ||
      t.contains('lehenga') ||
      t.contains('salwar') ||
      t.contains('anarkali') ||
      t.contains('bandhgala') ||
      t.contains('nehru') ||
      t.contains('pavadai') ||
      t.contains('pattu') ||
      t.contains('kanjivaram') ||
      t.contains('banarasi') ||
      t.contains('chanderi') ||
      t.contains('ikat') ||
      t.contains('phulkari') ||
      t.contains('handloom') ||
      t.contains('zari') ||
      t.contains('embroidered') ||
      t.contains('kundan') ||
      t.contains('oxidized') ||
      t.contains('kolhapuri') ||
      t.contains('pathani') ||
      t.contains('patiala') ||
      t.contains('georgette') ||
      t.contains('chiffon')) {
    return StyleGroup.traditional;
  }
  if (t.contains('formal') ||
      t.contains('office') ||
      t.contains('oxford') ||
      t.contains('business') ||
      t.contains('corporate') ||
      t.contains('loafer') ||
      t.contains('blazer') ||
      t.contains('trouser')) {
    return StyleGroup.formal;
  }
  if (t.contains('denim') ||
      t.contains('jeans') ||
      t.contains('western') ||
      t.contains('fusion') ||
      t.contains('modern') ||
      t.contains('jacket') ||
      t.contains('shirt') ||
      t.contains('indo-western') ||
      t.contains('street')) {
    return StyleGroup.western;
  }
  if (t.contains('casual') ||
      t.contains('daily') ||
      t.contains('cotton') ||
      t.contains('linen') ||
      t.contains('printed') ||
      t.contains('palazzo') ||
      t.contains('block print')) {
    return StyleGroup.casual;
  }
  return StyleGroup.traditional;
}

String styleLabel(StyleGroup g) {
  if (g == StyleGroup.traditional) return '🪔 Traditional';
  if (g == StyleGroup.sports) return '🏃 Sports';
  if (g == StyleGroup.formal) return '💼 Formal';
  if (g == StyleGroup.casual) return '☀️ Casual';
  if (g == StyleGroup.western) return '✨ Western';
  return '🧒 Kids';
}

Color styleColour(StyleGroup g) {
  if (g == StyleGroup.traditional) return const Color(0xFFBF9430);
  if (g == StyleGroup.sports) return const Color(0xFF2A8F8F);
  if (g == StyleGroup.formal) return const Color(0xFF2E5B8A);
  if (g == StyleGroup.casual) return const Color(0xFF2A7A5A);
  if (g == StyleGroup.western) return const Color(0xFF7B1FA2);
  return const Color(0xFFE64A19);
}

// ─── Wear type ────────────────────────────────────────────────────────────────

WearType detectWearType(Product p) {
  final cat = p.category.toLowerCase();
  final name = p.name.toLowerCase();
  final tags = p.tags.join(' ').toLowerCase();
  if (cat.contains('footwear')) return WearType.footwear;
  if (cat.contains('saree') ||
      cat.contains('lehenga') ||
      cat.contains('dhoti') ||
      name.contains('saree') ||
      name.contains('lehenga') ||
      name.contains('dhoti') ||
      tags.contains('dhoti')) {
    return WearType.fullwear;
  }
  if (cat.contains('kurti') ||
      name.contains('kurti') ||
      name.contains('kurta') ||
      name.contains('blouse') ||
      name.contains('top') ||
      name.contains('shirt') ||
      name.contains('jacket') ||
      name.contains('sherwani') ||
      tags.contains('topwear')) {
    return WearType.topwear;
  }
  if (cat.contains('suit') &&
      (name.contains('pant') ||
          name.contains('pyjama') ||
          name.contains('palazzo') ||
          name.contains('salwar') ||
          name.contains('patiala'))) {
    return WearType.bottomwear;
  }
  if (name.contains('pant') ||
      name.contains('trouser') ||
      name.contains('pyjama') ||
      name.contains('palazzo') ||
      name.contains('salwar') ||
      tags.contains('pant')) {
    return WearType.bottomwear;
  }
  if (cat.contains('suit')) return WearType.topwear;
  return WearType.topwear;
}

// ═══════════════════════════════════════════════════════════════
//  COLOUR INTELLIGENCE ENGINE
// ═══════════════════════════════════════════════════════════════

class _ColourEngine {
  static String normalise(String raw) {
    final r = raw.toLowerCase();
    if (r.contains('red') ||
        r.contains('maroon') ||
        r.contains('wine') ||
        r.contains('crimson')) {
      return 'red';
    }
    if (r.contains('blue') ||
        r.contains('navy') ||
        r.contains('indigo') ||
        r.contains('royal blue') ||
        r.contains('sky blue')) {
      return 'blue';
    }
    if (r.contains('green') ||
        r.contains('mint') ||
        r.contains('olive') ||
        r.contains('teal') ||
        r.contains('forest')) {
      return 'green';
    }
    if (r.contains('yellow') ||
        r.contains('gold') ||
        r.contains('mustard') ||
        r.contains('cream') ||
        r.contains('beige') ||
        r.contains('ivory') ||
        r.contains('peach')) {
      return 'yellow';
    }
    if (r.contains('pink') ||
        r.contains('rose') ||
        r.contains('blush') ||
        r.contains('magenta') ||
        r.contains('fuchsia')) {
      return 'pink';
    }
    if (r.contains('purple') ||
        r.contains('violet') ||
        r.contains('lavender') ||
        r.contains('plum')) {
      return 'purple';
    }
    if (r.contains('orange') ||
        r.contains('rust') ||
        r.contains('terracotta')) {
      return 'orange';
    }
    if (r.contains('black') || r.contains('charcoal')) return 'black';
    if (r.contains('white') || r.contains('off-white')) return 'white';
    if (r.contains('grey') || r.contains('gray') || r.contains('silver')) {
      return 'grey';
    }
    if (r.contains('brown') || r.contains('tan') || r.contains('camel')) {
      return 'brown';
    }
    return 'neutral';
  }

  static const Map<String, List<String>> _harmony = {
    'red': ['black', 'white', 'grey', 'gold', 'navy', 'brown'],
    'blue': ['white', 'grey', 'brown', 'tan', 'yellow', 'orange', 'gold'],
    'green': ['white', 'brown', 'tan', 'gold', 'black', 'yellow'],
    'yellow': ['white', 'brown', 'black', 'blue', 'green', 'grey'],
    'pink': ['white', 'grey', 'black', 'gold', 'blue', 'green'],
    'purple': ['white', 'gold', 'grey', 'pink', 'black', 'cream'],
    'orange': ['white', 'black', 'brown', 'blue', 'gold', 'cream'],
    'black': ['white', 'grey', 'gold', 'red', 'blue', 'pink', 'green'],
    'white': ['black', 'blue', 'red', 'grey', 'gold', 'green', 'pink'],
    'grey': ['white', 'black', 'blue', 'pink', 'red', 'yellow'],
    'brown': ['cream', 'white', 'blue', 'green', 'orange', 'gold'],
    'neutral': ['white', 'black', 'blue', 'grey', 'brown'],
  };

  // Style-aware shade tips (no switch expressions)
  static List<String> getShadeSuggestions(String baseColour, StyleGroup style) {
    final norm = normalise(baseColour);
    if (style == StyleGroup.traditional) {
      final map = {
        'red': [
          'Pair with golden or cream silk bottoms',
          'Kolhapuri sandals in tan or brown',
          'Add gold jewellery to complete the look'
        ],
        'blue': [
          'Ivory or cream silk dupatta pairs beautifully',
          'Silver or gold kolhapuri sandals',
          'Try embroidered mojri footwear'
        ],
        'green': [
          'Gold zari border saree works perfectly',
          'Tan or cream ethnic footwear',
          'Kundan jewellery elevates the look'
        ],
        'yellow': [
          'Red or maroon silk blouse complements',
          'Golden embroidered sandals ideal',
          'Traditional chunky jewellery works well'
        ],
        'pink': [
          'Gold or cream ethnic bottoms look elegant',
          'Embroidered juttis in gold/silver',
          'Polki or kundan jewellery pairs beautifully'
        ],
        'neutral': [
          'Go bold with contrasting blouse or dupatta',
          'Embroidered sandals add a traditional touch',
          'Traditional jewellery elevates the outfit'
        ],
      };
      return map[norm] ?? map['neutral']!;
    }
    if (style == StyleGroup.sports) {
      final map = {
        'black': [
          'Pair with white or grey sport bottoms',
          'White running shoes for a clean look',
          'Add a bright accent with a jacket'
        ],
        'blue': [
          'Grey or black sport bottoms work best',
          'White or grey sport shoes',
          'Keep accessories minimal'
        ],
        'white': [
          'Black or navy sport bottoms give contrast',
          'Colourful trainers add energy',
          'Try a bright sport cap'
        ],
        'neutral': [
          'Choose contrasting sport bottoms',
          'Lightweight sport shoes in neutral tones',
          'Moisture-wicking fabric recommended'
        ],
      };
      return map[norm] ?? map['neutral']!;
    }
    if (style == StyleGroup.formal) {
      final map = {
        'black': [
          'Pair with crisp white or grey formal bottoms',
          'Oxford shoes in black or dark brown',
          'Belt to match shoes'
        ],
        'blue': [
          'Grey or charcoal formal trousers',
          'Brown oxford or derby shoes',
          'Subtle pocket square in gold'
        ],
        'white': [
          'Navy or charcoal formal bottoms',
          'Black or dark brown oxford shoes',
          'Classic leather belt'
        ],
        'neutral': [
          'Stick to neutral palette throughout',
          'Classic leather shoes in black or brown',
          'Well-fitted silhouette is key'
        ],
      };
      return map[norm] ?? map['neutral']!;
    }
    if (style == StyleGroup.western) {
      final map = {
        'black': [
          'Classic black jeans or skirt',
          'White sneakers or ankle boots',
          'Silver or minimal jewellery'
        ],
        'blue': [
          'White or grey western bottoms',
          'White sneakers or loafers',
          'Denim on denim if shades differ'
        ],
        'white': [
          'Black or denim western bottoms',
          'Classic white sneakers or boots',
          'Bold accessories make the look'
        ],
        'neutral': [
          'Build a tonal western look',
          'Classic white sneakers never fail',
          'One statement accessory elevates'
        ],
      };
      return map[norm] ?? map['neutral']!;
    }
    // casual + kids fallback
    final map = {
      'blue': [
        'White or beige casual bottoms work great',
        'White sneakers or sandals',
        'Denim accessories add character'
      ],
      'white': [
        'Any casual colour bottom works',
        'Colourful sneakers or flats',
        'Try a patterned scarf'
      ],
      'green': [
        'Cream or beige casual bottoms',
        'Brown sandals or white sneakers',
        'Minimal accessories'
      ],
      'neutral': [
        'Mix and match with any casual colour',
        'Comfortable sneakers or flats',
        'Let one item be the statement piece'
      ],
    };
    return map[norm] ?? map['neutral']!;
  }

  static int scoreMatch(String sourceColour, List<String> targetColors) {
    if (targetColors.isEmpty) return 30;
    final norm = normalise(sourceColour);
    final matches = _harmony[norm] ?? _harmony['neutral']!;
    int best = 0;
    for (final tc in targetColors) {
      final tn = normalise(tc);
      if (tn == norm) {
        best = max(best, 50);
        continue;
      }
      final idx = matches.indexOf(tn);
      if (idx >= 0) best = max(best, 100 - (idx * 10));
    }
    return best;
  }
}

// ═══════════════════════════════════════════════════════════════
//  RECOMMENDATION MODEL
// ═══════════════════════════════════════════════════════════════

class OutfitRecommendation {
  final Product selected;
  final Product? top;
  final Product? bottom;
  final Product? footwear;
  final List<String> shadeTips;
  final int overallScore;
  final StyleGroup styleGroup;
  final _Gender gender;

  const OutfitRecommendation({
    required this.selected,
    this.top,
    this.bottom,
    this.footwear,
    required this.shadeTips,
    required this.overallScore,
    required this.styleGroup,
    required this.gender,
  });
}

// ═══════════════════════════════════════════════════════════════
//  RECOMMENDATION SCREEN
// ═══════════════════════════════════════════════════════════════

class OutfitRecommenderScreen extends StatefulWidget {
  final AppState appState;
  const OutfitRecommenderScreen({super.key, required this.appState});

  @override
  State<OutfitRecommenderScreen> createState() =>
      _OutfitRecommenderScreenState();
}

class _OutfitRecommenderScreenState extends State<OutfitRecommenderScreen>
    with TickerProviderStateMixin {
  Product? _selected;
  String? _selectedColor;
  OutfitRecommendation? _recommendation;
  bool _loading = false;
  String _filterCat = 'All';

  late AnimationController _pulseCtrl;
  late AnimationController _cardCtrl;
  late Animation<double> _cardAnim;

  final List<String> _filterCats = [
    'All',
    'Sarees',
    'Lehengas',
    'Suits',
    'Kurtis',
    "Men's Ethnic",
    'Footwear',
  ];

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _cardCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _cardAnim = CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOutBack);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _cardCtrl.dispose();
    super.dispose();
  }

  List<Product> get _filteredProducts {
    final all = widget.appState.products;
    if (_filterCat == 'All') return all;
    return all.where((p) => p.category == _filterCat).toList();
  }

  void _selectProduct(Product p) {
    setState(() {
      _selected = p;
      _selectedColor = p.colors.isNotEmpty ? p.colors.first : null;
      _recommendation = null;
    });
    _cardCtrl.reset();
  }

  Future<void> _generateRecommendation() async {
    if (_selected == null) return;
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 700));
    final rec = _buildRecommendation(_selected!, _selectedColor);
    setState(() {
      _recommendation = rec;
      _loading = false;
    });
    _cardCtrl.forward();
  }

  // ─── Core matching engine ───────────────────────────────────────────────
  // Rules (in priority order):
  //   1. Same gender (men → men/unisex, women → women/unisex, kids → kids)
  //   2. Same style group (traditional→traditional, sports→sports, …)
  //   3. Best colour harmony score
  //   4. Every slot picks a UNIQUE product (no product appears twice)
  // ─────────────────────────────────────────────────────────────────────────
  OutfitRecommendation _buildRecommendation(Product sel, String? color) {
    final all = widget.appState.products;
    final srcColor =
        color ?? (sel.colors.isNotEmpty ? sel.colors.first : 'neutral');
    final srcStyle = detectStyle(sel);
    final srcGender = _detectGender(sel);
    final srcWear = detectWearType(sel);

    // IDs already committed to this outfit — ensures uniqueness across slots
    final usedIds = <String>{sel.id};

    // ── Picker: gender + style filtered, colour sorted, unique ────────────
    // ignore: no_leading_underscores_for_local_identifiers
    Product? _pick(List<WearType> wearTypes) {
      // Tier 1: same gender + same style
      final t1 = all.where((p) {
        if (usedIds.contains(p.id)) return false;
        if (!wearTypes.contains(detectWearType(p))) return false;
        if (!_genderCompatible(srcGender, _detectGender(p))) return false;
        return detectStyle(p) == srcStyle;
      }).toList();
      t1.sort((a, b) => _ColourEngine.scoreMatch(srcColor, b.colors)
          .compareTo(_ColourEngine.scoreMatch(srcColor, a.colors)));
      if (t1.isNotEmpty) {
        usedIds.add(t1.first.id);
        return t1.first;
      }

      // Tier 2: same gender + compatible style
      final t2 = all.where((p) {
        if (usedIds.contains(p.id)) return false;
        if (!wearTypes.contains(detectWearType(p))) return false;
        if (!_genderCompatible(srcGender, _detectGender(p))) return false;
        return _isCompatibleStyle(srcStyle, detectStyle(p));
      }).toList();
      t2.sort((a, b) => _ColourEngine.scoreMatch(srcColor, b.colors)
          .compareTo(_ColourEngine.scoreMatch(srcColor, a.colors)));
      if (t2.isNotEmpty) {
        usedIds.add(t2.first.id);
        return t2.first;
      }

      // Tier 3: same gender only (any style)
      final t3 = all.where((p) {
        if (usedIds.contains(p.id)) return false;
        if (!wearTypes.contains(detectWearType(p))) return false;
        return _genderCompatible(srcGender, _detectGender(p));
      }).toList();
      t3.sort((a, b) => _ColourEngine.scoreMatch(srcColor, b.colors)
          .compareTo(_ColourEngine.scoreMatch(srcColor, a.colors)));
      if (t3.isNotEmpty) {
        usedIds.add(t3.first.id);
        return t3.first;
      }
      return null;
    }

    Product? bestTop, bestBottom, bestFoot;

    if (srcWear == WearType.footwear) {
      bestTop = _pick([WearType.topwear, WearType.fullwear]);
      bestBottom = _pick([WearType.bottomwear]);
      bestFoot = sel;
    } else if (srcWear == WearType.topwear) {
      bestTop = sel;
      bestBottom = _pick([WearType.bottomwear]);
      bestFoot = _pick([WearType.footwear]);
    } else if (srcWear == WearType.bottomwear) {
      bestBottom = sel;
      bestTop = _pick([WearType.topwear]);
      bestFoot = _pick([WearType.footwear]);
    } else if (srcWear == WearType.fullwear) {
      bestTop = sel;
      bestFoot = _pick([WearType.footwear]);
    } else {
      // accessory
      bestTop = sel;
      bestFoot = _pick([WearType.footwear]);
    }

    // Score
    int score = 70;
    for (final p in [bestTop, bestBottom, bestFoot]) {
      if (p != null && p.id != sel.id) {
        score = max(score, _ColourEngine.scoreMatch(srcColor, p.colors));
        if (detectStyle(p) == srcStyle) score = min(100, score + 5);
      }
    }

    return OutfitRecommendation(
      selected: sel,
      top: (bestTop?.id != sel.id) ? bestTop : null,
      bottom: (bestBottom?.id != sel.id) ? bestBottom : null,
      footwear: (bestFoot?.id != sel.id) ? bestFoot : null,
      shadeTips: _ColourEngine.getShadeSuggestions(srcColor, srcStyle),
      overallScore: score.clamp(60, 100),
      styleGroup: srcStyle,
      gender: srcGender,
    );
  }

  bool _isCompatibleStyle(StyleGroup a, StyleGroup b) {
    if (a == StyleGroup.traditional) return b == StyleGroup.formal;
    if (a == StyleGroup.formal) {
      return b == StyleGroup.traditional || b == StyleGroup.western;
    }
    if (a == StyleGroup.western) {
      return b == StyleGroup.casual || b == StyleGroup.formal;
    }
    if (a == StyleGroup.casual) {
      return b == StyleGroup.western || b == StyleGroup.kids;
    }
    if (a == StyleGroup.sports) return false;
    if (a == StyleGroup.kids) return b == StyleGroup.casual;
    return false;
  }

  // ─── Bottom-nav badge helpers ──────────────────────────────────────────
  Widget _wishlistBadge(Widget icon) {
    final count = widget.appState.wishlistProducts.length;
    if (count == 0) return icon;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        icon,
        Positioned(
          right: -8,
          top: -6,
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
                color: AppTheme.secondary, shape: BoxShape.circle),
            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
            child: Text('$count',
                style: const TextStyle(
                    color: AppTheme.primaryDark,
                    fontSize: 9,
                    fontWeight: FontWeight.w800),
                textAlign: TextAlign.center),
          ),
        ),
      ],
    );
  }

  Widget _cartBadge(Widget icon) {
    final count = widget.appState.cartCount;
    if (count == 0) return icon;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        icon,
        Positioned(
          right: -8,
          top: -6,
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
                color: AppTheme.primary, shape: BoxShape.circle),
            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
            child: Text('$count',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w800),
                textAlign: TextAlign.center),
          ),
        ),
      ],
    );
  }

  // ─── FAB (already on Style page — tapping goes back) ──────────────────
  // ═══ build ════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: _buildAppBar(),
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
          currentIndex: 0,
          onTap: (index) => Navigator.pop(context, index),
          selectedItemColor: AppTheme.textLight,
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
              icon: _wishlistBadge(const Icon(Icons.favorite_outline_rounded)),
              activeIcon: _wishlistBadge(const Icon(Icons.favorite_rounded)),
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
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: _selected == null
                ? _buildPickerView()
                : _buildRecommendationView(),
          ),
        ],
      ),
    );
  }

  // ─── AppBar ────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.primaryDark,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('STYLE RECOMMENDER',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2)),
          Text('Smart matching by style & colour',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65), fontSize: 10)),
        ],
      ),
      actions: [
        if (_selected != null)
          TextButton.icon(
            onPressed: () => setState(() {
              _selected = null;
              _recommendation = null;
            }),
            icon: const Icon(Icons.refresh_rounded,
                color: Colors.white70, size: 16),
            label: const Text('Reset',
                style: TextStyle(color: Colors.white70, fontSize: 12)),
          ),
      ],
    );
  }

  // ─── Filter bar ────────────────────────────────────────────────────────
  Widget _buildFilterBar() {
    return Container(
      color: AppTheme.primaryDark,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: SizedBox(
        height: 34,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _filterCats.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final cat = _filterCats[i];
            final active = _filterCat == cat;
            return GestureDetector(
              onTap: () => setState(() {
                _filterCat = cat;
                _selected = null;
                _recommendation = null;
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: active
                      ? AppTheme.secondary
                      : Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: active
                        ? AppTheme.secondary
                        : Colors.white.withValues(alpha: 0.25),
                  ),
                ),
                child: Text(cat,
                    style: TextStyle(
                      color: active ? AppTheme.primaryDark : Colors.white,
                      fontSize: 11,
                      fontWeight: active ? FontWeight.w800 : FontWeight.w500,
                    )),
              ),
            );
          },
        ),
      ),
    );
  }

  // ─── Step 1: Pick a garment ────────────────────────────────────────────
  Widget _buildPickerView() {
    final products = _filteredProducts;
    return Column(
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              AppTheme.accent.withValues(alpha: 0.15),
              AppTheme.primary.withValues(alpha: 0.1),
            ]),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.accent.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (_, __) => Transform.scale(
                  scale: 1.0 + _pulseCtrl.value * 0.15,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [AppTheme.accent, AppTheme.primary]),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: AppTheme.accent.withValues(alpha: 0.4),
                            blurRadius: 12,
                            spreadRadius: 2)
                      ],
                    ),
                    child: const Icon(Icons.auto_awesome_rounded,
                        color: Colors.white, size: 20),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pick any garment to start',
                        style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700)),
                    SizedBox(height: 2),
                    Text(
                      'Recommendations match your style & colour automatically.',
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.62,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: products.length,
            itemBuilder: (_, i) => _ProductPickCard(
              product: products[i],
              onTap: () => _selectProduct(products[i]),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Step 2: Colour picker + generate ─────────────────────────────────
  Widget _buildRecommendationView() {
    final sel = _selected!;
    final wearType = detectWearType(sel);
    final selStyle = detectStyle(sel);
    final styleColor = styleColour(selStyle);

    String typeLabel = 'Item';
    if (wearType == WearType.topwear) typeLabel = 'Top Wear';
    if (wearType == WearType.bottomwear) typeLabel = 'Bottom Wear';
    if (wearType == WearType.footwear) typeLabel = 'Footwear';
    if (wearType == WearType.fullwear) typeLabel = 'Full Wear';
    if (wearType == WearType.accessory) typeLabel = 'Accessory';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Selected item card ─────────────────────────────────
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: styleColor.withValues(alpha: 0.3), width: 1.5),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.07),
                    blurRadius: 10,
                    offset: const Offset(0, 3))
              ],
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(sel.imageUrl,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                          width: 80,
                          height: 80,
                          color: AppTheme.primaryLight,
                          child: const Icon(Icons.checkroom_rounded,
                              color: AppTheme.primary, size: 32))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badges row — style + wear type only
                      Wrap(
                        spacing: 6,
                        children: [
                          _badge(styleLabel(selStyle), styleColor),
                          _badge(typeLabel, AppTheme.primary),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(sel.name,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary),
                          maxLines: 2),
                      const SizedBox(height: 4),
                      Text('₹${sel.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                              color: AppTheme.secondary,
                              fontWeight: FontWeight.w700,
                              fontSize: 14)),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() {
                    _selected = null;
                    _recommendation = null;
                  }),
                  icon: const Icon(Icons.close_rounded,
                      size: 18, color: AppTheme.textLight),
                ),
              ],
            ),
          ),

          // ── Colour picker ──────────────────────────────────────
          if (sel.colors.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('Select colour variant',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: sel.colors.map((c) {
                final active = _selectedColor == c;
                return GestureDetector(
                  onTap: () => setState(() {
                    _selectedColor = c;
                    _recommendation = null;
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: active ? AppTheme.primary : AppTheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: active ? AppTheme.primary : AppTheme.divider,
                        width: active ? 2 : 1,
                      ),
                      boxShadow: active
                          ? [
                              BoxShadow(
                                  color:
                                      AppTheme.primary.withValues(alpha: 0.3),
                                  blurRadius: 6)
                            ]
                          : [],
                    ),
                    child: Text(c,
                        style: TextStyle(
                          color: active ? Colors.white : AppTheme.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        )),
                  ),
                );
              }).toList(),
            ),
          ],

          const SizedBox(height: 20),

          // ── Generate button ────────────────────────────────────
          if (_recommendation == null)
            SizedBox(
              width: double.infinity,
              height: 52,
              child: _loading
                  ? Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [AppTheme.accent, AppTheme.primary]),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            ),
                            SizedBox(width: 10),
                            Text('Finding the perfect match…',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    )
                  : GestureDetector(
                      onTap: _generateRecommendation,
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [AppTheme.accent, AppTheme.primary]),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                                color: AppTheme.accent.withValues(alpha: 0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 4))
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.auto_awesome_rounded,
                                color: Colors.white, size: 18),
                            SizedBox(width: 8),
                            Text('Generate Matching Outfit',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15)),
                          ],
                        ),
                      ),
                    ),
            ),

          // ── Result ────────────────────────────────────────────
          if (_recommendation != null)
            ScaleTransition(
              scale: _cardAnim,
              child: _buildOutfitResult(_recommendation!),
            ),
        ],
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 9, fontWeight: FontWeight.w800)),
    );
  }

  // ─── Outfit result ─────────────────────────────────────────────────────
  Widget _buildOutfitResult(OutfitRecommendation rec) {
    final isFullWear = detectWearType(rec.selected) == WearType.fullwear;
    final sc = styleColour(rec.styleGroup);

    String genderTitle = '';
    if (rec.gender == _Gender.men) genderTitle = 'Men\'s ';
    if (rec.gender == _Gender.women) genderTitle = 'Women\'s ';
    if (rec.gender == _Gender.kids) genderTitle = 'Kids\' ';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),

        // Score header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              sc.withValues(alpha: 0.9),
              AppTheme.primaryDark.withValues(alpha: 0.85),
            ]),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('${rec.overallScore}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900)),
                    Text('%',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 10)),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('Outfit Match Score',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w800)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                              '$genderTitle${styleLabel(rec.styleGroup)}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(_getScoreLabel(rec.overallScore),
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 11)),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: rec.overallScore / 100,
                        backgroundColor: Colors.white.withValues(alpha: 0.25),
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(Colors.white),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),
        const Text('Complete the Look',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary)),
        const SizedBox(height: 4),
        Text(
          isFullWear
              ? 'Your full outfit pairs best with:'
              : 'All items matched to: $genderTitle${styleLabel(rec.styleGroup)}',
          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 16),

        // ── 360° Mannequin Preview ─────────────────────────────
        _MannequinView(recommendation: rec),

        const SizedBox(height: 16),

        if (!isFullWear && rec.top != null)
          _OutfitSlotCard(
              label: '👕 Top Wear',
              product: rec.top!,
              appState: widget.appState),
        if (rec.bottom != null) ...[
          const SizedBox(height: 10),
          _OutfitSlotCard(
              label: '👖 Bottom Wear',
              product: rec.bottom!,
              appState: widget.appState),
        ],
        if (rec.footwear != null) ...[
          const SizedBox(height: 10),
          _OutfitSlotCard(
              label: '👟 Footwear',
              product: rec.footwear!,
              appState: widget.appState),
        ],

        if (!isFullWear &&
            rec.top == null &&
            rec.bottom == null &&
            rec.footwear == null)
          _buildNoMatchBanner(rec.styleGroup),

        // Style tips
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: sc.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: sc.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.lightbulb_rounded, color: sc, size: 16),
                  const SizedBox(width: 6),
                  Text('$genderTitle${styleLabel(rec.styleGroup)} Style Tips',
                      style: TextStyle(
                          color: sc,
                          fontSize: 13,
                          fontWeight: FontWeight.w800)),
                ],
              ),
              const SizedBox(height: 8),
              ...rec.shadeTips.map((tip) => Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          margin: const EdgeInsets.only(top: 5, right: 8),
                          decoration:
                              BoxDecoration(color: sc, shape: BoxShape.circle),
                        ),
                        Expanded(
                          child: Text(tip,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                  height: 1.4)),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),

        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: () => _addOutfitToCart(rec),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppTheme.primary, width: 1.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.shopping_bag_outlined, size: 18),
            label: const Text('Add Full Outfit to Cart'),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: () => setState(() {
              _selected = null;
              _recommendation = null;
            }),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Try Another Outfit'),
          ),
        ),
      ],
    );
  }

  Widget _buildNoMatchBanner(StyleGroup style) {
    final c = styleColour(style);
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: c, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Limited ${styleLabel(style)} matches in our catalogue right now. '
              'Visit our store for more options!',
              style: const TextStyle(
                  fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  String _getScoreLabel(int score) {
    if (score >= 90) return 'Excellent match — perfect combination!';
    if (score >= 80) return 'Great match — colours complement beautifully';
    if (score >= 70) return 'Good match — works well together';
    return 'Decent match — see style tips below';
  }

  void _addOutfitToCart(OutfitRecommendation rec) {
    final items = [
      rec.selected,
      if (rec.top != null) rec.top!,
      if (rec.bottom != null) rec.bottom!,
      if (rec.footwear != null) rec.footwear!,
    ];
    final added = <String>{};
    for (final p in items) {
      if (added.contains(p.id)) continue;
      added.add(p.id);
      widget.appState.addToCart(
        p,
        p.sizes.isNotEmpty ? p.sizes.first : 'Free Size',
        p.colors.isNotEmpty ? p.colors.first : 'Standard',
      );
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('${added.length} items added to cart!'),
      backgroundColor: AppTheme.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 2),
    ));
  }
} // end _OutfitRecommenderScreenState

// ═══════════════════════════════════════════════════════════════
//  PRODUCT PICK CARD
// ═══════════════════════════════════════════════════════════════
class _ProductPickCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  const _ProductPickCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final style = detectStyle(product);
    final sc = styleColour(style);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image (no overlaid badges) ─────────────────────
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
              child: AspectRatio(
                aspectRatio: 1,
                child: Image.network(product.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                        color: AppTheme.primaryLight,
                        child: const Center(
                            child: Icon(Icons.checkroom_rounded,
                                color: AppTheme.primary, size: 36)))),
              ),
            ),
            // ── Description ────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 7, 8, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Style badge in description
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: sc.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: sc.withValues(alpha: 0.35)),
                      ),
                      child: Text(styleLabel(style),
                          style: TextStyle(
                              color: sc,
                              fontSize: 8,
                              fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(height: 4),
                    Text(product.name,
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text('₹${product.price.toStringAsFixed(0)}',
                              style: const TextStyle(
                                  color: AppTheme.secondary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12),
                              overflow: TextOverflow.ellipsis),
                        ),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration:
                              BoxDecoration(color: sc, shape: BoxShape.circle),
                          child: const Icon(Icons.auto_awesome_rounded,
                              color: Colors.white, size: 10),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  OUTFIT SLOT CARD
// ═══════════════════════════════════════════════════════════════
class _OutfitSlotCard extends StatelessWidget {
  final String label;
  final Product product;
  final AppState appState;

  const _OutfitSlotCard({
    required this.label,
    required this.product,
    required this.appState,
  });

  @override
  Widget build(BuildContext context) {
    final style = detectStyle(product);
    final sc = styleColour(style);

    return GestureDetector(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) =>
                  ProductDetailScreen(product: product, appState: appState))),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.divider),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05), blurRadius: 6)
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 70,
              height: 70,
              clipBehavior: Clip.hardEdge,
              decoration:
                  BoxDecoration(borderRadius: BorderRadius.circular(10)),
              child: Image.network(product.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                      color: AppTheme.primaryLight,
                      child: const Icon(Icons.checkroom_rounded,
                          color: AppTheme.primary))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 10,
                          color: AppTheme.textLight,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(product.name,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 5),
                  // Style badge in description
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: sc.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: sc.withValues(alpha: 0.3)),
                    ),
                    child: Text(styleLabel(style),
                        style: TextStyle(
                            color: sc,
                            fontSize: 8,
                            fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(height: 4),
                  Text('₹${product.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                          color: AppTheme.secondary,
                          fontWeight: FontWeight.w800,
                          fontSize: 14)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 12, color: AppTheme.textLight),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  360° MANNEQUIN VIEW
//  Draws a schematic human silhouette that slowly rotates.
//  Each clothing zone (head/top/bottom/feet) is colour-tinted
//  to show the recommended palette. A legend panel on the right
//  lists each slot with: zone colour, recommended colour name,
//  and whether a matching product is in the shop or is a
//  colour-only suggestion.
// ═══════════════════════════════════════════════════════════════

class _MannequinView extends StatefulWidget {
  final OutfitRecommendation recommendation;
  const _MannequinView({required this.recommendation});

  @override
  State<_MannequinView> createState() => _MannequinViewState();
}

class _MannequinViewState extends State<_MannequinView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // Returns a human-readable colour name for the first colour of a product
  String _colourOf(Product? p, String fallback) {
    if (p == null) return fallback;
    if (p.colors.isNotEmpty) return p.colors.first;
    return fallback;
  }

  // Resolve a recommended colour for a slot.
  // If the product exists in-shop → use its colour.
  // Otherwise derive a suggestion from the harmony engine.
  String _suggestColour(String baseColour, String slot) {
    final norm = _ColourEngine.normalise(baseColour);
    // Simple complementary map for suggestions
    const Map<String, Map<String, String>> slotSuggestions = {
      'top': {
        'red': 'Black or White',
        'blue': 'White or Grey',
        'green': 'Cream or Beige',
        'yellow': 'Brown or White',
        'pink': 'White or Ivory',
        'purple': 'White or Gold',
        'orange': 'White or Black',
        'black': 'White or Grey',
        'white': 'Black or Navy',
        'grey': 'White or Black',
        'brown': 'Cream or Gold',
        'neutral': 'White or Beige',
      },
      'bottom': {
        'red': 'Black or Navy',
        'blue': 'White or Khaki',
        'green': 'Brown or White',
        'yellow': 'White or Denim',
        'pink': 'White or Grey',
        'purple': 'Black or Ivory',
        'orange': 'Black or Brown',
        'black': 'White or Cream',
        'white': 'Black or Denim',
        'grey': 'White or Black',
        'brown': 'Beige or Olive',
        'neutral': 'Black or Navy',
      },
      'footwear': {
        'red': 'Brown or Black',
        'blue': 'Brown or White',
        'green': 'Brown or Tan',
        'yellow': 'Brown or White',
        'pink': 'White or Nude',
        'purple': 'Black or Silver',
        'orange': 'Brown or Tan',
        'black': 'Black or White',
        'white': 'White or Beige',
        'grey': 'Black or White',
        'brown': 'Brown or Tan',
        'neutral': 'Brown or Black',
      },
    };
    return slotSuggestions[slot]?[norm] ?? 'Matching Tone';
  }

  @override
  Widget build(BuildContext context) {
    final rec = widget.recommendation;
    final sel = rec.selected;
    final selColor = sel.colors.isNotEmpty ? sel.colors.first : 'neutral';
    final selWear = detectWearType(sel);

    // Determine what each zone shows
    // Zone: top, bottom, footwear
    // For the selected item's zone, use its actual colour.
    // For others, use matched product colour (if available) or suggested.

    String topColor, bottomColor, footColor;
    bool topInShop, bottomInShop, footInShop;
    String topLabel, bottomLabel, footLabel;
    String topName, bottomName, footName;

    // TOP
    if (selWear == WearType.topwear ||
        selWear == WearType.fullwear ||
        selWear == WearType.accessory) {
      topColor = selColor;
      topInShop = true;
      topName = sel.name;
      topLabel = selColor.isNotEmpty ? selColor : 'Selected';
    } else if (rec.top != null) {
      topColor = _colourOf(rec.top, selColor);
      topInShop = true;
      topName = rec.top!.name;
      topLabel = topColor;
    } else {
      topColor = _suggestColour(selColor, 'top');
      topInShop = false;
      topName = 'Suggested Colour';
      topLabel = topColor;
    }

    // BOTTOM
    if (selWear == WearType.bottomwear) {
      bottomColor = selColor;
      bottomInShop = true;
      bottomName = sel.name;
      bottomLabel = selColor.isNotEmpty ? selColor : 'Selected';
    } else if (rec.bottom != null) {
      bottomColor = _colourOf(rec.bottom, selColor);
      bottomInShop = true;
      bottomName = rec.bottom!.name;
      bottomLabel = bottomColor;
    } else {
      bottomColor = _suggestColour(selColor, 'bottom');
      bottomInShop = false;
      bottomName = 'Suggested Colour';
      bottomLabel = bottomColor;
    }

    // FOOTWEAR
    if (selWear == WearType.footwear) {
      footColor = selColor;
      footInShop = true;
      footName = sel.name;
      footLabel = selColor.isNotEmpty ? selColor : 'Selected';
    } else if (rec.footwear != null) {
      footColor = _colourOf(rec.footwear, selColor);
      footInShop = true;
      footName = rec.footwear!.name;
      footLabel = footColor;
    } else {
      footColor = _suggestColour(selColor, 'footwear');
      footInShop = false;
      footName = 'Suggested Colour';
      footLabel = footColor;
    }

    // Parse colour strings into actual Color objects for tinting
    Color tintFor(String colourStr) {
      final n = _ColourEngine.normalise(colourStr);
      const Map<String, Color> palette = {
        'red': Color(0xFFD32F2F),
        'blue': Color(0xFF1565C0),
        'green': Color(0xFF2E7D32),
        'yellow': Color(0xFFFFCA28),
        'pink': Color(0xFFE91E8C),
        'purple': Color(0xFF6A1B9A),
        'orange': Color(0xFFE65100),
        'black': Color(0xFF212121),
        'white': Color(0xFFECEFF1),
        'grey': Color(0xFF757575),
        'brown': Color(0xFF5D4037),
        'neutral': Color(0xFF90A4AE),
      };
      return palette[n] ?? const Color(0xFF90A4AE);
    }

    final topTint = tintFor(topColor);
    final bottomTint = tintFor(bottomColor);
    final footTint = tintFor(footColor);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.view_in_ar_rounded,
                  color: AppTheme.primary, size: 16),
              const SizedBox(width: 6),
              const Text('360° OUTFIT VIEW',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.primary,
                      letterSpacing: 0.8)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Tap slots to view items',
                    style: TextStyle(
                        fontSize: 9,
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Mannequin + Legend row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Rotating mannequin ───────────────────────────
              AnimatedBuilder(
                animation: _ctrl,
                builder: (_, __) {
                  // Perspective tilt oscillates to simulate 360°
                  final t = _ctrl.value * 2 * 3.14159;
                  final skewX = 0.12 *
                      (t % (2 * 3.14159) < 3.14159 ? 1.0 : -1.0) *
                      (0.5 - (t % 3.14159 / 3.14159 - 0.5).abs() * 2.0).abs();
                  return Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY(skewX * 0.8),
                    child: _MannequinSilhouette(
                      topTint: topTint,
                      bottomTint: bottomTint,
                      footTint: footTint,
                    ),
                  );
                },
              ),
              const SizedBox(width: 16),
              // ── Legend ───────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ZoneLegendRow(
                      icon: '👕',
                      zoneLabel: 'Top',
                      colourLabel: topLabel,
                      itemName: topName,
                      inShop: topInShop,
                      tint: topTint,
                      isSelected: selWear == WearType.topwear ||
                          selWear == WearType.fullwear,
                    ),
                    const SizedBox(height: 8),
                    _ZoneLegendRow(
                      icon: '👖',
                      zoneLabel: 'Bottom',
                      colourLabel: bottomLabel,
                      itemName: bottomName,
                      inShop: bottomInShop,
                      tint: bottomTint,
                      isSelected: selWear == WearType.bottomwear,
                    ),
                    const SizedBox(height: 8),
                    _ZoneLegendRow(
                      icon: '👟',
                      zoneLabel: 'Footwear',
                      colourLabel: footLabel,
                      itemName: footName,
                      inShop: footInShop,
                      tint: footTint,
                      isSelected: selWear == WearType.footwear,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Zone legend row ──────────────────────────────────────────────────────────
class _ZoneLegendRow extends StatelessWidget {
  final String icon;
  final String zoneLabel;
  final String colourLabel;
  final String itemName;
  final bool inShop;
  final Color tint;
  final bool isSelected;

  const _ZoneLegendRow({
    required this.icon,
    required this.zoneLabel,
    required this.colourLabel,
    required this.itemName,
    required this.inShop,
    required this.tint,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? tint.withValues(alpha: 0.12) : AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? tint.withValues(alpha: 0.5) : AppTheme.divider,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          // Colour swatch
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: tint,
              shape: BoxShape.circle,
              border: Border.all(
                  color: Colors.black.withValues(alpha: 0.15), width: 1),
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('$icon $zoneLabel',
                        style: const TextStyle(
                            fontSize: 9,
                            color: AppTheme.textLight,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(width: 4),
                    // In-shop or suggestion tag
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: inShop
                            ? AppTheme.success.withValues(alpha: 0.12)
                            : AppTheme.warning.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        inShop ? '✓ In Stock' : '💡 Suggestion',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          color: inShop ? AppTheme.success : AppTheme.warning,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  inShop ? itemName : colourLabel,
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? tint : AppTheme.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (!inShop) ...[
                  const SizedBox(height: 1),
                  Text('Not in catalogue — try this tone',
                      style: const TextStyle(
                          fontSize: 8,
                          color: AppTheme.textLight,
                          fontStyle: FontStyle.italic),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Mannequin silhouette drawn with CustomPainter ───────────────────────────
class _MannequinSilhouette extends StatelessWidget {
  final Color topTint;
  final Color bottomTint;
  final Color footTint;

  const _MannequinSilhouette({
    required this.topTint,
    required this.bottomTint,
    required this.footTint,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 200,
      child: CustomPaint(
        painter: _MannequinPainter(
          topTint: topTint,
          bottomTint: bottomTint,
          footTint: footTint,
        ),
      ),
    );
  }
}

class _MannequinPainter extends CustomPainter {
  final Color topTint;
  final Color bottomTint;
  final Color footTint;

  const _MannequinPainter({
    required this.topTint,
    required this.bottomTint,
    required this.footTint,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Proportions (relative to height)
    final headR = w * 0.14;
    final headCY = h * 0.08;
    final neckT = h * 0.16;
    final neckB = h * 0.20;
    final shoulderY = h * 0.20;
    final shoulderW = w * 0.42;
    final torsoB = h * 0.50;
    final hipW = w * 0.38;
    final hipB = h * 0.56;
    final kneeY = h * 0.75;
    final legW = w * 0.13;
    final footB = h * 0.96;
    final footW = w * 0.18;
    final cx = w / 2;

    final outlinePaint = Paint()
      ..color = AppTheme.textLight.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // ── Head ──────────────────────────────────────────────────
    final headPaint = Paint()
      ..color = const Color(0xFFE8C9A0) // skin tone
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, headCY), headR, headPaint);
    canvas.drawCircle(Offset(cx, headCY), headR, outlinePaint);

    // ── Neck ─────────────────────────────────────────────────
    final neckW = headR * 0.55;
    canvas.drawRect(
      Rect.fromLTRB(cx - neckW, neckT, cx + neckW, neckB),
      headPaint,
    );

    // ── Torso (top zone) ──────────────────────────────────────
    final torsoPaint = Paint()
      ..color = topTint.withOpacity(0.85)
      ..style = PaintingStyle.fill;
    final torsoPath = Path()
      ..moveTo(cx - shoulderW, shoulderY)
      ..lineTo(cx + shoulderW, shoulderY)
      ..lineTo(cx + hipW, torsoB)
      ..lineTo(cx - hipW, torsoB)
      ..close();
    canvas.drawPath(torsoPath, torsoPaint);
    canvas.drawPath(torsoPath, outlinePaint);

    // ── Arms ─────────────────────────────────────────────────
    final armW = w * 0.09;
    final armBY = h * 0.47;
    // Left arm
    final leftArm = Path()
      ..moveTo(cx - shoulderW, shoulderY)
      ..lineTo(cx - shoulderW - armW, shoulderY + armW * 0.3)
      ..lineTo(cx - shoulderW - armW, armBY)
      ..lineTo(cx - shoulderW, torsoB - h * 0.04)
      ..close();
    canvas.drawPath(leftArm, torsoPaint);
    canvas.drawPath(leftArm, outlinePaint);
    // Right arm
    final rightArm = Path()
      ..moveTo(cx + shoulderW, shoulderY)
      ..lineTo(cx + shoulderW + armW, shoulderY + armW * 0.3)
      ..lineTo(cx + shoulderW + armW, armBY)
      ..lineTo(cx + shoulderW, torsoB - h * 0.04)
      ..close();
    canvas.drawPath(rightArm, torsoPaint);
    canvas.drawPath(rightArm, outlinePaint);

    // ── Lower body (bottom zone) ──────────────────────────────
    final bottomPaint = Paint()
      ..color = bottomTint.withOpacity(0.85)
      ..style = PaintingStyle.fill;
    // Hip band
    final hipPath = Path()
      ..moveTo(cx - hipW, torsoB)
      ..lineTo(cx + hipW, torsoB)
      ..lineTo(cx + hipW, hipB)
      ..lineTo(cx - hipW, hipB)
      ..close();
    canvas.drawPath(hipPath, bottomPaint);
    canvas.drawPath(hipPath, outlinePaint);
    // Left leg
    final leftLeg = Path()
      ..moveTo(cx - legW * 0.2, hipB)
      ..lineTo(cx - hipW + legW * 0.2, hipB)
      ..lineTo(cx - hipW + legW, kneeY)
      ..lineTo(cx - legW * 0.8, kneeY)
      ..close();
    canvas.drawPath(leftLeg, bottomPaint);
    canvas.drawPath(leftLeg, outlinePaint);
    // Right leg
    final rightLeg = Path()
      ..moveTo(cx + legW * 0.2, hipB)
      ..lineTo(cx + hipW - legW * 0.2, hipB)
      ..lineTo(cx + hipW - legW, kneeY)
      ..lineTo(cx + legW * 0.8, kneeY)
      ..close();
    canvas.drawPath(rightLeg, bottomPaint);
    canvas.drawPath(rightLeg, outlinePaint);
    // Left shin
    final leftShin = Path()
      ..moveTo(cx - hipW + legW, kneeY)
      ..lineTo(cx - legW * 0.8, kneeY)
      ..lineTo(cx - legW * 0.8, footB - footW * 0.4)
      ..lineTo(cx - hipW + legW, footB - footW * 0.4)
      ..close();
    canvas.drawPath(leftShin, bottomPaint);
    canvas.drawPath(leftShin, outlinePaint);
    // Right shin
    final rightShin = Path()
      ..moveTo(cx + hipW - legW, kneeY)
      ..lineTo(cx + legW * 0.8, kneeY)
      ..lineTo(cx + legW * 0.8, footB - footW * 0.4)
      ..lineTo(cx + hipW - legW, footB - footW * 0.4)
      ..close();
    canvas.drawPath(rightShin, bottomPaint);
    canvas.drawPath(rightShin, outlinePaint);

    // ── Feet (footwear zone) ──────────────────────────────────
    final footPaint = Paint()
      ..color = footTint.withOpacity(0.9)
      ..style = PaintingStyle.fill;
    // Left foot
    final leftFoot = RRect.fromRectAndRadius(
      Rect.fromLTRB(
        cx - hipW + legW - footW * 0.3,
        footB - footW * 0.45,
        cx - hipW + legW - footW * 0.3 + footW * 1.6,
        footB,
      ),
      const Radius.circular(5),
    );
    canvas.drawRRect(leftFoot, footPaint);
    canvas.drawRRect(leftFoot, outlinePaint);
    // Right foot
    final rightFoot = RRect.fromRectAndRadius(
      Rect.fromLTRB(
        cx + hipW - legW - footW * 1.3,
        footB - footW * 0.45,
        cx + hipW - legW - footW * 1.3 + footW * 1.6,
        footB,
      ),
      const Radius.circular(5),
    );
    canvas.drawRRect(rightFoot, footPaint);
    canvas.drawRRect(rightFoot, outlinePaint);
  }

  @override
  bool shouldRepaint(_MannequinPainter old) =>
      old.topTint != topTint ||
      old.bottomTint != bottomTint ||
      old.footTint != footTint;
}
