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
        // Yandex MapKit Mobile SDK API key
        MapKitFactory.setApiKey("bf5c7011-5a0b-4643-a899-097d1f3d2ab9")
    }
}
