{disko, ...}: {
  imports = [
    disko.nixosModules.disko
  ];
  disko.devices = {
    disk.main = {
      type = "disk";
      device = "/dev/disk/by-path/virtio-pci-0000:00:10.0";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            size = "512M";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = ["umask=0077"];
            };
          };

          root = {
            size = "100%";
            content = {
              type = "btrfs";
              extraArgs = ["-f"];
              subvolumes = {
                "@root" = {
                  mountpoint = "/";
                  mountOptions = [
                    "compress-force=zstd:15"
                    "noatime"
                  ];
                };
                "@nix" = {
                  mountpoint = "/nix";
                  mountOptions = [
                    "compress-force=zstd:15"
                    "noatime"
                  ];
                };
                "@home" = {
                  mountpoint = "/home";
                  mountOptions = [
                    "compress-force=zstd:15"
                    "noatime"
                  ];
                };
              };
            };
          };
        };
      };
    };
  };
}
