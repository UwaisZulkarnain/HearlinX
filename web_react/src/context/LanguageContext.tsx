"use client";

import {
  createContext,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from "react";

import en from "@/i18n/en.json";
import ms from "@/i18n/ms.json";

type Lang = "en" | "ms";
type TranslationKey = keyof typeof en;
type LanguageContextValue = {
  lang: Lang;
  toggleLang: () => void;
  t: (key: TranslationKey) => string;
};

const LANGUAGE_STORAGE_KEY = "hearlinx_lang";
const translations = { en, ms } satisfies Record<Lang, typeof en>;

const LanguageContext = createContext<LanguageContextValue | null>(null);

export function LanguageProvider({ children }: { children: ReactNode }) {
  const [lang, setLang] = useState<Lang>("ms");

  useEffect(() => {
    const storedLang = window.localStorage.getItem(LANGUAGE_STORAGE_KEY);

    if (storedLang === "en" || storedLang === "ms") {
      setLang(storedLang);
    }
  }, []);

  const value = useMemo<LanguageContextValue>(
    () => ({
      lang,
      toggleLang: () => {
        setLang((currentLang) => {
          const nextLang = currentLang === "en" ? "ms" : "en";
          window.localStorage.setItem(LANGUAGE_STORAGE_KEY, nextLang);
          return nextLang;
        });
      },
      t: (key) => translations[lang][key],
    }),
    [lang]
  );

  return (
    <LanguageContext.Provider value={value}>
      {children}
    </LanguageContext.Provider>
  );
}

export function useLang() {
  const context = useContext(LanguageContext);

  if (!context) {
    throw new Error("useLang must be used within LanguageProvider");
  }

  return context;
}
