"use client";

import { Bell } from "lucide-react";

import { Button } from "@/components/ui/button";
import { useLang } from "@/context/LanguageContext";

type TopBarProps = {
  title: string;
};

export function TopBar({ title }: TopBarProps) {
  const { lang, t, toggleLang } = useLang();

  return (
    <header className="sticky top-0 z-20 flex h-16 items-center justify-between border-b border-slate-200 bg-white/90 px-4 backdrop-blur xl:px-6">
      <div>
        <h1 className="text-lg font-semibold tracking-normal text-slate-950">
          {title}
        </h1>
        <p className="hidden text-xs text-slate-500 sm:block">
          {t("portalSubtitle")}
        </p>
      </div>
      <div className="flex items-center gap-2">
        <Button
          aria-label={t("notifications")}
          className="text-slate-600"
          size="icon"
          type="button"
          variant="outline"
        >
          <Bell className="size-4" />
        </Button>
        <div className="inline-flex rounded-md border border-slate-200 bg-white p-1 shadow-sm">
          <Button
            aria-pressed={lang === "en"}
            className={
              lang === "en"
                ? "font-bold text-[#0F766E] hover:text-[#0F766E]"
                : "text-slate-600"
            }
            onClick={() => {
              if (lang !== "en") {
                toggleLang();
              }
            }}
            size="sm"
            type="button"
            variant="ghost"
          >
            EN
          </Button>
          <Button
            aria-pressed={lang === "ms"}
            className={
              lang === "ms"
                ? "font-bold text-[#0F766E] hover:text-[#0F766E]"
                : "text-slate-600"
            }
            onClick={() => {
              if (lang !== "ms") {
                toggleLang();
              }
            }}
            size="sm"
            type="button"
            variant="ghost"
          >
            BM
          </Button>
        </div>
      </div>
    </header>
  );
}
