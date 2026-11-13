// Real Flutter Web screenshots with an isolated API database and Venice AI.
// Usage: node shoot-api.mjs <webUrl> <outDir> <apiUrl>
// Run the screenshot API with DATABASE_PATH=./data/screenshots.db and
// AI_DAILY_LIMIT=3. Never run fixture generation against a production API.
import { randomUUID } from 'node:crypto';
import fs from 'node:fs';

import puppeteer from 'puppeteer-core';

const [base, out, api] = process.argv.slice(2);
if (!base || !out || !api) throw new Error('Usage: node shoot-api.mjs <webUrl> <outDir> <apiUrl>');
if (![base, api].every((url) => ['localhost', '127.0.0.1'].includes(new URL(url).hostname))) {
  throw new Error('Screenshot fixtures require local web and API servers.');
}
fs.mkdirSync(out, { recursive: true });
const password = `Screenshot-${randomUUID()}`;
const email = `screenshots-${randomUUID()}@example.com`;
let fixtureToken;
let browserToken;

async function request(method, path, body, token = fixtureToken) {
  const response = await fetch(`${api}${path}`, {
    method, signal: AbortSignal.timeout(15_000),
    headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}) },
    ...(body === undefined ? {} : { body: JSON.stringify(body) }),
  });
  if (!response.ok) throw new Error(`Fixture ${method} ${path}: HTTP ${response.status}`);
  return response.status === 204 ? null : response.json();
}

const session = await request('POST', '/auth/register', { email, password });
fixtureToken = session.token;
const quota = await request('GET', '/ai/usage');
if (quota.limit !== 3) throw new Error('The isolated screenshot API must use AI_DAILY_LIMIT=3.');
await request('PUT', '/profile', { name: 'Lucas Andrade', sex: 'masculino', bloodType: 'O-' });
for (const [days, location] of [[40, 'Hemocentro (exemplo)'], [130, 'Campanha (exemplo)'], [220, 'Unidade móvel (exemplo)']]) {
  const date = new Date();
  date.setUTCDate(date.getUTCDate() - days);
  await request('POST', '/donations', { date: date.toISOString().slice(0, 10), location,
    notes: 'Registro fictício para demonstração do aplicativo.' });
}

const browser = await puppeteer.launch({
  executablePath: process.env.CHROME_PATH ?? 'C:/Program Files/Google/Chrome/Application/chrome.exe',
  headless: true, args: ['--lang=pt-BR'],
});
const page = await browser.newPage();
page.setDefaultTimeout(30_000);
await page.setViewport({ width: 412, height: 915, deviceScaleFactor: 2 });
await page.emulateMediaFeatures([{ name: 'prefers-color-scheme', value: 'light' }]);
const settle = () => new Promise((resolve) => setTimeout(resolve, 350));

async function enableAccessibility() {
  await page.waitForSelector('flutter-view, flt-glass-pane');
  await page.waitForFunction(() => document.querySelector('flt-semantics-placeholder, flt-semantics input, flt-semantics[role]'));
  await page.evaluate(() => document.querySelector('flt-semantics-placeholder')?.click());
}
async function waitText(text) {
  await page.waitForFunction((value) => document.body.innerText.includes(value)
    || Array.from(document.querySelectorAll('[aria-label], [aria-valuetext], input, textarea'))
      .some((e) => [e.getAttribute('aria-label'), e.getAttribute('aria-valuetext'), e.value]
        .some((candidate) => typeof candidate === 'string' && candidate.includes(value))), {}, text);
  await settle();
}
async function go(path, text) {
  await page.evaluate((value) => { window.location.hash = value; }, path);
  await waitText(text);
}
async function clickText(text) {
  // Use Chromium's accessible names (chips may use aria-labelledby rather
  // than an aria-label/text node on the clickable element itself).
  await page.locator(`::-p-aria([name=${JSON.stringify(text)}])`).click();
  await settle();
}
async function shot(name) {
  await page.mouse.move(4, 4);
  await page.evaluate(() => { document.activeElement?.blur(); window.scrollTo(0, 0); });
  await settle();
  await page.screenshot({ path: `${out}/${name}.png` });
  console.log('saved', name);
}
async function aiResponse(path, action, expectedStatus = 200) {
  const pending = page.waitForResponse((res) => res.url() === `${api}${path}` && res.request().method() === 'POST',
    { timeout: 80_000 }).then((response) => ({ response }), (error) => ({ error }));
  await action();
  const result = await pending;
  if (result.error) throw result.error;
  const { response } = result;
  if (response.status() !== expectedStatus) throw new Error(`Screenshot ${path}: HTTP ${response.status()}`);
  return response.json();
}

