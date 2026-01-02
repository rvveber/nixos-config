// @ts-nocheck
import Gtk from "gi://Gtk?version=4.0"
import { For, createBinding } from "gnim"
import { notificationService } from "../../services/notifications"
import { IconBadge, PopoverCard, IconButton } from "../../common"

function formatTime(timestamp?: number) {
  if (!timestamp) return ""
  const date = new Date(timestamp * 1000)
  return date.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" })
}

function NotificationCard({ notification }: { notification: any }) {
  const summary = createBinding(notification, "summary")
  const body = createBinding(notification, "body")
  const time = createBinding(notification, "time")

  function dismiss() {
    notificationService.dismiss(notification)
  }

  function activateDefault() {
    const actions = notificationService.toArray(notification.actions)
    const defaultAction = actions[0]
    if (defaultAction) {
      notification.invoke?.(defaultAction.id)
    }
  }

  return (
    <box orientation={Gtk.Orientation.VERTICAL} class="NotificationCard" spacing={4}>
      <box spacing={6}>
        <label class="NotificationTitle" label={summary} hexpand xalign={0} />
        <label class="NotificationTime" label={time.as(formatTime)} />
      </box>
      <label class="NotificationBody" label={body} wrap widthChars={42} />
      <box spacing={4}>
  <IconButton className="IconAction" icon="object-select-symbolic" tooltip="Open" onClicked={activateDefault} />
  <IconButton className="IconAction" icon="user-trash-symbolic" tooltip="Dismiss" onClicked={dismiss} />
      </box>
    </box>
  )
}

export default function NotificationModule() {
  const { notifications, unreadCountAccessor, dontDisturb, dismissAll } = notificationService
  const badge = unreadCountAccessor()

  return (
    
      <menubutton
        
        class="TopBarButton"
        focusable
        receivesDefault
        tooltipText="Notifications"
      >
        <IconBadge icon="mail-unread-symbolic" text={badge.as((count) => `${count}`)}>
          <label class="NotificationBadge" label={badge.as((count) => `${count}`)} />
        </IconBadge>
        <PopoverCard width={360} className="NotificationPopover">
          <box spacing={10} orientation={Gtk.Orientation.VERTICAL}>
            <box spacing={6} valign={Gtk.Align.CENTER}>
              <label class="SectionTitle" label="Notifications" />
              <IconButton
                className="IconAction"
                icon="user-trash-symbolic"
                tooltip="Dismiss all"
                onClicked={dismissAll}
              />
            </box>
            <box spacing={6}>
              <togglebutton
                class="IconToggleButton"
                focusable
                active={dontDisturb}
                onToggled={() => {
                  const current = dontDisturb?.get?.() ?? false
                  notificationService.notifd.dont_disturb = !current
                }}
              >
                <label label={dontDisturb?.as((value) => (value ? "Focus" : "Alert")) ?? "Mode"} />
              </togglebutton>
            </box>
            <box orientation={Gtk.Orientation.VERTICAL} spacing={6}>
              {notifications ? (
                <For each={notifications}>{(notification) => <NotificationCard notification={notification} />}</For>
              ) : (
                <label label="No notifications" opacity={0.6} />
              )}
            </box>
          </box>
        </PopoverCard>
      </menubutton>
    
  )
}
