// قدّها · admin → GitHub proxy (Vercel serverless function).
// The admin page logs in with a Gaddha account (Supabase). This function checks that the
// account is an admin (public.is_admin()), then calls the GitHub API with a server-side token.
// The GitHub token lives only in Vercel → Project → Settings → Environment Variables → GITHUB_TOKEN.
// Only this repository's contents and git-data endpoints are allowed.

const OWNER = 'ZaidShalbak', REPO = 'gaddha';
const SB_URL = process.env.SUPABASE_URL || 'https://nxhlmlgcveokoqdegqaa.supabase.co';
const SB_KEY = process.env.SUPABASE_PUBLISHABLE_KEY || 'sb_publishable_BOPfNiIHdUXjHLcDvhhCpg_TpWjTNtx';
const ALLOWED = new RegExp(`^/repos/${OWNER}/${REPO}/(contents/|git/(ref|refs|commits|trees|blobs)(/|$|\\?))`);

module.exports = async (req, res) => {
  res.setHeader('Cache-Control', 'no-store');
  const gh = process.env.GITHUB_TOKEN;
  if (!gh) return res.status(500).json({ message: 'GITHUB_TOKEN is not set in Vercel', code: 'no_token' });

  const jwt = String(req.headers.authorization || '').replace(/^Bearer\s+/i, '');
  if (!jwt) return res.status(401).json({ message: 'login required', code: 'login' });

  // is this logged-in account an admin? (the RPC runs as the user, using their own token)
  let isAdmin = false;
  try {
    const r = await fetch(`${SB_URL}/rest/v1/rpc/is_admin`, {
      method: 'POST',
      headers: { apikey: SB_KEY, Authorization: `Bearer ${jwt}`, 'Content-Type': 'application/json' },
      body: '{}'
    });
    if (r.status === 401) return res.status(401).json({ message: 'session expired', code: 'login' });
    isAdmin = r.ok && (await r.json()) === true;
  } catch (e) {
    return res.status(502).json({ message: 'could not reach Supabase', code: 'supabase' });
  }
  if (!isAdmin) return res.status(403).json({ message: 'not an admin', code: 'not_admin' });

  const p = String((req.query && req.query.p) || '');
  if (!ALLOWED.test(p) || /\.\.|%2e|\/\/|\\/i.test(p)) return res.status(400).json({ message: 'path not allowed', code: 'path' });
  if (!['GET', 'POST', 'PATCH'].includes(req.method)) return res.status(405).json({ message: 'method not allowed' });

  let body;
  if (req.method !== 'GET') body = typeof req.body === 'string' ? req.body : JSON.stringify(req.body || {});

  const g = await fetch('https://api.github.com' + p, {
    method: req.method,
    headers: {
      Authorization: `Bearer ${gh}`,
      Accept: 'application/vnd.github+json',
      'X-GitHub-Api-Version': '2022-11-28',
      'User-Agent': 'gaddha-admin',
      ...(body ? { 'Content-Type': 'application/json' } : {})
    },
    body
  });
  res.status(g.status);
  res.setHeader('Content-Type', g.headers.get('content-type') || 'application/json');
  res.send(Buffer.from(await g.arrayBuffer()));
};
