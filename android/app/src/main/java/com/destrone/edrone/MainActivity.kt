package com.destrone.edrone

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.remember
import androidx.compose.runtime.staticCompositionLocalOf
import com.destrone.edrone.data.AppContainer
import com.destrone.edrone.ui.theme.EDroneTheme

val LocalAppContainer = staticCompositionLocalOf<AppContainer> {
    error("AppContainer not provided")
}

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        setContent {
            val container = remember { AppContainer(applicationContext) }
            CompositionLocalProvider(LocalAppContainer provides container) {
                EDroneTheme {
                    EDroneApp()
                }
            }
        }
    }
}
