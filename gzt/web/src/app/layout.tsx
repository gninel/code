import type { Metadata } from "next";
import { Geist, Geist_Mono } from "next/font/google";
import "./globals.css";

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: "思辨智教 - 教师工作台",
  description: "AI 驱动的教学设计辅助工具",
};

import Sidebar from "@/components/Sidebar";

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="zh-CN">
      <body className={`${geistSans.variable} ${geistMono.variable} flex h-screen overflow-hidden`}>
        {/* Sidebar removed from root layout, moved to (main) layout */}
        <div className="flex-1 overflow-auto bg-muted/20">
          {children}
        </div>
      </body>
    </html>
  );
}
