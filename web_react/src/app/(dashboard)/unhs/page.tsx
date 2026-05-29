"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import {
  Activity,
  AlertCircle,
  Building2,
  ClipboardList,
  FileCheck2,
  ShieldCheck,
  TrendingUp,
  Users,
} from "lucide-react";

import { StatCard } from "@/components/shared/StatCard";
import { Badge } from "@/components/ui/badge";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { useLang } from "@/context/LanguageContext";
import api from "@/lib/api";
import { getToken, getUserFromToken } from "@/lib/auth";

type MonthlyReport = {
  hospital_id: string;
  hospital_name: string;
  year: number;
  month: number;
  total_screenings: number;
  total_pass: number;
  total_refer: number;
  total_not_tested: number;
  total_ltfu?: number | null;
};

type AuditLog = {
  id: number;
  action: string;
  table_name?: string | null;
  actor_name: string;
  created_at: string;
  hospital_name?: string | null;
};

const programmeSummary = [
  { key: "hospitalsActive", value: "1", icon: Building2 },
  { key: "coordinatorsActive", value: "1", icon: Users },
  { key: "reportsThisMonth", value: "1", icon: FileCheck2 },
  { key: "pendingAudits", value: "0", icon: ShieldCheck },
] as const;

function calculateRate(part: number, total: number) {
  if (total === 0) {
    return 0;
  }

  return Math.round((part / total) * 100);
}

function formatPercent(value: number) {
  return `${value}%`;
}

function getHospitalStatus(coverageRate: number) {
  if (coverageRate >= 80) {
    return {
      key: "onTrack",
      className: "bg-emerald-50 text-emerald-700 hover:bg-emerald-50",
    } as const;
  }

  if (coverageRate >= 60) {
    return {
      key: "monitor",
      className: "bg-amber-50 text-amber-700 hover:bg-amber-50",
    } as const;
  }

  return {
    key: "actionRequired",
    className: "bg-red-50 text-red-700 hover:bg-red-50",
  } as const;
}

function formatDateTime(value: string, lang: "en" | "ms") {
  return new Intl.DateTimeFormat(lang === "ms" ? "ms-MY" : "en-MY", {
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
    month: "short",
    year: "numeric",
  }).format(new Date(value));
}

