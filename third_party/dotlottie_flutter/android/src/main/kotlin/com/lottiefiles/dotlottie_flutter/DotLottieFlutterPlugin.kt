package com.lottiefiles.dotlottie_flutter

import android.app.Activity
import android.app.Application
import android.os.Bundle
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class DotLottieFlutterPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {

    private lateinit var channel: MethodChannel
    private var activity: Activity? = null

    private val lifecycleCallbacks = object : Application.ActivityLifecycleCallbacks {
        override fun onActivityResumed(a: Activity) {
            if (a === activity) {
                platformViews.values.forEach { it.resumeGL() }
            }
        }

        override fun onActivityPaused(a: Activity) {
            if (a === activity) {
                platformViews.values.forEach { it.pauseGL() }
            }
        }

        override fun onActivityCreated(a: Activity, b: Bundle?) {}
        override fun onActivityStarted(a: Activity) {}
        override fun onActivityStopped(a: Activity) {}
        override fun onActivitySaveInstanceState(a: Activity, b: Bundle) {}
        override fun onActivityDestroyed(a: Activity) {}
    }

    // Store references to platform views
    companion object {
        val platformViews = mutableMapOf<Int, DotLottiePlatformView>()
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "dotlottie_flutter")
        channel.setMethodCallHandler(this)

        flutterPluginBinding.platformViewRegistry.registerViewFactory(
            "dotlottie_view",
            // Each engine's factory keeps that engine's own messenger. The
            // original kept ONE static messenger that every engine to attach
            // overwrote (WorkManager's and the foreground service's headless
            // engines included), so a view built afterwards talked to an
            // engine that was gone and logged "FlutterJNI was detached"
            // for every animation frame, for ever.
            DotLottieViewFactory(flutterPluginBinding.binaryMessenger)
        )
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.activity.application.registerActivityLifecycleCallbacks(lifecycleCallbacks)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity?.application?.unregisterActivityLifecycleCallbacks(lifecycleCallbacks)
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.activity.application.registerActivityLifecycleCallbacks(lifecycleCallbacks)
    }

    override fun onDetachedFromActivity() {
        activity?.application?.unregisterActivityLifecycleCallbacks(lifecycleCallbacks)
        activity = null
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        // All methods are handled by individual platform view channels
        result.notImplemented()
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        activity = null
    }
}
