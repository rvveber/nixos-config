# Enables OpenCode with language-server diagnostics and semantic LSP queries.
_: {
  programs.opencode = {
    enable = true;
    settings = {
      lsp = true;
      permission.lsp = "allow";
    };
  };

  home.sessionVariables.OPENCODE_EXPERIMENTAL_LSP_TOOL = "true";
}
