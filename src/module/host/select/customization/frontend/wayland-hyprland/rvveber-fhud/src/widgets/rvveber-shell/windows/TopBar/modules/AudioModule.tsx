// @ts-nocheck
import Gtk from "gi://Gtk?version=4.0"
import { For, createBinding, createComputed } from "gnim"
import { audioService } from "../../../services/audio"
import { IconBadge, PopoverCard, SliderRow } from "../../../components"

function formatPercent(value: number) {
  return `${Math.round(value * 100)}%`
}

function EndpointButton({ endpoint }: { endpoint: any }) {
  const description = createBinding(endpoint, "description")
  const icon = createBinding(endpoint, "icon")
  const isDefault = createBinding(endpoint, "isDefault")

  return (
    <button
      class="DeviceButton"
      focusable
      onClicked={() => endpoint.set_is_default?.(true)}
    >
      <box spacing={6}>
        <image iconName="audio-volume-medium-symbolic" pixelSize={18} />
        <label xalign={0} hexpand label={description?.((value) => value || "Unknown device")} />
        <image
          iconName="object-select-symbolic"
          visible={isDefault}
          pixelSize={16}
        />
      </box>
    </button>
  )
}

function InputButton({ endpoint }: { endpoint: any }) {
  const description = createBinding(endpoint, "description")
  const isDefault = createBinding(endpoint, "isDefault")

  return (
    <button
      class="DeviceButton"
      focusable
      onClicked={() => endpoint.set_is_default?.(true)}
    >
      <box spacing={6}>
        <image iconName="audio-input-microphone-symbolic" pixelSize={18} />
        <label xalign={0} hexpand label={description?.((value) => value || "Unknown input")} />
        <image iconName="object-select-symbolic" visible={isDefault} pixelSize={16} />
      </box>
    </button>
  )
}

export default function AudioModule() {
  const {
    audio,
    speakers,
    microphones,
    defaultSpeaker,
    speakerVolume,
    speakerMuted,
    speakerIcon,
    speakerName,
    setSpeakerVolume,
  } = audioService

  if (!audio || !defaultSpeaker) {
    return null
  }

  const volumeLabel = speakerVolume
    ? speakerVolume.as((value) => formatPercent(value))
    : "--"

  const tooltipText = speakerName && speakerVolume
    ? createComputed([speakerName, speakerVolume], (name, volume) => `${name}: ${formatPercent(volume)}`)
    : "Audio"

  return (
    <box class="TopBarSection TopBarSection--item">
      <menubutton
        class="TopBarButton"
        focusable
        receivesDefault
        sensitive={Boolean(audio)}
        tooltipText={tooltipText}
      >
        <IconBadge icon={speakerIcon} text={volumeLabel} />
        <PopoverCard width={360} className="AudioPopover">
          <box spacing={10} orientation={Gtk.Orientation.VERTICAL}>
            <SliderRow
              title="Audio"
              value={speakerVolume}
              onChange={setSpeakerVolume}
              quickSteps={[0, 0.5, 1]}
            />
            {speakers && (
              <box orientation={Gtk.Orientation.VERTICAL} spacing={4}>
                <label class="SectionLabel" label="Outputs" />
                <box orientation={Gtk.Orientation.VERTICAL} spacing={2}>
                  <For each={speakers}>{(endpoint) => <EndpointButton endpoint={endpoint} />}</For>
                </box>
              </box>
            )}
            {microphones && (
              <box orientation={Gtk.Orientation.VERTICAL} spacing={4}>
                <label class="SectionLabel" label="Inputs" />
                <box orientation={Gtk.Orientation.VERTICAL} spacing={2}>
                  <For each={microphones}>{(endpoint) => <InputButton endpoint={endpoint} />}</For>
                </box>
              </box>
            )}
          </box>
        </PopoverCard>
      </menubutton>
    </box>
  )
}
