import { createReadStream } from "node:fs";
import { readdir, stat } from "node:fs/promises";
import { createServer } from "node:http";
import path from "node:path";
import { fileURLToPath } from "node:url";

const modRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const projectRoot = path.resolve(process.argv[2] || "C:/Users/mibas/Desktop/aaa");
const port = Number(process.argv[3] || 41731);
const host = process.argv[4] || "127.0.0.1";
const types = { ".html":"text/html; charset=utf-8", ".js":"text/javascript; charset=utf-8", ".css":"text/css", ".txt":"text/plain; charset=utf-8", ".png":"image/png", ".gif":"image/gif", ".bmp":"image/bmp" };

createServer(async (request, response) => {
  try {
    const url = new URL(request.url, `http://127.0.0.1:${port}`);
    if (url.pathname.startsWith("/directory/")) {
      const relativeDirectory = decodeURIComponent(url.pathname.replace(/^\/directory\//, ""));
      const directory = path.resolve(projectRoot, relativeDirectory);
      if (!directory.toLowerCase().startsWith(projectRoot.toLowerCase() + path.sep)) throw new Error("Invalid path");
      const entries = await readdir(directory, { withFileTypes: true });
      const body = JSON.stringify(entries.map((entry) => ({ name: entry.name, path: path.join(directory, entry.name), isFile: entry.isFile(), isDirectory: entry.isDirectory() })));
      response.writeHead(200, { "Content-Type": "application/json", "Content-Length": Buffer.byteLength(body), "Cache-Control": "no-store" });
      response.end(body); return;
    }
    const projectFile = url.pathname.startsWith("/project/");
    const relative = decodeURIComponent(url.pathname.replace(projectFile ? /^\/project\// : /^\//, "")) || "tests/harness.html";
    const base = projectFile ? projectRoot : modRoot;
    const filename = path.resolve(base, relative);
    if (!filename.toLowerCase().startsWith(base.toLowerCase() + path.sep) && filename !== base) throw new Error("Invalid path");
    const info = await stat(filename);
    if (!info.isFile()) throw new Error("Not a file");
    response.writeHead(200, { "Content-Type": types[path.extname(filename).toLowerCase()] || "application/octet-stream", "Content-Length": info.size, "Cache-Control":"no-store" });
    if (request.method === "HEAD") response.end(); else createReadStream(filename).pipe(response);
  } catch {
    response.writeHead(404); response.end("Not found");
  }
}).listen(port, host, () => console.log(`PBS harness: http://${host}:${port}/tests/harness.html`));
