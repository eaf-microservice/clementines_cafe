package com.eafmicroservice.clementinecafe

import android.os.Bundle
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
  override fun onCreate(savedInstanceState: Bundle?) {
    // Aligns the Flutter UI behind the status bar and navigation bar.
    WindowCompat.setDecorFitsSystemWindows(window, false)

    super.onCreate(savedInstanceState)
  }
}
