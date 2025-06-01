package com.milanciganovic.instagram_share_plus;

import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.content.pm.ResolveInfo;
import android.net.Uri;

import androidx.core.content.FileProvider;

import java.io.File;
import java.util.List;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;

public class ShareInstagramVideoPlugin implements MethodCallHandler {
    private final Context context;

    private ShareInstagramVideoPlugin(Context context) {
        this.context = context;
    }

    public static void registerWith(Registrar registrar) {
        final MethodChannel channel = new MethodChannel(registrar.messenger(), "instagram_share_plus");
        channel.setMethodCallHandler(new ShareInstagramVideoPlugin(registrar.context()));
    }

    @Override
    public void onMethodCall(MethodCall call, Result result) {
        if (call.method.equals("shareToStory")) {
            String filePath = call.argument("filePath");
            boolean success = shareToInstagram(filePath);
            result.success(success ? "shared" : "instagram_not_installed");
        } else {
            result.notImplemented();
        }
    }

    private boolean shareToInstagram(String filePath) {
        File file = new File(filePath);
        if (!file.exists()) return false;

        // Vérifie si Instagram est installé
        if (!isInstagramInstalled()) {
            return false;
        }

        Uri uri = FileProvider.getUriForFile(
                context,
                context.getPackageName() + ".provider",
                file
        );

        Intent intent = new Intent("com.instagram.share.ADD_TO_STORY");
        intent.setDataAndType(uri, "image/*");
        intent.setFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION | Intent.FLAG_ACTIVITY_NEW_TASK);

        // 🔥 Cibler explicitement le package Instagram
        intent.setPackage("com.instagram.android");

        context.grantUriPermission("com.instagram.android", uri, Intent.FLAG_GRANT_READ_URI_PERMISSION);
        context.startActivity(intent);

        return true;
    }

    private boolean isInstagramInstalled() {
        PackageManager pm = context.getPackageManager();
        try {
            pm.getPackageInfo("com.instagram.android", PackageManager.GET_ACTIVITIES);
            return true;
        } catch (PackageManager.NameNotFoundException e) {
            return false;
        }
    }
}
