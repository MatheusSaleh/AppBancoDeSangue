// Static server with SPA fallback to index.html (needed for path URLs).
import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
const [root, port] = process.argv.slice(2);
const rootDir = path.resolve(root);
const types = { '.html': 'text/html', '.js': 'text/javascript', '.mjs': 'text/javascript', '.json': 'application/json', '.wasm': 'application/wasm', '.png': 'image/png', '.otf': 'font/otf', '.ttf': 'font/ttf', '.css': 'text/css', '.frag': 'text/plain' };
http.createServer((req, res) => {
  const url = decodeURIComponent(req.url.split('?')[0]);
  let file = path.join(rootDir, url);
  if (!(file.startsWith(rootDir + path.sep) || file === rootDir) || !fs.existsSync(file) || fs.statSync(file).isDirectory()) file = path.join(rootDir, 'index.html');
  res.writeHead(200, { 'Content-Type': types[path.extname(file)] || 'application/octet-stream' });
  fs.createReadStream(file).pipe(res);
}).listen(Number(port), '127.0.0.1');
