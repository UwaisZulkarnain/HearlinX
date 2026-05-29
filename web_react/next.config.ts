import type { NextConfig } from "next";
import path from "path";

const nextConfig: NextConfig = {
  allowedDevOrigins: ["192.168.56.1"],
  turbopack: {
    root: path.resolve(__dirname),
  },
};

export default nextConfig;
