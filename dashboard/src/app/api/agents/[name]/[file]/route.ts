import { NextResponse } from "next/server";
import { updateAgentFile } from "@/lib/agents";

export async function PUT(req: Request, { params }: { params: Promise<{ name: string; file: string }> }) {
  const { name, file } = await params;
  const { content } = await req.json();
  if (typeof content !== "string") {
    return NextResponse.json({ error: "content required" }, { status: 400 });
  }
  const ok = await updateAgentFile(name, file, content);
  if (!ok) return NextResponse.json({ error: "not found or invalid path" }, { status: 404 });
  return NextResponse.json({ ok: true });
}
