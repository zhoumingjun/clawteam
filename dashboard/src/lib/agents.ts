import fs from "fs/promises";
import path from "path";

const DATA_DIR = process.env.OPENCLAW_DATA_DIR || path.join(process.cwd(), "..", "volumes", "openclaw");

// Directories that are agent workspaces (contain IDENTITY.md)
const SKIP_DIRS = new Set(["agents", "matrix", "credentials", "devices", "identity", "logs", "canvas", "delivery-queue"]);

export async function getAgentNames(): Promise<string[]> {
  const entries = await fs.readdir(DATA_DIR, { withFileTypes: true });
  const names: string[] = [];
  for (const e of entries) {
    if (!e.isDirectory() || SKIP_DIRS.has(e.name)) continue;
    const idFile = path.join(DATA_DIR, e.name, "IDENTITY.md");
    try {
      await fs.access(idFile);
      names.push(e.name);
    } catch {
      // not an agent workspace
    }
  }
  return names.sort();
}

export async function getAgentFiles(name: string): Promise<Record<string, string> | null> {
  const dir = safePath(name);
  if (!dir) return null;
  try {
    const entries = await fs.readdir(dir);
    const files: Record<string, string> = {};
    for (const f of entries) {
      if (!f.endsWith(".md")) continue;
      files[f] = await fs.readFile(path.join(dir, f), "utf-8");
    }
    return Object.keys(files).length > 0 ? files : null;
  } catch {
    return null;
  }
}

export async function updateAgentFile(name: string, file: string, content: string): Promise<boolean> {
  if (!file.endsWith(".md") || file.includes("/") || file.includes("\\") || file.startsWith(".")) {
    return false;
  }
  const dir = safePath(name);
  if (!dir) return false;
  const filePath = path.join(dir, file);
  try {
    await fs.access(path.dirname(filePath));
    await fs.writeFile(filePath, content, "utf-8");
    return true;
  } catch {
    return false;
  }
}

export async function getTeamFile(): Promise<string | null> {
  try {
    return await fs.readFile(path.join(DATA_DIR, "TEAM.md"), "utf-8");
  } catch {
    return null;
  }
}

export async function updateTeamFile(content: string): Promise<boolean> {
  try {
    await fs.writeFile(path.join(DATA_DIR, "TEAM.md"), content, "utf-8");
    return true;
  } catch {
    return false;
  }
}

function safePath(name: string): string | null {
  if (name.includes("/") || name.includes("\\") || name.startsWith(".") || name.includes("..")) {
    return null;
  }
  return path.join(DATA_DIR, name);
}
