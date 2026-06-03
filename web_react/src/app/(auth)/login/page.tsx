"use client";

import { FormEvent, useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { Ear, Eye, LockKeyhole, Loader2 } from "lucide-react";

import api from "@/lib/api";
import { getUserFromToken, removeToken, saveToken } from "@/lib/auth";
import { Button } from "@/components/ui/button";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { useLang } from "@/context/LanguageContext";
import type { Role } from "@/types";

type LoginResponse = {
  token?: string;
  access_token?: string;
};

type Hospital = {
  id: string;
  name: string;
  code: string;
  state: string;
  is_active: boolean;
};

const roleRedirects: Record<Role, string> = {
  screener: "/login",
  coordinator: "/coordinator",
  unhs_coordinator: "/unhs",
  moh: "/moh",
};

export default function LoginPage() {
  const router = useRouter();
  const { lang, t, toggleLang } = useLang();
  const [hospitals, setHospitals] = useState<Hospital[]>([]);
  const [selectedHospitalCode, setSelectedHospitalCode] = useState("");
  const [staffId, setStaffId] = useState("");
  const [pin, setPin] = useState("");
  const [isLoading, setIsLoading] = useState(false);
  const [isLoadingHospitals, setIsLoadingHospitals] = useState(true);
  const [hospitalError, setHospitalError] = useState("");
  const [error, setError] = useState("");

  useEffect(() => {
    async function loadHospitals() {
      setIsLoadingHospitals(true);
      setHospitalError("");

      try {
        const response = await api.get<Hospital[]>("/hospitals/");
        setHospitals(response.data);
        setSelectedHospitalCode(response.data[0]?.code ?? "");
      } catch {
        setHospitalError(
          lang === "ms" ? "Gagal memuatkan hospital" : "Failed to load hospitals"
        );
      } finally {
        setIsLoadingHospitals(false);
      }
    }

    void loadHospitals();
  }, [lang]);

  function handlePinChange(value: string) {
    setPin(value.replace(/\D/g, "").slice(0, 6));
  }

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setError("");
    setIsLoading(true);

    try {
      const response = await api.post<LoginResponse>("/auth/login", {
        staff_id: staffId,
        pin,
        hospital_code: selectedHospitalCode,
      });
      const token = response.data.token ?? response.data.access_token;

      if (!token) {
        throw new Error("Missing authentication token");
      }

      saveToken(token);

      const user = getUserFromToken();

      if (!user) {
        throw new Error("Invalid authentication token");
      }

      if (user.role === "screener") {
        removeToken();
        setError("Sila gunakan aplikasi mudah alih / Please use the mobile app");
        return;
      }

      router.push(roleRedirects[user.role]);
    } catch {
      setError(t("loginInvalidCreds"));
    } finally {
      setIsLoading(false);
    }
  }

  return (
    <main className="grid min-h-screen bg-white lg:grid-cols-[0.95fr_1.05fr]">
      <section className="relative hidden overflow-hidden bg-[#0F766E] px-12 py-10 text-white lg:flex lg:flex-col">
        <div className="flex items-center gap-3">
          <div className="flex size-11 items-center justify-center rounded-md bg-white/12 ring-1 ring-white/20">
            <Ear className="size-6" aria-hidden="true" />
          </div>
          <div>
            <h1 className="text-4xl font-bold tracking-normal">
              {t("brand")}
            </h1>
            <p className="mt-1 text-sm font-medium text-white/90">
              {t("tagline")}
            </p>
          </div>
        </div>

        <div className="flex flex-1 items-center">
          <div className="max-w-md">
            <div className="mb-5 flex size-14 items-center justify-center rounded-md bg-white/12 ring-1 ring-white/20">
              <Eye className="size-7" aria-hidden="true" />
            </div>
            <p className="text-3xl font-semibold leading-tight">
              {t("platform")}
            </p>
            <p className="mt-4 text-base leading-7 text-white/78">
              {t("platformDescription")}
            </p>
          </div>
        </div>

        <p className="text-xs font-medium text-white/75">{t("credit")}</p>
      </section>

      <section className="flex min-h-screen flex-col bg-white">
        <div className="flex justify-end px-5 py-5 sm:px-8">
          <div className="inline-flex rounded-md border border-slate-200 bg-white p-1 shadow-sm">
            <Button
              aria-pressed={lang === "en"}
              onClick={() => {
                if (lang !== "en") {
                  toggleLang();
                }
              }}
              size="sm"
              type="button"
              variant="ghost"
              className={
                lang === "en"
                  ? "font-bold text-[#0F766E] hover:text-[#0F766E]"
                  : "text-slate-600 hover:text-slate-950"
              }
            >
              EN
            </Button>
            <Button
              aria-pressed={lang === "ms"}
              onClick={() => {
                if (lang !== "ms") {
                  toggleLang();
                }
              }}
              size="sm"
              type="button"
              variant="ghost"
              className={
                lang === "ms"
                  ? "font-bold text-[#0F766E] hover:text-[#0F766E]"
                  : "text-slate-600 hover:text-slate-950"
              }
            >
              BM
            </Button>
          </div>
        </div>

        <div className="flex flex-1 items-center justify-center px-5 pb-10 sm:px-8">
          <Card className="w-full max-w-md border-slate-200 shadow-sm">
            <CardHeader className="space-y-2 text-center">
              <div className="mx-auto flex size-12 items-center justify-center rounded-md bg-[#0F766E]/10 text-[#0F766E]">
                <LockKeyhole className="size-6" aria-hidden="true" />
              </div>
              <CardTitle className="text-2xl font-semibold text-slate-950">
                {t("loginWelcome")}
              </CardTitle>
              <CardDescription className="text-slate-500">
                {t("loginSubtitle")}
              </CardDescription>
            </CardHeader>

            <CardContent>
              <form className="space-y-4" onSubmit={handleSubmit}>
                <div className="space-y-2">
                  <label
                    className="text-sm font-medium text-slate-700"
                    htmlFor="hospital"
                  >
                    {t("hospitalName")}
                  </label>
                  {isLoadingHospitals ? (
                    <div className="flex h-10 items-center rounded-md border border-slate-200 px-3 text-sm text-slate-500">
                      <Loader2 className="mr-2 size-4 animate-spin text-[#0F766E]" />
                      {t("loading")}
                    </div>
                  ) : hospitalError ? (
                    <p className="rounded-md border border-red-200 bg-red-50 px-3 py-2 text-sm text-red-600">
                      {hospitalError}
                    </p>
                  ) : (
                    <select
                      className="flex h-10 w-full rounded-md border border-slate-200 bg-white px-3 py-2 text-sm text-slate-950 shadow-xs outline-none transition-colors focus:border-[#0F766E] focus:ring-3 focus:ring-[#0F766E]/15 disabled:cursor-not-allowed disabled:opacity-50"
                      id="hospital"
                      onChange={(event) =>
                        setSelectedHospitalCode(event.target.value)
                      }
                      required
                      value={selectedHospitalCode}
                    >
                      {hospitals.map((hospital) => (
                        <option key={hospital.id} value={hospital.code}>
                          {hospital.name} ({hospital.code})
                        </option>
                      ))}
                    </select>
                  )}
                </div>

                <div className="space-y-2">
                  <label
                    className="text-sm font-medium text-slate-700"
                    htmlFor="staff-id"
                  >
                    {t("loginStaffId")}
                  </label>
                  <input
                    autoComplete="username"
                    className="flex h-10 w-full rounded-md border border-slate-200 bg-white px-3 py-2 text-sm text-slate-950 shadow-xs outline-none transition-colors placeholder:text-slate-400 focus:border-[#0F766E] focus:ring-3 focus:ring-[#0F766E]/15 disabled:cursor-not-allowed disabled:opacity-50"
                    id="staff-id"
                    onChange={(event) => setStaffId(event.target.value)}
                    required
                    value={staffId}
                  />
                </div>

                <div className="space-y-2">
                  <label
                    className="text-sm font-medium text-slate-700"
                    htmlFor="pin"
                  >
                    {t("loginPin")}
                  </label>
                  <input
                    autoComplete="current-password"
                    className="flex h-10 w-full rounded-md border border-slate-200 bg-white px-3 py-2 text-sm text-slate-950 shadow-xs outline-none transition-colors placeholder:text-slate-400 focus:border-[#0F766E] focus:ring-3 focus:ring-[#0F766E]/15 disabled:cursor-not-allowed disabled:opacity-50"
                    id="pin"
                    inputMode="numeric"
                    maxLength={6}
                    onChange={(event) => handlePinChange(event.target.value)}
                    pattern="[0-9]*"
                    required
                    type="password"
                    value={pin}
                  />
                </div>

                <Button
                  className="h-10 w-full bg-[#0F766E] text-white hover:bg-[#115E59]"
                  disabled={isLoading || isLoadingHospitals || !selectedHospitalCode}
                  type="submit"
                >
                  {isLoading ? (
                    <>
                      <Loader2 className="size-4 animate-spin" />
                      {t("loginLoggingIn")}
                    </>
                  ) : (
                    t("loginSignIn")
                  )}
                </Button>

                <p className="min-h-5 text-sm text-red-600" role="alert">
                  {error}
                </p>
              </form>
            </CardContent>
          </Card>
        </div>

        <p className="pb-5 text-center text-xs text-slate-400">
          {t("loginFooter")}
        </p>
      </section>
    </main>
  );
}
