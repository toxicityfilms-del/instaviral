const nodemailer = require('nodemailer');

/**
 * Gmail App Passwords are often pasted with spaces — Gmail expects 16 chars without spaces.
 */
function normalizeGmailAppPassword(pass) {
  return String(pass || '').replace(/\s+/g, '').trim();
}

/**
 * Read env (Gmail): EMAIL_USER, EMAIL_PASS, optional EMAIL_FROM / MAIL_FROM.
 * Custom SMTP: SMTP_HOST, SMTP_USER, SMTP_PASS, MAIL_FROM or EMAIL_FROM.
 */
function getMailerConfig() {
  const emailUser = String(process.env.EMAIL_USER || '').trim();
  const emailPassRaw = String(process.env.EMAIL_PASS || '').trim();
  const emailPass = emailPassRaw ? normalizeGmailAppPassword(emailPassRaw) : '';
  const fromOverride = String(process.env.EMAIL_FROM || process.env.MAIL_FROM || '').trim();

  if (emailUser && emailPass) {
    const port = Number(process.env.SMTP_PORT || 587);
    const secure = port === 465;
    const from = fromOverride || emailUser;
    return {
      configured: true,
      provider: 'gmail',
      host: 'smtp.gmail.com',
      port,
      secure,
      user: emailUser,
      pass: emailPass,
      from,
    };
  }

  const host = String(process.env.SMTP_HOST || '').trim();
  const port = Number(process.env.SMTP_PORT || 587);
  const user = String(process.env.SMTP_USER || '').trim();
  const pass = String(process.env.SMTP_PASS || '').trim();
  const from = fromOverride || user;

  const configured = !!(host && user && pass && from);
  return {
    configured,
    provider: 'smtp',
    host,
    port,
    secure: String(process.env.SMTP_SECURE || '').trim().toLowerCase() === 'true' || port === 465,
    user,
    pass,
    from,
  };
}

/** Which SMTP-related vars are missing (for logs only; never log secrets). */
function diagnoseSmtpEnvMissing() {
  const cfg = getMailerConfig();
  if (cfg.configured) return { mode: cfg.provider, missing: [] };

  const missing = [];
  const emailUser = String(process.env.EMAIL_USER || '').trim();
  const emailPassNorm = normalizeGmailAppPassword(String(process.env.EMAIL_PASS || '').trim());
  const host = String(process.env.SMTP_HOST || '').trim();
  const smtpUser = String(process.env.SMTP_USER || '').trim();
  const smtpPass = String(process.env.SMTP_PASS || '').trim();
  const from = String(process.env.EMAIL_FROM || process.env.MAIL_FROM || '').trim();

  if (emailUser && !emailPassNorm) missing.push('EMAIL_PASS');
  if (host) {
    if (!smtpUser) missing.push('SMTP_USER');
    if (!smtpPass) missing.push('SMTP_PASS');
    if (!from) missing.push('MAIL_FROM or EMAIL_FROM');
  }
  if (!emailUser && !host) missing.push('EMAIL_USER (Gmail) or SMTP_HOST');

  return { mode: 'none', missing: [...new Set(missing)] };
}

/**
 * Log once at startup + optional detail when sending fails.
 * Does not print passwords.
 */
function logSmtpEnvDiagnostics(context) {
  const diag = diagnoseSmtpEnvMissing();
  const gmailUserSet = !!String(process.env.EMAIL_USER || '').trim();
  const gmailPassSet = !!String(process.env.EMAIL_PASS || '').trim();
  const passLen = normalizeGmailAppPassword(String(process.env.EMAIL_PASS || '')).length;

  // eslint-disable-next-line no-console
  console.log(`[mail] env check (${context})`, {
    mode: diag.mode,
    missing: diag.missing.length ? diag.missing : undefined,
    EMAIL_USER_set: gmailUserSet,
    EMAIL_PASS_set: gmailPassSet,
    gmailAppPasswordCharCount: gmailPassSet ? passLen : undefined,
    EMAIL_FROM_or_MAIL_FROM_set: !!(process.env.EMAIL_FROM || process.env.MAIL_FROM),
    SMTP_HOST_set: !!String(process.env.SMTP_HOST || '').trim(),
    hint:
      diag.missing.length && diag.mode === 'none'
        ? 'For Gmail set EMAIL_USER + EMAIL_PASS (16-char App Password, not your normal password).'
        : undefined,
  });

  if (diag.missing.length && diag.mode === 'none') {
    // eslint-disable-next-line no-console
    console.error('[mail] SMTP not ready — missing:', diag.missing.join(', '));
  }

  if (gmailPassSet && passLen > 0 && passLen !== 16) {
    // eslint-disable-next-line no-console
    console.warn(
      '[mail] Gmail App Password is usually exactly 16 characters (spaces ignored). If send fails, regenerate an App Password in Google Account → Security → App passwords.'
    );
  }
}