export default function UnhsDashboardPage() {
  const router = useRouter();
  const { lang, t } = useLang();
  const [monthlyReport, setMonthlyReport] = useState<MonthlyReport | null>(null);
  const [auditLogs, setAuditLogs] = useState<AuditLog[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isAuditLoading, setIsAuditLoading] = useState(true);
  const [hasError, setHasError] = useState(false);
  const [auditError, setAuditError] = useState(false);

  useEffect(() => {
    const token = getToken();
    const user = getUserFromToken();

    if (!token || user?.role !== "unhs_coordinator") {
      router.replace("/login");
      return;
    }

    async function loadProgrammeOverview() {
      setIsLoading(true);
      setHasError(false);

      try {
        const response = await api.get<MonthlyReport>("/reports/monthly");
        setMonthlyReport(response.data);
      } catch {
        setHasError(true);
      } finally {
        setIsLoading(false);
      }
    }

    async function loadAuditLogs() {
      setIsAuditLoading(true);
      setAuditError(false);

      try {
        const response = await api.get<AuditLog[]>("/audit-logs/recent", {
          params: { limit: 10 },
        });
        setAuditLogs(response.data.slice(0, 10));
      } catch {
        setAuditError(true);
      } finally {
        setIsAuditLoading(false);
      }
    }

    void loadProgrammeOverview();
    void loadAuditLogs();
  }, [router]);

  const totalScreened = monthlyReport?.total_screenings ?? 0;
  const totalRefer = monthlyReport?.total_refer ?? 0;
  const totalLtfu = monthlyReport?.total_ltfu ?? monthlyReport?.total_not_tested ?? 0;
  const coverageRate = calculateRate(
    totalScreened,
    totalScreened + totalLtfu
  );
  const referRate = calculateRate(totalRefer, totalScreened);
  const hospitalStatus = getHospitalStatus(coverageRate);

  return (
    <div className="mx-auto flex max-w-7xl flex-col gap-5">
      <section className="overflow-hidden rounded-md border border-[#0F766E]/15 bg-white shadow-sm">
        <div className="flex flex-col gap-4 bg-[linear-gradient(135deg,#0F766E_0%,#115E59_50%,#134E4A_100%)] p-5 text-white sm:flex-row sm:items-center sm:justify-between">
          <div>
            <p className="text-sm font-medium text-white/75">
              {t("pilotPhase")}
            </p>
            <h2 className="mt-1 text-2xl font-semibold tracking-normal">
              {t("unhsDashboard")}
            </h2>
          </div>
          <div className="rounded-md bg-white/10 px-4 py-3 text-sm font-semibold ring-1 ring-white/15">
            {t("pilotCoverage")}: {formatPercent(coverageRate)}
          </div>
        </div>
      </section>

      {hasError ? (
        <div className="rounded-md border border-red-200 bg-red-50 px-4 py-3 text-sm font-medium text-red-700">
          {t("error")}
        </div>
      ) : null}

      <section className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <StatCard
          description={t("allHospitals")}
          icon={Activity}
          isLoading={isLoading}
          label={`${t("totalScreened")} (${t("allHospitals")})`}
          value={totalScreened.toLocaleString()}
        />
        <StatCard
          accentClassName="bg-emerald-500"
          description={t("allHospitals")}
          icon={TrendingUp}
          isLoading={isLoading}
          label={t("pilotCoverage")}
          value={formatPercent(coverageRate)}
        />
        <StatCard
          accentClassName="bg-amber-500"
          description={t("allHospitals")}
          icon={ClipboardList}
          isLoading={isLoading}
          label={t("totalReferReport")}
          value={totalRefer.toLocaleString()}
        />
        <StatCard
          accentClassName="bg-red-500"
          description={t("allHospitals")}
          icon={AlertCircle}
          isLoading={isLoading}
          label={t("totalLtfu")}
          value={totalLtfu.toLocaleString()}
        />
      </section>

      <section className="grid gap-5 xl:grid-cols-[minmax(0,1.15fr)_minmax(420px,0.85fr)]">
        <Card className="border-slate-200 bg-white shadow-sm">
          <CardHeader>
            <CardTitle className="text-slate-950">
              {t("hospitalPerformance")}
            </CardTitle>
            <CardDescription>{t("allHospitals")}</CardDescription>
          </CardHeader>
          <CardContent>
            {isLoading ? (
              <Skeleton className="h-24 w-full bg-slate-100" />
            ) : (
              <>
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead>{t("hospitalName")}</TableHead>
                      <TableHead>{t("coverageRate")}</TableHead>
                      <TableHead>{t("referRate")}</TableHead>
                      <TableHead>{t("ltfu")}</TableHead>
                      <TableHead>{t("status")}</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    <TableRow>
                      <TableCell className="font-medium text-slate-950">
                        {monthlyReport?.hospital_name ?? t("notRecorded")}
                      </TableCell>
                      <TableCell>{formatPercent(coverageRate)}</TableCell>
                      <TableCell>{formatPercent(referRate)}</TableCell>
                      <TableCell>{totalLtfu}</TableCell>
                      <TableCell>
                        <Badge className={hospitalStatus.className}>
                          {t(hospitalStatus.key)}
                        </Badge>
                      </TableCell>
                    </TableRow>
                  </TableBody>
                </Table>
                <p className="mt-3 rounded-md border border-amber-200 bg-amber-50 px-3 py-2 text-sm font-medium text-amber-800">
                  {t("pilotDataNote")}
                </p>
              </>
            )}
          </CardContent>
        </Card>

        <Card className="border-amber-200 bg-amber-50 shadow-sm">
          <CardHeader>
            <CardTitle className="text-amber-950">
              {t("nationalTrend")}
            </CardTitle>
            <CardDescription className="text-amber-800">
              {t("pilotPhase")}
            </CardDescription>
          </CardHeader>
          <CardContent>
            <div className="flex h-[320px] items-center rounded-md border border-amber-200 bg-white/70 p-6 text-sm font-medium leading-6 text-amber-900">
              {t("nationalTrendNotice")}
            </div>
          </CardContent>
        </Card>
      </section>

      <Card className="border-slate-200 bg-white shadow-sm">
        <CardHeader>
          <CardTitle className="text-slate-950">{t("auditLog")}</CardTitle>
          <CardDescription>{t("allHospitals")}</CardDescription>
        </CardHeader>
        <CardContent>
          {auditError ? (
            <div className="rounded-md border border-red-200 bg-red-50 px-4 py-3 text-sm font-medium text-red-700">
              {t("error")}
            </div>
          ) : isAuditLoading ? (
            <div className="space-y-3">
              {Array.from({ length: 6 }, (_, index) => (
                <Skeleton className="h-10 w-full bg-slate-100" key={index} />
              ))}
            </div>
          ) : auditLogs.length === 0 ? (
            <div className="rounded-md border border-dashed border-slate-200 py-10 text-center text-sm text-slate-500">
              <ShieldCheck className="mx-auto mb-3 size-7 text-slate-300" />
              {t("noAuditLogs")}
            </div>
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>{t("timestamp")}</TableHead>
                  <TableHead>{t("user")}</TableHead>
                  <TableHead>{t("action")}</TableHead>
                  <TableHead>{t("hospitalName")}</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {auditLogs.map((log) => (
                  <TableRow key={log.id}>
                    <TableCell className="text-slate-600">
                      {formatDateTime(log.created_at, lang)}
                    </TableCell>
                    <TableCell className="font-medium text-slate-950">
                      {log.actor_name}
                    </TableCell>
                    <TableCell className="text-slate-600">
                      {log.action}
                      {log.table_name ? ` / ${log.table_name}` : ""}
                    </TableCell>
                    <TableCell className="text-slate-600">
                      {log.hospital_name ?? t("allHospitals")}
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          )}
        </CardContent>
      </Card>

      <section>
        <h3 className="mb-3 text-sm font-semibold uppercase tracking-wide text-slate-500">
          {t("programSummary")}
        </h3>
        <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
          {programmeSummary.map((item) => (
            <StatCard
              description={t("allHospitals")}
              icon={item.icon}
              key={item.key}
              label={t(item.key)}
              value={item.value}
            />
          ))}
        </div>
      </section>
    </div>
  );
}
