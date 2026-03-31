export interface AgentIdentity {
  name: string;
  creature: string;
  vibe: string;
  emoji: string;
  avatar: string;
}

export function parseIdentity(markdown: string): AgentIdentity {
  const get = (key: string) => {
    const m = markdown.match(new RegExp(`\\*\\*${key}:\\*\\*\\s*(.*)`, "i"));
    return m?.[1]?.trim() || "";
  };
  return {
    name: get("Name"),
    creature: get("Creature"),
    vibe: get("Vibe"),
    emoji: get("Emoji"),
    avatar: get("Avatar"),
  };
}
