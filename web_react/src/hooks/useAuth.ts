"use client";

import { useState } from "react";

import { getUserFromToken, removeToken } from "@/lib/auth";
import type { Role } from "@/types";

type AuthUser = {
  user_id: string;
  role: Role;
};

export function useAuth() {
  const [user, setUser] = useState<AuthUser | null>(() => getUserFromToken());

  function logout() {
    removeToken();
    setUser(null);
    window.location.assign("/login");
  }

  return {
    user,
    isAuthenticated: Boolean(user),
    isLoading: false,
    logout,
  };
}
