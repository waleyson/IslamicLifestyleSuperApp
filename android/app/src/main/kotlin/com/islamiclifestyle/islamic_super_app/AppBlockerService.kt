package com.islamiclifestyle.islamic_super_app

import android.accessibilityservice.AccessibilityService
import android.content.Context
import android.content.Intent
import android.view.accessibility.AccessibilityEvent
import android.widget.Toast

class AppBlockerService : AccessibilityService() {

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return
        
        if (event.eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
            val packageName = event.packageName?.toString() ?: return
            
            // Check if this package is a blocked social media app
            if (isSocialMediaApp(packageName)) {
                // Read from blocker_prefs SharedPreferences
                val sharedPreferences = getSharedPreferences("blocker_prefs", Context.MODE_PRIVATE)
                val isLocked = sharedPreferences.getBoolean("is_locked", true)
                
                if (isLocked) {
                    // Go to home screen to block the app
                    performGlobalAction(GLOBAL_ACTION_HOME)
                    
                    // Show a helpful Toast message
                    Toast.makeText(
                        applicationContext,
                        "Social media is locked until you meet your daily Quran & Azkar targets!",
                        Toast.LENGTH_LONG
                    ).show()
                    
                    // Launch our own app so they can see and complete the targets
                    val launchIntent = packageManager.getLaunchIntentForPackage(applicationContext.packageName)
                    if (launchIntent != null) {
                        launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        startActivity(launchIntent)
                    }
                }
            }
        }
    }

    override fun onInterrupt() {
        // Required method override
    }

    private fun isSocialMediaApp(packageName: String): Boolean {
        val socialMediaPackages = setOf(
            "com.instagram.android",
            "com.facebook.katana",
            "com.twitter.android",
            "com.zhiliaoapp.musically", // TikTok
            "com.snapchat.android",
            "com.reddit.frontpage",
            "com.whatsapp",
            "com.whatsapp.w4b",
            "org.telegram.messenger",
            "com.discord",
            "com.facebook.orca",
            "com.google.android.youtube"
        )
        return socialMediaPackages.contains(packageName)
    }
}
