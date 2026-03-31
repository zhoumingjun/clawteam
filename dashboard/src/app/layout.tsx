import type { Metadata } from "next";
import Link from "next/link";
import "./globals.css";

export const metadata: Metadata = {
  title: "Claw Team Dashboard",
  description: "AI Agent Management",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="zh-CN">
      <body className="bg-gray-50 text-gray-900">
        <div className="flex h-screen">
          <nav className="w-56 bg-gray-900 text-gray-100 flex flex-col p-4 shrink-0">
            <Link href="/" className="text-xl font-bold mb-8 hover:text-white">
              Claw Team
            </Link>
            <Link href="/" className="py-2 px-3 rounded hover:bg-gray-700 mb-1">
              Agents
            </Link>
            <Link href="/team" className="py-2 px-3 rounded hover:bg-gray-700 mb-1">
              Team
            </Link>
          </nav>
          <main className="flex-1 overflow-auto p-6">{children}</main>
        </div>
      </body>
    </html>
  );
}
