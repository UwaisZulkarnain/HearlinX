"use client";

import { useEffect, useMemo, useState } from "react";
import { useRouter } from "next/navigation";
import {
  CalendarClock,
  CheckCircle2,
  RotateCcw,
  Search,
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
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Skeleton } from "@/components/ui/skeleton";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { Toaster } from "@/components/ui/toaster";
import { useLang } from "@/context/LanguageContext";
import { toast } from "@/hooks/use-toast";
import api from "@/lib/api";
import { getToken, getUserFromToken } from "@/lib/auth";
import { cn } from "@/lib/utils";

type FollowUpStatus =
  | "pending"
  | "contacted"
  | "appointment_booked"
  | "escalated"
  | "closed";

type Urgency = "pending" | "amber" | "red" | "ltfu";

type FollowUp = {
  id: string;
  baby_id: string;
  baby_system_id?: string | null;
  screening_id: string;
  hospital_id: string;
  assigned_to?: string | null;
  status: FollowUpStatus;
  due_date?: string | null;
  notes?: string | null;
  created_at: string;
  updated_at: string;
  ward?: string | null;
};

type PendingAction = {
  followUp: FollowUp;
  label: string;
  nextStatus: FollowUpStatus;
};

const statusOptions: Array<FollowUpStatus | "all"> = [
  "all",
  "pending",
  "contacted",
  "appointment_booked",
  "escalated",
  "closed",
];

const urgencyOptions: Array<Urgency | "all"> = [
  "all",
  "amber",
  "red",
  "ltfu",
];

function daysSince(dateValue: string) {
  const createdAt = new Date(dateValue).getTime();
  const diff = Date.now() - createdAt;
  const dayInMs = 1000 * 60 * 60 * 24;

  return Math.max(1, Math.floor(diff / dayInMs) + 1);
}

function getUrgency(days: number): Urgency {
  if (days >= 60) {
    return "ltfu";
  }

  if (days >= 28) {
    return "red";
  }

  if (days >= 14) {
    return "amber";
  }

  return "pending";
}

function maskBabyId(value: string) {
  const lastFour = value.slice(-4);
  return `****${lastFour}`;
}

function formatDate(value: string, lang: "en" | "ms") {
  return new Intl.DateTimeFormat(lang === "ms" ? "ms-MY" : "en-MY", {
    day: "2-digit",
    month: "short",
    year: "numeric",
  }).format(new Date(value));
}

