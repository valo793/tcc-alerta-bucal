package com.example.tcc_alertabucal

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Context
import android.media.AudioManager

class MainActivity: FlutterFragmentActivity() {
    private val CHANNEL = "com.example.webview/audio"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            call, result ->
            val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager

            when (call.method) {
                "mute" -> {
                    audioManager.adjustStreamVolume(
                        AudioManager.STREAM_MUSIC,
                        AudioManager.ADJUST_MUTE,
                        0
                    )
                    result.success(null)
                }
                "unmute" -> {
                    audioManager.adjustStreamVolume(
                        AudioManager.STREAM_MUSIC,
                        AudioManager.ADJUST_UNMUTE,
                        0
                    )
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }
}
