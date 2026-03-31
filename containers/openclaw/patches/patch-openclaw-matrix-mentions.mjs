#!/usr/bin/env node
/**
 * Hotfix for Matrix m.mentions + mention HTML (upstream gap):
 * https://github.com/openclaw/openclaw/issues/56950
 *
 * Replaces applyMatrixFormatting in the bundled auth-profiles-*.js (openclaw
 * pin in Dockerfile); build fails if anchor missing after upgrade.
 */
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const dist = path.join("/opt/openclaw-app/node_modules/openclaw/dist");
const files = fs.readdirSync(dist).filter((f) => /^auth-profiles-.+\.js$/.test(f));
if (files.length !== 1) {
  console.error("patch-openclaw-matrix-mentions: expected exactly one auth-profiles-*.js, got:", files);
  process.exit(1);
}

const fp = path.join(dist, files[0]);
let s = fs.readFileSync(fp, "utf8");

const oldBlock = `function applyMatrixFormatting(content, body) {
	const formatted = markdownToMatrixHtml(body ?? "");
	if (!formatted) return;
	content.format = "org.matrix.custom.html";
	content.formatted_body = formatted;
}`;

const inject = fs.readFileSync(path.join(__dirname, "openclaw-matrix-mentions-inject.js"), "utf8").trim();

if (!s.includes(oldBlock)) {
  console.error("patch-openclaw-matrix-mentions: anchor not found in", fp);
  process.exit(1);
}

// 必须使用函数 repl：若 inject 含 "$&" 等，String.replace 会把整个 matched oldBlock 插入替换串。
s = s.replace(oldBlock, () => inject);
fs.writeFileSync(fp, s);
console.log("patch-openclaw-matrix-mentions: patched", fp);
