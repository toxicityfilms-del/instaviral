const { Router } = require('express');
const { body } = require('express-validator');
const { getMe, patchMe, registerFcmToken } = require('../controllers/userController');

const router = Router();

router.get('/me', getMe);

router.patch(
  '/me',
  [body('trendAlertsEnabled').optional().isBoolean()],
  patchMe
);

router.post(
  '/fcm-token',
  [body('token').isString().trim().notEmpty()],
  registerFcmToken
);

module.exports = router;
