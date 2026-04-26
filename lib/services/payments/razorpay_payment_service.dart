import 'dart:async';

import 'package:razorpay_flutter/razorpay_flutter.dart';

enum PremiumPurchaseStatus { success, cancelled, failed }

/// Razorpay checkout only (debug / non–Play-Store builds). Release store builds should use Play Billing.
class PremiumPurchaseResult {
  const PremiumPurchaseResult._(
    this.status, {
    this.message,
    this.razorpayPaymentId,
    this.razorpayOrderId,
    this.razorpaySignature,
  });

  final PremiumPurchaseStatus status;
  final String? message;
  final String? razorpayPaymentId;
  final String? razorpayOrderId;
  final String? razorpaySignature;

  static PremiumPurchaseResult success({
    String? razorpayPaymentId,
    String? razorpayOrderId,
    String? razorpaySignature,
  }) =>
      PremiumPurchaseResult._(
        PremiumPurchaseStatus.success,
        razorpayPaymentId: razorpayPaymentId,
        razorpayOrderId: razorpayOrderId,
        razorpaySignature: razorpaySignature,
      );

  static PremiumPurchaseResult cancelled([String? message]) =>
      PremiumPurchaseResult._(PremiumPurchaseStatus.cancelled, message: message);

  static PremiumPurchaseResult failed([String? message]) =>
      PremiumPurchaseResult._(PremiumPurchaseStatus.failed, message: message);
}

/// Razorpay checkout (development / sideloaded APKs only — not used in Play release).
class RazorpayPaymentService {
  RazorpayPaymentService({String? razorpayKey})
      : _razorpayKey = (razorpayKey ?? _defaultKey).trim();

  static const String _defaultKey = 'rzp_test_your_key_here';

  final String _razorpayKey;
  Razorpay? _razorpay;
  Completer<PremiumPurchaseResult>? _completer;

  void init() {
    final rz = Razorpay();
    rz.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
    rz.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
    rz.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);
    _razorpay = rz;
  }

  void dispose() {
    _razorpay?.clear();
    _razorpay = null;
    _completer = null;
  }

  bool get _ready => _razorpay != null && _razorpayKey.isNotEmpty;

  Future<PremiumPurchaseResult> buyPremium199({
    required String userId,
    required String email,
    required String name,
  }) async {
    if (!_ready) {
      return PremiumPurchaseResult.failed('Payment not initialized.');
    }
    if (_completer != null && !(_completer?.isCompleted ?? true)) {
      return PremiumPurchaseResult.failed('Payment already in progress.');
    }

    final c = Completer<PremiumPurchaseResult>();
    _completer = c;

    final options = <String, dynamic>{
      'key': _razorpayKey,
      'amount': 19900,
      'name': 'ReelBoost AI',
      'description': 'Premium Upgrade ₹199',
      'prefill': {'email': email, 'name': name},
      'notes': {'userId': userId},
      'theme': {'color': '#7C3AED'},
    };

    try {
      _razorpay!.open(options);
    } catch (e) {
      _completeIfNeeded(PremiumPurchaseResult.failed('Payment init failed: $e'));
    }

    return c.future;
  }

  void _completeIfNeeded(PremiumPurchaseResult result) {
    final comp = _completer;
    if (comp == null || comp.isCompleted) return;
    comp.complete(result);
  }

  void _onPaymentSuccess(PaymentSuccessResponse response) {
    _completeIfNeeded(
      PremiumPurchaseResult.success(
        razorpayPaymentId: response.paymentId,
        razorpayOrderId: response.orderId,
        razorpaySignature: response.signature,
      ),
    );
  }

  void _onPaymentError(PaymentFailureResponse response) {
    final code = response.code;
    final msg = response.message;
    final lower = (msg ?? '').toLowerCase();
    final isCancel = code == 2 || lower.contains('cancel');
    if (isCancel) {
      _completeIfNeeded(PremiumPurchaseResult.cancelled('Payment cancelled.'));
      return;
    }
    _completeIfNeeded(
      PremiumPurchaseResult.failed(msg ?? 'Payment failed ($code).'),
    );
  }

  void _onExternalWallet(ExternalWalletResponse response) {
    _completeIfNeeded(
      PremiumPurchaseResult.failed(
        'External wallet selected: ${response.walletName ?? 'wallet'}.',
      ),
    );
  }
}
