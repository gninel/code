import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "睿智教 AI课堂分析",
  description: "AI辅助教学设计与评估平台",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="zh-CN">
      <body className="flex h-screen overflow-hidden antialiased">
        {/* Sidebar removed from root layout, moved to (main) layout */}
        <div className="flex-1 overflow-auto bg-muted/20">
          {children}
        </div>
      </body>
    </html>
  );
}
