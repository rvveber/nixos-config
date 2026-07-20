// Small local contract for gnim's reactive primitives; enough for app code without checking upstream sources.
export interface Accessor<T = unknown> {
  <U>(transform: (value: T) => U): Accessor<U>
  as<U>(transform: (value: T) => U): Accessor<U>
  get(): T
}

export type Setter<T> = (value: T | ((previousValue: T) => T)) => void

export function createState<T>(initialValue: T): [Accessor<T>, Setter<T>]
export function createBinding<T = any>(object: unknown, property: string): Accessor<T>
export function createComputed<T>(
  compute: (track: <V>(accessor: Accessor<V>) => V) => T,
): Accessor<T>
export function createComputed<T>(
  dependencies: readonly unknown[],
  compute: (...values: any[]) => T,
): Accessor<T>
export function onCleanup(cleanup: () => void): void
export function For<T>(props: {
  each: Accessor<T[]> | T[] | null | undefined
  children: (item: T, index?: Accessor<number>) => unknown
}): unknown
