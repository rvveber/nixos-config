// @ts-nocheck
import Wp from "gi://AstalWp"
import { createBinding, createComputed } from "gnim"

const wp = Wp.get_default()
const audio = wp?.get_audio?.() ?? wp?.audio

const speakers = audio ? createBinding(audio, "speakers") : undefined
const microphones = audio ? createBinding(audio, "microphones") : undefined
const defaultSpeaker = audio ? createBinding(audio, "defaultSpeaker") : undefined
const defaultMicrophone = audio ? createBinding(audio, "defaultMicrophone") : undefined

// Get the actual speaker object (not an accessor)
const speaker = defaultSpeaker?.get()

// Create bindings directly to the speaker's properties
const speakerVolume = speaker ? createBinding(speaker, "volume") : undefined
const speakerMuted = speaker ? createBinding(speaker, "mute") : undefined  
const speakerIcon = speaker ? createBinding(speaker, "volumeIcon") : undefined
const speakerName = speaker ? createBinding(speaker, "description") : undefined

function setSpeakerVolume(value: number) {
  const speaker = defaultSpeaker?.get()
  if (!speaker) return
  
  // Set volume
  speaker.set_volume?.(value)
  
  // Auto-mute when volume is 0, unmute otherwise
  if (value === 0) {
    speaker.set_mute?.(true)
  } else if (speaker.mute) {
    speaker.set_mute?.(false)
  }
}

export const audioService = {
  audio,
  speakers,
  microphones,
  defaultSpeaker,
  defaultMicrophone,
  speakerVolume,
  speakerMuted,
  speakerIcon,
  speakerName,
  setSpeakerVolume,
}
