import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CartScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cart;

  const CartScreen({super.key, required this.cart});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late List<Map<String, dynamic>> _cart;
  final _tableController = TextEditingController();
  bool _isSubmitting = false;
  String _locationType = 'table'; // 'table' أو 'room'

  @override
  void initState() {
    super.initState();
    _cart = List.from(widget.cart);
  }

  double get _total => _cart.fold(
    0.0,
    (sum, item) => sum + (item['price'] * item['quantity']),
  );

  int get _itemsCount => _cart.fold(
    0,
    (sum, item) => sum + (item['quantity'] as int),
  );

  void _updateQuantity(int index, int change) {
    setState(() {
      _cart[index]['quantity'] += change;
      if (_cart[index]['quantity'] <= 0) {
        _cart.removeAt(index);
      }
    });
  }

  void _removeItem(int index) {
    setState(() {
      _cart.removeAt(index);
    });
  }

  Future<void> _submitOrder() async {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('السلة فارغة'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final workerName = prefs.getString('worker_name') ?? 'عامل';
      final workerId = prefs.getString('worker_id') ?? '';
      final workerPosition = prefs.getString('worker_position') ?? 'عامل';

      final database = FirebaseDatabase.instance;
      final ordersRef = database.ref('restaurant-system/restaurants/sham-coffee-1/orders').push();
      
      final items = _cart.map((item) => {
        'name': item['name'],
        'price': item['price'],
        'quantity': item['quantity'],
        'total': item['price'] * item['quantity'],
      }).toList();

      final locationNumber = _tableController.text.trim();
      
      await ordersRef.set({
        'items': items,
        'total': _total,
        'locationType': _locationType, // 'table' أو 'room'
        'tableNumber': _locationType == 'table' && locationNumber.isNotEmpty 
            ? locationNumber 
            : null,
        'roomNumber': _locationType == 'room' && locationNumber.isNotEmpty 
            ? locationNumber 
            : null,
        'status': 'pending',
        'source': 'worker-app',
        'workerId': workerId,
        'workerName': workerName,
        'workerPosition': workerPosition,
        'createdAt': ServerValue.timestamp,
      });

      // Update table/room status if number provided
      if (locationNumber.isNotEmpty) {
        if (_locationType == 'table') {
          final tableRef = database.ref(
            'restaurant-system/restaurants/sham-coffee-1/tables/$locationNumber'
          );
          await tableRef.update({
            'status': 'occupied',
            'lastOrderId': ordersRef.key,
            'updatedAt': ServerValue.timestamp,
          });
        } else {
          // Update room status
          final roomRef = database.ref(
            'restaurant-system/restaurants/sham-coffee-1/rooms/$locationNumber'
          );
          await roomRef.update({
            'status': 'occupied',
            'lastOrderId': ordersRef.key,
            'updatedAt': ServerValue.timestamp,
          });
        }
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('تم إرسال الطلب بنجاح!'),
            ],
          ),
          backgroundColor: const Color(0xFF4ade80),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

      // Clear cart and go back
      Navigator.pop(context, <Map<String, dynamic>>[]);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _tableController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.pop(context, _cart);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0a0a0f),
        appBar: AppBar(
          backgroundColor: const Color(0xFF16161f),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, _cart),
          ),
          title: Row(
            children: [
              const Icon(Icons.shopping_bag, color: Color(0xFF8B5CF6)),
              const SizedBox(width: 8),
              const Text('سلة التسوق'),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$_itemsCount',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        body: _cart.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shopping_bag_outlined,
                      size: 100,
                      color: Colors.grey[700],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'السلة فارغة',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.grey[500],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'أضف منتجات للسلة للمتابعة',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _cart.length,
                      itemBuilder: (context, index) {
                        final item = _cart[index];
                        return _buildCartItem(item, index);
                      },
                    ),
                  ),
                  _buildBottomSection(),
                ],
              ),
      ),
    );
  }

  Widget _buildCartItem(Map<String, dynamic> item, int index) {
    final emoji = item['emoji'] ?? '📦';
    
    return Dismissible(
      key: Key(item['id'].toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) => _removeItem(index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF16161f),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2a2a3a)),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFF1e1e2a),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 30)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['name'] ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(item['price'] as double).toStringAsFixed(3)} ر.ع',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF8B5CF6),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1e1e2a),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => _updateQuantity(index, -1),
                    icon: const Icon(Icons.remove, size: 18),
                    color: Colors.white,
                  ),
                  Text(
                    '${item['quantity']}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    onPressed: () => _updateQuantity(index, 1),
                    icon: const Icon(Icons.add, size: 18),
                    color: const Color(0xFF8B5CF6),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF16161f),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Location Type Selector
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1e1e2a),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _locationType = 'table'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _locationType == 'table' 
                              ? const Color(0xFF8B5CF6) 
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.table_restaurant,
                              color: _locationType == 'table' 
                                  ? Colors.white 
                                  : const Color(0xFF8a8a9a),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'طاولة',
                              style: TextStyle(
                                color: _locationType == 'table' 
                                    ? Colors.white 
                                    : const Color(0xFF8a8a9a),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _locationType = 'room'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _locationType == 'room' 
                              ? const Color(0xFFF59E0B) 
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.meeting_room,
                              color: _locationType == 'room' 
                                  ? Colors.white 
                                  : const Color(0xFF8a8a9a),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'غرفة',
                              style: TextStyle(
                                color: _locationType == 'room' 
                                    ? Colors.white 
                                    : const Color(0xFF8a8a9a),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            
            // Location Number Input
            TextField(
              controller: _tableController,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: _locationType == 'table' 
                    ? 'رقم الطاولة (اختياري)' 
                    : 'رقم الغرفة (اختياري)',
                hintStyle: const TextStyle(color: Color(0xFF8a8a9a)),
                prefixIcon: Icon(
                  _locationType == 'table' ? Icons.table_restaurant : Icons.meeting_room,
                  color: _locationType == 'table' 
                      ? const Color(0xFF8B5CF6) 
                      : const Color(0xFFF59E0B),
                ),
                filled: true,
                fillColor: const Color(0xFF1e1e2a),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Summary
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'المجموع:',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF8a8a9a),
                  ),
                ),
                Text(
                  '${_total.toStringAsFixed(3)} ر.ع',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8B5CF6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 8,
                  shadowColor: const Color(0xFF8B5CF6).withValues(alpha: 0.5),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle),
                          SizedBox(width: 8),
                          Text(
                            'تأكيد الطلب',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
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

