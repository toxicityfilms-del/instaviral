require('dotenv').config();
const express = require('express');
const cors = require('cors');
const { connectDb } = require('./config/db');
const { authMiddleware } = require('./middleware/authMiddleware');
const { errorHandler } = require('./middleware/errorHandler');
const { requirePremium } = require('./middleware/requirePremium');
const { startTrendAlertScheduler } = require('./services/trendAlertScheduler');
const { initFirebaseAdmin } = require('./services/notificationService');
const { triggerTrendingDigest } = require('./controllers/adminController');

const authRoutes = require('./routes/authRoutes');
const userRoutes = require('./routes/userRoutes');
const paymentRoutes = require('./routes/paymentRoutes');
const hashtagRoutes = require('./routes/hashtagRoutes');
const captionRoutes = require('./routes/captionRoutes');
const ideasRoutes = require('./routes/ideasRoutes');
const viralRoutes = require('./routes/viralRoutes');
const trendsRoutes = require('./routes/trendsRoutes');

const app = express();
const port = process.env.PORT || 3000;

app.use(
  cors({
    origin: true,
    credentials: true,
  })
);
app.use(express.json({ limit: '1mb' }));

app.get('/health', (req, res) => {
  res.json({ ok: true, service: 'reelboost-ai-api' });
});

app.use('/auth', authRoutes);

app.use('/users', authMiddleware, userRoutes);
app.use('/payments', authMiddleware, paymentRoutes);

app.use('/hashtag', authMiddleware, requirePremium, hashtagRoutes);
app.use('/caption', authMiddleware, requirePremium, captionRoutes);
app.use('/ideas', authMiddleware, requirePremium, ideasRoutes);

app.use('/viral', authMiddleware, viralRoutes);
app.use('/trends', authMiddleware, trendsRoutes);

app.post('/admin/trending-digest', triggerTrendingDigest);

app.use(errorHandler);

async function start() {
  await connectDb();
  initFirebaseAdmin();
  startTrendAlertScheduler();
  app.listen(port, () => {
    // eslint-disable-next-line no-console
    console.log(`ReelBoost AI API listening on http://localhost:${port}`);
  });
}

start().catch((err) => {
  // eslint-disable-next-line no-console
  console.error('Failed to start server', err);
  process.exit(1);
});
