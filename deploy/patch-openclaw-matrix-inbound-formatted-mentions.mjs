#!/usr/bin/env node
/**
 * Inbound Matrix mention: when formatted_body has <a href="https://matrix.to/#/..."> pointing at
 * this bot's userId, count as mention even if link text is display-name-only (Element).
 * Upstream gates on isVisibleMentionLabel() and drops valid Element pills → no-mention.
 *
 * @see https://github.com/openclaw/openclaw/issues/6982
 */
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const dist = path.join("/opt/openclaw-app/node_modules/openclaw/dist");

const oldBlock = `\t\t\tif (decodeURIComponent(parsed.hash.replace(/^#\\/?/, "").trim()) !== params.userId.trim()) continue;
\t\t\tif (isVisibleMentionLabel({
\t\t\t\ttext: visibleLabel,
\t\t\t\tuserId: params.userId,
\t\t\t\tmentionRegexes: params.mentionRegexes,
\t\t\t\tdisplayName: params.displayName
\t\t\t})) return true;`;

const newBlock = `\t\t\tif (decodeURIComponent(parsed.hash.replace(/^#\\/?/, "").trim()) !== params.userId.trim()) continue;
\t\t\t// Claw Team: trust matrix.to href for this user (openclaw#6982 / Element).
\t\t\treturn true;`;

const files = fs.readdirSync(dist).filter((f) => /^monitor-.+\.js$/.test(f));
const targets = files.filter((f) =>
	fs.readFileSync(path.join(dist, f), "utf8").includes("function checkFormattedBodyMention(params)")
);
if (targets.length !== 1) {
	console.error(
		"patch-openclaw-matrix-inbound-formatted-mentions: expected exactly one monitor-*.js with checkFormattedBodyMention, got:",
		targets
	);
	process.exit(1);
}

const fp = path.join(dist, targets[0]);
let s = fs.readFileSync(fp, "utf8");
if (!s.includes(oldBlock)) {
	console.error("patch-openclaw-matrix-inbound-formatted-mentions: anchor not found in", fp);
	process.exit(1);
}
s = s.replace(oldBlock, newBlock);
fs.writeFileSync(fp, s);
console.log("patch-openclaw-matrix-inbound-formatted-mentions: patched", fp);
