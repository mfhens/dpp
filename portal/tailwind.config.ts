import type { Config } from "tailwindcss";

const config: Config = {
  content: [
    "./app/**/*.{ts,tsx}",
    "./components/**/*.{ts,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        ey: {
          yellow: "#ffd200",
          black: "#111111",
          charcoal: "#1f1f1f",
          surface: "#ffffff",
          surface2: "#f7f7f7",
          border: "#e5e7eb",
        },
      },
      borderRadius: {
        xl: "var(--ey-radius)",
        "2xl": "20px",
      },
      boxShadow: {
        ey1: "var(--ey-shadow-1)",
        ey2: "var(--ey-shadow-2)",
      },
    },
  },
  plugins: [],
};
export default config;

