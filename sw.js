// ── Atikuzzaman Portfolio — Service Worker v3 ──────────────
const CACHE = 'ah-portfolio-v4';

// Core files to pre-cache on install
const PRECACHE = [
  './',
  './index.html',
  './manifest.json',
];

self.addEventListener('install', e => {
  e.waitUntil(
    caches.open(CACHE).then(c =>
      Promise.allSettled(PRECACHE.map(url => c.add(url).catch(() => {})))
    ).then(() => self.skipWaiting())
  );
});

self.addEventListener('activate', e => {
  e.waitUntil(
    caches.keys()
      .then(keys => Promise.all(keys.filter(k => k !== CACHE).map(k => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', e => {
  const req = e.request;
  if (req.method !== 'GET') return;

  const url = new URL(req.url);

  // Navigation requests → serve index.html (SPA fallback)
  if (req.mode === 'navigate') {
    e.respondWith(
      caches.match('./index.html').then(c => c || fetch(req))
    );
    return;
  }

  // External CDN (fonts, Tailwind, Lucide) → cache-first
  const isCDN = ['cdn.tailwindcss.com','unpkg.com','fonts.googleapis.com','fonts.gstatic.com']
    .some(h => url.hostname.includes(h));

  if (isCDN) {
    e.respondWith(
      caches.open(CACHE).then(c =>
        c.match(req).then(cached => cached ||
          fetch(req).then(res => { c.put(req, res.clone()); return res; }).catch(() => cached)
        )
      )
    );
    return;
  }

  // Background photos (Pexels) → network-first, cache on success
  if (url.hostname === 'images.pexels.com') {
    e.respondWith(
      fetch(req)
        .then(res => {
          if (res.ok) {
            const clone = res.clone();
            caches.open(CACHE).then(c => c.put(req, clone));
          }
          return res;
        })
        .catch(() => caches.match(req))
    );
    return;
  }

  // Local app files → cache-first
  if (url.origin === self.location.origin) {
    e.respondWith(
      caches.match(req).then(c => c || fetch(req).then(res => {
        if (res.ok) {
          const clone = res.clone();
          caches.open(CACHE).then(cache => cache.put(req, clone));
        }
        return res;
      }))
    );
    return;
  }

  // Everything else → network only
  e.respondWith(fetch(req).catch(() => new Response('', { status: 408 })));
});
