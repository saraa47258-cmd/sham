import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'login_screen.dart';
import 'cart_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  String _workerName = '';
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _filteredProducts = [];
  String _selectedCategory = 'all';
  String _searchQuery = '';
  bool _isLoading = true;
  
  // Cart
  final List<Map<String, dynamic>> _cart = [];
  int _cartItemsCount = 0;
  double _cartTotal = 0;

  @override
  void initState() {
    super.initState();
    _loadWorkerData();
    _setupRealtimeListeners(); // الاستماع للتغييرات في الوقت الفعلي
  }

  @override
  void dispose() {
    // إلغاء الاستماع عند إغلاق الشاشة
    FirebaseDatabase.instance.ref('restaurant-system/restaurants/sham-coffee-1/categories').onValue.drain();
    FirebaseDatabase.instance.ref('restaurant-system/restaurants/sham-coffee-1/menu').onValue.drain();
    super.dispose();
  }

  Future<void> _loadWorkerData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _workerName = prefs.getString('worker_name') ?? 'عامل';
    });
  }

  String? _errorMessage;

  // الاستماع للتغييرات في الوقت الفعلي - التحديث التلقائي
  void _setupRealtimeListeners() {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final database = FirebaseDatabase.instance;
    debugPrint('🔄 بدء الاستماع للتغييرات في الوقت الفعلي...');

    // الاستماع للأقسام
    database.ref('restaurant-system/restaurants/sham-coffee-1/categories').onValue.listen((event) {
      debugPrint('📂 تحديث الأقسام...');
      if (event.snapshot.exists) {
        final catData = Map<String, dynamic>.from(event.snapshot.value as Map);
        setState(() {
          _categories = catData.entries.map((e) {
            final cat = Map<String, dynamic>.from(e.value as Map);
            return {'id': e.key, ...cat};
          }).toList();
        });
        debugPrint('✅ تم تحديث ${_categories.length} قسم');
      }
    }, onError: (error) {
      debugPrint('❌ خطأ في الأقسام: $error');
    });

    // الاستماع للمنتجات
    database.ref('restaurant-system/restaurants/sham-coffee-1/menu').onValue.listen((event) {
      debugPrint('📦 تحديث المنتجات...');
      if (event.snapshot.exists) {
        final prodData = Map<String, dynamic>.from(event.snapshot.value as Map);
        setState(() {
          _products = prodData.entries.map((e) {
            final prod = Map<String, dynamic>.from(e.value as Map);
            return {'id': e.key, ...prod};
          }).toList();
          _isLoading = false;
          _errorMessage = null;
        });
        debugPrint('✅ تم تحديث ${_products.length} منتج');
        _filterProducts();
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'لا توجد منتجات في قاعدة البيانات';
        });
      }
    }, onError: (error) {
      debugPrint('❌ خطأ في المنتجات: $error');
      setState(() {
        _isLoading = false;
        _errorMessage = 'خطأ في الاتصال: $error';
      });
    });
  }

  // إعادة تحميل يدوي (للسحب للتحديث)
  Future<void> _loadData() async {
    // البيانات تتحدث تلقائياً، لكن نعيد تحميل الصفحة للتأكد
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() => _isLoading = false);
  }

  void _filterProducts() {
    setState(() {
      _filteredProducts = _products.where((product) {
        final matchesCategory = _selectedCategory == 'all' || 
            product['category'] == _selectedCategory;
        final matchesSearch = _searchQuery.isEmpty || 
            (product['name'] ?? '').toString().toLowerCase().contains(_searchQuery.toLowerCase());
        return matchesCategory && matchesSearch;
      }).toList();
    });
  }

  void _addToCart(Map<String, dynamic> product, {String? selectedSize, double? sizePrice}) {
    final price = sizePrice ?? (product['price'] is int 
        ? (product['price'] as int).toDouble() 
        : (product['price'] ?? 0.0));
    
    final cartItem = {
      'id': selectedSize != null ? '${product['id']}_$selectedSize' : product['id'],
      'productId': product['id'],
      'name': selectedSize != null ? '${product['name']} - $selectedSize' : product['name'],
      'price': price,
      'quantity': 1,
      'emoji': product['emoji'],
      'imageUrl': product['imageUrl'],
    };

    final existingIndex = _cart.indexWhere((item) => item['id'] == cartItem['id']);
    
    setState(() {
      if (existingIndex >= 0) {
        _cart[existingIndex]['quantity']++;
      } else {
        _cart.add(cartItem);
      }
      _updateCartTotals();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text('تمت إضافة ${product['name']} للسلة'),
          ],
        ),
        backgroundColor: const Color(0xFF4ade80),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _updateCartTotals() {
    _cartItemsCount = _cart.fold(0, (sum, item) => sum + (item['quantity'] as int));
    _cartTotal = _cart.fold(0.0, (sum, item) => sum + (item['price'] * item['quantity']));
  }

  void _showProductDetails(Map<String, dynamic> product) {
    final sizes = product['sizes'] as Map<dynamic, dynamic>?;
    final shishaTypes = product['shishaTypes'] as Map<dynamic, dynamic>?;
    
    if (sizes != null || shishaTypes != null) {
      showModalBottomSheet(
        context: context,
        backgroundColor: const Color(0xFF16161f),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) => _buildProductOptionsSheet(product, sizes, shishaTypes),
      );
    } else {
      _addToCart(product);
    }
  }

  Widget _buildProductOptionsSheet(
    Map<String, dynamic> product,
    Map<dynamic, dynamic>? sizes,
    Map<dynamic, dynamic>? shishaTypes,
  ) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            product['name'] ?? '',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          
          if (sizes != null) ...[
            const Text(
              'اختر الحجم:',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF8a8a9a),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: sizes.entries.map((entry) {
                final sizeKey = entry.key.toString();
                final value = entry.value;
                
                // استخراج الاسم والسعر
                String sizeName = sizeKey;
                double sizePrice = 0.0;
                
                if (value is Map) {
                  // الهيكل: { name: 'صغير', price: 1.000 }
                  sizeName = value['name']?.toString() ?? sizeKey;
                  sizePrice = _extractPrice(value);
                } else {
                  sizePrice = _extractPrice(value);
                }
                
                return _buildOptionButton(
                  sizeName,
                  '${sizePrice.toStringAsFixed(3)} ر.ع',
                  () {
                    Navigator.pop(context);
                    _addToCart(product, selectedSize: sizeName, sizePrice: sizePrice);
                  },
                );
              }).toList(),
            ),
          ],
          
          if (shishaTypes != null) ...[
            const Text(
              'اختر النوع:',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF8a8a9a),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: shishaTypes.entries.map((entry) {
                final typeKey = entry.key.toString();
                final value = entry.value;
                
                // استخراج الاسم والسعر
                String typeName = typeKey;
                double typePrice = 0.0;
                
                if (value is Map) {
                  // الهيكل: { name: 'نوع', price: 5.000 }
                  typeName = value['name']?.toString() ?? typeKey;
                  typePrice = _extractPrice(value);
                } else {
                  typePrice = _extractPrice(value);
                }
                
                return _buildOptionButton(
                  typeName,
                  '${typePrice.toStringAsFixed(3)} ر.ع',
                  () {
                    Navigator.pop(context);
                    _addToCart(product, selectedSize: typeName, sizePrice: typePrice);
                  },
                );
              }).toList(),
            ),
          ],
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildOptionButton(String label, String price, VoidCallback onTap) {
    return Material(
      color: const Color(0xFF1e1e2a),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                price,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF8B5CF6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16161f),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('تسجيل الخروج', style: TextStyle(color: Colors.white)),
        content: const Text('هل تريد تسجيل الخروج؟', style: TextStyle(color: Color(0xFF8a8a9a))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('خروج'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  void _openCart() async {
    final result = await Navigator.push<List<Map<String, dynamic>>>(
      context,
      MaterialPageRoute(
        builder: (context) => CartScreen(cart: List.from(_cart)),
      ),
    );
    
    if (result != null) {
      setState(() {
        _cart.clear();
        _cart.addAll(result);
        _updateCartTotals();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0a0a0f),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16161f),
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text('☕', style: TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'قهوة الشام',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'مرحباً، $_workerName',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8a8a9a),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout, color: Colors.red),
            tooltip: 'تسجيل الخروج',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF8B5CF6)),
                  SizedBox(height: 16),
                  Text('جاري تحميل المنيو...', style: TextStyle(color: Color(0xFF8a8a9a))),
                ],
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 60, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 16)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _loadData,
                        icon: const Icon(Icons.refresh),
                        label: const Text('إعادة المحاولة'),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6)),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
              onRefresh: _loadData,
              color: const Color(0xFF8B5CF6),
              child: CustomScrollView(
                slivers: [
                  // Search Bar
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        onChanged: (value) {
                          _searchQuery = value;
                          _filterProducts();
                        },
                        decoration: InputDecoration(
                          hintText: 'ابحث عن منتج...',
                          hintStyle: const TextStyle(color: Color(0xFF8a8a9a)),
                          prefixIcon: const Icon(Icons.search, color: Color(0xFF8B5CF6)),
                          filled: true,
                          fillColor: const Color(0xFF16161f),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Categories
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 50,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          _buildCategoryChip('all', 'الكل', '🎯'),
                          ..._categories.map((cat) => _buildCategoryChip(
                            cat['id'],
                            cat['name'] ?? '',
                            cat['emoji'] ?? '📦',
                          )),
                        ],
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 16)),

                  // Products Grid
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.75,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildProductCard(_filteredProducts[index]),
                        childCount: _filteredProducts.length,
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),
      
      // Floating Cart Button
      floatingActionButton: _cartItemsCount > 0
          ? Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: FloatingActionButton.extended(
                onPressed: _openCart,
                backgroundColor: const Color(0xFF8B5CF6),
                icon: Badge(
                  label: Text('$_cartItemsCount'),
                  child: const Icon(Icons.shopping_bag),
                ),
                label: Text('${_cartTotal.toStringAsFixed(3)} ر.ع'),
              ),
            )
          : null,
    );
  }

  Widget _buildCategoryChip(String id, String name, String emoji) {
    final isSelected = _selectedCategory == id;
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: FilterChip(
        selected: isSelected,
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji),
            const SizedBox(width: 6),
            Text(name),
          ],
        ),
        onSelected: (selected) {
          setState(() {
            _selectedCategory = id;
            _filterProducts();
          });
        },
        selectedColor: const Color(0xFF8B5CF6),
        backgroundColor: const Color(0xFF16161f),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : const Color(0xFF8a8a9a),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? const Color(0xFF8B5CF6) : const Color(0xFF2a2a3a),
          ),
        ),
      ),
    );
  }

  // دالة مساعدة لاستخراج السعر من القيمة
  double _extractPrice(dynamic value) {
    if (value == null) return 0.0;
    
    // إذا كانت القيمة Map تحتوي على price
    if (value is Map) {
      final priceValue = value['price'];
      if (priceValue is int) return priceValue.toDouble();
      if (priceValue is double) return priceValue;
      if (priceValue is num) return priceValue.toDouble();
      if (priceValue is String) return double.tryParse(priceValue) ?? 0.0;
      return 0.0;
    }
    
    // إذا كانت القيمة رقم مباشرة
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    
    return 0.0;
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    // حساب السعر - إذا كان هناك أحجام، نعرض أقل سعر
    double price = 0.0;
    bool hasSizes = false;
    String priceLabel = '';
    
    final sizes = product['sizes'] as Map<dynamic, dynamic>?;
    final shishaTypes = product['shishaTypes'] as Map<dynamic, dynamic>?;
    
    if (sizes != null && sizes.isNotEmpty) {
      hasSizes = true;
      // أقل سعر من الأحجام
      double minPrice = double.infinity;
      for (var value in sizes.values) {
        double p = _extractPrice(value);
        if (p < minPrice && p > 0) minPrice = p;
      }
      price = minPrice == double.infinity ? 0.0 : minPrice;
      priceLabel = 'من ${price.toStringAsFixed(3)} ر.ع';
    } else if (shishaTypes != null && shishaTypes.isNotEmpty) {
      hasSizes = true;
      // أقل سعر من أنواع الشيشة
      double minPrice = double.infinity;
      for (var value in shishaTypes.values) {
        double p = _extractPrice(value);
        if (p < minPrice && p > 0) minPrice = p;
      }
      price = minPrice == double.infinity ? 0.0 : minPrice;
      priceLabel = 'من ${price.toStringAsFixed(3)} ر.ع';
    } else {
      // سعر عادي
      price = _extractPrice(product['price']);
      priceLabel = '${price.toStringAsFixed(3)} ر.ع';
    }
    
    final imageUrl = product['imageUrl'];
    final emoji = product['emoji'] ?? '📦';

    return Material(
      color: const Color(0xFF16161f),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => _showProductDetails(product),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF2a2a3a)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  margin: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1e1e2a),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: imageUrl != null && imageUrl.toString().isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: CachedNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              placeholder: (context, url) => const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFF8B5CF6),
                                  strokeWidth: 2,
                                ),
                              ),
                              errorWidget: (context, url, error) => Text(
                                emoji,
                                style: const TextStyle(fontSize: 50),
                              ),
                            ),
                          )
                        : Text(
                            emoji,
                            style: const TextStyle(fontSize: 50),
                          ),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product['name'] ?? '',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            priceLabel,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF8B5CF6),
                            ),
                          ),
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

