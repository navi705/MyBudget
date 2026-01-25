package com.mybudget.app

import android.app.Activity
import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel
import android.util.Log
import android.content.BroadcastReceiver
import android.content.Context
import android.content.IntentFilter
import android.provider.Telephony
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.my_budget_client/file_picker"
    private val PICK_FILE_REQUEST_CODE = 123
    private var pendingResult: MethodChannel.Result? = null
    private val SMS_CHANNEL = "com.example.my_budget_client/sms_events"
    private var smsEventSink: EventChannel.EventSink? = null

    private val smsReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action == Telephony.Sms.Intents.SMS_RECEIVED_ACTION) {
                Log.d("SMS_DEBUG", "Native: onReceive triggered")
                val messages = Telephony.Sms.Intents.getMessagesFromIntent(intent)
                for (sms in messages) {
                    Log.d("SMS_DEBUG", "Native: Sending message from ${sms.originatingAddress}")
                    val msgMap = mapOf(
                        "sender" to sms.originatingAddress,
                        "body" to sms.messageBody,
                        "date" to sms.timestampMillis
                    )
                    smsEventSink?.success(msgMap)
                }
            }
        }
    }

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

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, SMS_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    Log.d("SMS_DEBUG", "Native: onListen called")
                    smsEventSink = events
                    registerReceiver(smsReceiver, IntentFilter(Telephony.Sms.Intents.SMS_RECEIVED_ACTION))
                }

                override fun onCancel(arguments: Any?) {
                    smsEventSink = null
                    unregisterReceiver(smsReceiver)
                }
            }
        )
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
