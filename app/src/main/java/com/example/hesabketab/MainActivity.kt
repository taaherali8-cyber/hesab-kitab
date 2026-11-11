package com.example.hesabketab

import android.net.Uri
import android.os.Bundle
import android.webkit.JavascriptInterface
import android.webkit.WebChromeClient
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AppCompatActivity
import androidx.biometric.BiometricManager
import androidx.biometric.BiometricPrompt
import androidx.core.content.ContextCompat
import java.io.OutputStreamWriter

class MainActivity : AppCompatActivity() {
    private lateinit var webView: WebView
    private var pendingImportCallback: String? = null
    private var pendingExportCallback: String? = null
    private var pendingExportContent: String? = null

    private val importLauncher =
        registerForActivityResult(ActivityResultContracts.OpenDocument()) { uri ->
            val cbId = pendingImportCallback ?: return@registerForActivityResult
            pendingImportCallback = null
            if (uri == null) {
                callJs("window.onImportResult('$cbId', null, 'cancelled')")
                return@registerForActivityResult
            }
            try {
                val content = contentResolver.openInputStream(uri)
                    ?.bufferedReader()?.use { it.readText() } ?: ""
                val escaped = escapeJs(content)
                callJs("window.onImportResult('$cbId', '$escaped', null)")
            } catch (e: Exception) {
                callJs("window.onImportResult('$cbId', null, '${escapeJs(e.message ?: "error")}')")
            }
        }

    private val exportLauncher =
        registerForActivityResult(ActivityResultContracts.CreateDocument("application/json")) { uri ->
            val cbId = pendingExportCallback ?: return@registerForActivityResult
            val content = pendingExportContent ?: ""
            pendingExportCallback = null
            pendingExportContent = null
            if (uri == null) {
                callJs("window.onExportResult('$cbId', false)")
                return@registerForActivityResult
            }
            try {
                contentResolver.openOutputStream(uri)?.use { stream ->
                    OutputStreamWriter(stream).use { it.write(content) }
                }
                callJs("window.onExportResult('$cbId', true)")
            } catch (e: Exception) {
                callJs("window.onExportResult('$cbId', false)")
            }
        }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        webView = WebView(this)
        webView.settings.javaScriptEnabled = true
        webView.settings.domStorageEnabled = true
        webView.settings.allowFileAccess = true
        webView.webViewClient = WebViewClient()
        webView.webChromeClient = WebChromeClient()
        webView.addJavascriptInterface(Bridge(), "AndroidBridge")
        webView.loadUrl("file:///android_asset/index.html")
        setContentView(webView)
    }

    override fun onPause() {
        super.onPause()
        if (::webView.isInitialized) {
            webView.evaluateJavascript("window.onAppPause && window.onAppPause();", null)
        }
    }

    override fun onResume() {
        super.onResume()
        if (::webView.isInitialized) {
            webView.evaluateJavascript("window.onAppResume && window.onAppResume();", null)
        }
    }

    override fun onBackPressed() {
        if (webView.canGoBack()) webView.goBack() else super.onBackPressed()
    }

    private fun callJs(js: String) {
        runOnUiThread { webView.evaluateJavascript(js, null) }
    }

    private fun escapeJs(s: String): String {
        return s.replace("\\", "\\\\")
            .replace("'", "\\'")
            .replace("\n", "\\n")
            .replace("\r", "\\r")
    }

    inner class Bridge {
        @JavascriptInterface
        fun authenticate(callbackId: String) {
            runOnUiThread { startAuth(callbackId) }
        }

        @JavascriptInterface
        fun hasBiometric(): Boolean {
            val manager = BiometricManager.from(this@MainActivity)
            return manager.canAuthenticate(
                BiometricManager.Authenticators.BIOMETRIC_STRONG
            ) == BiometricManager.BIOMETRIC_SUCCESS
        }

        @JavascriptInterface
        fun exportBackup(callbackId: String, filename: String, content: String) {
            pendingExportCallback = callbackId
            pendingExportContent = content
            runOnUiThread { exportLauncher.launch(filename) }
        }

        @JavascriptInterface
        fun importBackup(callbackId: String) {
            pendingImportCallback = callbackId
            runOnUiThread {
                importLauncher.launch(arrayOf("application/json", "text/plain", "*/*"))
            }
        }
    }

    private fun startAuth(callbackId: String) {
        val manager = BiometricManager.from(this)
        val can = manager.canAuthenticate(BiometricManager.Authenticators.BIOMETRIC_STRONG)
        if (can != BiometricManager.BIOMETRIC_SUCCESS) {
            callJs("window.onAuthResult('$callbackId', true, 'unavailable');")
            return
        }

        val executor = ContextCompat.getMainExecutor(this)
        val prompt = BiometricPrompt(
            this, executor,
            object : BiometricPrompt.AuthenticationCallback() {
                override fun onAuthenticationSucceeded(result: BiometricPrompt.AuthenticationResult) {
                    super.onAuthenticationSucceeded(result)
                    callJs("window.onAuthResult('$callbackId', true, 'ok');")
                }

                override fun onAuthenticationError(errorCode: Int, errString: CharSequence) {
                    super.onAuthenticationError(errorCode, errString)
                    callJs("window.onAuthResult('$callbackId', false, 'error');")
                }

                override fun onAuthenticationFailed() {
                    super.onAuthenticationFailed()
                }
            })

        val info = BiometricPrompt.PromptInfo.Builder()
            .setTitle("ورود به حساب و کتاب")
            .setSubtitle("اثر انگشت را لمس کنید")
            .setNegativeButtonText("استفاده از پین")
            .setAllowedAuthenticators(BiometricManager.Authenticators.BIOMETRIC_STRONG)
            .build()
        prompt.authenticate(info)
    }
}
