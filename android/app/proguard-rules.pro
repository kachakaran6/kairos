# ProGuard & R8 keep rules for Kairos AppWidget suite and Native plugins

# Keep all Kairos AppWidget providers and receivers
-keep class com.samyukt.kairos.widgets.** { *; }
-keepclassmembers class * extends android.appwidget.AppWidgetProvider {
    public void onUpdate(android.content.Context, android.appwidget.AppWidgetManager, int[]);
    public void onReceive(android.content.Context, android.content.Intent);
}
-keep class * extends android.appwidget.AppWidgetProvider { *; }

# Keep home_widget plugin classes
-keep class es.antonborri.home_widget.** { *; }

# Keep WorkManager workers and receivers
-keep class androidx.work.** { *; }
-keep class * extends androidx.work.Worker { *; }
-keep class * extends androidx.work.ListenableWorker { *; }

# Keep Glance app widget receivers if present
-keep class androidx.glance.** { *; }
-keep class androidx.glance.appwidget.** { *; }
