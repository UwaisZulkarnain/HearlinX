"use client";

import { useEffect, useMemo, useState } from "react";
import { useRouter } from "next/navigation";
import { Baby, ClipboardList, Search } from "lucide-react";

import { DashboardLayout } from "@/components/layout/DashboardLayout";
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

type Screening = {
  id: string;
  baby_id: string;
  baby_system_id?: string | null;
  screener_id: string;
  ear_left: string;
  ear_right: string;
  screening_date: string;
  ward?: string | null;
  screener_name?: string | null;
};

function getScreeningResult(screening: Screening) {
  if (screening.ear_left === "refer" || screening.ear_right === "refer") {
    return "refer";
  }

  return "pass";
}

function formatDateTime(value: string, _lang: "en" | "ms") {
  const date = new Date(value);
  const day = date.getDate().toString().padStart(2, "0");
  const month = date.toLocaleString("en-US", { month: "short" });
  const year = date.getFullYear();
  let hours = date.getHours();
  const minutes = date.getMinutes().toString().padStart(2, "0");
  const ampm = hours >= 12 ? "PM" : "AM";
  hours = hours % 12;
  hours = hours ? hours : 12;
  const hoursStr = hours.toString().padStart(2, "0");
  return `${day} ${month} ${year}, ${hoursStr}:${minutes} ${ampm}`;
}

function shortId(value: string) {
  return value.slice(0, 8).toUpperCase();
}

export default function CoordinatorScreeningsPage() {
  const router = useRouter();
  const { lang, t } = useLang();
  const [screenings, setScreenings] = useState<Screening[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [hasError, setHasError] = useState(false);
  const [query, setQuery] = useState("");

  useEffect(() => {
    const token = getToken();
    const user = getUserFromToken();

    if (!token || user?.role !== "coordinator") {
      router.replace("/login");
      return;
    }

    async function loadScreenings() {
      setIsLoading(true);
      setHasError(false);

      try {
        const response = await api.get<Screening[]>("/screenings/");
        setScreenings(response.data);
      } catch {
        setHasError(true);
      } finally {
        setIsLoading(false);
      }
    }

    void loadScreenings();
  }, [router]);

  const filteredScreenings = useMemo(() => {
    const term = query.trim().toLowerCase();

    if (!term) {
      return screenings;
    }

    return screenings.filter((screening) =>
      [
        screening.baby_system_id,
        screening.baby_id,
        screening.ward,
        screening.screener_name,
        screening.screener_id,
        getScreeningResult(screening),
      ]
        .filter(Boolean)
        .some((value) => String(value).toLowerCase().includes(term))
    );
  }, [query, screenings]);

  return (
    <DashboardLayout roleLabel={t("coordinator")} title={t("recentScreenings")}>
      <div className="mx-auto flex max-w-7xl flex-col gap-5">
        <section className="overflow-hidden rounded-md border border-[#0F766E]/15 bg-white shadow-sm">
          <div className="flex items-center gap-4 bg-[linear-gradient(135deg,#0F766E_0%,#115E59_50%,#134E4A_100%)] p-5 text-white">
            <div className="flex size-11 items-center justify-center rounded-md bg-white/10 ring-1 ring-white/15">
              <ClipboardList className="size-6" />
            </div>
            <div>
              <p className="text-sm font-medium text-white/75">
                {t("hospitalCoordinator")}
              </p>
              <h1 className="mt-1 text-2xl font-semibold tracking-normal">
                {t("allScreenings")}
              </h1>
            </div>
          </div>
        </section>

        {hasError ? (
          <div className="rounded-md border border-red-200 bg-red-50 px-4 py-3 text-sm font-medium text-red-700">
            {t("error")}
          </div>
        ) : null}

        <Card className="border-slate-200 bg-white shadow-sm">
          <CardHeader className="gap-4 sm:flex-row sm:items-start sm:justify-between">
            <div>
              <CardTitle className="text-slate-950">
                {t("allScreenings")}
              </CardTitle>
              <CardDescription>
                {filteredScreenings.length.toLocaleString()} /{" "}
                {screenings.length.toLocaleString()} {t("totalScreenings")}
              </CardDescription>
            </div>
            <div className="relative w-full sm:w-80">
              <Search className="pointer-events-none absolute left-3 top-2.5 size-4 text-slate-400" />
              <input
                className="h-10 w-full rounded-md border border-slate-200 bg-white pl-9 pr-3 text-sm outline-none focus:border-[#0F766E] focus:ring-3 focus:ring-[#0F766E]/15"
                onChange={(event) => setQuery(event.target.value)}
                placeholder={t("searchScreenings")}
                value={query}
              />
            </div>
          </CardHeader>
          <CardContent>
            {isLoading ? (
              <div className="space-y-3">
                {Array.from({ length: 8 }, (_, index) => (
                  <Skeleton className="h-10 w-full bg-slate-100" key={index} />
                ))}
              </div>
            ) : filteredScreenings.length === 0 ? (
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
                    <TableHead>{t("screener")}</TableHead>
                    <TableHead>{t("date")}</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {filteredScreenings.map((screening) => {
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
                          {screening.screener_name ??
                            shortId(screening.screener_id)}
                        </TableCell>
                        <TableCell className="text-slate-600">
                          {formatDateTime(screening.screening_date, lang)}
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
