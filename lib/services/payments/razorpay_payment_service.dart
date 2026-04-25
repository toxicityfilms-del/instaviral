import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:reelboost_ai/services/api_service.dart';

enum PremiumPurchaseStatus { success, cancelled, failed }

class PremiumPurchaseResult {
  const PremiumPurchaseResult._(this.status, {this.message});

  final PremiumPurchaseStatus status;
  final String? message;

  static PremiumPurchaseResult success() =>
      const PremiumPurchaseResult._(PremiumPurchaseStatus.success);
  static PremiumPurchaseResult cancelled([String? message]) =>
      PremiumPurchaseResult._(PremiumPurchaseStatus.cancelled, message: message);
  static PremiumPurchaseResult failed([String? message]) =>
      PremiumPurchaseResult._(PremiumPurchaseStatus.failed, message: message);
}

/// Razorpay checkout + backend upgrade call (`POST /api/user/upgrade`).
///
/// Usage:
/// - Create once (e.g. in `initState`)
/// - Call [buyPremium199] to open Razorpay
/// - Dispose in `dispose()`
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
      'amount': 19900, // ₹199 in paise
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

  Future<bool> upgradeUserOnBackend({required String userId}) async {
    final uri = Uri.parse('${ApiService.baseUrl}/user/upgrade');
    final res = await http.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId}),
    );
    return res.statusCode >= 200 && res.statusCode < 300;
  }

  void _completeIfNeeded(PremiumPurchaseResult result) {
    final c = _completer;
    if (c == null || c.isCompleted) return;
    c.complete(result);
  }

  void _onPaymentSuccess(PaymentSuccessResponse response) {
    _completeIfNeeded(PremiumPurchaseResult.success());
  }

  void _onPaymentError(PaymentFailureResponse response) {
    final code = response.code;
    final msg = response.message;
    // Treat “cancel” as a distinct outcome for better UX.
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

