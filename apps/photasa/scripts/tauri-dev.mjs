#!/usr/bin/env node
/**
 * Cross-platform `tauri dev` launcher.
 * Windows: delegates to PowerShell script that loads MSVC (cl.exe) for ffmpeg-sys-next.
 */
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";
import path from "node:path";

const scriptsDir = path.dirname(fileURLToPath(import.meta.url));
const photasaRoot = path.dirname(scriptsDir);

if (process.platform === "win32") {
    const psScript = path.join(scriptsDir, "tauri-dev-windows.ps1");
    const shell = process.env.ComSpec || "cmd.exe";
    const result = spawnSync(
        "powershell.exe",
        ["-NoProfile", "-ExecutionPolicy", "Bypass", "-File", psScript],
        { stdio: "inherit", cwd: photasaRoot },
    );
    process.exit(result.status ?? 1);
}

const result = spawnSync("pnpm", ["exec", "tauri", "dev"], {
    stdio: "inherit",
    cwd: photasaRoot,
    shell: true,
});
process.exit(result.status ?? 1);
