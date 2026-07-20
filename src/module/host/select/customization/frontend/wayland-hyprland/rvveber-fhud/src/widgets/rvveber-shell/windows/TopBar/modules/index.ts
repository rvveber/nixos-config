import AudioModule from "./AudioModule"
import BatteryModule from "./BatteryModule"
import BluetoothModule from "./BluetoothModule"
import BrightnessModule from "./BrightnessModule"
import NetworkModule from "./NetworkModule"
import NotificationModule from "./NotificationModule"
import PowerModule from "./PowerModule"

// Right-side status modules, in visual order.
export const TOP_BAR_MODULES = [
  AudioModule,
  BrightnessModule,
  BatteryModule,
  BluetoothModule,
  NetworkModule,
  NotificationModule,
  PowerModule,
] as const
