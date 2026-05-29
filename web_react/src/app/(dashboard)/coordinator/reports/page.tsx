"use client";

import { useEffect, useMemo, useState } from "react";
import { useRouter } from "next/navigation";
import {
  AlertCircle,
  BarChart3,
  CheckCircle2,
  Download,
  FileSpreadsheet,
  Printer,
} from "lucide-react";

import { DashboardLayout } from "@/components/layout/DashboardLayout";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
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
import type { Role } from "@/types";

type MonthlyReport = {
  hospital_id: string;
  hospital_name: string;
  year: number;
  month: number;
  total_screenings: number;
  total_pass: number;
  total_refer: number;
  total_not_tested: number;
  total_births?: number | null;
};

type AuthPayload = {
  role?: Role;
  full_name?: string;
  name?: string;
};

type SummaryMetric = {
  label: string;
  value: string;
};

const benchmarkValues = [
  { key: "screen1m", value: 75 },
  { key: "diagnose3m", value: 60 },
  { key: "intervene6m", value: 45 },
] as const;

const currentDate = new Date();
const currentYear = currentDate.getFullYear();
const yearOptions = Array.from({ length: 5 }, (_, index) => currentYear - 2 + index);

function calculateRate(part: number, total: number) {
  if (total === 0) {
    return 0;
  }

  return Math.round((part / total) * 100);
}

function formatPercent(value: number) {
  return `${value}%`;
}

function getBenchmarkColor(value: number) {
  if (value >= 80) {
    return "bg-emerald-500";
  }

  if (value >= 50) {
    return "bg-amber-500";
  }

  return "bg-red-500";
}

function decodeTokenPayload(): AuthPayload | null {
  const token = getToken();

  if (!token) {
    return null;
  }

  try {
    const [, payload] = token.split(".");

    if (!payload) {
      return null;
    }

    const normalized = payload.replace(/-/g, "+").replace(/_/g, "/");
    const padded = normalized.padEnd(
      normalized.length + ((4 - (normalized.length % 4)) % 4),
      "="
    );

    return JSON.parse(window.atob(padded)) as AuthPayload;
  } catch {
    return null;
  }
}

function hasValue(value: unknown) {
  return value !== null && value !== undefined && value !== "";
}

