const cron = require('node-cron');
const { sendTrendingDigest } = require('./notificationService');

let job;

function startTrendAlertScheduler() {
  const expr = process.env.TREND_ALERT_CRON;
  if (!expr) {
    return;
  }
  if (job) {
    return;
  }
  job = cron.schedule(
    expr,
    () => {
      sendTrendingDigest().catch((e) => {
        // eslint-disable-next-line no-console
        console.error('Trend alert job failed', e);
      });
    },
    { timezone: process.env.TREND_ALERT_TZ || 'Asia/Kolkata' }
  );
  // eslint-disable-next-line no-console
  console.log(`Trend alert scheduler enabled: ${expr} (${process.env.TREND_ALERT_TZ || 'Asia/Kolkata'})`);
}

module.exports = { startTrendAlertScheduler };
