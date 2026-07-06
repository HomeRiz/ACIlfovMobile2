package ro.acilfov.mobile

import android.os.Bundle
import android.view.WindowManager
import android.webkit.CookieManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "acilfov/cookies"

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
                        result.success(cookieManager.getCookie(url))
                    }
                    "setCookies" -> {
                        val url = call.argument<String>("url")
                        val cookies = call.argument<String>("cookies")
                        cookieManager.setAcceptCookie(true)
                        if (url != null && cookies != null) {
                            for (pair in cookies.split("; ")) {
                                if (pair.isNotBlank()) {
                                    cookieManager.setCookie(url, "$pair; Secure")
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
    }
}
