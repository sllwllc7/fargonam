package uz.fargonam.mobile_user

import android.app.Application
import com.yandex.mapkit.MapKitFactory
import uz.fargonam.app.BuildConfig

/// Custom Application class — Yandex MapKit'ni boshlash uchun.
/// AndroidManifest.xml ichida ko'rsatilgan: uz.fargonam.mobile_user.MainApplication
class MainApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        try {
            // setApiKey() BIRINCHI bo'lishi shart — Yandex MapKit API talabi
            if (BuildConfig.YANDEX_MAPKIT_KEY.isNotEmpty()) {
                MapKitFactory.setApiKey(BuildConfig.YANDEX_MAPKIT_KEY)
            }
            // O'zbek tili — kartada lokal nomlar (setApiKey dan KEYIN)
            MapKitFactory.setLocale("uz_UZ")
        } catch (e: Throwable) {
            // Throwable — Error subclasslarini ham tutadi (UnsatisfiedLinkError, etc.)
            android.util.Log.e("Fargonam", "MapKit init xato: $e")
        }
    }
}
