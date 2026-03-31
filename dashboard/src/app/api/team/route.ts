import { NextResponse } from "next/server";
import { getTeamFile, updateTeamFile } from "@/lib/agents";

export async function GET() {
  const content = await getTeamFile();
  if (content === null) return NextResponse.json({ error: "TEAM.md not found" }, { status: 404 });
  return NextResponse.json({ content });
}

export async function PUT(req: Request) {
  const { content } = await req.json();
  if (typeof content !== "string") {
    return NextResponse.json({ error: "content required" }, { status: 400 });
  }
  const ok = await updateTeamFile(content);
  if (!ok) return NextResponse.json({ error: "write failed" }, { status: 500 });
  return NextResponse.json({ ok: true });
}
