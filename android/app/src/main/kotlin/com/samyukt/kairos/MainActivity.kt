package com.samyukt.kairos

import android.content.Intent
import com.samyukt.kairos.ecosystem.PlayEcosystemManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {

    private lateinit var playEcosystemManager: PlayEcosystemManager

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        playEcosystemManager = PlayEcosystemManager(this)
        playEcosystemManager.register(flutterEngine.dartExecutor.binaryMessenger)
    }

    override fun onResume() {
        super.onResume()
        if (::playEcosystemManager.isInitialized) {
            playEcosystemManager.onResume()
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (::playEcosystemManager.isInitialized &&
            playEcosystemManager.onActivityResult(requestCode, resultCode, data)
        ) {
            return
        }
        super.onActivityResult(requestCode, resultCode, data)
    }

    override fun onDestroy() {
        if (::playEcosystemManager.isInitialized) {
            playEcosystemManager.unregister()
        }
        super.onDestroy()
    }
}
