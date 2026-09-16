# Replaces Node.js package-manager commands with Bun-compatible wrappers across
# the host; disable this module first when diagnosing Node.js tooling failures.
{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    bun

    (writeShellScriptBin "node" ''
      exec bun "$@"
    '')
    (writeShellScriptBin "npm" ''
      exec bun "$@"
    '')
    (writeShellScriptBin "pnpm" ''
      exec bun "$@"
    '')
    (writeShellScriptBin "yarn" ''
      exec bun "$@"
    '')
    (writeShellScriptBin "yarnpkg" ''
      exec bun "$@"
    '')
    (writeShellScriptBin "cnpm" ''
      exec bun "$@"
    '')
    (writeShellScriptBin "tnpm" ''
      exec bun "$@"
    '')
    (writeShellScriptBin "ied" ''
      exec bun "$@"
    '')

    (writeShellScriptBin "npx" ''
      bunx --bun "$@" || bunx "$@"
    '')
    (writeShellScriptBin "pnpx" ''
      bunx --bun "$@" || bunx "$@"
    '')
    (writeShellScriptBin "cnpx" ''
      bunx --bun "$@" || bunx "$@"
    '')
    (writeShellScriptBin "tnpx" ''
      bunx --bun "$@" || bunx "$@"
    '')
    (writeShellScriptBin "iedx" ''
      bunx --bun "$@" || bunx "$@"
    '')
  ];
}
