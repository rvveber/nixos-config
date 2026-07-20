// Timer and polling helpers used by services and live TopBar labels.
import type { Accessor } from "gnim"

export interface Timer {
  cancel(): void
}

export function interval(milliseconds: number, callback?: () => void): Timer
export function timeout(milliseconds: number, callback?: () => void): Timer
export function createPoll(
  initialValue: string,
  intervalMilliseconds: number,
  command: string | string[],
): Accessor<string>
export function createPoll<T>(
  initialValue: T,
  intervalMilliseconds: number,
  poll: (previousValue: T) => T | Promise<T>,
): Accessor<T>
