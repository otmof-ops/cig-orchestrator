import assert from "node:assert/strict";
import { test } from "node:test";
import { render } from "./render.mjs";

test("the page carries the numbers", () => {
  const html = render({ version: "1.0.0", total: 12.5, orders: 3, topRegion: "north" });
  assert.match(html, /3 orders, 12\.5 in total; the top region is north/);
  assert.match(html, /release 1\.0\.0/);
});

test("the page escapes what it is given", () => {
  assert.match(render({ version: "<b>", total: 0, orders: 0, topRegion: "x" }), /&lt;b&gt;/);
});
