package uz.fargonam.mobile_user

import android.app.Application
import com.yandex.mapkit.MapKitFactory

/// Custom Application class — Yandex MapKit'ni boshlash uchun.
/// AndroidManifest.xml ichida ko'rsatilgan: uz.fargonam.mobile_user.MainApplication
class MainApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        // O'zbek tili — kartada lokal nomlar
        MapKitFactory.setLocale("uz_UZ")
        // Yandex MapKit API kalit — local.properties dan BuildConfig orqali o'qiladi
        MapKitFactory.setApiKey(BuildConfig.YANDEX_MAPKIT_KEY)
    }
}
