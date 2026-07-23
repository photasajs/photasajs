import { defineConfig } from "vitest/config";
import path from "path";

export default defineConfig({
    resolve: {
        alias: {
            "@": path.resolve(__dirname, "./src"),
            "@renderer": path.resolve(__dirname, "./src"),
            "@photasa/common": path.resolve(__dirname, "../../packages/common/src/index.ts"),
        },
    },
    test: {
        environment: "node",
        include: ["src/**/*.test.ts"],
        passWithNoTests: true,
    },
});
