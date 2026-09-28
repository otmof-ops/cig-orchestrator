// The page as a pure function of the numbers, so `node --test` can check it.
const escape = (value) =>
  String(value).replace(/[&<>"]/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" })[c]);

export function render({ version, total, orders, topRegion }) {
  return `<!doctype html>
<html lang="en">
<meta charset="utf-8">
<title>Sales ${escape(version)}</title>
<h1>Sales</h1>
<p>${escape(orders)} orders, ${escape(total)} in total; the top region is ${escape(topRegion)}.</p>
<footer>release ${escape(version)}</footer>
</html>
`;
}
