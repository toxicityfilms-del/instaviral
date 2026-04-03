const dns = require('dns');
const mongoose = require('mongoose');

// Prefer IPv4 first — helps some Windows / DNS setups.
if (typeof dns.setDefaultResultOrder === 'function') {
  dns.setDefaultResultOrder('ipv4first');
}

// Optional: comma-separated DNS servers (e.g. 8.8.8.8,1.1.1.1) when SRV lookups fail with querySrv ECONNREFUSED.
const mongoDns = process.env.MONGO_DNS_SERVERS;
if (mongoDns) {
  const servers = mongoDns.split(',').map((s) => s.trim()).filter(Boolean);
  if (servers.length) {
    dns.setServers(servers);
    // eslint-disable-next-line no-console
    console.log('[mongo] Using MONGO_DNS_SERVERS for SRV resolution');
  }
}

/** Log target without user/password (host after @, or path after scheme). */
function mongoTargetForLog(uri) {
  if (!uri || typeof uri !== 'string') return '(missing)';
  const u = uri.trim();
  const at = u.indexOf('@');
  if (at !== -1) {
    return u.slice(at + 1).split('?')[0] || '(unknown host)';
  }
  const m = u.match(/^mongodb(\+srv)?:\/\/(.+)$/i);
  if (m && m[2]) {
    return m[2].split('?')[0];
  }
  return '(redacted)';
}

function logMongoError(prefix, err) {
  const payload = {
    message: err?.message || String(err),
    name: err?.name,
    code: err?.code,
  };
  if (err?.reason) {
    payload.reason = err.reason?.message || String(err.reason);
  }
  // eslint-disable-next-line no-console
  console.error(`[mongo] ${prefix}`, payload);
  if (process.env.NODE_ENV !== 'production' && err?.stack) {
    // eslint-disable-next-line no-console
    console.error('[mongo] stack:', err.stack);
  }
}

let _eventsRegistered = false;

function registerConnectionLifecycleLogging() {
  if (_eventsRegistered) return;
  _eventsRegistered = true;

  mongoose.connection.on('connected', () => {
    // eslint-disable-next-line no-console
    console.log('[mongo] mongoose connected event');
  });

  mongoose.connection.on('error', (err) => {
    logMongoError('connection runtime error', err);
  });

  mongoose.connection.on('disconnected', () => {
    // eslint-disable-next-line no-console
    console.warn('[mongo] disconnected (network or server closed connection)');
  });

  mongoose.connection.on('reconnected', () => {
    // eslint-disable-next-line no-console
    console.log('[mongo] reconnected');
  });

  mongoose.connection.on('close', () => {
    // eslint-disable-next-line no-console
    console.warn('[mongo] connection closed');
  });
}

async function connectDb() {
  const uri = process.env.MONGO_URI;
  if (!uri || !uri.trim()) {
    const err = new Error('MONGO_URI is not set');
    logMongoError('configuration', err);
    throw err;
  }

  const target = mongoTargetForLog(uri.trim());
  // eslint-disable-next-line no-console
  console.log('[mongo] connecting…', { target });

  mongoose.set('strictQuery', true);
  registerConnectionLifecycleLogging();

  try {
    await mongoose.connect(uri.trim(), {
      serverSelectionTimeoutMS: 15_000,
      socketTimeoutMS: 45_000,
      maxPoolSize: 10,
    });
    // eslint-disable-next-line no-console
    console.log('[mongo] ready', {
      target,
      readyState: mongoose.connection.readyState,
      name: mongoose.connection.name,
    });
  } catch (err) {
    logMongoError('initial connection failed', err);
    // eslint-disable-next-line no-console
    console.error('[mongo] fix: check MONGO_URI, Atlas IP allowlist (0.0.0.0/0 for Railway), credentials, and cluster status');
    throw err;
  }
}

module.exports = { connectDb };
