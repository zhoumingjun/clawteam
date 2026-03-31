import { NextResponse } from "next/server";
import { getAgentNames, getAgentFiles } from "@/lib/agents";
import { parseIdentity } from "@/lib/identity";

export async function GET() {
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
  return NextResponse.json(agents);
}
