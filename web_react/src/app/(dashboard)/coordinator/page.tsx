"use client";

import { useEffect, useMemo, useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import {
  Activity,
  AlertTriangle,
  Baby,
  ClipboardList,
  Ear,
  TrendingDown,
  TrendingUp,
  Users,
} from "lucide-react";
import {
  CartesianGrid,
  Line,
  LineChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts";

import { DashboardLayout } from "@/components/layout/DashboardLayout";
import { StatCard } from "@/components/shared/StatCard";
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
import { useAuth } from "@/hooks/useAuth";
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
};

type Screening = {
  id: string;
  baby_id: string;
  baby_system_id?: string | null;
  screener_id: string;
  hospital_id: string;
  screening_type: string;
  ear_left: string;
  ear_right: string;
  screening_date: string;
  attempt_number: number;
  notes?: string | null;
  created_at: string;
  ward?: string | null;
  screener_name?: string | null;
};

type AuthPayload = {
  user_id?: string;
  role?: Role;
  full_name?: string;
  name?: string;
};

type TrendPoint = MonthlyReport & {
  label: string;
};

type BenchmarkReport = {
  screened_by_1_month_pct: number;
  diagnosed_by_3_months_pct: number;
};

type CoverageReport = {
  total_babies_registered: number;
  total_babies_screened: number;
  coverage_rate_pct: number;
};

type WardBreakdownItem = {
  ward?: string | null;
  total_screenings: number;
  total_refer: number;
  refer_rate_pct: number;
};

type WardBreakdownResponse = WardBreakdownItem[] | { wards: WardBreakdownItem[] };

function getMonthRequests() {
  const now = new Date();

  return Array.from({ length: 6 }, (_, index) => {
    const date = new Date(now.getFullYear(), now.getMonth() - (5 - index), 1);

    return {
      year: date.getFullYear(),
      month: date.getMonth() + 1,
      label: date.toLocaleString("en", { month: "short" }),
    };
  });
}

function calculateRate(part: number, total: number) {
  if (total === 0) {
    return 0;
  }

  return Math.round((part / total) * 100);
}

function formatPercent(value: number) {
  return `${Number.isInteger(value) ? value : value.toFixed(1)}%`;
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

function getBenchmarkColor(value: number) {
  if (value >= 90) {
    return "bg-emerald-500";
  }

  if (value >= 70) {
    return "bg-amber-500";
  }

  return "bg-red-500";
}

function getBenchmarkTextColor(value: number) {
  if (value >= 90) {
    return "text-emerald-700";
  }

  if (value >= 70) {
    return "text-amber-700";
  }

  return "text-red-700";
}

function getReferRateClassName(value: number) {
  if (value < 10) {
    return "bg-emerald-50 text-emerald-700 hover:bg-emerald-50";
  }

  if (value <= 20) {
    return "bg-amber-50 text-amber-700 hover:bg-amber-50";
  }

  return "bg-red-50 text-red-700 hover:bg-red-50";
}

function progressWidth(value: number) {
  return `${Math.min(Math.max(value, 0), 100)}%`;
}

function getScreeningResult(screening: Screening) {
  if (screening.ear_left === "refer" || screening.ear_right === "refer") {
    return "refer";
  }

  return "pass";
}

function formatDate(value: string, lang: "en" | "ms") {
  return new Intl.DateTimeFormat(lang === "ms" ? "ms-MY" : "en-MY", {
    day: "2-digit",
    month: "short",
    year: "numeric",
  }).format(new Date(value));
}

function shortId(value: string) {
  return value.slice(0, 8).toUpperCase();
}

export default function CoordinatorDashboardPage() {
  const router = useRouter();
  const { user } = useAuth();
  const { lang, t } = useLang();
  const [monthlyReports, setMonthlyReports] = useState<TrendPoint[]>([]);
  const [screenings, setScreenings] = useState<Screening[]>([]);
  const [benchmark, setBenchmark] = useState<BenchmarkReport | null>(null);
  const [coverage, setCoverage] = useState<CoverageReport | null>(null);
  const [wardBreakdown, setWardBreakdown] = useState<WardBreakdownItem[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isBenchmarkLoading, setIsBenchmarkLoading] = useState(true);
  const [isCoverageLoading, setIsCoverageLoading] = useState(true);
  const [isWardBreakdownLoading, setIsWardBreakdownLoading] = useState(true);
  const [hasError, setHasError] = useState(false);
  const [userName, setUserName] = useState("");

  useEffect(() => {
    const token = getToken();
    const user = getUserFromToken();

    if (!token || user?.role !== "coordinator") {
      router.replace("/login");
      return;
    }

    const payload = decodeTokenPayload();
    setUserName(payload?.full_name ?? payload?.name ?? "");

    async function loadDashboard() {
      setIsLoading(true);
      setHasError(false);

      try {
        const monthRequests = getMonthRequests();
        const [monthlyResponses, screeningsResponse] = await Promise.all([
          Promise.all(
            monthRequests.map((month) =>
              api.get<MonthlyReport>("/reports/monthly", {
                params: {
                  year: month.year,
                  month: month.month,
                },
              })
            )
          ),
          api.get<Screening[]>("/screenings/"),
        ]);

        setMonthlyReports(
          monthlyResponses.map((response, index) => ({
            ...response.data,
            label: monthRequests[index].label,
          }))
        );
        setScreenings(screeningsResponse.data.slice(0, 10));
      } catch {
        setHasError(true);
      } finally {
        setIsLoading(false);
      }
    }

    void loadDashboard();
  }, [router]);

  useEffect(() => {
    if (user?.role !== "coordinator") {
      return;
    }

    async function loadBenchmark() {
      setIsBenchmarkLoading(true);

      try {
        const response = await api.get<BenchmarkReport>("/reports/benchmark");
        setBenchmark(response.data);
      } catch {
        setHasError(true);
      } finally {
        setIsBenchmarkLoading(false);
      }
    }

    void loadBenchmark();
  }, [user?.role]);

  useEffect(() => {
    if (user?.role !== "coordinator") {
      return;
    }

    async function loadCoverage() {
      setIsCoverageLoading(true);

      try {
        const response = await api.get<CoverageReport>("/reports/coverage");
        setCoverage(response.data);
      } catch {
        setHasError(true);
      } finally {
        setIsCoverageLoading(false);
      }
    }

    void loadCoverage();
  }, [user?.role]);

  useEffect(() => {
    if (user?.role !== "coordinator") {
      return;
    }

    async function loadWardBreakdown() {
      setIsWardBreakdownLoading(true);

      try {
        const response = await api.get<WardBreakdownResponse>(
          "/reports/ward-breakdown"
        );
        const wards = Array.isArray(response.data)
          ? response.data
          : response.data.wards ?? [];
        setWardBreakdown(wards);
      } catch {
        setHasError(true);
      } finally {
        setIsWardBreakdownLoading(false);
      }
    }

    void loadWardBreakdown();
  }, [user?.role]);

  const latestReport = monthlyReports.at(-1);
  const totalScreened = latestReport?.total_screenings ?? 0;
  const passRate = calculateRate(latestReport?.total_pass ?? 0, totalScreened);
  const referRate = calculateRate(latestReport?.total_refer ?? 0, totalScreened);
  const ltfuCount = latestReport?.total_not_tested ?? 0;
  const outstandingFollowUps = latestReport?.total_refer ?? 0;
  const benchmarkValues = [
    {
      label: "Disaring dalam 1 bulan",
      value: benchmark?.screened_by_1_month_pct ?? 0,
    },
    {
      label: "Diagnosis dalam 3 bulan",
      value: benchmark?.diagnosed_by_3_months_pct ?? 0,
    },
  ];
  const coverageRate = coverage?.coverage_rate_pct ?? 0;

  const chartData = useMemo(
    () =>
      monthlyReports.map((report) => ({
        month: new Date(report.year, report.month - 1).toLocaleString(
          lang === "ms" ? "ms-MY" : "en-MY",
          { month: "short" }
        ),
        total_screenings: report.total_screenings,
        total_pass: report.total_pass,
        total_refer: report.total_refer,
      })),
    [lang, monthlyReports]
  );

  return (
    <DashboardLayout
      roleLabel={t("coordinator")}
      title={t("coordinatorDashboard")}
      userName={userName}
    >
      <div className="mx-auto flex max-w-7xl flex-col gap-5">
        <section className="overflow-hidden rounded-md border border-[#0F766E]/15 bg-white shadow-sm">
          <div className="flex flex-col gap-4 bg-[linear-gradient(135deg,#0F766E_0%,#115E59_50%,#134E4A_100%)] p-5 text-white sm:flex-row sm:items-center sm:justify-between">
            <div>
              <p className="text-sm font-medium text-white/75">
                {t("hospitalOverview")}
              </p>
              <h2 className="mt-1 text-2xl font-semibold tracking-normal">
                {t("coordinatorDashboard")}
              </h2>
            </div>
            <div className="grid grid-cols-3 gap-2 rounded-md bg-white/10 p-2 text-center ring-1 ring-white/15">
              <div className="px-3">
                <p className="text-lg font-semibold">{totalScreened}</p>
                <p className="text-[11px] text-white/70">
                  {t("totalScreenings")}
                </p>
              </div>
              <div className="border-x border-white/15 px-3">
                <p className="text-lg font-semibold">{formatPercent(passRate)}</p>
                <p className="text-[11px] text-white/70">{t("totalPass")}</p>
              </div>
              <div className="px-3">
                <p className="text-lg font-semibold">
                  {formatPercent(referRate)}
                </p>
                <p className="text-[11px] text-white/70">{t("totalRefer")}</p>
              </div>
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
            description={t("currentMonth")}
            icon={Users}
            isLoading={isLoading}
            label={t("statTotalScreened")}
            value={totalScreened.toLocaleString()}
          />
          <StatCard
            accentClassName="bg-emerald-500"
            description={t("currentMonth")}
            icon={TrendingUp}
            isLoading={isLoading}
            label={t("statPassRate")}
            value={formatPercent(passRate)}
          />
          <StatCard
            accentClassName="bg-amber-500"
            description={t("currentMonth")}
            icon={Activity}
            isLoading={isLoading}
            label={t("statReferRate")}
            value={formatPercent(referRate)}
          />
          <StatCard
            accentClassName="bg-red-500"
            description={t("currentMonth")}
            icon={TrendingDown}
            isLoading={isLoading}
            label={t("statLtfu")}
            value={ltfuCount.toLocaleString()}
          />
        </section>

        <section className="grid gap-5 xl:grid-cols-[minmax(0,1.5fr)_minmax(340px,1fr)]">
          <Card className="border-slate-200 bg-white shadow-sm">
            <CardHeader>
              <CardTitle className="flex items-center gap-2 text-slate-950">
                <Ear className="size-5 text-[#0F766E]" />
                {t("trendChart")}
              </CardTitle>
              <CardDescription>{t("trendDescription")}</CardDescription>
            </CardHeader>
            <CardContent>
              {isLoading ? (
                <Skeleton className="h-[320px] w-full bg-slate-100" />
              ) : (
                <div className="h-[320px]">
                  <ResponsiveContainer height="100%" width="100%">
                    <LineChart
                      data={chartData}
                      margin={{ bottom: 8, left: -16, right: 12, top: 12 }}
                    >
                      <CartesianGrid stroke="#E2E8F0" strokeDasharray="4 4" />
                      <XAxis
                        dataKey="month"
                        stroke="#64748B"
                        tickLine={false}
                      />
                      <YAxis stroke="#64748B" tickLine={false} />
                      <Tooltip
                        contentStyle={{
                          borderColor: "#CBD5E1",
                          borderRadius: 8,
                          boxShadow: "0 12px 30px rgba(15, 23, 42, 0.12)",
                        }}
                      />
                      <Line
                        dataKey="total_screenings"
                        name={t("totalScreenings")}
                        stroke="#0F766E"
                        strokeWidth={3}
                        type="monotone"
                      />
                      <Line
                        dataKey="total_pass"
                        name={t("totalPass")}
                        stroke="#16A34A"
                        strokeWidth={3}
                        type="monotone"
                      />
                      <Line
                        dataKey="total_refer"
                        name={t("totalRefer")}
                        stroke="#F59E0B"
                        strokeWidth={3}
                        type="monotone"
                      />
                    </LineChart>
                  </ResponsiveContainer>
                </div>
              )}
            </CardContent>
          </Card>

          <Card className="border-slate-200 bg-white shadow-sm">
            <CardHeader>
              <CardTitle className="text-slate-950">
                {t("benchmark")}
              </CardTitle>
              <CardDescription>{t("benchmarkDescription")}</CardDescription>
            </CardHeader>
            <CardContent className="space-y-5">
              {isBenchmarkLoading ? (
                <div className="space-y-4">
                  <Skeleton className="h-12 w-full bg-slate-100" />
                  <Skeleton className="h-12 w-full bg-slate-100" />
                </div>
              ) : (
                <>
                  <div className="rounded-md bg-slate-50 px-3 py-2 text-xs font-semibold text-slate-600">
                    Sasaran KKM ≥90%
                  </div>
                  {benchmarkValues.map((item) => (
                    <div className="space-y-2" key={item.label}>
                      <div className="flex items-center justify-between gap-3">
                        <p className="text-sm font-medium text-slate-700">
                          {item.label}: {formatPercent(item.value)}
                        </p>
                        <p
                          className={`text-sm font-semibold ${getBenchmarkTextColor(
                            item.value
                          )}`}
                        >
                          {formatPercent(item.value)}
                        </p>
                      </div>
                      <div className="h-2.5 overflow-hidden rounded-full bg-slate-100">
                        <div
                          className={`${getBenchmarkColor(
                            item.value
                          )} h-full rounded-full transition-all`}
                          style={{ width: progressWidth(item.value) }}
                        />
                      </div>
                    </div>
                  ))}
                </>
              )}
            </CardContent>
          </Card>
        </section>

        <section className="grid gap-5 xl:grid-cols-[minmax(300px,0.8fr)_minmax(0,1.2fr)]">
          <Card className="border-slate-200 bg-white shadow-sm">
            <CardHeader>
              <CardTitle className="text-slate-950">
                {t("coverageRate")}
              </CardTitle>
              <CardDescription>{t("currentMonth")}</CardDescription>
            </CardHeader>
            <CardContent>
              {isCoverageLoading ? (
                <div className="space-y-4">
                  <Skeleton className="h-16 w-32 bg-slate-100" />
                  <Skeleton className="h-3 w-full bg-slate-100" />
                  <Skeleton className="h-4 w-40 bg-slate-100" />
                </div>
              ) : (
                <div className="space-y-4">
                  <div className="flex items-end gap-2">
                    <span className="text-5xl font-semibold tracking-normal text-[#0F766E]">
                      {formatPercent(coverageRate)}
                    </span>
                    <span className="pb-2 text-sm font-medium text-slate-500">
                      {t("coverageRate")}
                    </span>
                  </div>
                  <div className="h-3 overflow-hidden rounded-full bg-slate-100">
                    <div
                      className="h-full rounded-full bg-[#0F766E] transition-all"
                      style={{ width: progressWidth(coverageRate) }}
                    />
                  </div>
                  <p className="text-sm font-medium text-slate-600">
                    {(coverage?.total_babies_screened ?? 0).toLocaleString()} /{" "}
                    {(coverage?.total_babies_registered ?? 0).toLocaleString()}{" "}
                    bayi disaring
                  </p>
                </div>
              )}
            </CardContent>
          </Card>

          <Card className="border-slate-200 bg-white shadow-sm">
            <CardHeader>
              <CardTitle className="text-slate-950">Pecahan Wad</CardTitle>
              <CardDescription>{t("referRate")}</CardDescription>
            </CardHeader>
            <CardContent>
              {isWardBreakdownLoading ? (
                <div className="space-y-3">
                  {Array.from({ length: 4 }, (_, index) => (
                    <Skeleton
                      className="h-10 w-full bg-slate-100"
                      key={index}
                    />
                  ))}
                </div>
              ) : wardBreakdown.length === 0 ? (
                <div className="rounded-md border border-dashed border-slate-200 py-10 text-center text-sm text-slate-500">
                  {t("notRecorded")}
                </div>
              ) : (
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead>Ward</TableHead>
                      <TableHead>Screenings</TableHead>
                      <TableHead>Rujuk</TableHead>
                      <TableHead>Refer Rate %</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {wardBreakdown.map((ward, index) => (
                      <TableRow key={`${ward.ward ?? "not-recorded"}-${index}`}>
                        <TableCell className="font-medium text-slate-950">
                          {ward.ward ?? t("notRecorded")}
                        </TableCell>
                        <TableCell className="text-slate-600">
                          {ward.total_screenings.toLocaleString()}
                        </TableCell>
                        <TableCell className="text-slate-600">
                          {ward.total_refer.toLocaleString()}
                        </TableCell>
                        <TableCell>
                          <Badge
                            className={getReferRateClassName(
                              ward.refer_rate_pct
                            )}
                          >
                            {formatPercent(ward.refer_rate_pct)}
                          </Badge>
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              )}
            </CardContent>
          </Card>
        </section>

        {outstandingFollowUps > 0 ? (
          <section className="flex flex-col gap-3 rounded-md border border-amber-200 bg-amber-50 px-4 py-3 text-amber-950 shadow-sm sm:flex-row sm:items-center sm:justify-between">
            <div className="flex items-center gap-3">
              <div className="flex size-9 items-center justify-center rounded-md bg-amber-100 text-amber-700">
                <AlertTriangle className="size-5" />
              </div>
              <p className="text-sm font-semibold">
                {outstandingFollowUps} {t("casesNeedAction")}
              </p>
            </div>
            <Button
              asChild
              className="bg-amber-600 text-white hover:bg-amber-700"
              size="sm"
            >
              <Link href="/coordinator/followups">{t("viewFollowups")}</Link>
            </Button>
          </section>
        ) : null}

        <Card className="border-slate-200 bg-white shadow-sm">
          <CardHeader className="flex-row items-start justify-between">
            <div>
              <CardTitle className="flex items-center gap-2 text-slate-950">
                <ClipboardList className="size-5 text-[#0F766E]" />
                {t("recentScreenings")}
              </CardTitle>
              <CardDescription>{t("recentDescription")}</CardDescription>
            </div>
            <Button asChild size="sm" variant="outline">
              <Link href="/coordinator/screenings">{t("viewAll")}</Link>
            </Button>
          </CardHeader>
          <CardContent>
            {isLoading ? (
              <div className="space-y-3">
                {Array.from({ length: 6 }, (_, index) => (
                  <Skeleton
                    className="h-10 w-full bg-slate-100"
                    key={index}
                  />
                ))}
              </div>
            ) : screenings.length === 0 ? (
              <div className="rounded-md border border-dashed border-slate-200 py-10 text-center text-sm text-slate-500">
                <Baby className="mx-auto mb-3 size-7 text-slate-300" />
                {t("noScreenings")}
              </div>
            ) : (
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>{t("babyId")}</TableHead>
                    <TableHead>{t("ward")}</TableHead>
                    <TableHead>{t("result")}</TableHead>
                    <TableHead>{t("date")}</TableHead>
                    <TableHead>{t("screener")}</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {screenings.map((screening) => {
                    const result = getScreeningResult(screening);

                    return (
                      <TableRow key={screening.id}>
                        <TableCell className="font-medium text-slate-950">
                          {screening.baby_system_id ?? shortId(screening.baby_id)}
                        </TableCell>
                        <TableCell className="text-slate-600">
                          {screening.ward ?? t("notRecorded")}
                        </TableCell>
                        <TableCell>
                          <Badge
                            className={
                              result === "pass"
                                ? "bg-emerald-50 text-emerald-700 hover:bg-emerald-50"
                                : "bg-red-50 text-red-700 hover:bg-red-50"
                            }
                          >
                            {t(result)}
                          </Badge>
                        </TableCell>
                        <TableCell className="text-slate-600">
                          {formatDate(screening.screening_date, lang)}
                        </TableCell>
                        <TableCell className="text-slate-600">
                          {screening.screener_name ??
                            shortId(screening.screener_id)}
                        </TableCell>
                      </TableRow>
                    );
                  })}
                </TableBody>
              </Table>
            )}
          </CardContent>
        </Card>
      </div>
    </DashboardLayout>
  );
}
