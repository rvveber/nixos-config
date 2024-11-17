# system-wide npm/node replacement hack - if strange node issues arise, this is probably the cause
{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    bun
    (writeShellScriptBin "node" ''
      exec bun "$@"
    '')
    (writeShellScriptBin "npm" ''
      exec bun "$@"
    '')
    (writeShellScriptBin "npx" ''
      exec bunx --bun "$@"
    '')
  ];
}
