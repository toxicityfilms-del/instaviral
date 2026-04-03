const { Router } = require('express');
const { body } = require('express-validator');
const { createOrder, verifyPayment } = require('../controllers/paymentController');

const router = Router();

router.post('/razorpay/create-order', createOrder);

router.post(
  '/razorpay/verify',
  [
    body('razorpay_order_id').isString().trim().notEmpty(),
    body('razorpay_payment_id').isString().trim().notEmpty(),
    body('razorpay_signature').isString().trim().notEmpty(),
  ],
  verifyPayment
);

module.exports = router;
