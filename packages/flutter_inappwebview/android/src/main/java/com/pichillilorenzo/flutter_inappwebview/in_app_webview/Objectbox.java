package com.pichillilorenzo.flutter_inappwebview.in_app_webview;

import android.content.Context;

import io.objectbox.BoxStore;

public class Objectbox {
    private static BoxStore boxStore;

    public static void init(Context context) {
        boxStore = MyObjectBox.builder()
                .androidContext(context.getApplicationContext())
                .build();
    }

    public static BoxStore get() { return boxStore; }
}