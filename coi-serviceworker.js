/* coi-serviceworker v0.1.7 — github.com/gzuidhof/coi-serviceworker */
self.addEventListener("install",()=>self.skipWaiting());
self.addEventListener("activate",e=>e.waitUntil(self.clients.claim()));
function coiHeaders(headers){
  const h=new Headers(headers);
  h.set("Cross-Origin-Opener-Policy","same-origin");
  h.set("Cross-Origin-Embedder-Policy","require-corp");
  return h;
}
self.addEventListener("fetch",e=>{
  if(e.request.cache==="only-if-cached"&&e.request.mode!=="same-origin")return;
  e.respondWith(fetch(e.request).then(r=>new Response(r.body,{status:r.status,statusText:r.statusText,headers:coiHeaders(r.headers)})));
});
