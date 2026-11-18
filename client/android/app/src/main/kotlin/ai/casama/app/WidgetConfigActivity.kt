package ai.casama.app

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.Intent
import android.graphics.Typeface
import android.os.Bundle
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.CheckBox
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView

/**
 * The widget picker (D-405 §6.4, "Choosing"): a small native dialog, no Flutter, shown when Ask,
 * Bot or Routines is placed and again from the widget's long-press menu (reconfigurable). It reads
 * the bots and routines from the glance. A bot for Ask and Bot; for Routines, automatic or up to
 * four chosen ones. The widgets are configuration_optional, so placing one never waits on this.
 */
class WidgetConfigActivity : Activity() {
  private var widgetId = AppWidgetManager.INVALID_APPWIDGET_ID
  private val dp get() = resources.displayMetrics.density

  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    widgetId = intent?.getIntExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, AppWidgetManager.INVALID_APPWIDGET_ID)
      ?: AppWidgetManager.INVALID_APPWIDGET_ID
    // Backing out leaves the widget as it was (or, when first placed, with its defaults).
    setResult(RESULT_CANCELED, Intent().putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId))
    if (widgetId == AppWidgetManager.INVALID_APPWIDGET_ID) return finish()
    val provider = AppWidgetManager.getInstance(this).getAppWidgetInfo(widgetId)?.provider?.className
    val glance = GlanceStore.load(this).glance
    when {
      glance == null || glance.bots.isEmpty() -> showNothing()
      provider == RoutinesWidget::class.java.name -> showRoutines(glance)
      else -> showBots(glance)
    }
  }

  // MARK: Views (built in code: three short lists don't need layouts)

  private fun frame(title: String, hint: String?): LinearLayout {
    val list = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL }
    val root = LinearLayout(this).apply {
      orientation = LinearLayout.VERTICAL
      setPadding((24 * dp).toInt(), (24 * dp).toInt(), (24 * dp).toInt(), (16 * dp).toInt())
      addView(text(title, 20f, R.color.widget_fg, bold = true))
      if (hint != null) addView(text(hint, 14f, R.color.widget_fg2).apply { setPadding(0, (6 * dp).toInt(), 0, 0) })
      addView(
        ScrollView(this@WidgetConfigActivity).apply {
          setPadding(0, (12 * dp).toInt(), 0, 0)
          addView(list)
        },
        LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, 0, 1f),
      )
    }
    setContentView(root)
    return list
  }

  private fun text(value: String, sp: Float, color: Int, bold: Boolean = false) = TextView(this).apply {
    text = value
    setTextSize(TypedValue.COMPLEX_UNIT_SP, sp)
    setTextColor(getColor(color))
    if (bold) typeface = Typeface.create("sans-serif-medium", Typeface.NORMAL)
  }

  /** A tappable row: the bot's face (or nothing), two lines, and something at the end. */
  private fun row(
    parent: LinearLayout,
    title: String,
    subtitle: String?,
    mark: Pair<String, String?>?,
    end: View?,
    onTap: () -> Unit,
  ) {
    val ripple = TypedValue().also { theme.resolveAttribute(android.R.attr.selectableItemBackground, it, true) }
    val row = LinearLayout(this).apply {
      orientation = LinearLayout.HORIZONTAL
      gravity = Gravity.CENTER_VERTICAL
      minimumHeight = (56 * dp).toInt()
      setPadding((4 * dp).toInt(), (6 * dp).toInt(), (4 * dp).toInt(), (6 * dp).toInt())
      setBackgroundResource(ripple.resourceId)
      isClickable = true
      setOnClickListener { onTap() }
    }
    if (mark != null) {
      row.addView(
        ImageView(this).apply {
          setImageBitmap(BotArt.bitmap(context, mark.first.ifEmpty { "Casama" }, mark.second?.ifEmpty { null }, (36 * dp).toInt()))
          importantForAccessibility = View.IMPORTANT_FOR_ACCESSIBILITY_NO
        },
        LinearLayout.LayoutParams((36 * dp).toInt(), (36 * dp).toInt()).apply { marginEnd = (14 * dp).toInt() },
      )
    }
    val texts = LinearLayout(this).apply {
      orientation = LinearLayout.VERTICAL
      addView(text(title, 16f, R.color.widget_fg))
      if (!subtitle.isNullOrEmpty()) addView(text(subtitle, 13f, R.color.widget_fg2))
    }
    row.addView(texts, LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f))
    if (end != null) row.addView(end)
    parent.addView(row)
  }

  private fun tick(on: Boolean) = text(if (on) "✓" else "", 18f, R.color.widget_primary, bold = true)

  // MARK: The three pickers

  private fun showNothing() {
    val list = frame(getString(R.string.widget_config_signed_out_title), getString(R.string.widget_config_signed_out))
    row(list, getString(R.string.widget_config_done), null, null, null) { done() }
  }

  private fun showBots(glance: GlanceStore.Glance) {
    val chosen = WidgetConfig.botFor(this, widgetId, glance)?.id
    val list = frame(getString(R.string.widget_config_bot_title), null)
    for (bot in glance.bots) {
      row(list, bot.name, null, bot.name to bot.avatar, tick(bot.id == chosen)) {
        WidgetConfig.setBot(this, widgetId, bot.id)
        done()
      }
    }
  }

  private fun showRoutines(glance: GlanceStore.Glance) {
    val picked = WidgetConfig.routines(this, widgetId).toMutableList()
    val list = frame(getString(R.string.widget_config_routines_title), getString(R.string.widget_config_routines_hint))
    val auto = tick(picked.isEmpty())
    val boxes = mutableListOf<Pair<String, CheckBox>>()
    fun refresh() {
      auto.text = if (picked.isEmpty()) "✓" else ""
      for ((id, box) in boxes) {
        box.isChecked = id in picked
        // Four at most: the rest wait until one is unticked.
        box.isEnabled = id in picked || picked.size < 4
      }
    }
    row(list, getString(R.string.widget_config_automatic), getString(R.string.widget_config_automatic_hint), null, auto) {
      picked.clear()
      refresh()
    }
    for (r in glance.next) {
      val box = CheckBox(this).apply {
        isClickable = false
        isFocusable = false
        buttonTintList = getColorStateList(R.color.widget_primary)
      }
      boxes += r.id to box
      row(list, r.name, listOf(r.bot, r.every).filter { it.isNotEmpty() }.joinToString(" · "), r.bot to r.botAvatar, box) {
        if (r.id in picked) picked.remove(r.id) else if (picked.size < 4) picked.add(r.id)
        refresh()
      }
    }
    refresh()
    val doneButton = text(getString(R.string.widget_config_done), 15f, R.color.widget_primary, bold = true).apply {
      gravity = Gravity.END
      setPadding((12 * dp).toInt(), (16 * dp).toInt(), (12 * dp).toInt(), (4 * dp).toInt())
      setOnClickListener {
        WidgetConfig.setRoutines(this@WidgetConfigActivity, widgetId, picked)
        done()
      }
    }
    (list.parent.parent as LinearLayout).addView(doneButton)
  }

  /** Redraws the widget with the choice and hands it back to the launcher. */
  private fun done() {
    val manager = AppWidgetManager.getInstance(this)
    val name = manager.getAppWidgetInfo(widgetId)?.provider?.className?.substringAfterLast('.')
    WidgetKit.provider(name)?.let { cls ->
      runCatching { cls.getDeclaredConstructor().newInstance().draw(this, manager, widgetId, GlanceStore.load(this)) }
    }
    setResult(RESULT_OK, Intent().putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId))
    finish()
  }
}
