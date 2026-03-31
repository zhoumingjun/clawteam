#!/usr/bin/env node
/**
 * Claw Team: Synapse / API clients may set m.mentions without matching mentionRegex text
 * (or formatted_body edge cases). Upstream requires (formatted OR text) AND user_ids,
 * which can drop valid @dev routing for agent→agent pings.
 */
import fs from "node:fs";
import path from "node:path";

const dist = path.join("/opt/openclaw-app/node_modules/openclaw/dist");
const files = fs.readdirSync(dist).filter((f) => /^monitor-.+\.js$/.test(f));
const target = files.find((f) =>
	fs.readFileSync(path.join(dist, f), "utf8").includes("metadataBackedUserMention")
);
if (!target) {
	console.error("patch-openclaw-matrix-trust-m-mentions: no monitor bundle with metadataBackedUserMention");
	process.exit(1);
}
const fp = path.join(dist, target);
let s = fs.readFileSync(fp, "utf8");
const old =
	"const metadataBackedUserMention = Boolean(params.userId && mentionedUsers.has(params.userId) && (mentionedInFormattedBody || textMentioned));";
const neu =
	"const metadataBackedUserMention = Boolean(params.userId && mentionedUsers.has(params.userId));";
if (!s.includes(old)) {
	console.error("patch-openclaw-matrix-trust-m-mentions: anchor not found in", fp);
	process.exit(1);
}
s = s.replace(old, neu);
fs.writeFileSync(fp, s);
console.log("patch-openclaw-matrix-trust-m-mentions: patched", fp);
