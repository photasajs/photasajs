import { defineConfig } from "vite";
import vue from "@vitejs/plugin-vue";
import vueJsx from "@vitejs/plugin-vue-jsx";
import path from "path";
import yaml from "@rollup/plugin-yaml";

const commonPackageRoot = path.resolve(__dirname, "../../packages/common");

// https://vitejs.dev/config/
export default defineConfig({
    plugins: [vue(), vueJsx(), yaml()],
    clearScreen: false,
    server: {
        port: 1421,
        strictPort: true,
        watch: {
            // 监听 src 目录的变化
            ignored: ["**/src-tauri/**"],
        },
    },
    resolve: {
        alias: {
            "@": path.resolve(__dirname, "./src"),
            // Dev/build bundle from source; dist is only required when consuming as a built lib elsewhere.
            "@photasa/common": path.resolve(commonPackageRoot, "src/index.ts"),
            "@renderer": path.resolve(__dirname, "./src"),
        },
    },
    build: {
        outDir: "dist",
        emptyOutDir: true,
        target: "esnext",
    },
});
