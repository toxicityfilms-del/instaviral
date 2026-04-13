const bcrypt = require('bcryptjs');
const crypto = require('crypto');
const jwt = require('jsonwebtoken');
const mongoose = require('mongoose');
const { validationResult } = require('express-validator');
const User = require('../models/User');
const { buildPostAnalyzeUsageMeta } = require('../services/usageService');
const { sendPasswordResetEmail } = require('../services/mailService');

function signToken(userId) {
  const secret = String(process.env.JWT_SECRET || '').trim();
  if (!secret) {
    const err = new Error(
      'Server misconfiguration: JWT_SECRET is not set. Add JWT_SECRET in Railway (or .env) and redeploy.'
    );
    err.status = 503;
    throw err;
  }
  const expiresIn = process.env.JWT_EXPIRES_IN || '7d';
  return jwt.sign({ sub: userId }, secret, { expiresIn });
}

function dbUnavailableResponse(res) {
  return res.status(503).json({
    success: false,
    code: 'DB_UNAVAILABLE',
    message:
      'Database is not connected. Set MONGO_URI on the server (Railway Variables) and ensure Atlas allows Railway IPs.',
  });
}

function userPayload(user) {
  const usage = buildPostAnalyzeUsageMeta(user);
  return {
    id: user._id != null ? String(user._id) : user._id,
    email: user.email,
    name: user.name || '',
    bio: user.bio || '',
    instagramLink: user.instagramLink || '',
    facebookLink: user.facebookLink || '',
    tiktokLink: user.tiktokLink || '',
    niche: user.niche || '',
    isPremium: usage.isPremium,
    postAnalyzeLimit: usage.postAnalyzeLimit,
    postAnalyzeRemaining: usage.postAnalyzeRemaining,
    postAnalyzeAdRewardsRemaining: usage.postAnalyzeAdRewardsRemaining,
    adRewardAnalytics: usage.adRewardAnalytics,
    adRewardSuspiciousFlag: usage.adRewardSuspiciousFlag,
    adRewardsBlockedSuspicious: usage.adRewardsBlockedSuspicious,
    invalidAdCompletionCountToday: usage.invalidAdCompletionCountToday,
  };
}

async function signup(req, res, next) {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ success: false, errors: errors.array() });
    }
    if (mongoose.connection.readyState !== 1) {
      return dbUnavailableResponse(res);
    }
    const { email, password, name } = req.body;
    const existing = await User.findOne({ email });
    if (existing) {
      return res.status(409).json({ success: false, message: 'Email already registered' });
    }
    const passwordHash = await bcrypt.hash(password, 12);
    const user = await User.create({
      email,
      passwordHash,
      name: name || '',
    });
    const token = signToken(user._id.toString());
    return res.status(201).json({
      success: true,
      token,
      user: userPayload(user),
    });
  } catch (e) {
    return next(e);
  }
}

async function login(req, res, next) {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ success: false, errors: errors.array() });
    }
    if (mongoose.connection.readyState !== 1) {
      return dbUnavailableResponse(res);
    }
    const { email, password } = req.body;
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(401).json({ success: false, message: 'Invalid email or password' });
    }
    if (!user.passwordHash || typeof user.passwordHash !== 'string') {
      return res.status(401).json({ success: false, message: 'Invalid email or password' });
    }
    const ok = await bcrypt.compare(password, user.passwordHash);
    if (!ok) {
      return res.status(401).json({ success: false, message: 'Invalid email or password' });
    }
    const token = signToken(user._id.toString());
    return res.json({
      success: true,
      token,
      user: userPayload(user),
    });
  } catch (e) {
    return next(e);
  }
}

function resetTokenTtlMinutes() {
  const ttl = Number(process.env.PASSWORD_RESET_TTL_MINUTES || 20);
  if (Number.isNaN(ttl) || ttl < 15) return 15;
  if (ttl > 30) return 30;
  return ttl;
}

/**
 * Full URL base for the reset link in emails.
 * - Prefer PASSWORD_RESET_BASE_URL (any HTTPS page that handles ?token=)
 * - Else PUBLIC_BASE_URL + /api/auth/reset-password-page (built-in form on this API)
 */
function resolveResetLinkBase() {
  const direct = (process.env.PASSWORD_RESET_BASE_URL || '').trim().replace(/\/$/, '');
  if (direct) return direct;
  const pub = (process.env.PUBLIC_BASE_URL || '').trim().replace(/\/$/, '');
  if (pub) return `${pub}/api/auth/reset-password-page`;
  return '';
}

function buildResetLink(rawToken) {
  const base = resolveResetLinkBase();
  if (!base) return '';
  const sep = base.includes('?') ? '&' : '?';
  return `${base}${sep}token=${encodeURIComponent(rawToken)}`;
}

