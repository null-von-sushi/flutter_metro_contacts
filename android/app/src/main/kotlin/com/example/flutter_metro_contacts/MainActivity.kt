package com.example.flutter_metro_contacts

import android.content.pm.PackageManager
import android.os.Build
import android.provider.ContactsContract
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val packageCheckChannelName =
        "com.example.flutter_metro_contacts/package_check"
    private val groupsChannelName =
        "com.example.flutter_metro_contacts/groups"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // ── Existing package check channel ──────────────────────────
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, packageCheckChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isPackageInstalled" -> {
                        val packageName = call.argument<String>("packageName")
                        if (packageName.isNullOrEmpty()) {
                            result.error("INVALID_ARGUMENT", "packageName is required", null)
                            return@setMethodCallHandler
                        }
                        val installed = try {
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                                packageManager.getPackageInfo(
                                    packageName,
                                    PackageManager.PackageInfoFlags.of(0)
                                )
                            } else {
                                @Suppress("DEPRECATION")
                                packageManager.getPackageInfo(packageName, 0)
                            }
                            true
                        } catch (e: PackageManager.NameNotFoundException) {
                            false
                        }
                        result.success(installed)
                    }
                    else -> result.notImplemented()
                }
            }

        // ── New groups channel ──────────────────────────────────────
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, groupsChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getGroups" -> {
                        try {
                            result.success(queryGroups())
                        } catch (e: Exception) {
                            result.error("GROUPS_ERROR", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /// Queries ContactsContract.Groups directly. Returns a list of maps
    /// with the keys "id", "title", "accountType", "accountName".
    /// This bypasses flutter_contacts entirely because its groups API
    /// returns an empty list on some devices/accounts.
    private fun queryGroups(): List<Map<String, String>> {
        val groups = mutableListOf<Map<String, String>>()
        val projection = arrayOf(
            ContactsContract.Groups._ID,
            ContactsContract.Groups.TITLE,
            ContactsContract.Groups.ACCOUNT_TYPE,
            ContactsContract.Groups.ACCOUNT_NAME
        )
        // Exclude rows that have been deleted but not yet purged.
        val selection = "${ContactsContract.Groups.DELETED} = 0"

        contentResolver.query(
            ContactsContract.Groups.CONTENT_URI,
            projection,
            selection,
            null,
            "${ContactsContract.Groups.TITLE} ASC"
        )?.use { cursor ->
            val idIdx = cursor.getColumnIndex(ContactsContract.Groups._ID)
            val titleIdx = cursor.getColumnIndex(ContactsContract.Groups.TITLE)
            val typeIdx = cursor.getColumnIndex(ContactsContract.Groups.ACCOUNT_TYPE)
            val nameIdx = cursor.getColumnIndex(ContactsContract.Groups.ACCOUNT_NAME)

            while (cursor.moveToNext()) {
                val id = if (idIdx >= 0) cursor.getString(idIdx) else null
                val title = if (titleIdx >= 0) cursor.getString(titleIdx) else null
                val type = if (typeIdx >= 0) cursor.getString(typeIdx) else null
                val name = if (nameIdx >= 0) cursor.getString(nameIdx) else null
                if (id != null && title != null) {
                    groups.add(mapOf(
                        "id" to id,
                        "title" to title,
                        "accountType" to (type ?: ""),
                        "accountName" to (name ?: "")
                    ))
                }
            }
        }
        return groups
    }
}