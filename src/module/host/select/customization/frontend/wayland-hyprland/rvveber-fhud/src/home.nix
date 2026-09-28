# Defines the Home Manager layer of the FHUD desktop experience.
{
  appearance,
  config,
  lib,
  holographicWindows,
  mainMonitor,
  packages,
  pkgs,
  theme,
}: let
  hyprshadeShaderName = "blue-light-filter-550";
  hyprshadeStartTime = "20:00:00";
  hyprshadeEndTime = "05:00:00";
  lua = lib.generators.mkLuaInline;
  rgba = color: alpha: "rgba(${lib.removePrefix "#" color}${alpha})";
  luaCall = args: {_args = args;};
  bind = keys: dispatcher: flags:
    luaCall (
      [
        (lua ''mainMod .. " + ${keys}"'')
        (lua dispatcher)
      ]
      ++ lib.optional (flags != null) flags
    );
  plainBind = keys: dispatcher: flags:
    luaCall (
      [
        keys
        (lua dispatcher)
      ]
      ++ lib.optional (flags != null) flags
    );
in {
  imports = [
    ({
      config,
      lib,
      ...
    }: {
      home.activation.createFhudShaderStateDirectory = lib.mkIf holographicWindows (
        lib.hm.dag.entryBetween ["linkGeneration"] ["writeBoundary"] ''
          run ${pkgs.coreutils}/bin/mkdir -p -- ${lib.escapeShellArg "${config.xdg.stateHome}/rvveber-fhud"}
        ''
      );
    })
  ];

  # Enable stylix for home-manager
  stylix.enable = true;

  # Hyprshade configuration must live in $XDG_CONFIG_HOME. Hyprshade
  # does not search /etc/xdg.
  #
  # Note: hyprshade expects TOML "time" values (unquoted).
  xdg.configFile."hypr/hyprshade.toml".text = ''
    [[shades]]
    name = "${hyprshadeShaderName}"
    start_time = ${hyprshadeStartTime}
    end_time = ${hyprshadeEndTime}
  '';

  # More aggressive blue-light filter approximation.
  # Note: displays are RGB; a true spectral cutoff (e.g. <550nm) isn't
  # physically achievable, but we can heavily suppress blue and most
  # green to approximate an amber-only output.
  xdg.configFile."hypr/shaders/blue-light-filter-550.glsl".text = ''
    #version 300 es
                // Aggressive "blue light" suppression shader (approximate).
                // Based on hyprshade's built-in blue-light-filter.glsl.
                precision highp float;

                in vec2 v_texcoord;
                uniform sampler2D tex;
                out vec4 fragColor;

                // Warmer than the built-in (2600K), but not as red as 1800K.
                const float temperature = 2200.0;
                const float temperatureStrength = 1.0;

                // Extra channel suppression for non-cool pixels (approximate ">=550nm only").
                const vec3 channelScale = vec3(1.0, 0.25, 0.0);

                // Make "clipped" (cool/blue-ish) areas readable instead of going dark:
                // map them to slightly-dark grayscale (not too bright).
                const float clippedGrayBoost = 0.90; // brightness multiplier
                const float clippedGrayLift = 0.00;  // additive lift

                // Reduce warm tint saturation a bit (less "pure red").
                const float tintSaturation = 0.80;

                #define WithQuickAndDirtyLuminancePreservation
                const float LuminancePreservationFactor = 1.0;

                // function from https://www.shadertoy.com/view/4sc3D7
                // valid from 1000 to 40000 K (and additionally 0 for pure full white)
                vec3 colorTemperatureToRGB(const in float temperature) {
                    // values from: http://blenderartists.org/forum/showthread.php?270332-OSL-Goodness&p=2268693&viewfull=1#post2268693
                    mat3 m = (temperature <= 6500.0)
                        ? mat3(vec3(0.0, -2902.1955373783176, -8257.7997278925690),
                               vec3(0.0, 1669.5803561666639, 2575.2827530017594),
                               vec3(1.0, 1.3302673723350029, 1.8993753891711275))
                        : mat3(vec3(1745.0425298314172, 1216.6168361476490, -8257.7997278925690),
                               vec3(-2666.3474220535695, -2173.1012343082230, 2575.2827530017594),
                               vec3(0.55995389139931482, 0.70381203140554553, 1.8993753891711275));

                    return mix(
                        clamp(m[0] / (vec3(clamp(temperature, 1000.0, 40000.0)) + m[1]) + m[2], 0.0, 1.0),
                        vec3(1.0),
                        (1.0 - smoothstep(0.0, 1000.0, temperature))
                    );
                }

                void main() {
                    vec4 pixColor = texture(tex, v_texcoord);
                    vec3 color = pixColor.rgb;

    #ifdef WithQuickAndDirtyLuminancePreservation
                    float lum = dot(color, vec3(0.2126, 0.7152, 0.0722));
                    color *= mix(1.0, lum / max(lum, 1e-5), LuminancePreservationFactor);
    #endif

                     // Detect "cool" pixels (approximation for <~550nm-dominant areas).
                     float cool = max(color.b - max(color.r, color.g), 0.0);
                     float clippedMask = smoothstep(0.02, 0.20, cool);

                     float lumC = dot(color, vec3(0.2126, 0.7152, 0.0722));

                     // Important: grayscale the "cool" parts BEFORE applying the warm filter.
                     // This avoids weird hue/contrast artifacts in UI highlights (e.g. text selection).
                     vec3 pre = mix(color, vec3(lumC), clippedMask);
                     pre = mix(pre, vec3(lumC), clippedMask); // slightly softer transition
                     pre = mix(pre, vec3(lumC) * clippedGrayBoost + clippedGrayLift, clippedMask);

                     vec3 warmMul = mix(vec3(1.0), colorTemperatureToRGB(temperature), tintSaturation);
                     vec3 outColor = mix(pre, pre * warmMul, temperatureStrength);
                     outColor *= channelScale;

                     fragColor = vec4(clamp(outColor, 0.0, 1.0), pixColor.a);
                 }
  '';

  # Run hyprshade on a schedule via systemd user units.
  # Use `uwsm app -- ...` so the command runs with compositor/session env.
  systemd.user.services.hyprshade = {
    Unit.Description = "Apply screen shader";
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.uwsm}/bin/uwsm app -- ${packages.nightshift-tuner}/bin/rvveber-fhud-nightshift-tuner --auto ${hyprshadeStartTime} ${hyprshadeEndTime}";
    };
  };
  systemd.user.timers.hyprshade = {
    Unit.Description = "Apply screen shader on schedule";
    Timer = {
      OnCalendar = [
        "*-*-* ${hyprshadeStartTime}"
        "*-*-* ${hyprshadeEndTime}"
      ];
      Persistent = true;
    };
    Install.WantedBy = ["timers.target"];
  };

  # Install icon themes in user profile for complete coverage
  home.packages = with pkgs; [
    packages.ui
    packages.take-screenshot
    packages.lock-and-suspend
    packages.paste-timestamp
    packages.handle-monitor-change
    packages.switch-workspace-group
    packages.move-to-workspace-group
    packages.app-launcher
    packages.clipboard-owner
    packages.clipboard
    packages.nightshift-tuner
    papirus-icon-theme
    adwaita-icon-theme
    adwaita-icon-theme-legacy # Additional icon coverage for older apps
    hicolor-icon-theme
  ];

  home.sessionVariables.RVVEBER_FHUD_MAIN_MONITOR = mainMonitor;

  # kitty configuration
  programs.kitty = {
    enable = true;
    settings = {
      confirm_os_window_close = 0;
      enable_audio_bell = false;
    };
    shellIntegration = {
      enableZshIntegration = config.programs.zsh.enable;
      enableBashIntegration = config.programs.bash.enable;
      enableFishIntegration = config.programs.fish.enable;
    };
  };

  services.cliphist = {
    enable = true;
    allowImages = true;
    # Search the complete retained history so restoring an entry moves it to
    # the front instead of creating a second copy.
    extraOptions = [
      "-max-dedupe-search"
      "500"
      "-max-items"
      "500"
    ];
  };
  systemd.user.services.cliphist.Service = {
    CacheDirectory = "cliphist";
    CacheDirectoryMode = "0700";
    ExecStart = lib.mkForce "${pkgs.wl-clipboard}/bin/wl-paste --type text --watch ${pkgs.cliphist}/bin/cliphist -max-dedupe-search 500 -max-items 500 store";
    UMask = "0077";
  };
  systemd.user.services.cliphist-images.Service = {
    CacheDirectory = "cliphist";
    CacheDirectoryMode = "0700";
    UMask = "0077";
  };
  systemd.user.services.rvveber-fhud-clipboard-owner = {
    Unit.Description = "Own the clipboard selection chosen from FHUD";
    Service = {
      Type = "simple";
      ExecStart = "${packages.clipboard-owner}/bin/rvveber-fhud-clipboard-owner";
      Restart = "no";
      SyslogIdentifier = "rvveber-fhud-clipboard-owner";
    };
  };

  wayland.windowManager.hyprland = {
    enable = true;
    configType = "lua";
    plugins = lib.optionals holographicWindows [packages.holographic-plugin];
    extraConfig = lib.optionalString holographicWindows ''
      if hl.plugin.darkwindow ~= nil then
        local reduced = os.getenv("RVVEBER_FHUD_REDUCED_MOTION") == "1"
        hl.plugin.darkwindow.load_shader("fhud", {
          path = "${packages.holographic-shader}/holographic.glsl",
          introduces_transparency = true,
          fade_in_speed = reduced and 0 or ${toString (appearance.motion.scene / 100.0)},
          fade_out_speed = 0,
        })
        hl.plugin.darkwindow.load_shader("fhud-debug", {
          path = "${packages.holographic-shader}/holographic-debug.glsl",
          introduces_transparency = false,
          fade_in_speed = 0,
          fade_out_speed = 0,
        })
        local stateHome = os.getenv("XDG_STATE_HOME")
        if stateHome == nil or stateHome == "" then
          stateHome = os.getenv("HOME") .. "/.local/state"
        end
        local statePath = stateHome .. "/rvveber-fhud/holographic-windows"
        local enabled = true
        local saved, readError, readCode = io.open(statePath, "r")
        if saved then
          local value = saved:read("*l")
          assert(saved:close())
          assert(value == "on" or value == "off", "Invalid FutureHUD shader state: " .. statePath)
          enabled = value == "on"
        else
          assert(readCode == 2, readError)
        end

        local shaderRule = hl.window_rule({
          name = "fhud-holographic-windows",
          enabled = enabled,
          match = { fullscreen = false },
          ["darkwindow:shade"] = "fhud",
        })
        hl.bind("SUPER + F10", function()
          local nextEnabled = not shaderRule:is_enabled()
          local pending = assert(io.open(statePath .. ".tmp", "w"))
          assert(pending:write(nextEnabled and "on\n" or "off\n"))
          assert(pending:close())
          assert(os.rename(statePath .. ".tmp", statePath))

          for _, window in ipairs(hl.get_windows()) do
            hl.plugin.darkwindow.dsp_shade({ window = window, shader = "" })()
          end
          shaderRule:set_enabled(nextEnabled)
        end)
        local debugShader = hl.plugin.darkwindow.dsp_shade({ shader = "fhud-debug" })
        hl.bind("SUPER + SHIFT + F10", function()
          if shaderRule:is_enabled() then
            debugShader()
          end
        end)
      end
    '';
    settings = {
      mainMod._var = "SUPER";
      terminal._var = "kitty";
      fileManager._var = "xdg-open ~";
      menu._var = "${packages.app-launcher}/bin/rvveber-fhud-app-launcher apps";
      clipboard._var = "${packages.app-launcher}/bin/rvveber-fhud-app-launcher clipboard";
      takeScreenshot._var = "uwsm app -- ${packages.take-screenshot}/bin/rvveber-fhud-take-screenshot";
      takeScreenshotMaxCompat._var = "uwsm app -- ${packages.take-screenshot}/bin/rvveber-fhud-take-screenshot --max-compat";
      lockAndSuspend._var = "uwsm app -- ${packages.lock-and-suspend}/bin/rvveber-fhud-lock-and-suspend";
      pasteTimestamp._var = "${packages.paste-timestamp}/bin/rvveber-fhud-paste-timestamp";
      switchWorkspace._var = "${packages.switch-workspace-group}/bin/rvveber-fhud-switch-workspace-group";
      moveToWorkspace._var = "${packages.move-to-workspace-group}/bin/rvveber-fhud-move-to-workspace-group";
      handleMonitorChange._var = "${packages.handle-monitor-change}/bin/rvveber-fhud-handle-monitor-change";
      focusWindow._var = "${packages.focus-window}/bin/rvveber-fhud-focus-window";
      moveWindow._var = "${packages.move-window}/bin/rvveber-fhud-move-window";

      config = {
        input = {
          kb_layout = config.console.keyMap;
          sensitivity = 0.31;
          accel_profile = "flat";
          force_no_accel = true;
        };
        general = {
          layout = "dwindle";
          border_size = appearance.borderWidth;
          gaps_in = appearance.gap;
          gaps_out = appearance.window.outerGap;
          col = {
            active_border = lib.mkForce {
              colors = [(rgba theme.base0C "ee") (rgba theme.base07 "b0") (rgba theme.base0C "66")];
              angle = 135;
            };
            inactive_border = lib.mkForce (rgba theme.base04 "44");
          };
        };
        binds.window_direction_monitor_fallback = true;
        dwindle = {
          preserve_split = true;
          split_bias = 0;
          force_split = 2;
          smart_split = true;
          smart_resizing = true;
        };
        decoration = {
          rounding = appearance.radius;
          active_opacity = appearance.window.activeOpacity;
          inactive_opacity = appearance.window.inactiveOpacity;
          fullscreen_opacity = 1;
          glow = {
            enabled = true;
            range = appearance.glow.inner.range;
            render_power = appearance.glow.inner.power;
            color = rgba theme.base0C appearance.glow.inner.activeAlpha;
            color_inactive = rgba theme.base03 appearance.glow.inner.inactiveAlpha;
          };
          shadow = {
            enabled = true;
            range = appearance.window.shadowRange;
            render_power = 3;
            offset = "0 ${toString appearance.window.shadowOffset}";
            sharp = false;
            color = lib.mkForce (rgba theme.base00 "c0");
            color_inactive = lib.mkForce (rgba theme.base00 "80");
          };
          blur = {
            enabled = true;
            size = appearance.window.blurSize;
            passes = appearance.window.blurPasses;
            new_optimizations = true;
            ignore_opacity = true;
          };
        };
        animations.enabled = lua ''os.getenv("RVVEBER_FHUD_REDUCED_MOTION") ~= "1"'';
      };

      curve = [
        (luaCall [
          "easeInOutQuint"
          {
            type = "bezier";
            points = [
              [0.83 0]
              [0.17 1]
            ];
          }
        ])
        (luaCall [
          "easeOutExpo"
          {
            type = "bezier";
            points = [
              [0.16 1]
              [0.3 1]
            ];
          }
        ])
      ];
      animation = [
        {
          leaf = "global";
          enabled = true;
          speed = appearance.motion.move / 100.0;
          bezier = "easeOutExpo";
        }
        {
          leaf = "windowsIn";
          enabled = true;
          speed = appearance.motion.scene / 100.0;
          bezier = "easeOutExpo";
          style = "popin 96%";
        }
        {
          leaf = "windowsOut";
          enabled = true;
          speed = appearance.motion.quick / 100.0;
          bezier = "easeOutExpo";
          style = "popin 98%";
        }
        {
          leaf = "workspaces";
          enabled = true;
          speed = appearance.motion.scene / 100.0;
          bezier = "easeInOutQuint";
          style = "slidefade 8%";
        }
      ];

      on = luaCall [
        "hyprland.start"
        (lua ''
          function()
            hl.exec_cmd("uwsm app -- ${packages.ui}/bin/rvveber-fhud-ui")
            hl.exec_cmd("uwsm app -- ${packages.nightshift-tuner}/bin/rvveber-fhud-nightshift-tuner --auto ${hyprshadeStartTime} ${hyprshadeEndTime}")
            hl.exec_cmd(handleMonitorChange)
          end
        '')
      ];

      bind =
        [
          (plainBind "Escape" ''hl.dsp.exec_cmd("${packages.ui}/bin/rvveber-fhud-ui ipc call hud close")'' {non_consuming = true;})
          (plainBind "XF86MonBrightnessDown" ''hl.dsp.exec_cmd("${pkgs.brightnessctl}/bin/brightnessctl set 5%-")'' {
            locked = true;
            repeating = true;
          })
          (plainBind "XF86MonBrightnessUp" ''hl.dsp.exec_cmd("${pkgs.brightnessctl}/bin/brightnessctl set 5%+")'' {
            locked = true;
            repeating = true;
          })
          (plainBind "XF86AudioLowerVolume" ''hl.dsp.exec_cmd("${pkgs.wireplumber}/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-")'' {
            locked = true;
            repeating = true;
          })
          (plainBind "XF86AudioRaiseVolume" ''hl.dsp.exec_cmd("${pkgs.wireplumber}/bin/wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+")'' {
            locked = true;
            repeating = true;
          })
          (plainBind "XF86AudioMute" ''hl.dsp.exec_cmd("${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle")'' {locked = true;})
          (plainBind "XF86AudioMicMute" ''hl.dsp.exec_cmd("${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle")'' {locked = true;})
          (plainBind "XF86AudioPlay" ''hl.dsp.exec_cmd("${pkgs.playerctl}/bin/playerctl play-pause")'' {locked = true;})
          (plainBind "XF86AudioPause" ''hl.dsp.exec_cmd("${pkgs.playerctl}/bin/playerctl play-pause")'' {locked = true;})
          (plainBind "XF86AudioNext" ''hl.dsp.exec_cmd("${pkgs.playerctl}/bin/playerctl next")'' {locked = true;})
          (plainBind "XF86AudioPrev" ''hl.dsp.exec_cmd("${pkgs.playerctl}/bin/playerctl previous")'' {locked = true;})
          (bind "Return" "hl.dsp.exec_cmd(terminal)" null)
          (bind "A" "hl.dsp.exec_cmd(menu)" null)
          (bind "V" "hl.dsp.exec_cmd(clipboard)" null)
          (bind "Q" "hl.dsp.window.close()" null)
          (bind "E" "hl.dsp.exec_cmd(fileManager)" null)
          (bind "Space" ''hl.dsp.window.float({ action = "toggle" })'' null)
          (bind "F" ''hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" })'' null)
          (bind "SHIFT + F" ''hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" })'' null)
          (bind "P" "hl.dsp.window.pseudo()" null)
          (bind "SHIFT + M" "hl.dsp.exit()" null)
          (bind "S" "hl.dsp.exec_cmd(takeScreenshot)" null)
          (bind "SHIFT + S" "hl.dsp.exec_cmd(takeScreenshotMaxCompat)" null)
          (bind "less" "hl.dsp.exec_cmd(pasteTimestamp)" null)
          (bind "L" "hl.dsp.exec_cmd(lockAndSuspend)" null)
          (bind "SHIFT + Q" ''hl.dsp.exec_cmd("hyprctl kill")'' null)
          (bind "LEFT" ''hl.dsp.exec_cmd(focusWindow .. " l")'' null)
          (bind "RIGHT" ''hl.dsp.exec_cmd(focusWindow .. " r")'' null)
          (bind "UP" ''hl.dsp.exec_cmd(focusWindow .. " u")'' null)
          (bind "DOWN" ''hl.dsp.exec_cmd(focusWindow .. " d")'' null)
          (bind "h" ''hl.dsp.exec_cmd(focusWindow .. " l")'' null)
          (bind "l" ''hl.dsp.exec_cmd(focusWindow .. " r")'' null)
          (bind "k" ''hl.dsp.exec_cmd(focusWindow .. " u")'' null)
          (bind "j" ''hl.dsp.exec_cmd(focusWindow .. " d")'' null)
          (bind "Tab" "hl.dsp.window.cycle_next()" null)
          (bind "SHIFT + LEFT" ''hl.dsp.exec_cmd(moveWindow .. " l")'' null)
          (bind "SHIFT + RIGHT" ''hl.dsp.exec_cmd(moveWindow .. " r")'' null)
          (bind "SHIFT + UP" ''hl.dsp.exec_cmd(moveWindow .. " u")'' null)
          (bind "SHIFT + DOWN" ''hl.dsp.exec_cmd(moveWindow .. " d")'' null)
        ]
        ++ map (workspace: bind workspace "hl.dsp.exec_cmd(switchWorkspace .. \" ${workspace}\")" null) [
          "1"
          "2"
          "3"
          "4"
          "5"
          "6"
          "7"
          "8"
          "9"
          "0"
        ]
        ++ map (workspace: bind "SHIFT + ${workspace}" "hl.dsp.exec_cmd(moveToWorkspace .. \" ${workspace}\")" null) [
          "1"
          "2"
          "3"
          "4"
          "5"
          "6"
          "7"
          "8"
          "9"
          "0"
        ]
        ++ [
          (bind "mouse:272" "hl.dsp.window.drag()" {mouse = true;})
          (bind "mouse:273" "hl.dsp.window.resize()" {mouse = true;})
          (plainBind "switch:on:Lid Switch" "hl.dsp.exec_cmd(lockAndSuspend)" {locked = true;})
        ];
    };
  };
}
