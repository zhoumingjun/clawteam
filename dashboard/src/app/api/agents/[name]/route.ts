import { NextResponse } from "next/server";
import { getAgentFiles } from "@/lib/agents";

export async function GET(_req: Request, { params }: { params: Promise<{ name: string }> }) {
  const { name } = await params;
  const files = await getAgentFiles(name);
  if (!files) return NextResponse.json({ error: "not found" }, { status: 404 });
  return NextResponse.json(files);
}
