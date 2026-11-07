// RF-51: widget «Tareas de hoy» para iOS (WidgetKit).
//
// Lee los datos que escribe la app con home_widget en el App Group
// `group.com.chenj.todoCalendar`. En iOS 17+ el check completa la tarea con
// un App Intent que ejecuta el callback de Dart en segundo plano; en
// versiones anteriores el widget es solo lectura (tocar abre la app).
//
// Para activarlo hay que crear el target «TodayWidget» en Xcode (ver README).

import AppIntents
import SwiftUI
import WidgetKit
import home_widget

private let appGroup = "group.com.chenj.todoCalendar"

struct TaskRow: Identifiable {
  let id: Int
  let time: String
  let title: String
  let done: Bool
  let payload: String
}

struct TodayEntry: TimelineEntry {
  let date: Date
  let header: String
  let progress: String
  let empty: String
  let more: String
  let rows: [TaskRow]
}

struct TodayProvider: TimelineProvider {
  func placeholder(in context: Context) -> TodayEntry {
    TodayEntry(date: .now, header: "Hoy", progress: "", empty: "", more: "", rows: [
      TaskRow(id: 0, time: "09:00", title: "…", done: false, payload: ""),
    ])
  }

  func getSnapshot(in context: Context, completion: @escaping (TodayEntry) -> Void) {
    completion(load())
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<TodayEntry>) -> Void) {
    // La app pide recargar al cambiar datos; además se refresca cada 30 min.
    completion(Timeline(entries: [load()], policy: .after(.now.addingTimeInterval(1800))))
  }

  private func load() -> TodayEntry {
    let d = UserDefaults(suiteName: appGroup)
    let count = d?.integer(forKey: "count") ?? 0
    var rows: [TaskRow] = []
    for i in 0..<count {
      rows.append(TaskRow(
        id: i,
        time: d?.string(forKey: "row\(i)_time") ?? "",
        title: d?.string(forKey: "row\(i)_title") ?? "",
        done: d?.bool(forKey: "row\(i)_done") ?? false,
        payload: d?.string(forKey: "row\(i)_payload") ?? ""
      ))
    }
    return TodayEntry(
      date: .now,
      header: d?.string(forKey: "header") ?? "Hoy",
      progress: d?.string(forKey: "progress") ?? "",
      empty: d?.string(forKey: "empty") ?? "",
      more: d?.string(forKey: "more") ?? "",
      rows: rows
    )
  }
}

@available(iOS 17.0, *)
struct ToggleTaskIntent: AppIntent {
  static var title: LocalizedStringResource = "Completar tarea"
  @Parameter(title: "Tarea") var payload: String

  init() {}
  init(payload: String) { self.payload = payload }

  func perform() async throws -> some IntentResult {
    var components = URLComponents(string: "todocal://toggle")!
    components.queryItems = [URLQueryItem(name: "p", value: payload)]
    await HomeWidgetBackgroundWorker.run(url: components.url, appGroup: appGroup)
    return .result()
  }
}

struct TodayWidgetView: View {
  let entry: TodayEntry

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      HStack {
        Text(entry.header).font(.headline).lineLimit(1)
        Spacer()
        Text(entry.progress).font(.caption).foregroundStyle(.secondary)
      }
      if entry.rows.isEmpty {
        Text(entry.empty).font(.subheadline).foregroundStyle(.secondary)
      }
      ForEach(entry.rows) { row in
        HStack(spacing: 6) {
          check(row)
          Text(row.time).font(.caption).foregroundStyle(.secondary).frame(minWidth: 40, alignment: .leading)
          Link(destination: URL(string: "todocal://open?p=\(row.payload.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")")!) {
            Text(row.title).font(.subheadline).lineLimit(1).strikethrough(row.done)
          }
        }
      }
      if !entry.more.isEmpty {
        Text(entry.more).font(.caption2).foregroundStyle(.secondary)
      }
      Spacer(minLength: 0)
    }
    .widgetBackground()
  }

  @ViewBuilder
  private func check(_ row: TaskRow) -> some View {
    let icon = Image(systemName: row.done ? "checkmark.circle.fill" : "circle")
    if #available(iOS 17.0, *) {
      Button(intent: ToggleTaskIntent(payload: row.payload)) { icon }.buttonStyle(.plain)
    } else {
      icon
    }
  }
}

extension View {
  @ViewBuilder
  func widgetBackground() -> some View {
    if #available(iOS 17.0, *) {
      containerBackground(.fill.tertiary, for: .widget)
    } else {
      padding()
    }
  }
}

@main
struct TodayWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "TodayWidget", provider: TodayProvider()) { entry in
      TodayWidgetView(entry: entry)
    }
    .configurationDisplayName("Tareas de hoy")
    .description("Tus tareas de hoy, con check para completarlas.")
    .supportedFamilies([.systemMedium, .systemLarge])
  }
}
