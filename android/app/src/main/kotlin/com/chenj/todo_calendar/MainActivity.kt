package com.chenj.todo_calendar

import android.content.Intent
import android.net.Uri
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * Recibe archivos .ics abiertos desde otras apps («Abrir con…» o
 * «Compartir»), los copia a la caché y pasa la ruta a Flutter por el canal
 * `todo/ics`.
 */
class MainActivity : FlutterActivity() {
    private var channel: MethodChannel? = null
    private var initialIcs: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        initialIcs = icsFromIntent(intent)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "todo/ics").also {
            it.setMethodCallHandler { call, result ->
                if (call.method == "initialIcsFile") {
                    result.success(initialIcs)
                    initialIcs = null
                } else {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        icsFromIntent(intent)?.let { channel?.invokeMethod("icsFile", it) }
    }

    private fun icsFromIntent(intent: Intent?): String? {
        if (intent == null) return null
        val uri: Uri = when (intent.action) {
            Intent.ACTION_VIEW -> intent.data
            Intent.ACTION_SEND ->
                if (Build.VERSION.SDK_INT >= 33) {
                    intent.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
                } else {
                    @Suppress("DEPRECATION")
                    intent.getParcelableExtra(Intent.EXTRA_STREAM)
                }
            else -> null
        } ?: return null
        // Los enlaces del widget (todocal://) no son archivos.
        if (uri.scheme != "content" && uri.scheme != "file") return null
        return try {
            val out = File(cacheDir, "incoming-${System.currentTimeMillis()}.ics")
            val input = contentResolver.openInputStream(uri) ?: return null
            input.use { src -> out.outputStream().use { src.copyTo(it) } }
            out.absolutePath
        } catch (e: Exception) {
            null
        }
    }
}
