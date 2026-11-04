package education.ysem.horloge_monotone;

import android.content.Context;
import android.os.Build;
import android.os.SystemClock;
import android.provider.Settings;

import androidx.annotation.NonNull;

import java.util.HashMap;
import java.util.Map;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

/**
 * Compteur interne de l'appareil : elapsedRealtime compte depuis le démarrage,
 * veille comprise, et changer l'heure du téléphone ne le touche pas.
 */
public class HorlogeMonotonePlugin implements FlutterPlugin, MethodChannel.MethodCallHandler {
    private MethodChannel canal;
    private Context contexte;

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding liaison) {
        contexte = liaison.getApplicationContext();
        canal = new MethodChannel(liaison.getBinaryMessenger(), "ysem/horloge_monotone");
        canal.setMethodCallHandler(this);
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding liaison) {
        canal.setMethodCallHandler(null);
        canal = null;
        contexte = null;
    }

    @Override
    public void onMethodCall(@NonNull MethodCall appel, @NonNull MethodChannel.Result resultat) {
        if (!"lire".equals(appel.method)) {
            resultat.notImplemented();
            return;
        }
        Map<String, Object> valeurs = new HashMap<>();
        valeurs.put("ms", SystemClock.elapsedRealtime());
        valeurs.put("demarrage", numeroDeDemarrage());
        resultat.success(valeurs);
    }

    private Integer numeroDeDemarrage() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) {
            return null;
        }
        try {
            return Settings.Global.getInt(contexte.getContentResolver(), Settings.Global.BOOT_COUNT);
        } catch (Settings.SettingNotFoundException e) {
            return null;
        }
    }
}
