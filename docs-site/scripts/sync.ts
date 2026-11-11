/** Copies the OpenAPI document into the site and writes the API reference page before a build. */
import { copyFileSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";

const root = new URL("../../", import.meta.url);
const here = new URL("../", import.meta.url);
mkdirSync(new URL("public/api/", here), { recursive: true });
copyFileSync(
  new URL("packages/contracts/openapi.json", root),
  new URL("public/api/openapi.json", here),
);
const version = JSON.parse(readFileSync(new URL("packages/contracts/openapi.json", root), "utf8"))
  .info.version;
writeFileSync(
  new URL("public/api/index.html", here),
  `<!doctype html>
<html lang="en">
<head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Kasama API reference</title></head>
<body>
<script id="api-reference" data-url="./openapi.json"></script>
<script src="https://cdn.jsdelivr.net/npm/@scalar/api-reference@1.76.0"></script>
</body>
</html>
`,
);
console.log(`synced OpenAPI ${version}`);
