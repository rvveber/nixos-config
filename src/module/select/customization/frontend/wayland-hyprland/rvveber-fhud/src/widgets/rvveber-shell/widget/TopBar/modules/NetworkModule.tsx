// @ts-nocheck
import Gtk from "gi://Gtk?version=4.0"
import { networkService } from "../../services/network"
import { IconBadge, PopoverCard, IconButton } from "../../common"

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
    activeName,
    wiredLabel,
    reconnectVpn,
  } = networkService

  return (
    
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
          <box spacing={10} orientation={Gtk.Orientation.VERTICAL}>
            {wifi && (
              <box orientation={Gtk.Orientation.VERTICAL} spacing={6}>
                <label class="SectionTitle" label="Wi-Fi" />
                <label class="SectionLabel" label={activeName} />
                <box spacing={6}>
                  <IconButton
                    className="IconAction"
                    icon="network-wireless-signal-excellent-symbolic"
                    tooltip="Rescan"
                    onClicked={() => wifi?.get?.()?.scan?.()}
                  />
                  <IconButton
                    className="IconAction"
                    icon="network-wired-symbolic"
                    tooltip="Deactivate"
                    onClicked={() => wifi?.get?.()?.deactivate_connection?.()}
                  />
                </box>
              </box>
            )}
            {wired && (
              <box orientation={Gtk.Orientation.VERTICAL} spacing={6}>
                <label class="SectionTitle" label="Ethernet" />
                <label class="SectionLabel" label={wiredLabel} />
                <label label={wiredSpeed?.as((speed) => `Link: ${formatSpeed(speed)}`) ?? "Link: --"} />
              </box>
            )}
            <box orientation={Gtk.Orientation.VERTICAL} spacing={6}>
              <label class="SectionTitle" label="VPN" />
              <IconButton
                className="IconAction"
                icon="network-vpn-symbolic"
                tooltip="Reconnect Mullvad"
                onClicked={reconnectVpn}
              />
            </box>
          </box>
        </PopoverCard>
      </menubutton>
    
  )
}