export default function CoordinatorReportsPage() {
  const router = useRouter();
  const { lang, t } = useLang();
  const [selectedMonth, setSelectedMonth] = useState(currentDate.getMonth() + 1);
  const [selectedYear, setSelectedYear] = useState(currentYear);
  const [report, setReport] = useState<MonthlyReport | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [isExporting, setIsExporting] = useState(false);
  const [hasError, setHasError] = useState(false);
  const [userName, setUserName] = useState("");

  const monthOptions = useMemo(
    () =>
      Array.from({ length: 12 }, (_, index) => ({
        value: index + 1,
        label: new Intl.DateTimeFormat(lang === "ms" ? "ms-MY" : "en-MY", {
          month: "long",
        }).format(new Date(currentYear, index, 1)),
      })),
    [lang]
  );

  async function loadReport(year: number, month: number) {
    setIsLoading(true);
    setHasError(false);

    try {
      const response = await api.get<MonthlyReport>("/reports/monthly", {
        params: { year, month },
      });
      setReport(response.data);
    } catch {
      setHasError(true);
    } finally {
      setIsLoading(false);
    }
  }

  useEffect(() => {
    const token = getToken();
    const user = getUserFromToken();

    if (!token || user?.role !== "coordinator") {
      router.replace("/login");
      return;
    }

    const payload = decodeTokenPayload();
    setUserName(payload?.full_name ?? payload?.name ?? "");
    void loadReport(currentYear, currentDate.getMonth() + 1);
  }, [router]);

  const totalScreened = report?.total_screenings ?? 0;
  const totalBirths = report?.total_births ?? totalScreened;
  const totalPass = report?.total_pass ?? 0;
  const totalRefer = report?.total_refer ?? 0;
  const ltfuCount = report?.total_not_tested ?? 0;
  const coverageRate = calculateRate(totalScreened, totalBirths);
  const referRate = calculateRate(totalRefer, totalScreened);
  const isDataComplete =
    report !== null &&
    hasValue(report.hospital_name) &&
    hasValue(report.total_screenings) &&
    hasValue(report.total_pass) &&
    hasValue(report.total_refer) &&
    hasValue(report.total_not_tested);

  const summaryMetrics: SummaryMetric[] = [
    { label: t("totalBirths"), value: totalBirths.toLocaleString() },
    { label: t("totalScreened"), value: totalScreened.toLocaleString() },
    { label: t("coverageRate"), value: formatPercent(coverageRate) },
    { label: t("totalPassReport"), value: totalPass.toLocaleString() },
    { label: t("totalReferReport"), value: totalRefer.toLocaleString() },
    { label: t("referRate"), value: formatPercent(referRate) },
    { label: t("ltfuCount"), value: ltfuCount.toLocaleString() },
  ];

  async function handleExportExcel() {
    setIsExporting(true);

    try {
      const response = await api.get<Blob>("/reports/export", {
        params: {
          year: selectedYear,
          month: selectedMonth,
        },
        responseType: "blob",
      });
      const downloadUrl = window.URL.createObjectURL(response.data);
      const anchor = document.createElement("a");

      anchor.href = downloadUrl;
      anchor.download = `monthly_report_${selectedYear}_${String(
        selectedMonth
      ).padStart(2, "0")}.xlsx`;
      document.body.appendChild(anchor);
      anchor.click();
      anchor.remove();
      window.URL.revokeObjectURL(downloadUrl);
    } catch {
      setHasError(true);
    } finally {
      setIsExporting(false);
    }
  }

  return (
    <DashboardLayout
      roleLabel={t("coordinator")}
      title={t("reports")}
      userName={userName}
    >
      <div className="mx-auto flex max-w-7xl flex-col gap-5">
        <section className="overflow-hidden rounded-md border border-[#0F766E]/15 bg-white shadow-sm">
          <div className="flex flex-col gap-4 bg-[linear-gradient(135deg,#0F766E_0%,#115E59_50%,#134E4A_100%)] p-5 text-white lg:flex-row lg:items-center lg:justify-between">
            <div>
              <p className="text-sm font-medium text-white/75">
                {t("monthlyReport")}
              </p>
              <h2 className="mt-1 text-2xl font-semibold tracking-normal">
                {t("reports")}
              </h2>
            </div>

            <div className="grid gap-2 sm:grid-cols-[minmax(150px,1fr)_120px_auto]">
              <label className="sr-only" htmlFor="report-month">
                {t("selectMonth")}
              </label>
              <select
                className="h-10 rounded-md border border-white/20 bg-white px-3 text-sm font-medium text-slate-900 shadow-sm outline-none focus:ring-2 focus:ring-white/70"
                id="report-month"
                onChange={(event) => setSelectedMonth(Number(event.target.value))}
                value={selectedMonth}
              >
                {monthOptions.map((month) => (
                  <option key={month.value} value={month.value}>
                    {month.label}
                  </option>
                ))}
              </select>

              <label className="sr-only" htmlFor="report-year">
                {t("selectYear")}
              </label>
              <select
                className="h-10 rounded-md border border-white/20 bg-white px-3 text-sm font-medium text-slate-900 shadow-sm outline-none focus:ring-2 focus:ring-white/70"
                id="report-year"
                onChange={(event) => setSelectedYear(Number(event.target.value))}
                value={selectedYear}
              >
                {yearOptions.map((year) => (
                  <option key={year} value={year}>
                    {year}
                  </option>
                ))}
              </select>

              <Button
                className="bg-white text-[#0F766E] hover:bg-white/90"
                disabled={isLoading}
                onClick={() => void loadReport(selectedYear, selectedMonth)}
              >
                <BarChart3 className="mr-2 size-4" />
                {t("generateReport")}
              </Button>
            </div>
          </div>
        </section>

        {hasError ? (
          <div className="rounded-md border border-red-200 bg-red-50 px-4 py-3 text-sm font-medium text-red-700">
            {t("error")}
          </div>
        ) : null}

        <Card className="border-slate-200 bg-white shadow-sm">
          <CardHeader className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
            <div>
              <CardTitle className="flex items-center gap-2 text-slate-950">
                <FileSpreadsheet className="size-5 text-[#0F766E]" />
                {t("monthlyReport")}
              </CardTitle>
              <CardDescription>
                {isLoading ? (
                  <Skeleton className="mt-1 h-4 w-52 bg-slate-100" />
                ) : (
                  `${t("hospitalName")}: ${
                    report?.hospital_name ?? t("notRecorded")
                  }`
                )}
              </CardDescription>
            </div>
            {isLoading ? (
              <Skeleton className="h-6 w-32 bg-slate-100" />
            ) : (
              <Badge
                className={
                  isDataComplete
                    ? "bg-emerald-50 text-emerald-700 hover:bg-emerald-50"
                    : "bg-amber-50 text-amber-700 hover:bg-amber-50"
                }
              >
                {isDataComplete ? (
                  <CheckCircle2 className="mr-1.5 size-3.5" />
                ) : (
                  <AlertCircle className="mr-1.5 size-3.5" />
                )}
                {isDataComplete ? t("dataComplete") : t("dataPartial")}
              </Badge>
            )}
          </CardHeader>
          <CardContent>
            {isLoading ? (
              <div className="grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
                {Array.from({ length: 8 }, (_, index) => (
                  <Skeleton className="h-24 w-full bg-slate-100" key={index} />
                ))}
              </div>
            ) : (
              <div className="grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
                {summaryMetrics.map((metric) => (
                  <div
                    className="rounded-md border border-slate-200 bg-slate-50/80 p-4"
                    key={metric.label}
                  >
                    <p className="text-xs font-medium uppercase tracking-wide text-slate-500">
                      {metric.label}
                    </p>
                    <p className="mt-2 text-2xl font-semibold text-slate-950">
                      {metric.value}
                    </p>
                  </div>
                ))}
              </div>
            )}
          </CardContent>
        </Card>

        <section className="grid gap-5 xl:grid-cols-[minmax(0,1fr)_360px]">
          <Card className="border-slate-200 bg-white shadow-sm">
            <CardHeader>
              <CardTitle className="text-slate-950">{t("benchmark")}</CardTitle>
              <CardDescription>{t("benchmarkDescription")}</CardDescription>
            </CardHeader>
            <CardContent className="space-y-5">
              {benchmarkValues.map((benchmark) => (
                <div className="space-y-2" key={benchmark.key}>
                  <div className="flex items-center justify-between gap-3">
                    <p className="text-sm font-medium text-slate-700">
                      {t(benchmark.key)}
                    </p>
                    <p className="text-sm font-semibold text-slate-950">
                      {formatPercent(benchmark.value)}
                    </p>
                  </div>
                  <div className="h-2.5 overflow-hidden rounded-full bg-slate-100">
                    <div
                      className={`${getBenchmarkColor(
                        benchmark.value
                      )} h-full rounded-full transition-all`}
                      style={{ width: `${benchmark.value}%` }}
                    />
                  </div>
                </div>
              ))}
            </CardContent>
          </Card>

          <Card className="border-slate-200 bg-white shadow-sm">
            <CardHeader>
              <CardTitle className="text-slate-950">{t("export")}</CardTitle>
              <CardDescription>{t("monthlyReport")}</CardDescription>
            </CardHeader>
            <CardContent className="grid gap-3">
              <Button
                className="bg-[#0F766E] text-white hover:bg-[#115E59]"
                disabled={isExporting}
                onClick={() => void handleExportExcel()}
              >
                <Download className="mr-2 size-4" />
                {t("exportExcel")}
              </Button>
              <Button onClick={() => window.print()} variant="outline">
                <Printer className="mr-2 size-4" />
                {t("exportPdf")}
              </Button>
            </CardContent>
          </Card>
        </section>

        <Card className="border-slate-200 bg-white shadow-sm">
          <CardHeader>
            <CardTitle className="text-slate-950">
              {t("submissionLog")}
            </CardTitle>
            <CardDescription>{t("monthlyReport")}</CardDescription>
          </CardHeader>
          <CardContent>
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>{t("date")}</TableHead>
                  <TableHead>{t("exportedBy")}</TableHead>
                  <TableHead>{t("format")}</TableHead>
                  <TableHead>{t("status")}</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                <TableRow>
                  <TableCell
                    className="py-10 text-center text-sm text-slate-500"
                    colSpan={4}
                  >
                    <CheckCircle2 className="mx-auto mb-3 size-7 text-emerald-500" />
                    {t("noExports")}
                  </TableCell>
                </TableRow>
              </TableBody>
            </Table>
          </CardContent>
        </Card>
      </div>
    </DashboardLayout>
  );
}
