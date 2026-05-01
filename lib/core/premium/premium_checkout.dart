import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reelboost_ai/core/providers/app_providers.dart';
import 'package:reelboost_ai/services/payments/razorpay_payment_service.dart';

/// Play Store release: snackbar only — **no Razorpay**. Debug/sideload: Razorpay + `/user/upgrade`.
Future<void> attemptPremiumRazorpayCheckout(WidgetRef ref, BuildContext context) async {
  if (kReleaseMode) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Premium upgrade coming soon')),
    );
    return;
  }

  final current = ref.read(authControllerProvider).asData?.value;
  if (current == null) return;

  final payments = RazorpayPaymentService()..init();
  try {
    final result = await payments.buyPremium199(
      userId: current.id,
      email: current.email,
      name: current.name,
    );

    if (!context.mounted) return;

    if (result.status == PremiumPurchaseStatus.cancelled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment cancelled')),
      );
      return;
    }
    if (result.status == PremiumPurchaseStatus.failed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? 'Payment failed')),
      );
      return;
    }

    final pid = result.razorpayPaymentId?.trim() ?? '';
    final oid = result.razorpayOrderId?.trim() ?? '';
    final sig = result.razorpaySignature?.trim() ?? '';
    if (pid.isEmpty || oid.isEmpty || sig.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Payment succeeded but verification data is missing. '
            'Use a Razorpay order created by your server, or set DEV_ALLOW_PREMIUM_UPGRADE on the API for QA.',
          ),
        ),
      );
      return;
    }

    final user = await ref.read(reelboostApiProvider).upgradeAfterRazorpayPayment(
      razorpayOrderId: oid,
      razorpayPaymentId: pid,
      razorpaySignature: sig,
    );
    if (!context.mounted) return;
    ref.read(authControllerProvider.notifier).applyUser(user);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('You are now Premium')),
    );
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment or upgrade failed: $e')),
    );
  } finally {
    payments.dispose();
  }
}