function escapeHtml(s) {
  return String(s)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

/** Browser page: open from email link, POSTs new password to /api/auth/reset-password */
function getResetPasswordPage(req, res) {
  const token = String(req.query.token || '').trim();
  res.set('Cache-Control', 'no-store');
  res.set('Content-Type', 'text/html; charset=utf-8');

  if (!token || token.length < 16) {
    return res.status(400).send(`<!DOCTYPE html><html><head><meta charset="utf-8"/><title>Invalid link</title></head>
<body style="font-family:system-ui;padding:24px"><p>Invalid or missing reset link. Request a new reset from the app.</p></body></html>`);
  }

  const safe = escapeHtml(token);
  const html = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8"/>
  <meta name="viewport" content="width=device-width,initial-scale=1"/>
  <title>ReelBoost — reset password</title>
  <style>
    body{font-family:system-ui,-apple-system,sans-serif;max-width:420px;margin:32px auto;padding:0 16px;color:#111}
    h1{font-size:1.25rem}
    label{display:block;margin:12px 0 6px;font-weight:600}
    input{width:100%;box-sizing:border-box;padding:10px 12px;border:1px solid #ccc;border-radius:8px;font-size:16px}
    button{margin-top:16px;width:100%;padding:12px;border:0;border-radius:8px;background:#0b84ff;color:#fff;font-weight:600;font-size:16px;cursor:pointer}
    button:disabled{opacity:.6;cursor:not-allowed}
    #msg{margin-top:16px;padding:12px;border-radius:8px;display:none}
    #msg.err{background:#ffe8e8;color:#8b0000}
    #msg.ok{background:#e8ffe8;color:#064e06}
  </style>
</head>
<body>
  <h1>Set a new password</h1>
  <p>Choose a new password (at least 8 characters). Then sign in again in the app.</p>
  <form id="f">
    <label for="p">New password</label>
    <input id="p" type="password" name="password" minlength="8" required autocomplete="new-password"/>
    <button type="submit" id="btn">Update password</button>
  </form>
  <div id="msg"></div>
  <input type="hidden" id="tok" value="${safe}"/>
  <script>
  (function(){
    var form=document.getElementById('f');
    var msg=document.getElementById('msg');
    var btn=document.getElementById('btn');
    form.addEventListener('submit',async function(e){
      e.preventDefault();
      msg.style.display='none';
      btn.disabled=true;
      try{
        var r=await fetch('/api/auth/reset-password',{
          method:'POST',
          headers:{'Content-Type':'application/json'},
          body:JSON.stringify({token:document.getElementById('tok').value,password:document.getElementById('p').value})
        });
        var data=await r.json().catch(function(){return {};});
        if(r.ok&&data.success){
          msg.className='ok';
          msg.textContent=data.message||'Password updated. You can close this page and open the app to log in.';
          msg.style.display='block';
          form.style.display='none';
        }else{
          msg.className='err';
          msg.textContent=(data&&data.message)||'Something went wrong. Try requesting a new reset link.';
          msg.style.display='block';
        }
      }catch(err){
        msg.className='err';
        msg.textContent='Network error. Check your connection and try again.';
        msg.style.display='block';
      }
      btn.disabled=false;
    });
  })();
  </script>
</body>
</html>`;
  return res.send(html);
}

const FORGOT_PASSWORD_GENERIC_MESSAGE =
  'If an account with that email exists, a reset link has been sent.';

async function forgotPassword(req, res, next) {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ success: false, errors: errors.array() });
    }
    if (mongoose.connection.readyState !== 1) {
      return dbUnavailableResponse(res);
    }

    const email = String(req.body.email || '').trim().toLowerCase();
    const genericResponse = { success: true, message: FORGOT_PASSWORD_GENERIC_MESSAGE };

    const user = await User.findOne({ email });
    if (!user) {
      return res.status(200).json(genericResponse);
    }

    const rawToken = crypto.randomBytes(32).toString('hex');
    const tokenHash = crypto.createHash('sha256').update(rawToken).digest('hex');
    const ttl = resetTokenTtlMinutes();
    const now = Date.now();
    const expiresAt = new Date(now + ttl * 60 * 1000);

    user.passwordResetTokenHash = tokenHash;
    user.passwordResetIssuedAt = new Date(now);
    user.passwordResetExpiresAt = expiresAt;
    await user.save();

    const resetLink = buildResetLink(rawToken);
    if (!resetLink) {
      // eslint-disable-next-line no-console
      console.error(
        '[auth] forgot-password: reset link URL missing — set PUBLIC_BASE_URL or PASSWORD_RESET_BASE_URL'
      );
      return res.status(200).json(genericResponse);
    }

    const mailOutcome = await sendPasswordResetEmail({
      to: user.email,
      resetLink,
      expiresMinutes: ttl,
    });

    if (!mailOutcome.sent) {
      // eslint-disable-next-line no-console
      console.error('[auth] forgot-password: mail not sent', { reason: mailOutcome.reason });
      return res.status(200).json(genericResponse);
    }

    return res.status(200).json(genericResponse);
  } catch (e) {
    return next(e);
  }
}

async function resetPassword(req, res, next) {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ success: false, errors: errors.array() });
    }
    if (mongoose.connection.readyState !== 1) {
      return dbUnavailableResponse(res);
    }
    const token = String(req.body.token || '').trim();
    const password = String(req.body.password || '');
    const tokenHash = crypto.createHash('sha256').update(token).digest('hex');

    const user = await User.findOne({
      passwordResetTokenHash: tokenHash,
      passwordResetExpiresAt: { $gt: new Date() },
    });
    if (!user) {
      return res.status(400).json({
        success: false,
        message: 'Invalid or expired reset token',
      });
    }

    user.passwordHash = await bcrypt.hash(password, 12);
    user.passwordResetTokenHash = '';
    user.passwordResetIssuedAt = null;
    user.passwordResetExpiresAt = null;
    await user.save();

    return res.json({
      success: true,
      message: 'Password updated successfully. Please log in with your new password.',
    });
  } catch (e) {
    return next(e);
  }
}

module.exports = { signup, login, forgotPassword, resetPassword, getResetPasswordPage };
