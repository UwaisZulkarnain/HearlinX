"use client";

import type { ReactNode } from "react";
import { LayoutDashboard } from "lucide-react";

import { DashboardLayout } from "@/components/layout/DashboardLayout";
import { useLang } from "@/context/LanguageContext";

export default function MohLayout({ children }: { children: ReactNode }) {
  const { t } = useLang();

  const navItems = [
    {
      href: "/moh",
      label: t("navDashboard"),
      icon: LayoutDashboard,
    },
  ];

  return (
    <DashboardLayout
      navItems={navItems}
      roleLabel={t("ministryRole")}
      title={t("mohDashboard")}
      userName={t("ministryOfHealth")}
    >
      {children}
    </DashboardLayout>
  );
}
