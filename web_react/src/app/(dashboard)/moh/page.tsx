"use client";

import { useEffect, useMemo, useState } from "react";
import { useRouter } from "next/navigation";
import {
  Activity,
  AlertTriangle,
  Building2,
  CheckCircle2,
  ClipboardList,
  FileBarChart,
  Map,
  ShieldCheck,
  TrendingDown,
  TrendingUp,
} from "lucide-react";
import {
  Bar,
  BarChart,
  CartesianGrid,
  Cell,
  Line,
  LineChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts";

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

type NationalHospitalSummary = {
  hospital_id: string;
  hospital_name: string;
  total_screenings: number;
  total_pass: number;
  total_refer: number;
  total_not_tested: number;
};

type NationalSummary = {
  year: number;
  month: number;
  total_hospitals: number;
  total_screenings: number;
  total_pass: number;
  total_refer: number;
  total_not_tested: number;
  hospitals: NationalHospitalSummary[];
};

type TrendPoint = {
  month: string;
  total_screenings: number;
  total_refer: number;
  total_not_tested: number;
};

type PolicySignal = {
  label: string;
  value: string;
  tone: "green" | "amber" | "red";
};

const currentDate = new Date();

function calculateRate(part: number, total: number) {
  if (total === 0) {
    return 0;
  }

  return Math.round((part / total) * 100);
}

function formatPercent(value: number) {
  return `${value}%`;
}

function getMonthRequests() {
  return Array.from({ length: 6 }, (_, index) => {
    const date = new Date(
      currentDate.getFullYear(),
      currentDate.getMonth() - (5 - index),
      1
    );

    return {
      year: date.getFullYear(),
      month: date.getMonth() + 1,
    };
  });
}

function getHospitalCoverage(hospital: NationalHospitalSummary) {
  return calculateRate(
    hospital.total_screenings,
    hospital.total_screenings + hospital.total_not_tested
  );
}

function getHospitalReferRate(hospital: NationalHospitalSummary) {
  return calculateRate(hospital.total_refer, hospital.total_screenings);
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

function getSignalClassName(tone: PolicySignal["tone"]) {
  if (tone === "green") {
    return "border-emerald-200 bg-emerald-50 text-emerald-800";
  }

  if (tone === "amber") {
    return "border-amber-200 bg-amber-50 text-amber-800";
  }

  return "border-red-200 bg-red-50 text-red-800";
}

export default function MohDashboardPage() {
  const router = useRouter();
  const { lang, t } = useLang();
  const [summary, setSummary] = useState<NationalSummary | null>(null);
  const [trendData, setTrendData] = useState<TrendPoint[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [hasError, setHasError] = useState(false);

  useEffect(() => {
    const token = getToken();
    const user = getUserFromToken();

    if (!token || user?.role !== "moh") {
      router.replace("/login");
      return;
    }

    async function loadMohDashboard() {
      setIsLoading(true);
      setHasError(false);

      try {
        const monthRequests = getMonthRequests();
        const responses = await Promise.all(
          monthRequests.map((month) =>
            api.get<NationalSummary>("/reports/national-summary", {
              params: {
                year: month.year,
                month: month.month,
              },
            })
          )
        );

        const reports = responses.map((response) => response.data);
        setSummary(reports.at(-1) ?? null);
        setTrendData(
          reports.map((report) => ({
            month: new Date(report.year, report.month - 1).toLocaleString(
              lang === "ms" ? "ms-MY" : "en-MY",
              { month: "short" }
            ),
            total_screenings: report.total_screenings,
            total_refer: report.total_refer,
            total_not_tested: report.total_not_tested,
          }))
        );
      } catch {
        setHasError(true);
      } finally {
        setIsLoading(false);
      }
    }

    void loadMohDashboard();
  }, [lang, router]);

  const totalScreened = summary?.total_screenings ?? 0;
  const totalRefer = summary?.total_refer ?? 0;
  const totalLtfu = summary?.total_not_tested ?? 0;
  const totalHospitals = summary?.total_hospitals ?? 0;
  const coverageRate = calculateRate(totalScreened, totalScreened + totalLtfu);
  const passRate = calculateRate(summary?.total_pass ?? 0, totalScreened);
  const referRate = calculateRate(totalRefer, totalScreened);

  const hospitalRows = useMemo(
    () =>
      [...(summary?.hospitals ?? [])].sort(
        (first, second) =>
          getHospitalCoverage(second) - getHospitalCoverage(first)
      ),
    [summary]
  );

  const policySignals: PolicySignal[] = [
    {
      label: t("coverageWatchlist"),
      value: hospitalRows
        .filter((hospital) => getHospitalCoverage(hospital) < 80)
        .length.toString(),
      tone: hospitalRows.some((hospital) => getHospitalCoverage(hospital) < 60)
        ? "red"
        : "amber",
    },
    {
      label: t("highReferHospitals"),
      value: hospitalRows
        .filter((hospital) => getHospitalReferRate(hospital) >= 10)
        .length.toString(),
      tone: hospitalRows.some((hospital) => getHospitalReferRate(hospital) >= 10)
        ? "amber"
        : "green",
    },
    {
      label: t("ltfuAlert"),
      value: totalLtfu.toLocaleString(),
      tone: totalLtfu > 0 ? "red" : "green",
    },
  ];

  return (
    <div className="mx-auto flex max-w-7xl flex-col gap-5">
      <section className="overflow-hidden rounded-md border border-[#0F766E]/15 bg-white shadow-sm">
        <div className="flex flex-col gap-4 bg-[linear-gradient(135deg,#0F766E_0%,#115E59_55%,#134E4A_100%)] p-5 text-white lg:flex-row lg:items-center lg:justify-between">
          <div>
            <p className="text-sm font-medium text-white/75">
              {t("aggregateOnly")}
            </p>
            <h2 className="mt-1 text-2xl font-semibold tracking-normal">
              {t("mohDashboard")}
            </h2>
            <p className="mt-2 max-w-2xl text-sm text-white/75">
              {t("ministryNotice")}
            </p>
          </div>
          <div className="grid grid-cols-2 gap-2 rounded-md bg-white/10 p-2 text-center ring-1 ring-white/15 sm:grid-cols-4">
            <div className="px-3">
              <p className="text-lg font-semibold">{totalHospitals}</p>
              <p className="text-[11px] text-white/70">
                {t("totalHospitals")}
              </p>
            </div>
            <div className="border-l border-white/15 px-3">
              <p className="text-lg font-semibold">
                {formatPercent(coverageRate)}
              </p>
              <p className="text-[11px] text-white/70">
                {t("coverageRate")}
              </p>
            </div>
            <div className="border-l border-white/15 px-3">
              <p className="text-lg font-semibold">
                {formatPercent(referRate)}
              </p>
              <p className="text-[11px] text-white/70">{t("referRate")}</p>
            </div>
            <div className="border-l border-white/15 px-3">
              <p className="text-lg font-semibold">{totalLtfu}</p>
              <p className="text-[11px] text-white/70">{t("ltfu")}</p>
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
          description={t("currentReportingMonth")}
          icon={Building2}
          isLoading={isLoading}
          label={t("totalHospitals")}
          value={totalHospitals.toLocaleString()}
        />
        <StatCard
          accentClassName="bg-emerald-500"
          description={t("currentReportingMonth")}
          icon={Activity}
          isLoading={isLoading}
          label={t("totalScreened")}
          value={totalScreened.toLocaleString()}
        />
        <StatCard
          accentClassName="bg-amber-500"
          description={t("currentReportingMonth")}
          icon={TrendingUp}
          isLoading={isLoading}
          label={t("nationalReferRate")}
          value={formatPercent(referRate)}
        />
        <StatCard
          accentClassName="bg-red-500"
          description={t("currentReportingMonth")}
          icon={TrendingDown}
          isLoading={isLoading}
          label={t("nationalLtfu")}
          value={totalLtfu.toLocaleString()}
        />
      </section>

      <section className="grid gap-5 xl:grid-cols-[minmax(0,1.45fr)_minmax(360px,0.75fr)]">
        <Card className="border-slate-200 bg-white shadow-sm">
          <CardHeader>
            <CardTitle className="flex items-center gap-2 text-slate-950">
              <FileBarChart className="size-5 text-[#0F766E]" />
              {t("nationalTrend")}
            </CardTitle>
            <CardDescription>{t("nationalTrendDescription")}</CardDescription>
          </CardHeader>
          <CardContent>
            {isLoading ? (
              <Skeleton className="h-[320px] w-full bg-slate-100" />
            ) : (
              <div className="h-[320px]">
                <ResponsiveContainer height="100%" width="100%">
                  <LineChart
                    data={trendData}
                    margin={{ bottom: 8, left: -14, right: 12, top: 12 }}
                  >
                    <CartesianGrid stroke="#E2E8F0" strokeDasharray="4 4" />
                    <XAxis dataKey="month" stroke="#64748B" tickLine={false} />
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
                      name={t("nationalScreened")}
                      stroke="#0F766E"
                      strokeWidth={3}
                      type="monotone"
                    />
                    <Line
                      dataKey="total_refer"
                      name={t("nationalRefer")}
                      stroke="#F59E0B"
                      strokeWidth={3}
                      type="monotone"
                    />
                    <Line
                      dataKey="total_not_tested"
                      name={t("nationalLtfu")}
                      stroke="#EF4444"
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
            <CardTitle className="flex items-center gap-2 text-slate-950">
              <ShieldCheck className="size-5 text-[#0F766E]" />
              {t("policyAttention")}
            </CardTitle>
            <CardDescription>{t("publicHealthSignal")}</CardDescription>
          </CardHeader>
          <CardContent className="space-y-3">
            {isLoading ? (
              Array.from({ length: 3 }, (_, index) => (
                <Skeleton className="h-20 w-full bg-slate-100" key={index} />
              ))
            ) : (
              policySignals.map((signal) => (
                <div
                  className={`rounded-md border p-4 ${getSignalClassName(
                    signal.tone
                  )}`}
                  key={signal.label}
                >
                  <p className="text-xs font-semibold uppercase tracking-wide opacity-75">
                    {signal.label}
                  </p>
                  <p className="mt-1 text-2xl font-semibold">{signal.value}</p>
                </div>
              ))
            )}
          </CardContent>
        </Card>
      </section>

      <section className="grid gap-5 xl:grid-cols-[minmax(0,1fr)_minmax(420px,0.9fr)]">
        <Card className="border-slate-200 bg-white shadow-sm">
          <CardHeader>
            <CardTitle className="flex items-center gap-2 text-slate-950">
              <Map className="size-5 text-[#0F766E]" />
              {t("hospitalBreakdown")}
            </CardTitle>
            <CardDescription>{t("aggregateOnly")}</CardDescription>
          </CardHeader>
          <CardContent>
            {isLoading ? (
              <div className="space-y-3">
                {Array.from({ length: 5 }, (_, index) => (
                  <Skeleton className="h-10 w-full bg-slate-100" key={index} />
                ))}
              </div>
            ) : hospitalRows.length === 0 ? (
              <div className="rounded-md border border-dashed border-slate-200 py-10 text-center text-sm text-slate-500">
                <Building2 className="mx-auto mb-3 size-7 text-slate-300" />
                {t("noHospitalData")}
              </div>
            ) : (
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
                  {hospitalRows.map((hospital) => {
                    const hospitalCoverage = getHospitalCoverage(hospital);
                    const hospitalReferRate = getHospitalReferRate(hospital);
                    const status = getHospitalStatus(hospitalCoverage);

                    return (
                      <TableRow key={hospital.hospital_id}>
                        <TableCell className="font-medium text-slate-950">
                          {hospital.hospital_name}
                        </TableCell>
                        <TableCell>{formatPercent(hospitalCoverage)}</TableCell>
                        <TableCell>{formatPercent(hospitalReferRate)}</TableCell>
                        <TableCell>{hospital.total_not_tested}</TableCell>
                        <TableCell>
                          <Badge className={status.className}>
                            {t(status.key)}
                          </Badge>
                        </TableCell>
                      </TableRow>
                    );
                  })}
                </TableBody>
              </Table>
            )}
          </CardContent>
        </Card>

        <Card className="border-slate-200 bg-white shadow-sm">
          <CardHeader>
            <CardTitle className="text-slate-950">
              {t("nationalSummary")}
            </CardTitle>
            <CardDescription>{t("currentReportingMonth")}</CardDescription>
          </CardHeader>
          <CardContent>
            {isLoading ? (
              <Skeleton className="h-[320px] w-full bg-slate-100" />
            ) : (
              <div className="h-[320px]">
                <ResponsiveContainer height="100%" width="100%">
                  <BarChart
                    data={[
                      {
                        name: t("pass"),
                        value: summary?.total_pass ?? 0,
                        fill: "#16A34A",
                      },
                      {
                        name: t("refer"),
                        value: totalRefer,
                        fill: "#F59E0B",
                      },
                      {
                        name: t("ltfu"),
                        value: totalLtfu,
                        fill: "#EF4444",
                      },
                    ]}
                    margin={{ bottom: 8, left: -14, right: 12, top: 12 }}
                  >
                    <CartesianGrid stroke="#E2E8F0" strokeDasharray="4 4" />
                    <XAxis dataKey="name" stroke="#64748B" tickLine={false} />
                    <YAxis stroke="#64748B" tickLine={false} />
                    <Tooltip
                      contentStyle={{
                        borderColor: "#CBD5E1",
                        borderRadius: 8,
                        boxShadow: "0 12px 30px rgba(15, 23, 42, 0.12)",
                      }}
                    />
                    <Bar dataKey="value" radius={[6, 6, 0, 0]}>
                      {[
                        "#16A34A",
                        "#F59E0B",
                        "#EF4444",
                      ].map((color) => (
                        <Cell fill={color} key={color} />
                      ))}
                    </Bar>
                  </BarChart>
                </ResponsiveContainer>
              </div>
            )}
          </CardContent>
        </Card>
      </section>

      <section className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <StatCard
          accentClassName="bg-emerald-500"
          description={t("currentReportingMonth")}
          icon={CheckCircle2}
          isLoading={isLoading}
          label={t("nationalPassRate")}
          value={formatPercent(passRate)}
        />
        <StatCard
          accentClassName="bg-amber-500"
          description={t("currentReportingMonth")}
          icon={AlertTriangle}
          isLoading={isLoading}
          label={t("coverageWatchlist")}
          value={policySignals[0].value}
        />
        <StatCard
          description={t("currentReportingMonth")}
          icon={ClipboardList}
          isLoading={isLoading}
          label={t("reportsThisMonth")}
          value={(summary ? 1 : 0).toLocaleString()}
        />
        <StatCard
          accentClassName="bg-[#0F766E]"
          description={t("ministryView")}
          icon={ShieldCheck}
          isLoading={isLoading}
          label={t("aggregateOnly")}
          value={t("active")}
        />
      </section>
    </div>
  );
}
