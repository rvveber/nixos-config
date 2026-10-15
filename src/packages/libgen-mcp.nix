# Packages the scholarly document retrieval MCP server from its upstream release.
{
  lib,
  buildGo127Module,
  fetchFromGitHub,
}:
buildGo127Module rec {
  pname = "libgen-mcp";
  version = "2.2.1";
  src = fetchFromGitHub {
    owner = "jmrplens";
    repo = "libgen-mcp";
    rev = "v${version}";
    sha256 = "1f7gsf13jg99dah2cfd8sdygcrad650njgkir4g054rznv9nvrqi";
  };
  vendorHash = "sha256-qP2TeQf1D4TSDC7MZjLB2hJeVjb8fH3StnDcHHNomiw=";
  subPackages = ["cmd/server"];
  env.CGO_ENABLED = 0;
  ldflags = ["-s" "-w"];
  doCheck = false;
  postInstall = ''
    mv $out/bin/server $out/bin/libgen-mcp
  '';
  meta = {
    description = "Scholarly document retrieval MCP server";
    homepage = "https://github.com/jmrplens/libgen-mcp";
    license = lib.licenses.mit;
    mainProgram = "libgen-mcp";
    platforms = lib.platforms.linux;
  };
}
