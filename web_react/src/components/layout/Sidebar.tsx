"use client";

import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import {
  Baby,
  ClipboardList,
  Ear,
  FileBarChart,
  LayoutDashboard,
  LogOut,
  Users,
  type LucideIcon,
} from "lucide-react";

import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { useLang } from "@/context/LanguageContext";
import { removeToken } from "@/lib/auth";
import { cn } from "@/lib/utils";

type SidebarProps = {
  navItems?: {
    href: string;
    label: string;
    icon: LucideIcon;
  }[];
  userName?: string;
  roleLabel?: string;
};

export function Sidebar({ navItems, userName, roleLabel }: SidebarProps) {
  const pathname = usePathname();
  const router = useRouter();
  const { t } = useLang();
  const navigationItems =
    navItems ?? [
    {
      href: "/coordinator",
      label: t("navDashboard"),
      icon: LayoutDashboard,
    },
    {
      href: "/coordinator/followups",
      label: t("navFollowups"),
      icon: ClipboardList,
    },
    {
      href: "/coordinator/screenings",
      label: t("recentScreenings"),
      icon: Ear,
    },
    {
      href: "/coordinator/babies",
      label: t("navRegisterBaby"),
      icon: Baby,
    },
    {
      href: "/coordinator/users",
      label: t("navManageUsers"),
      icon: Users,
    },
    {
      href: "/coordinator/reports",
      label: t("navReports"),
      icon: FileBarChart,
    },
  ];

  function handleLogout() {
    removeToken();
    router.push("/login");
  }

  return (
    <aside className="hidden min-h-screen w-72 border-r border-slate-200 bg-white lg:flex lg:flex-col">
      <div className="border-b border-slate-100 px-5 py-5">
        <p className="text-2xl font-bold tracking-normal text-[#0F766E]">
          {t("brand")}
        </p>
        <p className="mt-1 text-xs font-medium text-slate-500">
          {t("tagline")}
        </p>
      </div>

      <nav className="grid gap-1 p-3">
        {navigationItems.map((item) => (
          <Link
            className={cn(
              "flex items-center gap-3 rounded-md px-3 py-2.5 text-sm font-medium transition-colors",
              pathname === item.href
                ? "bg-[#0F766E] text-white shadow-sm"
                : "text-slate-600 hover:bg-slate-100 hover:text-slate-950"
            )}
            href={item.href}
            key={item.href}
          >
            <item.icon className="size-4" />
            {item.label}
          </Link>
        ))}
      </nav>

      <div className="mt-auto border-t border-slate-100 p-4">
        <div className="mb-3 rounded-md bg-slate-50 p-3">
          <p className="truncate text-sm font-semibold text-slate-950">
            {userName || t("hospitalCoordinator")}
          </p>
          <Badge className="mt-2 bg-[#0F766E]/10 text-[#0F766E] hover:bg-[#0F766E]/10">
            {roleLabel || t("coordinator")}
          </Badge>
        </div>
        <Button
          className="w-full justify-start gap-2 text-slate-600 hover:text-slate-950"
          onClick={handleLogout}
          type="button"
          variant="ghost"
        >
          <LogOut className="size-4" />
          {t("navLogout")}
        </Button>
      </div>
    </aside>
  );
}
