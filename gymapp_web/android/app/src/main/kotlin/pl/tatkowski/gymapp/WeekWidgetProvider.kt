package pl.tatkowski.gymapp

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin

/**
 * Home screen widget: this week's training (dots for the days, totals, streak).
 * The app writes the texts with home_widget (HomeWidgetSync in Dart); tapping opens the app.
 */
class WeekWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        val data = HomeWidgetPlugin.getData(context)
        for (id in ids) {
            val views = RemoteViews(context.packageName, R.layout.week_widget).apply {
                setTextViewText(R.id.widget_title, data.getString("week_title", context.getString(R.string.widget_default_title)))
                setTextViewText(R.id.widget_days, data.getString("week_days", "○ ○ ○ ○ ○ ○ ○"))
                setTextViewText(R.id.widget_line, data.getString("week_line", context.getString(R.string.widget_default_line)))
                setTextViewText(R.id.widget_streak, data.getString("week_streak", ""))
                setOnClickPendingIntent(R.id.widget_root, HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java))
            }
            manager.updateAppWidget(id, views)
        }
    }
}
