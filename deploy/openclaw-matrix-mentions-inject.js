/* Claw Team image hotfix — inserted into openclaw dist bundle at build time. */
function __clawteamMatrixLocalPart(mxid) {
	const t = mxid.startsWith("@") ? mxid.slice(1) : mxid;
	const i = t.indexOf(":");
	return i > 0 ? t.slice(0, i) : t;
}
function __clawteamExtractMatrixMentionUserIds(body, defaultServer) {
	const ids = [];
	const seen = new Set();
	if (!body || !defaultServer) return ids;
	const str = String(body);
	// Markdown 常把提及写成 [x](https://matrix.to/#/%40user%3Aserver) — 正文里没有裸 @，须从 fragment 解码
	const matToFrag = /matrix\.to\/#\/([^)\s"'<>\]]+)/gi;
	let m;
	while ((m = matToFrag.exec(str)) !== null) {
		let frag = m[1];
		try {
			frag = decodeURIComponent(frag);
		} catch (_) {
			continue;
		}
		if (!frag.startsWith("@")) continue;
		const colon = frag.indexOf(":");
		if (colon <= 0) continue;
		const id = frag.split("/")[0].split("?")[0];
		if (!/^@[A-Za-z0-9._=\-/]+:[A-Za-z0-9.\-]+$/.test(id)) continue;
		if (!seen.has(id)) {
			seen.add(id);
			ids.push(id);
		}
	}
	const fullRe = /@([A-Za-z0-9._=\-/]+):([A-Za-z0-9.\-]+)/g;
	const regions = [];
	while ((m = fullRe.exec(str)) !== null) {
		const id = "@" + m[1] + ":" + m[2];
		if (!seen.has(id)) {
			seen.add(id);
			ids.push(id);
		}
		regions.push({ start: m.index, end: m.index + m[0].length });
	}
	// 先挖掉完整 MXID 再跑裸 @local，否则 @qa:localhost 会被误拆成 @q、@qa 两条
	let work = str;
	regions.sort((a, b) => b.start - a.start);
	for (const r of regions) {
		work = work.slice(0, r.start) + "\ufffd" + work.slice(r.end);
	}
	// 只用 (?!:) 结尾：避免 @arch！、@arch， 等全角/中文标点后无法匹配（旧 lookahead 仅含 ASCII）
	const bareRe = /@([A-Za-z0-9._=\-/]+)(?!:)/g;
	while ((m = bareRe.exec(work)) !== null) {
		const start = m.index;
		if (start > 0 && /[A-Za-z0-9]/.test(work[start - 1])) continue;
		const local = m[1];
		if (local.includes("\ufffd")) continue;
		const id = "@" + local + ":" + defaultServer;
		if (!seen.has(id)) {
			seen.add(id);
			ids.push(id);
		}
	}
	return ids;
}
function __clawteamEscapeHtml(s) {
	return String(s)
		.replace(/&/g, "&amp;")
		.replace(/</g, "&lt;")
		.replace(/>/g, "&gt;")
		.replace(/"/g, "&quot;");
}
function __clawteamPlainToMatrixHtml(body) {
	const esc = __clawteamEscapeHtml(body);
	return "<p>" + esc.replace(/\n/g, "<br/>") + "</p>";
}
/** Element / 多数 Matrix 客户端用 matrix.to 链接画 mention pill；仅 data-mention 往往不够 */
function __clawteamMatrixToHref(mxid) {
	return "https://matrix.to/#/" + encodeURIComponent(mxid);
}
function __clawteamMentionAnchorHtml(mxid, displayText) {
	const href = __clawteamMatrixToHref(mxid);
	const esc = String(displayText)
		.replace(/&/g, "&amp;")
		.replace(/</g, "&lt;")
		.replace(/>/g, "&gt;")
		.replace(/"/g, "&quot;");
	return '<a href="' + href + '">' + esc + "</a>";
}
function __clawteamHtmlAlreadyHasMatrixToForMxid(html, mxid) {
	if (!html || !mxid) return false;
	const encFrag = encodeURIComponent(mxid);
	const esc = encFrag.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
	// 仅当已是 <a href="https://matrix.to/#/..."> 时跳过；正文/Markdown 里的裸 URL 不算
	const re = new RegExp(
		'<a\\s[^>]*href\\s*=\\s*["\']https?:\\/\\/matrix\\.to\\/#\\/(?:' +
			esc +
			"|" +
			mxid.replace(/[.*+?^${}()|[\]\\]/g, "\\$&") +
			')["\']',
		"i"
	);
	return re.test(html);
}
function __clawteamInjectMatrixMentionHtml(html, userIds) {
	if (!html || !userIds.length) return html;
	let out = html;
	const sorted = [...userIds].sort(
		(a, b) => __clawteamMatrixLocalPart(b).length - __clawteamMatrixLocalPart(a).length
	);
	for (const mxid of sorted) {
		if (!mxid.includes(":")) continue;
		const local = __clawteamMatrixLocalPart(mxid);
		if (!local) continue;
		if (__clawteamHtmlAlreadyHasMatrixToForMxid(out, mxid)) continue;
		if (out.includes(mxid)) {
			const safe = mxid.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
			out = out.replace(
				new RegExp(safe, "g"),
				__clawteamMentionAnchorHtml(mxid, mxid)
			);
		} else {
			const re = new RegExp(
				"@" + local.replace(/[.*+?^${}()|[\]\\]/g, "\\$&") + "(?!:)",
				"g"
			);
			out = out.replace(re, __clawteamMentionAnchorHtml(mxid, "@" + local));
		}
	}
	return out;
}
function __clawteamApplyMatrixMentions(content, rawBody) {
	const srv =
		typeof process !== "undefined" &&
		process.env &&
		(process.env.SYNAPSE_SERVER_NAME || process.env.MATRIX_MENTION_DEFAULT_SERVER);
	if (!srv || rawBody == null || rawBody === "") return;
	const ids = __clawteamExtractMatrixMentionUserIds(String(rawBody), srv);
	if (!ids.length) return;
	content["m.mentions"] = { user_ids: ids };
	let html =
		content.formatted_body && typeof content.formatted_body === "string"
			? content.formatted_body
			: "";
	// markdownToMatrixHtml 常对 Emoji/多行返回空，此时只有 m.mentions 没有 HTML，Element 不画 pill
	if (!html) {
		html = __clawteamPlainToMatrixHtml(String(rawBody));
		content.format = "org.matrix.custom.html";
	}
	content.formatted_body = __clawteamInjectMatrixMentionHtml(html, ids);
}
function applyMatrixFormatting(content, body) {
	const raw = body ?? "";
	const formatted = markdownToMatrixHtml(raw);
	if (formatted) {
		content.format = "org.matrix.custom.html";
		content.formatted_body = formatted;
	}
	__clawteamApplyMatrixMentions(content, raw);
}
