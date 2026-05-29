export type Role = "screener" | "coordinator" | "unhs_coordinator" | "moh";

export type User = {
  user_id: string;
  role: Role;
  staff_id: string;
  full_name: string;
  hospital_id: string;
};

export type ApiResponse<T> = {
  data: T;
  message?: string;
  success: boolean;
};
