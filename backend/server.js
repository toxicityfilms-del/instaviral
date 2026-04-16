/**
 * ReelBoost API — entry: `npm start` → `node server.js`
 *
 * Railway: set Root Directory to `backend` (if repo is monorepo). In Railway Variables add at least
 * MONGO_URI, JWT_SECRET, OPENAI_API_KEY. Railway injects PORT — do not set PORT manually unless needed.
 * Health check path: GET /health
 *
 * Forgot-password: EMAIL_USER + EMAIL_PASS (Gmail App Password), optional EMAIL_FROM; plus
 * PUBLIC_BASE_URL or PASSWORD_RESET_BASE_URL for the reset link.
 *
 * Local / LAN: HOST defaults to 0.0.0.0; use ipconfig IPv4 on the phone for http://<IP>:PORT/api
 */
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '.env') });

const express = require('express');
const cors = require('cors');
const mongoose = require('mongoose');
const { connectDb } = require('./src/config/db');
const { logSmtpEnvDiagnostics } = require('./src/services/mailService');
const { authMiddleware } = require('./src/middleware/authMiddleware');
const { adminMiddleware } = require('./src/middleware/adminMiddleware');
const { errorHandler } = require('./src/middleware/errorHandler');

const authRoutes = require('./src/routes/authRoutes');
const hashtagRoutes = require('./src/routes/hashtagRoutes');
const captionRoutes = require('./src/routes/captionRoutes');
const ideasRoutes = require('./src/routes/ideasRoutes');
const viralRoutes = require('./src/routes/viralRoutes');
const trendsRoutes = require('./src/routes/trendsRoutes');
const profileRoutes = require('./src/routes/profileRoutes');
const postRoutes = require('./src/routes/postRoutes');
const usageRoutes = require('./src/routes/usageRoutes');
const adminRoutes = require('./src/routes/adminRoutes');
const userRoutes = require('./src/routes/userRoutes');

const app = express();

if (process.env.NODE_ENV === 'production') {
  app.set('trust proxy', 1);
}

// Railway sets PORT; local dev falls back to 3000
const port = Number(process.env.PORT) || 3000;
const host = process.env.HOST || '0.0.0.0';

const corsOriginsEnv = (process.env.CORS_ORIGINS || '').trim();
const corsAllowlist =
  corsOriginsEnv.length > 0
    ? corsOriginsEnv.split(',').map((s) => s.trim()).filter(Boolean)
    : null;

function corsOriginDelegate(origin, callback) {
  if (!corsAllowlist) {
    callback(null, true);
    return;
  }
  if (!origin) {
    callback(null, true);
    return;
  }
  callback(null, corsAllowlist.includes(origin));
}

const corsOptions = {
  origin: corsOriginDelegate,
  credentials: true,
  methods: ['GET', 'HEAD', 'PUT', 'PATCH', 'POST', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'ngrok-skip-browser-warning'],
  exposedHeaders: ['X-RateLimit-Limit', 'X-RateLimit-Remaining', 'Retry-After'],
};
app.use(cors(corsOptions));
app.options('*', cors(corsOptions));
app.use(express.json({ limit: '15mb' }));

// Root — quick browser check (Railway public URL open karke verify)
app.get('/', (req, res) => {
  res.set('Content-Type', 'text/plain; charset=utf-8');
  res.send('Backend is Live 🚀');
});

// Railway / load balancer liveness (keep minimal JSON for health checks)
app.get('/health', (req, res) => {
  res.set('Cache-Control', 'no-store');
  res.json({ ok: true });
});

// Optional: detailed readiness (DB) for your own monitoring — not required by Railway
app.get('/health/ready', (req, res) => {
  const dbOk = mongoose.connection.readyState === 1;
  res.set('Cache-Control', 'no-store');
  res.status(dbOk ? 200 : 503).json({
    ok: dbOk,
    service: 'reelboost-ai-api',
    db: dbOk,
  });
});

app.post('/analyze', (req, res) => {
  const caption = String(req.body?.caption || '').trim();
  if (!caption) {
    return res.status(400).json({
      success: false,
      message: 'caption is required',
    });
  }
  return res.json({
    success: true,
    audioSuggestion: 'sample song',
  });
});

app.use('/api/auth', authRoutes);

app.use('/api/admin', adminMiddleware, adminRoutes);

app.use('/api/profile', authMiddleware, profileRoutes);

app.use('/api/post', authMiddleware, postRoutes);

app.use('/api/usage', authMiddleware, usageRoutes);
app.use('/api/user', authMiddleware, userRoutes);

app.use('/api/hashtag', authMiddleware, hashtagRoutes);
app.use('/api/caption', authMiddleware, captionRoutes);
app.use('/api/ideas', authMiddleware, ideasRoutes);
app.use('/api/viral', authMiddleware, viralRoutes);
app.use('/api/trends', authMiddleware, trendsRoutes);

app.use(errorHandler);

async function start() {
  // eslint-disable-next-line no-console
  console.log('NEW_DEPLOY_CHECK_14APR');
  await new Promise((resolve, reject) => {
    const server = app.listen(port, host, () => {
      // eslint-disable-next-line no-console
      console.log(`ReelBoost AI API listening on http://${host}:${port}`);
      resolve();
    });
    server.on('error', reject);
  });

  try {
    await connectDb();
  } catch {
    // Details already logged in src/config/db.js
    // eslint-disable-next-line no-console
    console.warn('[server] HTTP up without MongoDB — fix MONGO_URI and redeploy / restart');
  }

  if (!String(process.env.JWT_SECRET || '').trim()) {
    // eslint-disable-next-line no-console
    console.error(
      '[server] JWT_SECRET is empty — POST /api/auth/login and /signup will fail. Set JWT_SECRET in Railway Variables (e.g. openssl rand -hex 32).'
    );
  }

  logSmtpEnvDiagnostics('startup');

  // eslint-disable-next-line no-console
  console.log('[server] EXPOSE_RESET_LINK_ON_MAIL_FAILURE', {
    raw: process.env.EXPOSE_RESET_LINK_ON_MAIL_FAILURE ?? '(unset)',
    strictEqualsTrue: process.env.EXPOSE_RESET_LINK_ON_MAIL_FAILURE === 'true',
  });

  const gmailOk =
    String(process.env.EMAIL_USER || '').trim() && String(process.env.EMAIL_PASS || '').trim();
  const legacySmtpOk =
    String(process.env.SMTP_HOST || '').trim() &&
    String(process.env.SMTP_USER || '').trim() &&
    String(process.env.SMTP_PASS || '').trim() &&
    String(process.env.MAIL_FROM || process.env.EMAIL_FROM || '').trim();
  const smtpOk = gmailOk || legacySmtpOk;
  const resetBase =
    String(process.env.PASSWORD_RESET_BASE_URL || '').trim() ||
    String(process.env.PUBLIC_BASE_URL || '').trim();
  if (!smtpOk) {
    // eslint-disable-next-line no-console
    console.warn(
      '[server] Mail not configured — set EMAIL_USER + EMAIL_PASS (Gmail App Password) or full SMTP_* + MAIL_FROM for forgot-password emails.'
    );
  }
  if (!resetBase) {
    // eslint-disable-next-line no-console
    console.warn(
      '[server] Set PUBLIC_BASE_URL=https://<your-api-host> (or PASSWORD_RESET_BASE_URL) so reset emails contain a working link.'
    );
  }
}

start().catch((err) => {
  // eslint-disable-next-line no-console
  console.error('Failed to bind HTTP server:', err);
  process.exit(1);
});
