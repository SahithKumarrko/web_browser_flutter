package com.pichillilorenzo.flutter_inappwebview.in_app_webview;

import android.content.Context;

import org.adblockplus.libadblockplus.android.settings.AdblockHelper;
import org.adblockplus.libadblockplus.android.settings.AdblockSettings;
import org.adblockplus.libadblockplus.android.settings.AdblockSettingsStorage;

public class AdBlock {
    static AdblockSettings settings;
    static AdblockSettingsStorage storage;
    static boolean isAdBlockEnabled = true;
    public static void init(Context ctx){
        AdblockSettingsStorage storage = AdblockHelper.get().getStorage();
        settings = storage.load();
        if (settings == null) // not yet saved
        {
            settings = AdblockSettingsStorage.getDefaultSettings(ctx); // default
        }
    }


}
