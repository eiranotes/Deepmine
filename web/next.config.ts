import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // The source art is already authored at exact pixel sizes. Serving the files directly
  // preserves nearest-neighbour edges and avoids vinext's worker-only optimizer path.
  images: {
    unoptimized: true,
  },
};

export default nextConfig;
