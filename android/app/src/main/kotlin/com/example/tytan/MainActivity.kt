package com.example.tytan


import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import id.laskarmedia.openvpn_flutter.OpenVPNFlutterPlugin
import android.content.Intent
import android.os.Build
import android.provider.Settings
import android.util.Log

class MainActivity: FlutterActivity() {
    
    private val CHANNEL = "com.yallavpn.android/killswitch"
    private val TAG = "YallaMainActivity"
    
    // ═══════════════════════════════════════════════════════════════════════════
    // FLUTTER ENGINE CONFIGURATION
    // ═══════════════════════════════════════════════════════════════════════════
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Set up kill switch method channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "openKillSwitchSettings" -> {
                    openKillSwitchSettings()
                    result.success(true)
                }
                "isKillSwitchSupported" -> {
                    result.success(Build.VERSION.SDK_INT >= Build.VERSION_CODES.N)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
    
    // ═══════════════════════════════════════════════════════════════════════════
    // KILL SWITCH IMPLEMENTATION
    // ═══════════════════════════════════════════════════════════════════════════
    
    /**
     * Opens Android VPN Settings where users can enable:
     * - Always-on VPN: Keeps VPN connected at all times
     * - Block connections without VPN: Blocks internet when VPN is disconnected (Kill Switch)
     * 
     * Requirements:
     * - Android 7.0 (API 24) or higher for VPN Settings
     * - User must manually enable these settings
     */
    private fun openKillSwitchSettings() {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                val intent = Intent(Settings.ACTION_VPN_SETTINGS)
                intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                startActivity(intent)
                Log.d(TAG, "Opened VPN Settings for Kill Switch configuration")
            } else {
                Log.w(TAG, "Kill Switch not supported on Android version ${Build.VERSION.SDK_INT}")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to open VPN Settings: ${e.message}", e)
        }
    }
    
    // ═══════════════════════════════════════════════════════════════════════════
    // VPN PERMISSION HANDLING
    // ═══════════════════════════════════════════════════════════════════════════
    
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        // Handle OpenVPN permission result
        if (requestCode == 24 && resultCode == RESULT_OK) {
            try {
                OpenVPNFlutterPlugin.connectWhileGranted(true)
                Log.d(TAG, "OpenVPN permission granted, connecting...")
            } catch (e: Exception) {
                // OpenVPN not initialized, likely using Singbox or another protocol
                Log.e(TAG, "OpenVPN not initialized: ${e.message}")
            }
        }
        super.onActivityResult(requestCode, resultCode, data)
    }
}

