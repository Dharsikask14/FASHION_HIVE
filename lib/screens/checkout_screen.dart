import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../data/app_state.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import 'order_success_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final AppState appState;
  const CheckoutScreen({super.key, required this.appState});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  int _step = 0;
  String _paymentMethod = 'COD';
  late Address _selectedAddress;

  // ── Razorpay ──────────────────────────────────────────────────────────────
  late Razorpay _razorpay;
  bool _isProcessing = false;

  // 🔑 Replace with your actual Razorpay Key ID from https://dashboard.razorpay.com
  static const String _razorpayKeyId = 'rzp_test_1DP5mmOlF5G5ag';

  @override
  void initState() {
    super.initState();
    _selectedAddress = widget.appState.addresses.first;

    // Initialise Razorpay and register callbacks
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear(); // Always clear to prevent memory leaks
    super.dispose();
  }

  // ── Razorpay Callbacks ────────────────────────────────────────────────────

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    // Payment succeeded — place the order and navigate to success page
    widget.appState.placeOrder(_selectedAddress, 'Razorpay');
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OrderSuccessScreen(appState: widget.appState),
        ),
      );
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    setState(() => _isProcessing = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Payment failed: ${response.message ?? "Please try again."}',
          ),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('External Wallet: ${response.walletName}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ── Open Razorpay Checkout ─────────────────────────────────────────────────
  void _openRazorpayCheckout() {
    final amountInPaise = (widget.appState.cartTotal * 100).toInt();
    final options = {
      'key': _razorpayKeyId,
      'amount': amountInPaise, // Amount must be in paise (₹1 = 100 paise)
      'name': 'Siva Silks',
      'description': 'Order Payment',
      'currency': 'INR',
      'prefill': {
        'contact': widget.appState.userPhone,
        'email': widget.appState.userEmail,
        'name': widget.appState.userName,
      },
      'theme': {
        'color': '#1C3F66', // AppTheme.primaryDark
      },
      'external': {
        'wallets': ['paytm', 'phonepe', 'gpay'],
      },
    };
    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Razorpay open error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open payment gateway: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  // ── Place Order ───────────────────────────────────────────────────────────
  void _onPlaceOrder() {
    if (_paymentMethod == 'Razorpay') {
      setState(() => _isProcessing = true);
      _openRazorpayCheckout();
    } else {
      // Cash on Delivery — place directly
      widget.appState.placeOrder(_selectedAddress, 'Cash on Delivery');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OrderSuccessScreen(appState: widget.appState),
        ),
      );
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        centerTitle: true,
        title: const Text('CHECKOUT'),
      ),
      body: Column(
        children: [
          _buildStepper(),
          Expanded(
            child: IndexedStack(
              index: _step,
              children: [
                _buildAddressStep(),
                _buildPaymentStep(),
                _buildReviewStep(),
              ],
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildStepper() {
    final steps = ['Address', 'Payment', 'Review'];
    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            return Expanded(
              child: Container(
                height: 2,
                color: i ~/ 2 < _step
                    ? AppTheme.secondary
                    : AppTheme.divider,
              ),
            );
          }
          final stepIndex = i ~/ 2;
          final done = stepIndex < _step;
          final active = stepIndex == _step;
          return Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: done || active
                      ? AppTheme.secondary
                      : AppTheme.background,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: done || active
                        ? AppTheme.secondary
                        : AppTheme.divider,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: done
                      ? const Icon(Icons.check_rounded,
                          size: 16, color: Colors.white)
                      : Text(
                          '${stepIndex + 1}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: active
                                ? Colors.white
                                : AppTheme.textLight,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                steps[stepIndex],
                style: TextStyle(
                  fontSize: 10,
                  fontWeight:
                      active ? FontWeight.w700 : FontWeight.w500,
                  color: active
                      ? AppTheme.secondary
                      : AppTheme.textSecondary,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildAddressStep() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ...widget.appState.addresses.map((addr) => GestureDetector(
              onTap: () => setState(() => _selectedAddress = addr),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _selectedAddress.id == addr.id
                        ? AppTheme.secondary
                        : AppTheme.divider,
                    width: _selectedAddress.id == addr.id ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Radio<String>(
                      value: addr.id,
                      groupValue: _selectedAddress.id,
                      onChanged: (v) =>
                          setState(() => _selectedAddress = addr),
                      activeColor: AppTheme.secondary,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                addr.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                              if (addr.isDefault)
                                Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.success
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'Default',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: AppTheme.success,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            addr.fullAddress,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            addr.phone,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.add_location_alt_outlined),
          label: const Text('Add New Address'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            foregroundColor: AppTheme.primary,
            side: const BorderSide(color: AppTheme.primary),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentStep() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Cash on Delivery ──────────────────────────────────────────────
        _buildPaymentTile(
          id: 'COD',
          label: 'Cash on Delivery',
          subtitle: 'Pay when your order arrives',
          icon: Icons.money_rounded,
          iconColor: const Color(0xFF2A7A5A),
        ),
        const SizedBox(height: 10),

        // ── Razorpay ─────────────────────────────────────────────────────
        _buildPaymentTile(
          id: 'Razorpay',
          label: 'Pay Online',
          subtitle: 'UPI · Cards · Net Banking · Wallets',
          icon: Icons.payment_rounded,
          iconColor: const Color(0xFF2E5B8A),
          badge: 'RECOMMENDED',
        ),

        const SizedBox(height: 20),

        // ── Secure payment notice ─────────────────────────────────────────
        if (_paymentMethod == 'Razorpay')
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF2E5B8A).withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color(0xFF2E5B8A).withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.lock_rounded,
                    color: Color(0xFF2E5B8A), size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        '100% Secure Payment',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: Color(0xFF2E5B8A),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Your payment is secured by Razorpay with 256-bit SSL encryption.',
                        style: TextStyle(
                            fontSize: 11, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildPaymentTile({
    required String id,
    required String label,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    String? badge,
  }) {
    final selected = _paymentMethod == id;
    return GestureDetector(
      onTap: () => setState(() => _paymentMethod = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? iconColor.withValues(alpha: 0.05)
              : AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? iconColor : AppTheme.divider,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w600,
                          fontSize: 14,
                          color: selected
                              ? AppTheme.textPrimary
                              : AppTheme.textSecondary,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.secondary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            badge,
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textLight),
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: id,
              groupValue: _paymentMethod,
              onChanged: (v) => setState(() => _paymentMethod = v!),
              activeColor: iconColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewStep() {
    final cart = widget.appState.cart;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _reviewSection('Delivery Address',
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_selectedAddress.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  Text(_selectedAddress.fullAddress,
                      style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                          height: 1.4)),
                ],
              ),
            )),
        const SizedBox(height: 12),
        _reviewSection('Payment',
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  Icon(
                    _paymentMethod == 'Razorpay'
                        ? Icons.payment_rounded
                        : Icons.money_rounded,
                    size: 16,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _paymentMethod == 'Razorpay'
                        ? 'Pay Online (Razorpay)'
                        : 'Cash on Delivery',
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            )),
        const SizedBox(height: 12),
        _reviewSection('Items (${cart.length})',
            child: Column(
              children: cart
                  .map((item) => Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: SizedBox(
                                width: 48,
                                height: 48,
                                child: Image.network(
                                    item.product.imageUrl,
                                    fit: BoxFit.cover),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(item.product.name,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            ),
                            Text(
                              '₹${item.totalPrice.toInt()}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            )),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Amount',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                  Text(
                    '₹${widget.appState.cartTotal.toInt()}',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.secondary),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _reviewSection(String title, {required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppTheme.textPrimary)),
          child,
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final isLast = _step == 2;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.divider)),
      ),
      child: ElevatedButton(
        onPressed: _isProcessing
            ? null // Disable button while Razorpay is processing
            : () {
                if (isLast) {
                  _onPlaceOrder();
                } else {
                  setState(() => _step++);
                }
              },
        child: _isProcessing
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : Text(isLast
                ? (_paymentMethod == 'Razorpay'
                    ? 'Pay ₹${widget.appState.cartTotal.toInt()}'
                    : 'Place Order')
                : 'Continue'),
      ),
    );
  }
}
