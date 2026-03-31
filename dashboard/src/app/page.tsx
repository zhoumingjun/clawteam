import Link from "next/link";
import { getAgentNames, getAgentFiles } from "@/lib/agents";
import { parseIdentity } from "@/lib/identity";

export const dynamic = "force-dynamic";

export default async function HomePage() {
  const names = await getAgentNames();
  const agents = await Promise.all(
    names.map(async (name) => {
      const files = await getAgentFiles(name);
      const identity = files?.["IDENTITY.md"]
        ? parseIdentity(files["IDENTITY.md"])
        : { name, creature: "", vibe: "", emoji: "", avatar: "" };
      return { id: name, ...identity };
    })
  );

  return (
    <div>
      <h1 className="text-2xl font-bold mb-6">Agents</h1>
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
        {agents.map((a) => (
          <Link
            key={a.id}
            href={`/agents/${a.id}`}
            className="block bg-white rounded-lg shadow hover:shadow-md transition-shadow p-5 border border-gray-200"
          >
            <div className="text-4xl mb-3">{a.emoji || "🤖"}</div>
            <h2 className="text-lg font-semibold">{a.name || a.id}</h2>
            <p className="text-sm text-gray-600 mt-1">{a.creature}</p>
            <p className="text-xs text-gray-400 mt-2">{a.vibe}</p>
          </Link>
        ))}
      </div>
    </div>
  );
}
