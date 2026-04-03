const { Router } = require('express');
const { body } = require('express-validator');
const { signup, login } = require('../controllers/authController');

const router = Router();

router.post(
  '/signup',
  [
    body('email').isEmail().normalizeEmail(),
    body('password').isLength({ min: 8 }).withMessage('Password must be at least 8 characters'),
    body('name').optional().isString().trim(),
  ],
  signup
);

router.post(
  '/login',
  [body('email').isEmail().normalizeEmail(), body('password').notEmpty()],
  login
);

module.exports = router;
