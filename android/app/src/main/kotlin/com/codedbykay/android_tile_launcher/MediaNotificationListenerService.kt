package com.codedbykay.android_tile_launcher

import android.service.notification.NotificationListenerService

/**
 * Exists only so Android has something to bind once the user grants
 * notification access in Settings: [android.media.session.MediaSessionManager]
 * .getActiveSessions requires the caller to name an enabled listener
 * component of its own, even though nothing here ever reads a single
 * notification. No callback is overridden -- this service's binding, not
 * any callback on it, is what [MediaChannelHandler] actually needs.
 */
class MediaNotificationListenerService : NotificationListenerService()
