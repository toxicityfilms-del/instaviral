/**
 * Razorpay order creation (expand with real keys).
 * Requires: RAZORPAY_KEY_ID, RAZORPAY_KEY_SECRET
 */
async function createOrderStub(amountPaise, receipt) {
  const id = process.env.RAZORPAY_KEY_ID;
  const secret = process.env.RAZORPAY_KEY_SECRET;
  if (!id || !secret) {
    const err = new Error('Razorpay is not configured');
    err.status = 503;
    throw err;
  }
  // Optional: use official razorpay npm package for production
  // const Razorpay = require('razorpay');
  // const rzp = new Razorpay({ key_id: id, key_secret: secret });
  // return rzp.orders.create({ amount: amountPaise, currency: 'INR', receipt });
  return {
    keyId: id,
    amount: amountPaise,
    currency: 'INR',
    receipt,
    message: 'Wire razorpay package in razorpayService for live orders',
  };
}

module.exports = { createOrderStub };
