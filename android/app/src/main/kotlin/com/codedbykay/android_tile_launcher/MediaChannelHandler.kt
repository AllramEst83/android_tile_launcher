package com.codedbykay.android_tile_launcher

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.media.MediaMetadata
import android.media.session.MediaController
import android.media.session.MediaSessionManager
import android.media.session.PlaybackState
import android.provider.Settings
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

/**
 * Tells the Dart `AndroidMediaService` what is playing in whatever app owns
 * the active media session (Spotify, YouTube Music, a podcast app, ...), and
 * forwards play/pause/skip to it.
 *
 * Reading a session needs notification-listener access -- a "special
 * access" permission granted only from its own Settings screen, never a
 * runtime dialog -- which is why [MediaNotificationListenerService] exists:
 * once its component is enabled, [MediaSessionManager.getActiveSessions]
 * accepts it in place of this app's own notifications. Nothing here ever
 * reads a notification's content.
 */
class MediaChannelHandler(
    private val context: Context,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler {
    private val channel = MethodChannel(messenger, CHANNEL)
    private val sessionManager =
        context.getSystemService(Context.MEDIA_SESSION_SERVICE) as MediaSessionManager
    private val listenerComponent =
        ComponentName(context, MediaNotificationListenerService::class.java)

    init {
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "now" -> result.success(now())
            "playPause" -> {
                playPause()
                result.success(null)
            }
            "next" -> {
                activeController()?.transportControls?.skipToNext()
                result.success(null)
            }
            "previous" -> {
                activeController()?.transportControls?.skipToPrevious()
                result.success(null)
            }
            "openAccessSettings" -> result.success(openAccessSettings())
            else -> result.notImplemented()
        }
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
    }

    private fun hasAccess(): Boolean {
        val enabled = Settings.Secure.getString(
            context.contentResolver,
            "enabled_notification_listeners",
        ) ?: return false
        return enabled.contains(context.packageName)
    }

    // Prefers a session that is actually playing; falls back to the first one
    // with anything to show, so a paused player still reads instead of
    // looking like nothing is open. `getActiveSessions` can still throw even
    // with access granted (some OEMs lag the system setting behind the real
    // binding), so that is treated the same as no access rather than crashing.
    private fun activeController(): MediaController? {
        if (!hasAccess()) return null
        val controllers = try {
            sessionManager.getActiveSessions(listenerComponent)
        } catch (e: SecurityException) {
            return null
        }
        return controllers.firstOrNull { it.playbackState?.state == PlaybackState.STATE_PLAYING }
            ?: controllers.firstOrNull { it.metadata != null }
    }

    private fun now(): Map<String, Any?> {
        if (!hasAccess()) return mapOf("needsAccess" to true)
        val controller = activeController() ?: return mapOf("none" to true)
        val metadata = controller.metadata
        val state = controller.playbackState
        val artwork = metadata?.getBitmap(MediaMetadata.METADATA_KEY_ALBUM_ART)
            ?: metadata?.getBitmap(MediaMetadata.METADATA_KEY_ART)
        return mapOf(
            "title" to (metadata?.getString(MediaMetadata.METADATA_KEY_TITLE) ?: ""),
            "artist" to (metadata?.getString(MediaMetadata.METADATA_KEY_ARTIST) ?: ""),
            "album" to metadata?.getString(MediaMetadata.METADATA_KEY_ALBUM),
            "isPlaying" to (state?.state == PlaybackState.STATE_PLAYING),
            "appLabel" to appLabelOf(controller.packageName),
            "artwork" to artwork?.let(::pngBytes),
        )
    }

    private fun playPause() {
        val controller = activeController() ?: return
        val playing = controller.playbackState?.state == PlaybackState.STATE_PLAYING
        if (playing) {
            controller.transportControls.pause()
        } else {
            controller.transportControls.play()
        }
    }

    private fun appLabelOf(packageName: String): String? = try {
        val pm = context.packageManager
        pm.getApplicationLabel(pm.getApplicationInfo(packageName, 0)).toString()
    } catch (e: Exception) {
        null
    }

    private fun pngBytes(bitmap: Bitmap): ByteArray {
        val stream = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
        return stream.toByteArray()
    }

    private fun openAccessSettings(): Boolean = try {
        val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        context.startActivity(intent)
        true
    } catch (e: Exception) {
        false
    }

    companion object {
        const val CHANNEL = "com.codedbykay.android_tile_launcher/media"
    }
}
