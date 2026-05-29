"use client";

import { useEffect, useState, type FormEvent, type ReactNode } from "react";
import { useRouter } from "next/navigation";
import { Baby, Save } from "lucide-react";

import { DashboardLayout } from "@/components/layout/DashboardLayout";
import { Button } from "@/components/ui/button";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Toaster } from "@/components/ui/toaster";
import { useLang } from "@/context/LanguageContext";
import { toast } from "@/hooks/use-toast";
import api from "@/lib/api";
import { getToken, getUserFromToken } from "@/lib/auth";

type BabyForm = {
  system_id: string;
  full_name_enc: string;
  ic_number_enc: string;
  date_of_birth: string;
  gender: string;
  ward: string;
  gestational_age: string;
  birth_weight: string;
};

const initialForm: BabyForm = {
  system_id: "",
  full_name_enc: "",
  ic_number_enc: "",
  date_of_birth: "",
  gender: "",
  ward: "",
  gestational_age: "",
  birth_weight: "",
};

function getApiErrorMessage(error: unknown) {
  const response =
    typeof error === "object" && error !== null && "response" in error
      ? (error as { response?: { data?: { detail?: unknown } } }).response
      : undefined;

  if (
    response &&
    typeof response === "object" &&
    response.data &&
    typeof response.data === "object"
  ) {
    const data = response.data;

    if (typeof data.detail === "string") {
      return data.detail;
    }

    if (Array.isArray(data.detail) && data.detail.length > 0) {
      const firstError = data.detail[0] as { msg?: unknown };

      if (typeof firstError.msg === "string") {
        return firstError.msg;
      }
    }
  }

  return "Ralat API";
}

