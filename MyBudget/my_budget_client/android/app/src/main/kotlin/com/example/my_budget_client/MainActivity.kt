package com.example.my_budget_client

import android.app.Activity
import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.my_budget_client/file_picker"
    private val PICK_FILE_REQUEST_CODE = 123
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "pickFile") {
                val mimeType = call.argument<String>("mimeType") ?: "*/*"
                val title = call.argument<String>("title") ?: "Select File"
                val allowMultiple = call.argument<Boolean>("allowMultiple") ?: false
                pendingResult = result
                openFilePicker(mimeType, title, allowMultiple)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun openFilePicker(mimeType: String, title: String, allowMultiple: Boolean) {
        val intent = Intent(Intent.ACTION_GET_CONTENT).apply {
            type = mimeType
            addCategory(Intent.CATEGORY_OPENABLE)
            putExtra(Intent.EXTRA_ALLOW_MULTIPLE, allowMultiple)
        }
        startActivityForResult(Intent.createChooser(intent, title), PICK_FILE_REQUEST_CODE)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == PICK_FILE_REQUEST_CODE) {
            if (resultCode == Activity.RESULT_OK && data != null) {
                val paths = mutableListOf<String>()
                
                // Handle multiple files
                if (data.clipData != null) {
                    val count = data.clipData!!.itemCount
                    for (i in 0 until count) {
                        data.clipData!!.getItemAt(i).uri?.let { uri ->
                            copyFileToCache(uri)?.let { paths.add(it) }
                        }
                    }
                } else if (data.data != null) {
                    // Handle single file
                    copyFileToCache(data.data!!)?.let { paths.add(it) }
                }

                if (paths.isNotEmpty()) {
                    pendingResult?.success(paths)
                } else {
                    pendingResult?.success(null)
                }
            } else {
                pendingResult?.success(null)
            }
            pendingResult = null
        }
    }

    private fun copyFileToCache(uri: Uri): String? {
        return try {
            val inputStream = contentResolver.openInputStream(uri) ?: return null
            val fileName = getFileName(uri) ?: "temp_file_${System.currentTimeMillis()}"
            val cacheFile = File(cacheDir, fileName)
            FileOutputStream(cacheFile).use { outputStream ->
                inputStream.copyTo(outputStream)
            }
            cacheFile.absolutePath
        } catch (e: Exception) {
            e.printStackTrace()
            null
        }
    }

    private fun getFileName(uri: Uri): String? {
        var name: String? = null
        val cursor = contentResolver.query(uri, null, null, null, null)
        cursor?.use {
            if (it.moveToFirst()) {
                val nameIndex = it.getColumnIndex(android.provider.OpenableColumns.DISPLAY_NAME)
                if (nameIndex != -1) {
                    name = it.getString(nameIndex)
                }
            }
        }
        return name
    }
}
