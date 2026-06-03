"use client";

import type { ReactNode } from "react";
import { LayoutDashboard, Users } from "lucide-react";

import { DashboardLayout } from "@/components/layout/DashboardLayout";
import { useLang } from "@/context/LanguageContext";

export default function UnhsLayout({ children }: { children: ReactNode }) {
  const { t } = useLang();

  const navItems = [
    {
      href: "/unhs",
      label: t("navDashboard"),
      icon: LayoutDashboard,
    },
    {
      href: "/unhs/users",
      label: t("navManageUsers"),
      icon: Users,
    },
  ];

  return (
    <DashboardLayout
      navItems={navItems}
      roleLabel={t("unhsDashboard")}
      title={t("unhsDashboard")}
      userName={t("allHospitals")}
    >
      {children}
    </DashboardLayout>
  );
}
