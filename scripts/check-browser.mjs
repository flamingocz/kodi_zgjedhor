// Dependency-free browser smoke checks. Requires Node 22+ and Chrome's local CDP port.
// Run: node scripts/check-browser.mjs (preview server :8000, Chrome debugging :9223).
import { writeFile } from 'node:fs/promises';
import assert from 'node:assert/strict';
const base = 'http://127.0.0.1:8000';
const tabs = await (await fetch('http://127.0.0.1:9223/json')).json();
const tab = tabs.find(t => t.type === 'page');
assert(tab, 'Chrome page available');
const socket = new WebSocket(tab.webSocketDebuggerUrl);
await new Promise((resolve, reject) => { socket.onopen = resolve; socket.onerror = reject; });
let id = 0;
const pending = new Map();
const errors = [];
let loadVersion = 0;
socket.onmessage = ({data}) => {
 const message = JSON.parse(data);
 if (message.method === "Page.loadEventFired") loadVersion++;
 if (message.method === 'Runtime.exceptionThrown') errors.push(message.params.exceptionDetails.text);
 if (message.id && pending.has(message.id)) {
  const {resolve, reject, timer} = pending.get(message.id);
  clearTimeout(timer); pending.delete(message.id);
  message.error ? reject(message.error) : resolve(message.result);
 }
};
function call(method, params = {}) {
 return new Promise((resolve, reject) => {
  const n = ++id;
  const timer = setTimeout(() => { pending.delete(n); reject(new Error(`Timeout: ${method} ${params.expression || ""}`)); }, 10000);
  pending.set(n, {resolve, reject, timer});
  socket.send(JSON.stringify({id:n, method, params}));
 });
}
async function evaluate(expression) {
 const r = await call('Runtime.evaluate', {expression, returnByValue:true, awaitPromise:true});
 assert(!r.exceptionDetails, JSON.stringify(r.exceptionDetails));
 return r.result.value;
}
async function navigate(path) {
 const before = loadVersion;
 const navigation = await call('Page.navigate', {url:base+path});
 for (let i=0; i<100; i++) {
  if ((!navigation.loaderId || loadVersion > before) && await evaluate(`location.href === ${JSON.stringify(base+path)} && document.readyState === 'complete'`)) return;
  await new Promise(r=>setTimeout(r,50));
 }
 throw new Error(`Page did not load: ${path}`);
}
async function size(width, height=900) {
 await call('Emulation.setDeviceMetricsOverride',{width,height,deviceScaleFactor:1,mobile:false});
 await new Promise(r=>setTimeout(r,100));
}
async function screenshot(name) {
 const {cssContentSize} = await call('Page.getLayoutMetrics');
 const {data} = await call('Page.captureScreenshot',{format:'png',captureBeyondViewport:true,clip:{x:0,y:0,width:cssContentSize.width,height:cssContentSize.height,scale:1}});
 await writeFile(`/tmp/electoral-${name}.png`,Buffer.from(data,'base64'));
}
try {
 await call('Page.enable'); await call('Runtime.enable');
 await call('Emulation.setScriptExecutionDisabled',{value:false});
 await call('Page.bringToFront');
 console.log('Browser connected');
 await call('Emulation.clearDeviceMetricsOverride');
 await size(1440);
 await navigate('/index.html');
 assert.equal(await evaluate('document.documentElement.lang'),'sq');
 assert.equal(await evaluate('document.querySelectorAll("h1").length'),1);
 assert.equal(await evaluate('document.querySelectorAll(".topic").length'),15);
 assert.equal(await evaluate('document.querySelectorAll(".faq-list details").length'),11);
 assert.equal(await evaluate('getComputedStyle(document.querySelector(".menu-toggle")).display'),'none');
 const anchors = await evaluate('[...document.querySelectorAll("a[href]")].map(a=>a.getAttribute("href"))');
 for (const href of new Set(anchors)) {
  if (href.startsWith('#')) assert(await evaluate(`!!document.getElementById(${JSON.stringify(href.slice(1))})`), `Anchor exists ${href}`);
 }
 for (const file of new Set(anchors.filter(h=>!h.startsWith('#')&&!/^[a-z]+:/i.test(h)))) {
  const response = await fetch(new URL(file,base));
  assert.equal(response.status,200,`Download/page: ${file}`);
  if (/\.pdf$/i.test(file)) assert((await response.text()).startsWith('%PDF-'),`PDF bytes: ${file}`);
 }
 assert(await evaluate(`[...document.links].filter(a=>a.protocol === "tel:").every(a=>a.getAttribute("href")==="tel:+355694382248")`));
 assert(await evaluate(`[...document.links].filter(a=>a.hostname === "wa.me").every(a=>new URL(a.href).pathname==="/355694382248")`));
 assert(await evaluate(`[...document.links].filter(a=>a.protocol === "mailto:").every(a=>["mailto:edmondcata@hotmail.com","mailto:veprimi.qytetar@gmail.com"].includes(a.href.split("?")[0]))`));
 await evaluate('document.querySelector("[data-open-topic]").click()');
 assert(await evaluate('document.querySelector("#listat").open'));
 await navigate('/index.html#financimi');
 assert(await evaluate('document.querySelector("#financimi").open'));
 await navigate('/index.html');
 await evaluate('document.querySelector("#listat").open=false; document.querySelector("#listat summary").focus()');
 assert(await evaluate('document.activeElement.matches("#listat summary")'), 'Summary focused');
 await call('Input.dispatchKeyEvent',{type:'keyDown',key:'Enter',code:'Enter',windowsVirtualKeyCode:13,text:'\r',unmodifiedText:'\r'});
 await call('Input.dispatchKeyEvent',{type:'keyUp',key:'Enter',code:'Enter',windowsVirtualKeyCode:13});
 await new Promise(r=>setTimeout(r,100));
 assert(await evaluate('document.querySelector("#listat").open'),'Keyboard opens details');
 await evaluate('document.querySelector("#listat").open=false; document.activeElement.blur(); window.scrollTo(0,0)');
 console.log('Keyboard and links passed');

 for (const width of [320,375,390,600,768,850,1024,1440]) {
  await size(width);
  const overflow=await evaluate('document.documentElement.scrollWidth > innerWidth');
  assert.equal(overflow,false,`No horizontal overflow: ${width}`);
 }
 await size(390,844);
 await evaluate('document.querySelector(".menu-toggle").click()');
 assert(await evaluate('document.querySelector(".menu-toggle").getAttribute("aria-expanded")==="true"'));
 assert.equal(await evaluate('getComputedStyle(document.querySelector("nav")).display'),'flex');
 await call('Input.dispatchKeyEvent',{type:'keyDown',key:'Escape',code:'Escape',windowsVirtualKeyCode:27});
 assert(await evaluate('document.querySelector(".menu-toggle").getAttribute("aria-expanded")==="false"'));
 assert(await evaluate('document.activeElement.matches(".menu-toggle")'));
 await evaluate('document.querySelector(".menu-toggle").click(); document.querySelector("nav a").click()');
 assert(await evaluate('document.querySelector(".menu-toggle").getAttribute("aria-expanded")==="false"'));
 await navigate('/index.html');
 console.log('Responsive and mobile menu passed');

 await evaluate(`[...document.querySelectorAll('a.button')].find(a=>a.getAttribute('href')==='#firmos').click()`);
 await new Promise(r=>setTimeout(r,900));
 const signTop = await evaluate('document.getElementById("firmos").getBoundingClientRect().top');
 assert(signTop >= 0 && signTop <= 120, `Signing anchor visible below header: ${signTop}`);
 await navigate('/en.html');
 assert.equal(await evaluate('document.documentElement.lang'),'en');
 for (const width of [320,390,768,1440]) {
  await size(width);
  assert.equal(await evaluate('document.documentElement.scrollWidth > innerWidth'),false,`English overflow: ${width}`);
 }
 const enFiles = await evaluate('[...document.querySelectorAll("a[download]")].map(a=>a.href)');
 for (const file of new Set(enFiles)) assert.equal((await fetch(file)).status,200,`English download ${file}`);

 await call('Emulation.setEmulatedMedia',{features:[{name:'prefers-reduced-motion',value:'reduce'}]});
 assert.equal(await evaluate('getComputedStyle(document.documentElement).scrollBehavior'),'auto');
 await call('Emulation.setScriptExecutionDisabled',{value:true});
 await size(390,844);
 await navigate('/index.html');
 assert.equal(await evaluate('getComputedStyle(document.querySelector("nav")).display'),'flex','Navigation works without JS');
 assert.equal(await evaluate('document.querySelectorAll(".topic").length'),15,'Static topics without JS');
 await call('Emulation.setScriptExecutionDisabled',{value:false});
 assert.deepEqual(errors,[],'No page JavaScript exceptions');
 for (const [name,width,path] of [['desktop',1440,'/index.html'],['mobile',390,'/index.html'],['english',1440,'/en.html']]) {
  await call('Emulation.clearDeviceMetricsOverride');
  await size(width);
  await navigate(path);
  await screenshot(name);
 }
 await call('Emulation.clearDeviceMetricsOverride');
 console.log('PASS: Albanian + English pages; eight viewport widths; document responses and PDF bytes; anchors; contact URLs; keyboard details; mobile menu and Escape; deep links; reduced motion; no-JS content/navigation; no JavaScript exceptions. Screenshots: /tmp/electoral-{desktop,mobile,english}.png');
} finally { socket.close(); }
