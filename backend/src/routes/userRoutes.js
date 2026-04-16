const { Router } = require('express');
const { body } = require('express-validator');
const { upgrade } = require('../controllers/userController');

const router = Router();

router.post('/upgrade', [body('userId').isString().trim().notEmpty()], upgrade);

module.exports = router;
