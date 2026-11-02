package com.example.flutter_metro_contacts

import android.content.pm.PackageManager
import android.database.Cursor
import android.net.Uri
import android.os.Build
import android.provider.ContactsContract
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val tag = "MetrovTheme"

    private val packageCheckChannelName =
        "com.example.flutter_metro_contacts/package_check"
    private val groupsChannelName =
        "com.example.flutter_metro_contacts/groups"
    private val metrovThemeChannelName =
        "com.example.flutter_metro_contacts/metrov_theme"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

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

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, metrovThemeChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getAccentArgb" -> {
                        try {
                            queryMetrovAccent(result)
                        } catch (e: SecurityException) {
                            Log.e(tag, "Permission denied", e)
                            result.error(
                                "PERMISSION_DENIED",
                                "READ_THEME permission not granted. " +
                                        "Reinstall this app after installing MetroV.",
                                null
                            )
                        } catch (e: Exception) {
                            Log.e(tag, "Query failed", e)
                            result.error("QUERY_ERROR", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /// Queries MetroV's theme ContentProvider for the accent color.
    ///
    /// Uses column-name lookup instead of positional access — some
    /// ContentProviders ignore the projection hint and return columns
    /// in their own order, in which case `getLong(0)` would read the
    /// wrong column. Handles NULL and both INT and TEXT storage.
    private fun queryMetrovAccent(result: MethodChannel.Result) {
        val uri = Uri.parse("content://com.tuzkituan.metrov.theme/theme")

        val cursor: Cursor? = contentResolver.query(
            uri, null, null, null, null
        )

        if (cursor == null) {
            Log.w(tag, "query returned null cursor")
            result.error("NULL_CURSOR", "Provider returned no cursor", null)
            return
        }

        cursor.use { c ->
            val columns = c.columnNames.joinToString(", ")
            Log.d(tag, "Available columns: $columns")

            if (!c.moveToFirst()) {
                Log.w(tag, "cursor has no rows")
                result.error("EMPTY_CURSOR", "Provider returned no rows", null)
                return
            }

            val colIdx = c.getColumnIndex("accent_argb")
            if (colIdx < 0) {
                Log.e(tag, "column 'accent_argb' not found in: $columns")
                result.error(
                    "NO_COLUMN",
                    "accent_argb not present. Columns: $columns",
                    null
                )
                return
            }

            val type = c.getType(colIdx)
            Log.d(tag, "accent_argb column type: $type")

            if (c.isNull(colIdx)) {
                Log.w(tag, "accent_argb is NULL")
                result.error("NULL_VALUE", "accent_argb is NULL", null)
                return
            }

            val value: Long = when (type) {
                Cursor.FIELD_TYPE_INTEGER -> c.getLong(colIdx)
                Cursor.FIELD_TYPE_STRING -> {
                    val s = c.getString(colIdx) ?: ""
                    Log.d(tag, "accent_argb is TEXT: '$s'")
                    // Accept both "0xFFA20025" and "4278388197" and "#A20025".
                    val cleaned = s.removePrefix("#").removePrefix("0x")
                        .removePrefix("0X")
                    // Try hex first if it looks like hex or has no prefix.
                    val asHex = cleaned.toLongOrNull(16)
                    val asDec = cleaned.toLongOrNull(10)
                    asDec ?: asHex ?: 0L
                }
                else -> {
                    Log.w(tag, "unexpected accent_argb type $type")
                    0L
                }
            }

            Log.d(tag, "accent_argb raw=$value hex=${"%08X".format(value)}")

            if (value == 0L) {
                Log.w(tag, "accent_argb is 0 (transparent)")
                result.error("ZERO_VALUE", "accent_argb is zero", null)
                return
            }

            // Convert to Int32; Flutter's Color() expects signed ARGB.
            result.success(value.toInt())
        }
    }

    private fun queryGroups(): List<Map<String, String>> {
        val groups = mutableListOf<Map<String, String>>()
        val projection = arrayOf(
            ContactsContract.Groups._ID,
            ContactsContract.Groups.TITLE,
            ContactsContract.Groups.ACCOUNT_TYPE,
            ContactsContract.Groups.ACCOUNT_NAME
        )
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