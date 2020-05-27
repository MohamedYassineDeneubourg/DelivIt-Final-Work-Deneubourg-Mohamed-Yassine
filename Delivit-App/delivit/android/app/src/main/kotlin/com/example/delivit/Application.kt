package com.example.delivit

import android.os.Bundle

import io.flutter.app.FlutterApplication
import io.flutter.plugin.common.PluginRegistry
import io.flutter.plugin.common.PluginRegistry.PluginRegistrantCallback
import io.flutter.plugins.GeneratedPluginRegistrant
import io.flutter.plugins.androidalarmmanager.AlarmService;
import com.dexterous.flutterlocalnotifications.FlutterLocalNotificationsPlugin;


class Application : FlutterApplication(), PluginRegistrantCallback {
  override fun onCreate() {
    super.onCreate();
    AlarmService.setPluginRegistrant(this);
  }

  override fun registerWith(registry: PluginRegistry) {
    
  com.dexterous.flutterlocalnotifications.FlutterLocalNotificationsPlugin.registerWith(registry?.registrarFor("com.dexterous.flutterlocalnotifications.FlutterLocalNotificationsPlugin"));
    
    GeneratedPluginRegistrant.registerWith(registry);
  }
}