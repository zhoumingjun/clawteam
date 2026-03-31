"use client";

import { useEffect, useState } from "react";

export default function TeamPage() {
  const [content, setContent] = useState("");
  const [draft, setDraft] = useState("");
  const [saving, setSaving] = useState(false);
  const [msg, setMsg] = useState("");

  useEffect(() => {
    fetch("/api/team")
      .then((r) => r.json())
      .then((data) => {
        setContent(data.content || "");
        setDraft(data.content || "");
      });
  }, []);

  const save = async () => {
    setSaving(true);
    setMsg("");
    const res = await fetch("/api/team", {
      method: "PUT",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ content: draft }),
    });
    setSaving(false);
    if (res.ok) {
      setContent(draft);
      setMsg("Saved");
    } else {
      setMsg("Save failed");
    }
  };

  const dirty = draft !== content;

  return (
    <div>
      <h1 className="text-2xl font-bold mb-4">Team</h1>

      <textarea
        value={draft}
        onChange={(e) => setDraft(e.target.value)}
        className="w-full h-[60vh] font-mono text-sm p-4 border border-gray-300 rounded-lg bg-white resize-y focus:outline-none focus:ring-2 focus:ring-blue-500"
      />

      <div className="flex items-center gap-3 mt-3">
        <button
          onClick={save}
          disabled={saving || !dirty}
          className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700 disabled:opacity-40 disabled:cursor-not-allowed"
        >
          {saving ? "Saving..." : "Save"}
        </button>
        {msg && (
          <span className={msg === "Saved" ? "text-green-600" : "text-red-600"}>
            {msg}
          </span>
        )}
        {dirty && <span className="text-yellow-600 text-sm">Unsaved changes</span>}
      </div>
    </div>
  );
}
