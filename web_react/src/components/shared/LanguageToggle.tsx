"use client";

import { useState } from "react";

import { Button } from "@/components/ui/button";

type Language = "en" | "ms";

export function LanguageToggle() {
  const [language, setLanguage] = useState<Language>("en");

  function toggleLanguage() {
    setLanguage((current) => (current === "en" ? "ms" : "en"));
  }

  return (
    <Button onClick={toggleLanguage} type="button" variant="outline">
      {language === "en" ? "English" : "Bahasa Melayu"}
    </Button>
  );
}
