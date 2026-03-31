"use client";

import { useParams } from "next/navigation";
import { useEffect, useState } from "react";

const FILE_ORDER = [
  "IDENTITY.md", "SOUL.md", "AGENTS.md", "HEARTBEAT.md",
  "TOOLS.md", "USER.md", "MEMORY.md", "BOOTSTRAP.md",
];

export default function AgentDetailPage() {
  const { name } = useParams<{ name: string }>();
  const [files, setFiles] = useState<Record<string, string>>({});
  const [activeTab, setActiveTab] = useState("IDENTITY.md");
  const [draft, setDraft] = useState("");
  const [saving, setSaving] = useState(false);
  const [msg, setMsg] = useState("");

  useEffect(() => {
    fetch(`/api/agents/${name}`)
      .then((r) => r.json())
      .then((data) => {
        setFiles(data);
        setDraft(data["IDENTITY.md"] || "");
      });
  }, [name]);

  useEffect(() => {
    setDraft(files[activeTab] || "");
    setMsg("");
  }, [activeTab, files]);

  const save = async () => {
    setSaving(true);
    setMsg("");
    const res = await fetch(`/api/agents/${name}/${activeTab}`, {
      method: "PUT",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ content: draft }),
    });
    setSaving(false);
    if (res.ok) {
      setFiles((f) => ({ ...f, [activeTab]: draft }));
      setMsg("Saved");
    } else {
      setMsg("Save failed");
    }
  };

  const tabs = FILE_ORDER.filter((f) => f in files);
  const dirty = draft !== (files[activeTab] || "");

  return (
    <div>
      <h1 className="text-2xl font-bold mb-4">
        {files["IDENTITY.md"]?.match(/\*\*Emoji:\*\*\s*(.*)/)?.[1]?.trim() || "🤖"}{" "}
        {name}
      </h1>

      <div className="flex gap-1 mb-4 flex-wrap">
        {tabs.map((f) => (
          <button
            key={f}
            onClick={() => setActiveTab(f)}
            className={`px-3 py-1.5 rounded text-sm ${
              f === activeTab
                ? "bg-gray-900 text-white"
                : "bg-gray-200 text-gray-700 hover:bg-gray-300"
            }`}
          >
            {f}
          </button>
        ))}
      </div>

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