export default function CoordinatorBabyRegistrationPage() {
  const router = useRouter();
  const { lang, t } = useLang();
  const [form, setForm] = useState<BabyForm>(initialForm);
  const [isSubmitting, setIsSubmitting] = useState(false);

  const labels =
    lang === "ms"
      ? {
          title: "Daftar Bayi",
          description: "Daftar rekod bayi untuk saringan pendengaran hospital.",
          systemId: "ID Bayi",
          fullName: "Nama Penuh",
          icNumber: "No. Kad Pengenalan",
          dob: "DOB",
          gender: "Jantina",
          selectGender: "Pilih jantina",
          male: "Lelaki",
          female: "Perempuan",
          ward: "Wad",
          gestationalAge: "Umur Gestasi",
          birthWeight: "Berat Lahir",
          submit: "Daftar Bayi",
          submitting: "Sedang daftar...",
          successTitle: "Bayi berjaya didaftarkan",
          successDescription: "Rekod bayi telah disimpan.",
          errorTitle: "Gagal daftar bayi",
        }
      : {
          title: "Register Baby",
          description: "Register a baby record for hospital hearing screening.",
          systemId: "Baby ID",
          fullName: "Full Name",
          icNumber: "IC Number",
          dob: "DOB",
          gender: "Gender",
          selectGender: "Select gender",
          male: "Male",
          female: "Female",
          ward: "Ward",
          gestationalAge: "Gestational Age",
          birthWeight: "Birth Weight",
          submit: "Register Baby",
          submitting: "Registering...",
          successTitle: "Baby registered",
          successDescription: "The baby record has been saved.",
          errorTitle: "Failed to register baby",
        };

  useEffect(() => {
    const token = getToken();
    const user = getUserFromToken();

    if (!token || user?.role !== "coordinator") {
      router.replace("/login");
    }
  }, [router]);

  function updateField(field: keyof BabyForm, value: string) {
    setForm((current) => ({
      ...current,
      [field]: value,
    }));
  }

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setIsSubmitting(true);

    try {
      await api.post("/babies/", {
        system_id: form.system_id.trim(),
        full_name_enc: form.full_name_enc.trim() || null,
        ic_number_enc: form.ic_number_enc.trim() || null,
        date_of_birth: form.date_of_birth,
        gender: form.gender || null,
        ward: form.ward.trim() || null,
        gestational_age: form.gestational_age
          ? Number(form.gestational_age)
          : null,
        birth_weight: form.birth_weight ? Number(form.birth_weight) : null,
      });

      toast({
        title: labels.successTitle,
        description: labels.successDescription,
      });
      setForm(initialForm);
    } catch (error) {
      toast({
        title: labels.errorTitle,
        description: getApiErrorMessage(error),
        variant: "destructive",
      });
    } finally {
      setIsSubmitting(false);
    }
  }

  return (
    <DashboardLayout roleLabel={t("coordinator")} title={labels.title}>
      <Toaster />
      <div className="mx-auto flex max-w-5xl flex-col gap-5">
        <section className="overflow-hidden rounded-md border border-[#0F766E]/15 bg-white shadow-sm">
          <div className="flex items-center gap-4 bg-[linear-gradient(135deg,#0F766E_0%,#115E59_50%,#134E4A_100%)] p-5 text-white">
            <div className="flex size-11 items-center justify-center rounded-md bg-white/10 ring-1 ring-white/15">
              <Baby className="size-6" />
            </div>
            <div>
              <p className="text-sm font-medium text-white/75">
                {t("hospitalCoordinator")}
              </p>
              <h1 className="mt-1 text-2xl font-semibold tracking-normal">
                {labels.title}
              </h1>
            </div>
          </div>
        </section>

        <Card className="border-slate-200 bg-white shadow-sm">
          <CardHeader>
            <CardTitle className="text-slate-950">{labels.title}</CardTitle>
            <CardDescription>{labels.description}</CardDescription>
          </CardHeader>
          <CardContent>
            <form className="grid gap-5" onSubmit={handleSubmit}>
              <div className="grid gap-4 md:grid-cols-2">
                <Field label={labels.systemId}>
                  <input
                    className="h-10 w-full rounded-md border border-slate-200 bg-white px-3 text-sm outline-none focus:border-[#0F766E] focus:ring-3 focus:ring-[#0F766E]/15"
                    onChange={(event) =>
                      updateField("system_id", event.target.value)
                    }
                    required
                    value={form.system_id}
                  />
                </Field>

                <Field label={labels.fullName}>
                  <input
                    className="h-10 w-full rounded-md border border-slate-200 bg-white px-3 text-sm outline-none focus:border-[#0F766E] focus:ring-3 focus:ring-[#0F766E]/15"
                    onChange={(event) =>
                      updateField("full_name_enc", event.target.value)
                    }
                    value={form.full_name_enc}
                  />
                </Field>

                <Field label={labels.icNumber}>
                  <input
                    className="h-10 w-full rounded-md border border-slate-200 bg-white px-3 text-sm outline-none focus:border-[#0F766E] focus:ring-3 focus:ring-[#0F766E]/15"
                    onChange={(event) =>
                      updateField("ic_number_enc", event.target.value)
                    }
                    value={form.ic_number_enc}
                  />
                </Field>

                <Field label={labels.dob}>
                  <input
                    className="h-10 w-full rounded-md border border-slate-200 bg-white px-3 text-sm outline-none focus:border-[#0F766E] focus:ring-3 focus:ring-[#0F766E]/15"
                    onChange={(event) =>
                      updateField("date_of_birth", event.target.value)
                    }
                    required
                    type="date"
                    value={form.date_of_birth}
                  />
                </Field>

                <Field label={labels.gender}>
                  <select
                    className="h-10 w-full rounded-md border border-slate-200 bg-white px-3 text-sm outline-none focus:border-[#0F766E] focus:ring-3 focus:ring-[#0F766E]/15"
                    onChange={(event) =>
                      updateField("gender", event.target.value)
                    }
                    value={form.gender}
                  >
                    <option value="">{labels.selectGender}</option>
                    <option value="male">{labels.male}</option>
                    <option value="female">{labels.female}</option>
                  </select>
                </Field>

                <Field label={labels.ward}>
                  <input
                    className="h-10 w-full rounded-md border border-slate-200 bg-white px-3 text-sm outline-none focus:border-[#0F766E] focus:ring-3 focus:ring-[#0F766E]/15"
                    onChange={(event) => updateField("ward", event.target.value)}
                    value={form.ward}
                  />
                </Field>

                <Field label={labels.gestationalAge}>
                  <input
                    className="h-10 w-full rounded-md border border-slate-200 bg-white px-3 text-sm outline-none focus:border-[#0F766E] focus:ring-3 focus:ring-[#0F766E]/15"
                    min="0"
                    onChange={(event) =>
                      updateField("gestational_age", event.target.value)
                    }
                    type="number"
                    value={form.gestational_age}
                  />
                </Field>

                <Field label={labels.birthWeight}>
                  <input
                    className="h-10 w-full rounded-md border border-slate-200 bg-white px-3 text-sm outline-none focus:border-[#0F766E] focus:ring-3 focus:ring-[#0F766E]/15"
                    min="0"
                    onChange={(event) =>
                      updateField("birth_weight", event.target.value)
                    }
                    type="number"
                    value={form.birth_weight}
                  />
                </Field>
              </div>

              <div className="flex justify-end">
                <Button
                  className="gap-2 bg-[#0F766E] text-white hover:bg-[#115E59]"
                  disabled={isSubmitting}
                  type="submit"
                >
                  <Save className="size-4" />
                  {isSubmitting ? labels.submitting : labels.submit}
                </Button>
              </div>
            </form>
          </CardContent>
        </Card>
      </div>
    </DashboardLayout>
  );
}

function Field({
  children,
  label,
}: {
  children: ReactNode;
  label: string;
}) {
  return (
    <label className="grid gap-2">
      <span className="text-sm font-medium text-slate-700">{label}</span>
      {children}
    </label>
  );
}
