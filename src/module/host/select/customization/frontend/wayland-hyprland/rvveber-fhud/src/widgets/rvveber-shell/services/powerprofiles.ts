// @ts-nocheck
import PowerProfiles from "gi://AstalPowerProfiles"
import { createBinding } from "gnim"

const powerProfiles = PowerProfiles.get_default()

const activeProfile = powerProfiles ? createBinding(powerProfiles, "activeProfile") : undefined

function setProfile(profile: "performance" | "power-saver") {
  powerProfiles?.set_active_profile?.(profile)
}

export const powerProfilesService = {
  powerProfiles,
  activeProfile,
  setProfile,
}
