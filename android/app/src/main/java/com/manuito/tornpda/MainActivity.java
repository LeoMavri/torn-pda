package com.manuito.tornpda;

import androidx.annotation.NonNull;
import androidx.annotation.RequiresApi;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugins.GeneratedPluginRegistrant;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.os.Build;
import java.util.List;
import io.flutter.plugin.common.MethodChannel;
import android.os.Bundle;
import android.window.SplashScreenView;
import androidx.core.view.WindowCompat;
import android.appwidget.AppWidgetManager;
import android.os.PowerManager;

public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "tornpda.channel";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        // Aligns the Flutter view vertically with the window.
        WindowCompat.setDecorFitsSystemWindows(getWindow(), false);

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            // Disable the Android splash screen fade out animation to avoid
            // a flicker before the similar frame is drawn in Flutter.
            getSplashScreen()
                    .setOnExitAnimationListener(
                            (SplashScreenView splashScreenView) -> {
                                splashScreenView.remove();
                            });
        }

        super.onCreate(savedInstanceState);
    }

    private MethodChannel.Result myResult;

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine);

        // Setups a method channel for the Flutter part
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
                .setMethodCallHandler((call, result) -> {
                    if (call.method.equals("cancelNotifications")) {
                        cancelNotifications();
                    } else if (call.method.equals("deleteNotificationChannels")) {
                        deleteNotificationChannels();
                    } else if (call.method.equals("widgetCount")) {
                        AppWidgetManager lala = AppWidgetManager.getInstance(this);
                        ComponentName name = new ComponentName(this, HomeWidgetTornPda.class);
                        result.success(lala.getAppWidgetIds(name));
                    } else if (call.method.equals("checkBatteryOptimization")) {
                        boolean isRestricted = isBatteryOptimizationRestricted();
                        result.success(isRestricted);
                    } else if (call.method.equals("openBatterySettings")) {
                        openBatterySettings();
                        result.success(null);
                    } else {
                        result.notImplemented();
                    }
                });
    }

    // This cancels Firebase notifications upon request from the Flutter app, as the
    // local plugins also cancel their scheduled ones when cancelAll() is called.
    // Note: It is also possible to use "cancel("TAG", 0)" but giving a TAG in FCM
    // Android options overwrites the notifications with the same tag.
    // There is an alternative which is preparing multiple tags.
    private void cancelNotifications() {
        NotificationManager notificationManager = (NotificationManager) getSystemService(Context.NOTIFICATION_SERVICE);
        notificationManager.cancelAll();
    }

    // Deletes all notification channels
    private void deleteNotificationChannels() {
        // Oreo or above, otherwise it will fail (can't be cached in Flutter)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationManager notificationManager = (NotificationManager) getSystemService(
                    Context.NOTIFICATION_SERVICE);
            List<NotificationChannel> channels = notificationManager.getNotificationChannels();
            for (NotificationChannel channel : channels) {
                notificationManager.deleteNotificationChannel(channel.getId());
            }
        }
    }

    // Checks if the battery optimization is restricted
    private boolean isBatteryOptimizationRestricted() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PowerManager powerManager = (PowerManager) getSystemService(POWER_SERVICE);
            String packageName = getPackageName();
            return !powerManager.isIgnoringBatteryOptimizations(packageName);
        }
        return false; // Not restricted for versions below Marshmallow
    }

    // Opens the battery optimization settings screen
    private void openBatterySettings() {
        Intent intent = new Intent(android.provider.Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS);
        startActivity(intent);
    }
}