function buildResetEmailContent({ resetLink, expiresMinutes }) {
  const subject = 'Reset your ReelBoost AI password';

  const text = [
    'Hi,',
    '',
    'We received a request to reset your ReelBoost AI password.',
    '',
    `Open this link to choose a new password (valid ${expiresMinutes} minutes):`,
    resetLink,
    '',
    'If you did not request this, you can ignore this email.',
    '',
    '— ReelBoost AI',
  ].join('\n');

  const safeLink = resetLink.replace(/&/g, '&amp;');

  const html = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8"/>
  <meta name="viewport" content="width=device-width,initial-scale=1"/>
  <title>${subject}</title>
</head>
<body style="margin:0;padding:0;background:#f4f6f8;font-family:Segoe UI,Roboto,Helvetica,Arial,sans-serif;">
  <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="background:#f4f6f8;padding:32px 12px;">
    <tr>
      <td align="center">
        <table role="presentation" width="100%" style="max-width:560px;background:#ffffff;border-radius:12px;overflow:hidden;box-shadow:0 4px 24px rgba(0,0,0,.06);">
          <tr>
            <td style="padding:28px 28px 8px 28px;">
              <p style="margin:0;font-size:13px;font-weight:700;letter-spacing:.06em;color:#0b84ff;">REELBOOST AI</p>
              <h1 style="margin:12px 0 0 0;font-size:22px;line-height:1.3;color:#111;">Password reset</h1>
              <p style="margin:16px 0 0 0;font-size:15px;line-height:1.55;color:#444;">
                We received a request to reset your password. Use the button below — it expires in
                <strong>${expiresMinutes} minutes</strong>.
              </p>
            </td>
          </tr>
          <tr>
            <td style="padding:8px 28px 24px 28px;">
              <a href="${safeLink}" style="display:inline-block;padding:14px 28px;background:#0b84ff;color:#ffffff;text-decoration:none;border-radius:8px;font-weight:600;font-size:15px;">
                Reset password
              </a>
            </td>
          </tr>
          <tr>
            <td style="padding:0 28px 28px 28px;">
              <p style="margin:0;font-size:13px;line-height:1.5;color:#666;">
                If the button does not work, copy and paste this link into your browser:
              </p>
              <p style="margin:8px 0 0 0;font-size:12px;word-break:break-all;color:#0b84ff;">
                <a href="${safeLink}" style="color:#0b84ff;">${safeLink}</a>
              </p>
              <p style="margin:20px 0 0 0;font-size:13px;line-height:1.5;color:#888;">
                If you did not request a reset, you can safely ignore this message.
              </p>
            </td>
          </tr>
        </table>
        <p style="margin:20px 0 0 0;font-size:12px;color:#aaa;">Sent by ReelBoost AI</p>
      </td>
    </tr>
  </table>
</body>
</html>`;

  return { subject, text, html };
}

function smtpErrorDetails(err) {
  return {
    name: err.name,
    code: err.code,
    command: err.command,
    responseCode: err.responseCode,
    message: err.message,
    response: err.response,
  };
}

/**
 * @returns {Promise<{ sent: true, messageId?: string } | { sent: false, reason: string, message?: string, smtp?: object }>}
 */
async function sendPasswordResetEmail({ to, resetLink, expiresMinutes }) {
  // eslint-disable-next-line no-console
  console.log('[mail] sendPasswordResetEmail: received', {
    to: String(to || '').trim(),
    resetLinkLength: String(resetLink || '').length,
    expiresMinutes,
  });

  const cfg = getMailerConfig();

  if (!cfg.configured) {
    logSmtpEnvDiagnostics('send blocked — not configured');
    return {
      sent: false,
      reason: 'smtp_not_configured',
      message: 'Email transport is not configured on the server.',
    };
  }

  const toAddr = String(to || '').trim().toLowerCase();
  if (!toAddr || !toAddr.includes('@')) {
    // eslint-disable-next-line no-console
    console.error('[mail] invalid recipient', { to: toAddr || '(empty)' });
    return { sent: false, reason: 'invalid_recipient', message: 'Invalid recipient email.' };
  }

  // eslint-disable-next-line no-console
  console.log('[mail] creating transporter', {
    provider: cfg.provider,
    host: cfg.host,
    port: cfg.port,
    secure: cfg.secure,
    authUser: cfg.user,
    from: cfg.from,
  });

  const transporter = nodemailer.createTransport({
    host: cfg.host,
    port: cfg.port,
    secure: cfg.secure,
    auth: { user: cfg.user, pass: cfg.pass },
    ...(cfg.provider === 'gmail' && cfg.port === 587
      ? { requireTLS: true, tls: { minVersion: 'TLSv1.2' } }
      : {}),
  });

  const verifyFirst = String(process.env.MAIL_VERIFY_BEFORE_SEND || '').trim().toLowerCase() === 'true';
  if (verifyFirst) {
    try {
      // eslint-disable-next-line no-console
      console.log('[mail] SMTP verify() starting…');
      await transporter.verify();
      // eslint-disable-next-line no-console
      console.log('[mail] SMTP verify() OK');
    } catch (verErr) {
      // eslint-disable-next-line no-console
      console.error('[mail] SMTP verify() failed', smtpErrorDetails(verErr));
      return {
        sent: false,
        reason: 'smtp_verify_failed',
        message: verErr.message || 'SMTP verify failed.',
        smtp: smtpErrorDetails(verErr),
      };
    }
  }

  const { subject, text, html } = buildResetEmailContent({ resetLink, expiresMinutes });

  // eslint-disable-next-line no-console
  console.log('[mail] sending via sendMail', { from: cfg.from, to: toAddr, subject });

  try {
    const info = await transporter.sendMail({
      from: cfg.from,
      to: toAddr,
      subject,
      text,
      html,
    });

    // eslint-disable-next-line no-console
    console.log('[mail] sendMail success', {
      messageId: info.messageId,
      accepted: info.accepted,
      rejected: info.rejected,
      response: info.response,
      to: toAddr,
    });

    return { sent: true, messageId: info.messageId };
  } catch (err) {
    // eslint-disable-next-line no-console
    console.error('[mail] sendMail failure', smtpErrorDetails(err));
    return {
      sent: false,
      reason: 'send_failed',
      message: err.message || 'SMTP rejected or dropped the message.',
      smtp: smtpErrorDetails(err),
    };
  }
}

module.exports = {
  sendPasswordResetEmail,
  getMailerConfig,
  logSmtpEnvDiagnostics,
  diagnoseSmtpEnvMissing,
};
