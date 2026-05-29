"use client";

import Cookies from "js-cookie";

import type { Role } from "@/types";

const TOKEN_COOKIE = "dengartrack_token";

type TokenUser = {
  user_id: string;
  role: Role;
};

export function saveToken(token: string) {
  Cookies.set(TOKEN_COOKIE, token, {
    sameSite: "strict",
    secure: process.env.NODE_ENV === "production",
  });
}

export function getToken() {
  return Cookies.get(TOKEN_COOKIE);
}

export function removeToken() {
  Cookies.remove(TOKEN_COOKIE);
}

export function getUserFromToken(): TokenUser | null {
  const token = getToken();

  if (!token) {
    return null;
  }

  try {
    const [, payload] = token.split(".");

    if (!payload) {
      return null;
    }

    const normalizedPayload = payload.replace(/-/g, "+").replace(/_/g, "/");
    const paddedPayload = normalizedPayload.padEnd(
      normalizedPayload.length + ((4 - (normalizedPayload.length % 4)) % 4),
      "="
    );
    const decodedPayload =
      typeof window === "undefined"
        ? Buffer.from(paddedPayload, "base64").toString("utf-8")
        : window.atob(paddedPayload);
    const user = JSON.parse(decodedPayload) as Partial<TokenUser>;

    if (!user.user_id || !user.role) {
      return null;
    }

    return {
      user_id: user.user_id,
      role: user.role,
    };
  } catch {
    return null;
  }
}
