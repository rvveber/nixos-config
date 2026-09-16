import Quickshell
import Quickshell.Services.Notifications

Scope {
    id: root

    property bool doNotDisturb: false
    property var notifications: server.trackedNotifications.values
    property int count: notifications.length

    function dismissAll(): void {
        const current = root.notifications.slice();
        for (const notification of current)
            notification.dismiss();
    }

    function invokeDefault(notification): void {
        if (!notification || notification.actions.length === 0)
            return;
        const defaultAction = notification.actions.find(action => action.identifier === "default") || notification.actions[0];
        defaultAction.invoke();
    }

    NotificationServer {
        id: server
        bodySupported: true
        bodyImagesSupported: true
        bodyMarkupSupported: false
        persistenceSupported: true
        actionsSupported: true
        imageSupported: true
        actionIconsSupported: true
        keepOnReload: true

        onNotification: notification => {
            notification.tracked = true;
        }
    }
}
