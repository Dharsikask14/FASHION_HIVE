import 'package:flutter/material.dart';
import '../data/app_state.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/product_card.dart';
import '../widgets/shop_logo_button.dart';
import 'product_detail_screen.dart';

class ExploreScreen extends StatefulWidget {
  final AppState appState;
  const ExploreScreen({super.key, required this.appState});
  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen>
    with SingleTickerProviderStateMixin {
  String _selectedCategory = 'All';
  String _selectedGender = 'All';
  String _sortBy = 'Popular';
  RangeValues _priceRange = const RangeValues(0, 35000);
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late TabController _tabController;

  final List<String> _sortOptions = [
    'Popular', 'Newest', 'Price: Low to High', 'Price: High to Low', 'Rating',
  ];

  static const List<Map<String, dynamic>> _categoryData = [
    {'name': 'All',          'icon': Icons.apps_rounded,          'color': 0xFF2E5B8A},
    {'name': 'Sarees',       'icon': Icons.auto_awesome_rounded,  'color': 0xFF2A8F8F},
    {'name': 'Lehengas',     'icon': Icons.star_rounded,          'color': 0xFF6A1B9A},
    {'name': 'Suits',        'icon': Icons.checkroom_rounded,     'color': 0xFF00838F},
    {'name': 'Kurtis',       'icon': Icons.face_rounded,          'color': 0xFF558B2F},
    {'name': "Men's Ethnic", 'icon': Icons.man_rounded,           'color': 0xFF1565C0},
    {'name': "Men's Casual", 'icon': Icons.boy_rounded,           'color': 0xFF37474F},
    {'name': 'Footwear',     'icon': Icons.hiking_rounded,        'color': 0xFF1C3F66},
    {'name': "Kids' Wear",   'icon': Icons.child_care_rounded,    'color': 0xFF00897B},
  ];

  List<String> get _genderCategories {
    if (_selectedGender == 'All') return [];
    return genderSections[_selectedGender] ?? [];
  }

  List<Product> get _filteredProducts {
    final genderCats = _genderCategories;
    var products = widget.appState.products.where((p) {
      final matchCat = _selectedCategory == 'All' || p.category == _selectedCategory;
      final matchGender = genderCats.isEmpty || genderCats.contains(p.category);
      final matchPrice = p.price >= _priceRange.start && p.price <= _priceRange.end;
      final matchSearch = _searchQuery.isEmpty ||
          p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.category.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchCat && matchGender && matchPrice && matchSearch;
    }).toList();

    switch (_sortBy) {
      case 'Price: Low to High': products.sort((a, b) => a.price.compareTo(b.price)); break;
      case 'Price: High to Low': products.sort((a, b) => b.price.compareTo(a.price)); break;
      case 'Rating':             products.sort((a, b) => b.rating.compareTo(a.rating)); break;
      case 'Newest':
        products = products.where((p) => p.isNew).toList() +
                   products.where((p) => !p.isNew).toList();
        break;
    }
    return products;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categoryData.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _selectedCategory = _categoryData[_tabController.index]['name']);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final products = _filteredProducts;
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          _buildAppBar(),
          _buildCategoryTabs(),
          Container(
            color: AppTheme.surface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Text(
                  '${products.length} products found',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _showSortSheet,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.sort_rounded, size: 14, color: AppTheme.primary),
                        const SizedBox(width: 5),
                        Text(_sortBy,
                            style: const TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.primary)),
                        const SizedBox(width: 3),
                        const Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: AppTheme.primary),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.divider),
          Expanded(
            child: products.isEmpty
                ? _buildEmpty()
                : GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.68,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: products.length,
                    itemBuilder: (ctx, i) => ProductCard(
                      product: products[i],
                      appState: widget.appState,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductDetailScreen(
                            product: products[i],
                            appState: widget.appState,
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Material(
      color: AppTheme.primaryDark,
      elevation: 2,
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 52,
              child: Row(
                children: [
                  const ShopLogoButton(),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'EXPLORE',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 4,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.tune_rounded, color: Colors.white),
                    onPressed: _showFilterSheet,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: ['All', 'Women', 'Men', 'Kids'].map((g) {
                  final sel = g == _selectedGender;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _selectedGender = g;
                        _selectedCategory = 'All';
                        _tabController.animateTo(0);
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: sel ? AppTheme.secondary : Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: sel ? AppTheme.secondary : Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          g,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: sel ? Colors.white : Colors.white70,
                            fontSize: 12,
                            fontWeight: sel ? FontWeight.w800 : FontWeight.w500,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v),
                style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search sarees, kurtis, footwear...',
                  hintStyle: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.6)),
                  prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Colors.white70),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18, color: Colors.white70),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.15),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.25), width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: const BorderSide(color: AppTheme.secondary, width: 1.5),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      color: AppTheme.surface,
      height: 54,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: _categoryData.length,
        itemBuilder: (_, i) {
          final cat = _categoryData[i];
          final selected = _selectedCategory == cat['name'];
          final color = Color(cat['color'] as int);
          return GestureDetector(
            onTap: () {
              _tabController.animateTo(i);
              setState(() => _selectedCategory = cat['name']);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: selected ? color.withValues(alpha: 0.12) : AppTheme.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: selected ? color : AppTheme.divider,
                  width: selected ? 1.5 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(cat['icon'] as IconData, size: 14, color: color),
                  const SizedBox(width: 5),
                  Text(
                    cat['name'],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      color: selected ? color : AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(color: AppTheme.primaryLight, shape: BoxShape.circle),
            child: const Icon(Icons.search_off_rounded, size: 38, color: AppTheme.primary),
          ),
          const SizedBox(height: 16),
          const Text('No products found',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          const SizedBox(height: 6),
          const Text('Try a different search or category',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(width: 36, height: 4,
              decoration: BoxDecoration(color: AppTheme.divider, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          const Text('Sort By', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          ..._sortOptions.map((opt) => ListTile(
                leading: Icon(
                  _sortBy == opt ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                  color: AppTheme.primary,
                ),
                title: Text(opt,
                    style: TextStyle(fontWeight: _sortBy == opt ? FontWeight.w700 : FontWeight.w500)),
                onTap: () {
                  setState(() => _sortBy = opt);
                  Navigator.pop(context);
                },
              )),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.55,
          maxChildSize: 0.85,
          minChildSize: 0.4,
          expand: false,
          builder: (_, sc) => Column(
            children: [
              const SizedBox(height: 12),
              Container(width: 36, height: 4,
                  decoration: BoxDecoration(color: AppTheme.divider, borderRadius: BorderRadius.circular(2))),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Text('Filters', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        setModalState(() => _priceRange = const RangeValues(0, 35000));
                        setState(() => _priceRange = const RangeValues(0, 35000));
                      },
                      child: const Text('Reset'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  controller: sc,
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Text('Price Range', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    const SizedBox(height: 8),
                    RangeSlider(
                      values: _priceRange,
                      min: 0,
                      max: 35000,
                      divisions: 35,
                      activeColor: AppTheme.primary,
                      labels: RangeLabels('₹${_priceRange.start.toInt()}', '₹${_priceRange.end.toInt()}'),
                      onChanged: (v) {
                        setModalState(() => _priceRange = v);
                        setState(() => _priceRange = v);
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('₹${_priceRange.start.toInt()}',
                            style: const TextStyle(color: AppTheme.textSecondary)),
                        Text('₹${_priceRange.end.toInt()}',
                            style: const TextStyle(color: AppTheme.textSecondary)),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Apply Filters'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
