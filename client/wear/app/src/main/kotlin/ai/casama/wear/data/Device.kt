package ai.casama.wear.data

import ai.casama.wear.BuildConfig
import ai.casama.wear.core.Encode
import android.content.Context
import android.os.Build
import android.provider.Settings as SystemSettings

/** What the watch says about itself (WatchDevice): shown on the phone's Settings → Watch. */
object Device {
    fun describe(context: Context): Encode.Device {
        val name = runCatching { SystemSettings.Global.getString(context.contentResolver, SystemSettings.Global.DEVICE_NAME) }
            .getOrNull()?.takeIf { it.isNotBlank() } ?: Build.MODEL ?: "Wear OS"
        return Encode.Device(
            name = name.take(80),
            model = listOfNotNull(Build.MANUFACTURER?.replaceFirstChar { it.uppercase() }, Build.MODEL)
                .distinct().joinToString(" ").take(80).ifBlank { null },
            appVersion = BuildConfig.VERSION_NAME,
            osVersion = Build.VERSION.RELEASE,
        )
    }

    fun userAgent(): String = "CasamaWear/${BuildConfig.VERSION_NAME} (Android ${Build.VERSION.RELEASE}; ${Build.MODEL})"
}
