import type { ReactNode } from "react";
import type { LucideIcon } from "lucide-react";

import { Sidebar } from "@/components/layout/Sidebar";
import { TopBar } from "@/components/layout/TopBar";

type DashboardLayoutProps = {
  children: ReactNode;
  navItems?: {
    href: string;
    label: string;
    icon: LucideIcon;
  }[];
  title: string;
  userName?: string;
  roleLabel?: string;
};

export function DashboardLayout({
  children,
  navItems,
  title,
  userName,
  roleLabel,
}: DashboardLayoutProps) {
  return (
    <div className="flex min-h-screen bg-slate-50">
      <Sidebar navItems={navItems} roleLabel={roleLabel} userName={userName} />
      <div className="flex min-w-0 flex-1 flex-col">
        <TopBar title={title} />
        <main className="flex-1 p-4 xl:p-6">{children}</main>
      </div>
    </div>
  );
}
