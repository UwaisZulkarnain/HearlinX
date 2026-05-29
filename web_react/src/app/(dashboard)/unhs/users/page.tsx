"use client";

import { FormEvent, useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { KeyRound, UserPlus } from "lucide-react";

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
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
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

type UserRow = {
  id: string;
  staff_id: string;
  full_name: string;
  role: string;
  hospital_id?: string | null;
  hospital_name?: string | null;
  is_active: boolean;
};

type Hospital = {
  id: string;
  name: string;
  code: string;
};

function apiError(error: unknown) {
  const response =
    typeof error === "object" && error !== null && "response" in error
      ? (error as { response?: { data?: { detail?: unknown } } }).response
      : undefined;
  return typeof response?.data?.detail === "string"
    ? response.data.detail
    : "Ralat API";
}

export default function UnhsUsersPage() {
  const router = useRouter();
  const { lang, t } = useLang();
  const [users, setUsers] = useState<UserRow[]>([]);
  const [hospitals, setHospitals] = useState<Hospital[]>([]);
  const [staffId, setStaffId] = useState("");
  const [fullName, setFullName] = useState("");
  const [pin, setPin] = useState("");
  const [hospitalId, setHospitalId] = useState("");
  const [resetTarget, setResetTarget] = useState<UserRow | null>(null);
  const [resetPin, setResetPin] = useState("");

  const labels =
    lang === "ms"
      ? {
          title: "Urus Pengguna",
          description: "Tambah dan urus penyelaras hospital.",
          createTitle: "Tambah Penyelaras",
          staffId: "ID Staf",
          fullName: "Nama Penuh",
          pin: "PIN",
          hospital: "Hospital",
          create: "Tambah Penyelaras",
          active: "Aktif",
          inactive: "Tidak Aktif",
          actions: "Tindakan",
          resetPin: "Tetap Semula PIN",
          deactivate: "Nyahaktif",
          confirmDeactivate: "Nyahaktifkan pengguna ini?",
          success: "Berjaya dikemas kini",
          created: "Penyelaras berjaya ditambah",
          error: "Gagal mengemas kini",
        }
      : {
          title: "Manage Users",
          description: "Add and manage hospital coordinators.",
          createTitle: "Add Coordinator",
          staffId: "Staff ID",
          fullName: "Full Name",
          pin: "PIN",
          hospital: "Hospital",
          create: "Add Coordinator",
          active: "Active",
          inactive: "Inactive",
          actions: "Actions",
          resetPin: "Reset PIN",
          deactivate: "Deactivate",
          confirmDeactivate: "Deactivate this user?",
          success: "Updated successfully",
          created: "Coordinator created",
          error: "Update failed",
        };

  async function loadData() {
    try {
      const [usersResponse, hospitalsResponse] = await Promise.all([
        api.get<UserRow[]>("/users/"),
        api.get<Hospital[]>("/hospitals/"),
      ]);
      setUsers(usersResponse.data.filter((user) => user.role === "coordinator"));
      setHospitals(hospitalsResponse.data);
      setHospitalId((current) => current || hospitalsResponse.data[0]?.id || "");
    } catch (error) {
      toast({ title: labels.error, description: apiError(error), variant: "destructive" });
    }
  }

  useEffect(() => {
    const token = getToken();
    const user = getUserFromToken();
    if (!token || user?.role !== "unhs_coordinator") {
      router.replace("/login");
      return;
    }
    void loadData();
  }, [router]);

  async function createUser(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    try {
      await api.post("/users/", {
        staff_id: staffId.trim(),
        full_name: fullName.trim(),
        email: `${staffId.trim().toLowerCase()}@hearlinx.local`,
        pin,
        role: "coordinator",
        hospital_id: hospitalId,
      });
      toast({ title: labels.created });
      setStaffId("");
      setFullName("");
      setPin("");
      await loadData();
    } catch (error) {
      toast({ title: labels.error, description: apiError(error), variant: "destructive" });
    }
  }

  async function deactivateUser(user: UserRow) {
    if (!window.confirm(labels.confirmDeactivate)) return;
    try {
      await api.patch(`/users/${user.id}`, { is_active: false });
      toast({ title: labels.success });
      await loadData();
    } catch (error) {
      toast({ title: labels.error, description: apiError(error), variant: "destructive" });
    }
  }

  async function submitResetPin() {
    if (!resetTarget) return;
    try {
      await api.patch(`/users/${resetTarget.id}`, { pin: resetPin });
      toast({ title: labels.success });
      setResetTarget(null);
      setResetPin("");
    } catch (error) {
      toast({ title: labels.error, description: apiError(error), variant: "destructive" });
    }
  }

  return (
    <>
      <Toaster />
      <div className="mx-auto flex max-w-6xl flex-col gap-5">
        <Card className="border-slate-200 bg-white shadow-sm">
          <CardHeader>
            <CardTitle className="flex items-center gap-2 text-slate-950">
              <UserPlus className="size-5 text-[#0F766E]" />
              {labels.createTitle}
            </CardTitle>
            <CardDescription>{labels.description}</CardDescription>
          </CardHeader>
          <CardContent>
            <form className="grid gap-3 md:grid-cols-[1fr_1.3fr_1fr_1fr_auto]" onSubmit={createUser}>
              <input className="h-10 rounded-md border border-slate-200 px-3 text-sm outline-none focus:border-[#0F766E] focus:ring-3 focus:ring-[#0F766E]/15" onChange={(e) => setStaffId(e.target.value)} placeholder={labels.staffId} required value={staffId} />
              <input className="h-10 rounded-md border border-slate-200 px-3 text-sm outline-none focus:border-[#0F766E] focus:ring-3 focus:ring-[#0F766E]/15" onChange={(e) => setFullName(e.target.value)} placeholder={labels.fullName} required value={fullName} />
              <input className="h-10 rounded-md border border-slate-200 px-3 text-sm outline-none focus:border-[#0F766E] focus:ring-3 focus:ring-[#0F766E]/15" inputMode="numeric" onChange={(e) => setPin(e.target.value.replace(/\D/g, "").slice(0, 6))} placeholder={labels.pin} required type="password" value={pin} />
              <select className="h-10 rounded-md border border-slate-200 px-3 text-sm outline-none focus:border-[#0F766E] focus:ring-3 focus:ring-[#0F766E]/15" onChange={(e) => setHospitalId(e.target.value)} required value={hospitalId}>
                {hospitals.map((hospital) => (
                  <option key={hospital.id} value={hospital.id}>{hospital.name} ({hospital.code})</option>
                ))}
              </select>
              <Button className="bg-[#0F766E] text-white hover:bg-[#115E59]" disabled={!hospitalId} type="submit">{labels.create}</Button>
            </form>
          </CardContent>
        </Card>

        <Card className="border-slate-200 bg-white shadow-sm">
          <CardContent className="pt-4">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>{labels.staffId}</TableHead>
                  <TableHead>{labels.fullName}</TableHead>
                  <TableHead>{labels.hospital}</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead className="text-right">{labels.actions}</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {users.map((user) => (
                  <TableRow key={user.id}>
                    <TableCell className="font-medium">{user.staff_id}</TableCell>
                    <TableCell>{user.full_name}</TableCell>
                    <TableCell>{user.hospital_name ?? t("notRecorded")}</TableCell>
                    <TableCell>
                      <Badge className={user.is_active ? "bg-emerald-50 text-emerald-700 hover:bg-emerald-50" : "bg-slate-100 text-slate-600 hover:bg-slate-100"}>
                        {user.is_active ? labels.active : labels.inactive}
                      </Badge>
                    </TableCell>
                    <TableCell>
                      <div className="flex justify-end gap-2">
                        <Button onClick={() => setResetTarget(user)} size="sm" type="button" variant="outline">{labels.resetPin}</Button>
                        <Button disabled={!user.is_active} onClick={() => deactivateUser(user)} size="sm" type="button" variant="outline">{labels.deactivate}</Button>
                      </div>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </CardContent>
        </Card>
      </div>

      <Dialog open={Boolean(resetTarget)} onOpenChange={(open) => !open && setResetTarget(null)}>
        <DialogContent>
          <DialogHeader><DialogTitle className="flex items-center gap-2"><KeyRound className="size-5 text-[#0F766E]" />{labels.resetPin}</DialogTitle></DialogHeader>
          <input className="h-10 rounded-md border border-slate-200 px-3 text-sm outline-none focus:border-[#0F766E] focus:ring-3 focus:ring-[#0F766E]/15" inputMode="numeric" onChange={(e) => setResetPin(e.target.value.replace(/\D/g, "").slice(0, 6))} placeholder={labels.pin} type="password" value={resetPin} />
          <DialogFooter>
            <Button onClick={() => setResetTarget(null)} type="button" variant="outline">{t("cancel")}</Button>
            <Button className="bg-[#0F766E] text-white hover:bg-[#115E59]" disabled={!resetPin} onClick={submitResetPin} type="button">{t("confirm")}</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </>
  );
}
