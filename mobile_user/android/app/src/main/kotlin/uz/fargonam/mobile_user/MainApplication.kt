package uz.fargonam.mobile_user

import android.app.Application

/// Custom Application class — Yandex MapKit'ni boshlash uchun.
/// AndroidManifest.xml ichida ko'rsatilgan: uz.fargonam.mobile_user.MainApplication
///
/// 2026-08-20: Yandex MapKit vaqtincha o'chirilgan (APK ~71MB kamaytirish
/// uchun, taksi hali 2-bosqich funksiyasi). Qaytarish: PROGRESS.md
/// "Taksi qaytarish" bo'limiga qara — shu faylni asl holiga qaytarish ham
/// o'sha ro'yxatda.
// import com.yandex.mapkit.MapKitFactory
// import uz.fargonam.app.BuildConfig
class MainApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        // try {
        //     // setApiKey() BIRINCHI bo'lishi shart — Yandex MapKit API talabi
        //     if (BuildConfig.YANDEX_MAPKIT_KEY.isNotEmpty()) {
        //         MapKitFactory.setApiKey(BuildConfig.YANDEX_MAPKIT_KEY)
        //     }
        //     // O'zbek tili — kartada lokal nomlar (setApiKey dan KEYIN)
        //     MapKitFactory.setLocale("uz_UZ")
        // } catch (e: Throwable) {
        //     // Throwable — Error subclasslarini ham tutadi (UnsatisfiedLinkError, etc.)
        //     android.util.Log.e("Fargonam", "MapKit init xato: $e")
        // }
    }
}