export default function CoordinatorFollowupsPage() {
  const router = useRouter();
  const { lang, t } = useLang();
  const [followUps, setFollowUps] = useState<FollowUp[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isUpdating, setIsUpdating] = useState(false);
  const [hasError, setHasError] = useState(false);
  const [searchTerm, setSearchTerm] = useState("");
  const [statusFilter, setStatusFilter] = useState<FollowUpStatus | "all">(
    "all"
  );
  const [urgencyFilter, setUrgencyFilter] = useState<Urgency | "all">("all");
  const [pendingAction, setPendingAction] = useState<PendingAction | null>(
    null
  );

  async function loadFollowUps() {
    setIsLoading(true);
    setHasError(false);

    try {
      const response = await api.get<FollowUp[]>("/followups/");
      setFollowUps(response.data);
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

    void loadFollowUps();
  }, [router]);

  const enrichedFollowUps = useMemo(
    () =>
      followUps.map((followUp) => {
        const days = daysSince(followUp.created_at);
        return {
          ...followUp,
          days,
          urgency: getUrgency(days),
        };
      }),
    [followUps]
  );

  const summary = useMemo(
    () => ({
      totalPending: enrichedFollowUps.filter(
        (item) => item.status !== "closed"
      ).length,
      amber: enrichedFollowUps.filter((item) => item.urgency === "amber")
        .length,
      red: enrichedFollowUps.filter((item) => item.urgency === "red").length,
      ltfu: enrichedFollowUps.filter((item) => item.urgency === "ltfu").length,
    }),
    [enrichedFollowUps]
  );

  const filteredFollowUps = useMemo(() => {
    const normalizedSearch = searchTerm.trim().toLowerCase();

    return enrichedFollowUps.filter((followUp) => {
      const babyId = followUp.baby_system_id ?? followUp.baby_id;
      const ward = followUp.ward ?? "";
      const matchesSearch =
        normalizedSearch.length === 0 ||
        babyId.toLowerCase().includes(normalizedSearch) ||
        ward.toLowerCase().includes(normalizedSearch);
      const matchesStatus =
        statusFilter === "all" || followUp.status === statusFilter;
      const matchesUrgency =
        urgencyFilter === "all" || followUp.urgency === urgencyFilter;

      return matchesSearch && matchesStatus && matchesUrgency;
    });
  }, [enrichedFollowUps, searchTerm, statusFilter, urgencyFilter]);

  function getStatusLabel(status: FollowUpStatus) {
    if (status === "appointment_booked") {
      return t("appointmentBooked");
    }

    return t(status);
  }

  function getUrgencyLabel(urgency: Urgency) {
    switch (urgency) {
      case "pending":
        return t("pending");
      case "amber":
        return t("amber");
      case "red":
        return t("redFlag");
      case "ltfu":
        return t("ltfu");
    }
  }

  function getStatusClassName(status: FollowUpStatus) {
    switch (status) {
      case "pending":
        return "bg-slate-100 text-slate-700 hover:bg-slate-100";
      case "contacted":
        return "bg-blue-50 text-blue-700 hover:bg-blue-50";
      case "appointment_booked":
        return "bg-teal-50 text-teal-700 hover:bg-teal-50";
      case "escalated":
        return "bg-orange-50 text-orange-700 hover:bg-orange-50";
      case "closed":
        return "bg-emerald-50 text-emerald-700 hover:bg-emerald-50";
    }
  }

  function getUrgencyClassName(urgency: Urgency) {
    switch (urgency) {
      case "pending":
        return "bg-slate-100 text-slate-700 hover:bg-slate-100";
      case "amber":
        return "bg-amber-100 text-amber-800 hover:bg-amber-100";
      case "red":
        return "bg-red-100 text-red-700 hover:bg-red-100";
      case "ltfu":
        return "bg-red-950 text-white hover:bg-red-950";
    }
  }

  function getAvailableActions(followUp: FollowUp) {
    switch (followUp.status) {
      case "pending":
        return [
          { label: t("markContacted"), nextStatus: "contacted" as const },
          { label: t("escalate"), nextStatus: "escalated" as const },
        ];
      case "contacted":
        return [
          {
            label: t("bookAppointment"),
            nextStatus: "appointment_booked" as const,
          },
          { label: t("escalate"), nextStatus: "escalated" as const },
          { label: t("close"), nextStatus: "closed" as const },
        ];
      case "appointment_booked":
        return [
          { label: t("close"), nextStatus: "closed" as const },
          { label: t("escalate"), nextStatus: "escalated" as const },
        ];
      case "escalated":
        return [{ label: t("close"), nextStatus: "closed" as const }];
      case "closed":
        return [];
    }
  }

  function clearFilters() {
    setSearchTerm("");
    setStatusFilter("all");
    setUrgencyFilter("all");
  }

  async function confirmAction() {
    if (!pendingAction) {
      return;
    }

    setIsUpdating(true);

    try {
      await api.patch<FollowUp>(`/followups/${pendingAction.followUp.id}`, {
        status: pendingAction.nextStatus,
      });
      setFollowUps((current) =>
        current.map((item) =>
          item.id === pendingAction.followUp.id
            ? { ...item, status: pendingAction.nextStatus }
            : item
        )
      );
      toast({
        title: t("actionSuccess"),
      });
      setPendingAction(null);
      await loadFollowUps();
    } catch {
      toast({
        title: t("actionError"),
        variant: "destructive",
      });
    } finally {
      setIsUpdating(false);
    }
  }

  return (
    <DashboardLayout roleLabel={t("coordinator")} title={t("followupQueue")}>
      <Toaster />
      <div className="mx-auto flex max-w-7xl flex-col gap-5">
        <section className="flex flex-col gap-4 rounded-md border border-slate-200 bg-white p-5 shadow-sm">
          <div>
            <h1 className="text-2xl font-semibold tracking-normal text-slate-950">
              {t("followupQueue")}
            </h1>
            <p className="mt-1 text-sm text-slate-500">
              {t("followupSubtitle")}
            </p>
          </div>
          <div className="grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
            <SummaryBadge
              className="bg-slate-100 text-slate-700"
              label={t("totalPending")}
              value={summary.totalPending}
            />
            <SummaryBadge
              className="bg-amber-100 text-amber-800"
              label={t("amberCases")}
              value={summary.amber}
            />
            <SummaryBadge
              className="bg-red-100 text-red-700"
              label={t("redCases")}
              value={summary.red}
            />
            <SummaryBadge
              className="bg-red-950 text-white"
              label={t("ltfuCases")}
              value={summary.ltfu}
            />
          </div>
        </section>

        <Card className="border-slate-200 bg-white shadow-sm">
          <CardHeader>
            <CardTitle className="text-slate-950">
              {t("filterStatus")}
            </CardTitle>
            <CardDescription>{t("followupSubtitle")}</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="grid gap-3 lg:grid-cols-[minmax(240px,1fr)_220px_220px_auto]">
              <label className="relative">
                <Search className="absolute left-3 top-1/2 size-4 -translate-y-1/2 text-slate-400" />
                <input
                  className="h-10 w-full rounded-md border border-slate-200 bg-white pl-9 pr-3 text-sm outline-none focus:border-[#0F766E] focus:ring-3 focus:ring-[#0F766E]/15"
                  onChange={(event) => setSearchTerm(event.target.value)}
                  placeholder={t("searchPlaceholder")}
                  value={searchTerm}
                />
              </label>

              <select
                className="h-10 rounded-md border border-slate-200 bg-white px-3 text-sm outline-none focus:border-[#0F766E] focus:ring-3 focus:ring-[#0F766E]/15"
                onChange={(event) =>
                  setStatusFilter(event.target.value as FollowUpStatus | "all")
                }
                value={statusFilter}
              >
                {statusOptions.map((status) => (
                  <option key={status} value={status}>
                    {status === "all"
                      ? t("all")
                      : status === "appointment_booked"
                        ? t("appointmentBooked")
                        : t(status)}
                  </option>
                ))}
              </select>

              <select
                className="h-10 rounded-md border border-slate-200 bg-white px-3 text-sm outline-none focus:border-[#0F766E] focus:ring-3 focus:ring-[#0F766E]/15"
                onChange={(event) =>
                  setUrgencyFilter(event.target.value as Urgency | "all")
                }
                value={urgencyFilter}
              >
                {urgencyOptions.map((urgency) => (
                  <option key={urgency} value={urgency}>
                    {urgency === "all" ? t("all") : getUrgencyLabel(urgency)}
                  </option>
                ))}
              </select>

              <Button
                className="gap-2"
                onClick={clearFilters}
                type="button"
                variant="outline"
              >
                <RotateCcw className="size-4" />
                {t("clearFilters")}
              </Button>
            </div>
          </CardContent>
        </Card>

        <Card className="border-slate-200 bg-white shadow-sm">
          <CardContent className="pt-4">
            {isLoading ? (
              <div className="space-y-3">
                {Array.from({ length: 8 }, (_, index) => (
                  <Skeleton
                    className="h-12 w-full bg-slate-100"
                    key={index}
                  />
                ))}
              </div>
            ) : hasError ? (
              <div className="rounded-md border border-red-200 bg-red-50 px-4 py-6 text-center text-sm font-medium text-red-700">
                {t("error")}
              </div>
            ) : filteredFollowUps.length === 0 ? (
              <div className="flex flex-col items-center justify-center rounded-md border border-dashed border-emerald-200 bg-emerald-50/50 px-4 py-14 text-center">
                <CheckCircle2 className="mb-3 size-10 text-emerald-600" />
                <p className="text-base font-semibold text-emerald-900">
                  {t("noFollowups")}
                </p>
                <p className="mt-1 text-sm text-emerald-700">
                  {t("noFollowupsSubtitle")}
                </p>
              </div>
            ) : (
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>{t("babyId")}</TableHead>
                    <TableHead>{t("ward")}</TableHead>
                    <TableHead>{t("referDate")}</TableHead>
                    <TableHead>{t("daysSinceRefer")}</TableHead>
                    <TableHead>{t("urgency")}</TableHead>
                    <TableHead>{t("filterStatus")}</TableHead>
                    <TableHead className="text-right">{t("actions")}</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {filteredFollowUps.map((followUp) => {
                    const babyId = followUp.baby_system_id ?? followUp.baby_id;
                    const actions = getAvailableActions(followUp);

                    return (
                      <TableRow key={followUp.id}>
                        <TableCell className="font-medium text-slate-950">
                          {maskBabyId(babyId)}
                        </TableCell>
                        <TableCell className="text-slate-600">
                          {followUp.ward ?? t("notRecorded")}
                        </TableCell>
                        <TableCell className="text-slate-600">
                          {formatDate(followUp.created_at, lang)}
                        </TableCell>
                        <TableCell className="text-slate-600">
                          {followUp.days}
                        </TableCell>
                        <TableCell>
                          <Badge
                            className={getUrgencyClassName(followUp.urgency)}
                          >
                            {getUrgencyLabel(followUp.urgency)}
                          </Badge>
                        </TableCell>
                        <TableCell>
                          <Badge className={getStatusClassName(followUp.status)}>
                            {getStatusLabel(followUp.status)}
                          </Badge>
                        </TableCell>
                        <TableCell>
                          <div className="flex justify-end gap-2">
                            {actions.map((action) => (
                              <Button
                                key={action.nextStatus}
                                onClick={() =>
                                  setPendingAction({
                                    followUp,
                                    label: action.label,
                                    nextStatus: action.nextStatus,
                                  })
                                }
                                size="sm"
                                type="button"
                                variant="outline"
                              >
                                {action.label}
                              </Button>
                            ))}
                          </div>
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

      <Dialog
        onOpenChange={(open) => {
          if (!open) {
            setPendingAction(null);
          }
        }}
        open={Boolean(pendingAction)}
      >
        <DialogContent>
          <DialogHeader>
            <DialogTitle>{t("confirmAction")}</DialogTitle>
            <DialogDescription>
              {t("confirmActionQuestion")}
            </DialogDescription>
          </DialogHeader>
          {pendingAction ? (
            <div className="rounded-md bg-slate-50 p-3 text-sm text-slate-700">
              <div className="flex items-center gap-2">
                <CalendarClock className="size-4 text-[#0F766E]" />
                <span className="font-medium">{pendingAction.label}</span>
              </div>
              <p className="mt-2">
                {t("babyId")}:{" "}
                {maskBabyId(
                  pendingAction.followUp.baby_system_id ??
                    pendingAction.followUp.baby_id
                )}
              </p>
            </div>
          ) : null}
          <DialogFooter>
            <Button
              disabled={isUpdating}
              onClick={() => setPendingAction(null)}
              type="button"
              variant="outline"
            >
              {t("cancel")}
            </Button>
            <Button
              className="bg-[#0F766E] text-white hover:bg-[#115E59]"
              disabled={isUpdating}
              onClick={confirmAction}
              type="button"
            >
              {t("confirm")}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </DashboardLayout>
  );
}

function SummaryBadge({
  className,
  label,
  value,
}: {
  className: string;
  label: string;
  value: number;
}) {
  return (
    <div className={cn("rounded-md px-4 py-3", className)}>
      <p className="text-2xl font-semibold">{value}</p>
      <p className="mt-1 text-xs font-medium">{label}</p>
    </div>
  );
}
