import type { ComponentType } from "react";

import {
  Card,
  CardContent,
} from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { cn } from "@/lib/utils";

type StatCardProps = {
  label: string;
  value: string | number;
  description?: string;
  icon?: ComponentType<{ className?: string }>;
  isLoading?: boolean;
  accentClassName?: string;
};

export function StatCard({
  label,
  value,
  description,
  icon: Icon,
  isLoading = false,
  accentClassName,
}: StatCardProps) {
  return (
    <Card className="relative border-slate-200 bg-white shadow-sm">
      <div
        className={cn(
          "absolute inset-x-0 top-0 h-1 bg-[#0F766E]",
          accentClassName
        )}
      />
      <CardContent className="pt-2">
        <div className="flex items-start justify-between gap-4">
          <div className="min-w-0">
            <p className="text-sm font-medium text-slate-500">{label}</p>
            {isLoading ? (
              <Skeleton className="mt-3 h-8 w-24 bg-slate-100" />
            ) : (
              <p className="mt-2 text-3xl font-semibold tracking-normal text-slate-950">
                {value}
              </p>
            )}
          </div>
          {Icon ? (
            <div className="flex size-10 shrink-0 items-center justify-center rounded-md bg-[#0F766E]/10 text-[#0F766E]">
              <Icon className="size-5" />
            </div>
          ) : null}
        </div>
        {description ? (
          <p className="mt-3 text-xs font-medium text-slate-500">
            {description}
          </p>
        ) : null}
      </CardContent>
    </Card>
  );
}
