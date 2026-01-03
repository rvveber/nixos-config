// @ts-nocheck
import Gtk from "gi://Gtk?version=4.0"
import { For } from "gnim"
import { networkService } from "../../../services/network"
import { IconBadge, PopoverCard, IconButton } from "../../../components"

function formatSpeed(speed?: number) {
  if (!Number.isFinite(speed) || !speed) return "--"
  if (speed >= 1000) {
    return `${(speed / 1000).toFixed(1)} Gbps`
  }
  return `${speed} Mbps`
}

export default function NetworkModule() {
  const {
    wifi,
    wired,
    tooltip,
    signalStrength,
    wifiIcon,
    wiredSpeed,
    primaryLabel,
    wifiSsid,
    wifiConnected,
    wifiFrequency,
    wifiEnabled,
    wifiScanning,
    wifiNetworks,
    setWifiEnabled,
    rescanWifi,
    wiredName,
    wiredConnected,
    activeIcon,
    activeStatus,
    vpnInfo,
    activeName,
    wiredLabel,
  } = networkService

  const vpnName = vpnInfo.as((info) => info?.name ?? "")
  const vpnDevice = vpnInfo.as((info) => info?.device ?? "")
  const vpnVisible = vpnInfo.as((info) => Boolean(info))

  return (
    <box class="TopBarSection TopBarSection--item">
      <menubutton
        class="TopBarButton"
        focusable
        receivesDefault
        tooltipText={tooltip}
      >
        <IconBadge
          icon={wifi ? wifiIcon : "network-wired-symbolic"}
          text={wifi ? signalStrength : wiredSpeed?.as((speed) => formatSpeed(speed)) ?? "--"}
        >
          <label class="DataMono DataMono--secondary" label={activeName} />
        </IconBadge>
        <PopoverCard width={360} className="NetworkPopover">
          <box spacing={16} orientation={Gtk.Orientation.VERTICAL}>
            <box class="NetworkHeader" spacing={12} valign={Gtk.Align.CENTER}>
              <box class="NetworkHeader__icon">
                <image iconName={activeIcon} pixelSize={22} />
              </box>
              <box orientation={Gtk.Orientation.VERTICAL} spacing={2} hexpand>
                <label class="SectionTitle" label={primaryLabel} xalign={0} />
                <label class="SectionLabel" label={activeName} xalign={0} />
                <label class="NetworkMeta" label={activeStatus} xalign={0} />
              </box>
            </box>
            {wifi && (
              <box orientation={Gtk.Orientation.VERTICAL} spacing={6} halign={Gtk.Align.FILL} hexpand>
                <label class="SectionTitle" label="Wi-Fi" xalign={0} />
                <label class="SectionLabel" label={wifiSsid} xalign={0} />
                <box class="NetworkPills" spacing={6}>
                  <label
                    class="NetworkPill"
                    label={wifiConnected.as((value) => (value ? "Connected" : "Disconnected"))}
                  />
                  <label class="NetworkPill" label={signalStrength} />
                  <label class="NetworkPill" label={wifiFrequency} />
                  <label
                    class="NetworkPill"
                    label={wifiScanning.as((value) => (value ? "Scanning" : "Idle"))}
                  />
                </box>
                <box class="NetworkActions" spacing={6} halign={Gtk.Align.START}>
                  <IconButton
                    className="IconAction"
                    icon="view-refresh-symbolic"
                    tooltip="Rescan networks"
                    sensitive={wifiEnabled}
                    onClicked={rescanWifi}
                  />
                  <IconButton
                    className="IconAction"
                    icon={wifiEnabled.as((value) =>
                      value ? "network-wireless-disabled-symbolic" : "network-wireless-signal-excellent-symbolic"
                    )}
                    tooltip={wifiEnabled.as((value) => (value ? "Disable Wi-Fi" : "Enable Wi-Fi"))}
                    onClicked={() => setWifiEnabled(!wifiEnabled.get())}
                  />
                </box>
                <Gtk.ScrolledWindow heightRequest={180} class="NetworkList">
                  <box orientation={Gtk.Orientation.VERTICAL} spacing={6}>
                    <For each={wifiNetworks}>
                      {(network) => (
                        <box class="NetworkRow" spacing={8}>
                          <label class="NetworkRow__ssid" label={network.ssid} xalign={0} hexpand />
                          <label
                            class="NetworkRow__meta"
                            label={`${Math.round(network.strength)}% · ${(network.frequency / 1000).toFixed(2)} GHz`}
                          />
                          {network.secure && (
                            <image
                              class="NetworkRow__lock"
                              iconName="system-lock-screen-symbolic"
                              pixelSize={14}
                            />
                          )}
                        </box>
                      )}
                    </For>
                    <label
                      class="NetworkRow__empty"
                      label={wifiNetworks.as((list) => (list.length === 0 ? "No networks found" : ""))}
                      visible={wifiNetworks.as((list) => list.length === 0)}
                    />
                  </box>
                </Gtk.ScrolledWindow>
              </box>
            )}
            {wired && (
              <box orientation={Gtk.Orientation.VERTICAL} spacing={6} halign={Gtk.Align.FILL} hexpand visible={wiredConnected}>
                <label class="SectionTitle" label="Ethernet" xalign={0} />
                <label class="SectionLabel" label={wiredName} xalign={0} />
                <box class="NetworkPills" spacing={6}>
                  <label
                    class="NetworkPill"
                    label={wiredConnected.as((value) => (value ? "Connected" : "Disconnected"))}
                  />
                  <label
                    class="NetworkPill"
                    label={wiredSpeed?.as((speed) => `Link ${formatSpeed(speed)}`) ?? "Link --"}
                  />
                </box>
              </box>
            )}
            <box orientation={Gtk.Orientation.VERTICAL} spacing={6} halign={Gtk.Align.FILL} hexpand visible={vpnVisible}>
              <label class="SectionTitle" label="VPN" xalign={0} />
              <box class="NetworkPills" spacing={6}>
                <label class="NetworkPill" label="Connected" />
                <label class="NetworkPill" label={vpnName} />
                <label class="NetworkPill" label={vpnDevice} visible={vpnInfo.as((info) => Boolean(info?.device))} />
              </box>
            </box>
          </box>
        </PopoverCard>
      </menubutton>
    </box>
  )
}
