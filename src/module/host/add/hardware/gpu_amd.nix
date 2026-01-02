{pkgs, ...}: {
  # OpenCL support for AMD iGPU/dGPU (ROCm CLR runtime + ICD).
  hardware.graphics.extraPackages = [
    pkgs.rocmPackages.clr
    pkgs.rocmPackages.clr.icd
  ];
  hardware.graphics.extraPackages32 = [];
}
