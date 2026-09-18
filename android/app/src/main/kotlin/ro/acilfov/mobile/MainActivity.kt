package ro.acilfov.mobile

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.view.WindowManager
import android.webkit.CookieManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "acilfov/cookies"
    private val systemChannelName = "acilfov/system"
    private val portalHost = "acilfov.emsys.ro"

    // Validare defensiva a hostului si in codul nativ, chiar daca partea Dart
    // trimite deja URL-ul corect - canalul e apelabil doar din Dart (nu din
    // continutul web), dar nu ne bazam doar pe asta.
    private fun isPortalUrl(url: String?): Boolean {
        val host = url?.let { Uri.parse(it).host } ?: return false
        return host == portalHost
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE
        )
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                val cookieManager = CookieManager.getInstance()
                when (call.method) {
                    "getCookies" -> {
                        val url = call.argument<String>("url")
                        if (!isPortalUrl(url)) {
                            result.success("")
                            return@setMethodCallHandler
                        }
                        result.success(cookieManager.getCookie(url))
                    }
                    "setCookies" -> {
                        val url = call.argument<String>("url")
                        val cookies = call.argument<String>("cookies")
                        if (!isPortalUrl(url)) {
                            result.success(false)
                            return@setMethodCallHandler
                        }
                        cookieManager.setAcceptCookie(true)
                        if (cookies != null) {
                            for (pair in cookies.split("; ")) {
                                if (pair.isNotBlank()) {
                                    cookieManager.setCookie(url, "$pair; Secure; HttpOnly; SameSite=Lax")
                                }
                            }
                        }
                        cookieManager.flush()
                        result.success(true)
                    }
                    "clearCookies" -> {
                        cookieManager.removeAllCookies(null)
                        cookieManager.flush()
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }

        // Ecranele de setari ale sistemului.
        //
        // DE CE E NEVOIE: pe Android sub 13 nu exista niciun dialog de
        // permisiune pentru notificari. Daca userul le-a oprit din setari,
        // aplicatia NU are cum sa i le ceara - singurul lucru corect e sa-l
        // duca direct la ecranul unde le poate reporni.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, systemChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openNotificationSettings" -> {
                        val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                                .putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                        } else {
                            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                                .setData(Uri.fromParts("package", packageName, null))
                        }
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        result.success(runCatching { startActivity(intent) }.isSuccess)
                    }
                    "openBatterySettings" -> {
                        val intent = Intent(
                            Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS
                        ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        result.success(runCatching { startActivity(intent) }.isSuccess)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
