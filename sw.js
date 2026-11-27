var CACHE = 'lownet-v122';

var PRECACHE = [
  '/toolkit.html',
  '/'
];

self.addEventListener('install', function(e) {
  e.waitUntil(
    caches.open(CACHE).then(function(cache) {
      return cache.addAll(PRECACHE);
    }).then(function() {
      return self.skipWaiting();
    })
  );
});

self.addEventListener('activate', function(e) {
  e.waitUntil(
    caches.keys().then(function(keys) {
      return Promise.all(
        keys.filter(function(k) { return k !== CACHE; })
            .map(function(k) { return caches.delete(k); })
      ).then(function() { return keys.some(function(k) { return k !== CACHE; }); });
    }).then(function(hadOld) {
      // v1.2.2 (review R-5): a new version replaced an older one. Open tabs still run the old page until a reload.
      return self.clients.claim().then(function() {
        if (!hadOld) return;
        return self.clients.matchAll({ includeUncontrolled: true }).then(function(cs) { cs.forEach(function(cl) { cl.postMessage({ type: 'lownet-updated' }); }); });
      });
    })
  );
});

self.addEventListener('fetch', function(e) {
  if (e.request.method !== 'GET') return;

  var url = new URL(e.request.url);

  // Skip: API, submit, verify, cache-bypass
  if (url.pathname.startsWith('/posts/') ||
      url.pathname === '/submit' ||
      url.pathname.startsWith('/verify') ||
      url.searchParams.has('_nocache')) return;

  e.respondWith(
    caches.match(e.request).then(function(cached) {
      if (cached) {
        var before = cached.clone();
        fetch(e.request).then(function(resp) {
          if (resp && resp.status === 200 && resp.type === 'basic') {
            var clone = resp.clone(), probe = resp.clone();
            caches.open(CACHE).then(function(c) { c.put(e.request, clone); });
            // v1.2.2: tell open pages when the page itself changed; it runs after their next reload
            if (url.pathname === '/toolkit.html') {
              Promise.all([probe.text(), before.text()]).then(function(t) {
                if (t[0] !== t[1]) self.clients.matchAll().then(function(cs) { cs.forEach(function(cl) { cl.postMessage({ type: 'lownet-updated' }); }); });
              }).catch(function() {});
            }
          }
        }).catch(function() {});
        return cached;
      }
      return fetch(e.request).then(function(resp) {
        if (resp && resp.status === 200 && resp.type === 'basic') {
          var clone = resp.clone();
          caches.open(CACHE).then(function(c) { c.put(e.request, clone); });
        }
        return resp;
      });
    })
  );
});
