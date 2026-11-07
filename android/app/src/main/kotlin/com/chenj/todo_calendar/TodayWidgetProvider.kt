package com.chenj.todo_calendar

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Paint
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * RF-51: widget «Tareas de hoy». Los datos los escribe la app (Dart) con
 * home_widget; el check completa la tarea sin abrir la app mediante un
 * callback de Dart en segundo plano.
 */
class TodayWidgetProvider : HomeWidgetProvider() {

    private data class Row(val row: Int, val check: Int, val time: Int, val title: Int)

    private val rows = listOf(
        Row(R.id.row0, R.id.check0, R.id.time0, R.id.title0),
        Row(R.id.row1, R.id.check1, R.id.time1, R.id.title1),
        Row(R.id.row2, R.id.check2, R.id.time2, R.id.title2),
        Row(R.id.row3, R.id.check3, R.id.time3, R.id.title3),
        Row(R.id.row4, R.id.check4, R.id.time4, R.id.title4),
        Row(R.id.row5, R.id.check5, R.id.time5, R.id.title5),
    )

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        for (id in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_today)
            views.setTextViewText(R.id.header, widgetData.getString("header", "Hoy"))
            views.setTextViewText(R.id.progress, widgetData.getString("progress", ""))
            views.setOnClickPendingIntent(
                R.id.header,
                HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, Uri.parse("todocal://open")),
            )

            val count = widgetData.getInt("count", 0)
            views.setViewVisibility(R.id.empty, if (count == 0) View.VISIBLE else View.GONE)
            views.setTextViewText(R.id.empty, widgetData.getString("empty", ""))
            val more = widgetData.getString("more", "") ?: ""
            views.setTextViewText(R.id.more, more)
            views.setViewVisibility(R.id.more, if (more.isEmpty()) View.GONE else View.VISIBLE)

            rows.forEachIndexed { i, r ->
                if (i >= count) {
                    views.setViewVisibility(r.row, View.GONE)
                    return@forEachIndexed
                }
                views.setViewVisibility(r.row, View.VISIBLE)
                val done = widgetData.getBoolean("row${i}_done", false)
                val payload = Uri.encode(widgetData.getString("row${i}_payload", "") ?: "")
                views.setTextViewText(r.time, widgetData.getString("row${i}_time", ""))
                views.setTextViewText(r.title, widgetData.getString("row${i}_title", ""))
                views.setInt(
                    r.title, "setPaintFlags",
                    if (done) Paint.STRIKE_THRU_TEXT_FLAG or Paint.ANTI_ALIAS_FLAG else Paint.ANTI_ALIAS_FLAG,
                )
                views.setImageViewResource(r.check, if (done) R.drawable.ic_check_on else R.drawable.ic_check_off)
                views.setOnClickPendingIntent(
                    r.check,
                    HomeWidgetBackgroundIntent.getBroadcast(context, Uri.parse("todocal://toggle?p=$payload")),
                )
                views.setOnClickPendingIntent(
                    r.title,
                    HomeWidgetLaunchIntent.getActivity(
                        context, MainActivity::class.java, Uri.parse("todocal://open?p=$payload"),
                    ),
                )
            }
            appWidgetManager.updateAppWidget(id, views)
        }
    }
}