try {
  await page.goto(`${base}/#/login`, { waitUntil: 'networkidle0' });
  await enableAccessibility();
  await page.waitForSelector('input[aria-label="E-mail"]');
  await settle();
  await shot('01-login');
  await page.type('input[aria-label="E-mail"]', email);
  await page.type('input[aria-label="Senha"]', password);
  const loggedIn = page.waitForResponse((res) => res.url() === `${api}/auth/login` && res.request().method() === 'POST');
  await clickText('Entrar');
  const loginResponse = await loggedIn;
  if (!loginResponse.ok()) throw new Error(`Screenshot login: HTTP ${loginResponse.status()}`);
  browserToken = (await loginResponse.json()).token;
  await waitText('Olá, Lucas!');
  await shot('02-home');
  await go('/doacoes', 'Minhas doações');
  await shot('03-historico');
  await go('/compatibilidade', 'Compatibilidade sanguínea');
  await shot('04-compatibilidade');
  await go('/guia/antes', 'Verifique os requisitos básicos');
  await shot('05-guia');
  await go('/quiz', 'Gerar questionário com IA');
  await clickText('Usar quiz do app');
  await clickText('Apenas homens');
  await waitText('Não é bem assim.');
  await shot('06-quiz-feedback');
  await go('/doacoes/nova', 'Registrar doação');
  await shot('07-registrar');
  await page.emulateMediaFeatures([{ name: 'prefers-color-scheme', value: 'dark' }]);
  await go('/', 'Olá, Lucas!');
  await shot('08-home-escuro');
  await page.emulateMediaFeatures([{ name: 'prefers-color-scheme', value: 'light' }]);
  await page.setViewport({ width: 1280, height: 800, deviceScaleFactor: 1 });
  await go('/', 'Olá, Lucas!');
  await shot('09-home-desktop');

  await page.setViewport({ width: 412, height: 915, deviceScaleFactor: 2 });
  // A hash-only navigation would preserve the fallback quiz in the tab stack.
  await page.goto('about:blank');
  await page.goto(`${base}/#/quiz`, { waitUntil: 'networkidle0' });
  await enableAccessibility();
  await waitText('Gerar questionário com IA');
  const quiz = await aiResponse('/ai/quiz', () => clickText('Gerar questionário com IA'));
  await waitText(quiz.questions[0].text);
  await shot('10-quiz-ia');
  await clickText(quiz.questions[0].options[quiz.questions[0].correctIndex]);
  await waitText('Correto!');
  await shot('11-quiz-ia-feedback');

  await go('/chat', 'Assistente de doação');
  const input = 'textarea[aria-label="Sua dúvida"], input[aria-label="Sua dúvida"]';
  await page.waitForSelector(input);
  // Wait for Flutter to finish swapping the semantic/editing input on focus.
  await page.click(input);
  await settle();
  await page.keyboard.type('Como me preparar para doar sangue?');
  const first = await aiResponse('/ai/chat', () => clickText('Enviar mensagem'));
  await waitText(first.suggestions[0]);
  await shot('12-chat-ia');
  const followUp = await aiResponse('/ai/chat', () => clickText(first.suggestions[0]));
  await waitText(followUp.suggestions[0]);
  await shot('13-chat-contexto');

  await go('/quiz', 'Correto!');
  await clickText('Próxima');
  for (let i = 1; i < quiz.questions.length; i++) {
    await waitText(quiz.questions[i].text);
    await clickText(quiz.questions[i].options[quiz.questions[i].correctIndex]);
    await clickText(i === quiz.questions.length - 1 ? 'Ver resultado' : 'Próxima');
  }
  await waitText('5 de 5 acertos');
  await shot('14-quiz-resultado');
  await aiResponse('/ai/quiz', () => clickText('Gerar outro questionário'), 429);
  await waitText('Seu limite diário de 3 solicitações de IA foi atingido.');
  await shot('15-limite-ia');
  fs.writeFileSync(`${out}/capture-info.json`, JSON.stringify({
    capturedAt: new Date().toISOString(), platform: 'Flutter Web', backend: 'API TypeScript',
    aiProvider: 'Venice AI (respostas reais)', fixture: 'Lucas Andrade — doador fictício',
    screenshotDailyLimit: 3, applicationDefaultDailyLimit: 20,
  }, null, 2) + '\n');
} catch (error) {
  await page.screenshot({ path: '../../apps/mobile/.dart_tool/screenshot-error.png' });
  console.error('Screenshot stopped at', page.url(),
    await page.evaluate(() => Array.from(document.querySelectorAll('[role]')).map((e) => ({
      role: e.getAttribute('role'), label: e.getAttribute('aria-label'), text: e.innerText?.slice(0, 120),
    }))));
  throw error;
} finally {
  await browser.close();
  for (const token of [fixtureToken, browserToken].filter(Boolean)) {
    await request('POST', '/auth/logout', {}, token).catch(() => {});
  }
}
