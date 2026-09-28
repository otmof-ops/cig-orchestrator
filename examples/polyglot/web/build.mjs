// Node builds dist/index.html from the numbers Python worked out. They arrive
// as environment variables and an argument, filled in by the orchestrator from
// the earlier tasks' output: nothing here knows that Python ran.
import { appendFileSync, mkdirSync, writeFileSync } from "node:fs";
import { relative, resolve } from "node:path";
import { render } from "./render.mjs";

const at = process.argv.indexOf("--version");
const version = at > 0 ? process.argv[at + 1] : "dev";
const html = render({
  version,
  total: process.env.TOTAL ?? "?",
  orders: process.env.ORDERS ?? "?",
  topRegion: process.env.TOP_REGION ?? "?",
});

mkdirSync("dist", { recursive: true });
writeFileSync("dist/index.html", html);
// The path from the project root, which is where the next task runs.
const page = relative(process.env.CIG_PROJECT_ROOT ?? process.cwd(), resolve("dist/index.html"));
console.log(`built ${page} (${Buffer.byteLength(html)} bytes)`);

// Named values for the tasks after this one: {{site.page}} and {{site.bytes}}.
if (process.env.CIG_OUTPUT) {
  appendFileSync(process.env.CIG_OUTPUT, `page=${page}\nbytes=${Buffer.byteLength(html)}\n`);
}
