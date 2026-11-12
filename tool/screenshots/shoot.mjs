// Captures real screenshots of the demo web build.
// Seeds a sample demo session (fictitious donor "Lucas Andrade") in
// localStorage and captures each screen of the demo web build.
// Usage: node shoot.mjs <baseUrl> <outDir>   (CHROME_PATH overrides Chrome)
import puppeteer from 'puppeteer-core';
import fs from 'node:fs';

const [base, out] = process.argv.slice(2);
fs.mkdirSync(out, { recursive: true });

const browser = await puppeteer.launch({
  executablePath:
    process.env.CHROME_PATH ?? 'C:/Program Files/Google/Chrome/Application/chrome.exe',
  headless: true,
  args: ['--lang=pt-BR'],
});
const page = await browser.newPage();
await page.setViewport({ width: 412, height: 915, deviceScaleFactor: 2 });
await page.emulateMediaFeatures([{ name: 'prefers-color-scheme', value: 'light' }]);

const wait = (ms) => new Promise((r) => setTimeout(r, ms));
async function go(hash, settle = 1500) {
  await page.goto("about:blank");
  await page.goto(`${base}/#${hash}`, { waitUntil: "networkidle0" });
  await page.waitForSelector('flutter-view, flt-glass-pane', { timeout: 30000 });
  await wait(settle);
}
async function shot(name) {
  await page.screenshot({ path: `${out}/${name}.png` });
  console.log('saved', name);
}

// 1. Login (fresh storage).
await go('/login', 2500);
await shot('01-login');

// 2. Seed a demo session (same keys shared_preferences writes on web).
const today = new Date();
const daysAgo = (n) => {
  const d = new Date(today.getFullYear(), today.getMonth(), today.getDate() - n);
  return d.toISOString();
};
await page.evaluate((donations) => {
  const put = (k, v) => localStorage.setItem(k, JSON.stringify(v));
  put('demo.session', 'visitante-local');
  put('profile.visitante-local', JSON.stringify({ nome: 'Lucas Andrade', sexo: 'masculino', tipo_sanguineo: 'O-' }));
  put('donations.visitante-local', JSON.stringify(donations));
}, [
  { id: 'a', data: daysAgo(40), local: 'Hemocentro Regional', observacoes: '' },
  { id: 'b', data: daysAgo(130), local: 'Hemocentro Regional', observacoes: 'Campanha de inverno' },
  { id: 'c', data: daysAgo(220), local: 'Unidade móvel', observacoes: '' },
]);

await go('/', 2500);
await shot('02-home');
await go('/doacoes');
await shot('03-historico');
await go('/compatibilidade');
await shot('04-compatibilidade');
await go('/guia/antes');
await shot('05-guia');

await go('/quiz');
await page.mouse.click(206, 256);
await wait(900);
await shot('06-quiz-feedback');

await go('/doacoes/nova');
await shot('07-registrar');

// Dark theme + wide layout.
await page.emulateMediaFeatures([{ name: 'prefers-color-scheme', value: 'dark' }]);
await go('/', 2500);
await shot('08-home-escuro');
await page.emulateMediaFeatures([{ name: 'prefers-color-scheme', value: 'light' }]);
await page.setViewport({ width: 1280, height: 800, deviceScaleFactor: 1 });
await go('/', 2500);
await shot('09-home-desktop');

await browser.close();
