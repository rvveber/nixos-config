// @ts-nocheck
import Notifd from "gi://AstalNotifd"
import { createBinding } from "gnim"

const notifd = Notifd.get_default()

const notifications = notifd ? createBinding(notifd, "notifications") : undefined
const dontDisturb = notifd ? createBinding(notifd, "dontDisturb") : undefined

function toArray(list: any): any[] {
  if (!list) return []
  if (Array.isArray(list)) return list
  if (typeof list[Symbol.iterator] === "function") {
    return Array.from(list as Iterable<any>)
  }

  const result: any[] = []
  let node = list
  while (node) {
    result.push(node.data ?? node.value ?? node)
    node = node.next
  }
  return result
}

function unreadCountAccessor() {
  if (!notifications) return () => 0
  return notifications.as((list) => toArray(list).length)
}

function dismiss(notification: any) {
  notification?.dismiss?.()
}

function dismissAll() {
  if (!notifications) return
  for (const item of toArray(notifications.get())) {
    item?.dismiss?.()
  }
}

export const notificationService = {
  notifd,
  notifications,
  dontDisturb,
  toArray,
  unreadCountAccessor,
  dismiss,
  dismissAll,
}
