import AppKit
import SwiftUI
import TimeCore

private enum ClockPage { case clocks, cities, settings, help }

private typealias Palette = ClockTheme

struct ClockPopover: View {
    @ObservedObject var store: ClockStore
    @State private var page = ClockPage.clocks
    @State private var query = ""

    var body: some View {
        VStack(spacing: 0) {
            header
            Rectangle().fill(Palette.border.opacity(0.6)).frame(height: 0.5)
            Group {
                switch page {
                case .clocks: clocks
                case .cities: cityPicker
                case .settings: settings
                case .help: help
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            Rectangle().fill(Palette.border.opacity(0.6)).frame(height: 0.5)
            footer
        }
        .frame(width: 380, height: 590)
        .foregroundStyle(Palette.ink)
        .background(ClockBackdrop())
        .tint(Palette.accent)
        .preferredColorScheme(CommandLine.arguments.contains("--preview-dark") ? .dark : nil)
    }

    private var header: some View {
        HStack(spacing: 10) {
            if page != .clocks {
                iconButton("chevron.left", label: page == .help ? "返回显示设置" : "返回世界时钟") {
                    page = page == .help ? .settings : .clocks
                }
            } else {
                ClockArtwork(size: 27)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(page == .clocks ? "Time" : (page == .cities ? "添加城市" : (page == .settings ? "显示设置" : "使用帮助")))
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                if page == .clocks {
                    Text("世界时钟").font(.system(size: 10)).foregroundStyle(Palette.secondaryInk)
                }
            }
            Spacer()
            if page == .clocks {
                iconButton("plus", label: "添加城市") { query = ""; page = .cities }
                iconButton("gearshape", label: "显示设置") { store.refresh(); page = .settings }
            } else {
                ClockArtwork(size: 29)
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
    }

    private var clocks: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                primaryClock
                HStack(spacing: 6) {
                    ClockGlyph(symbol: "globe.asia.australia", color: Palette.accent, size: 19)
                    Text("世界时钟").font(.system(size: 11, weight: .semibold, design: .rounded))
                }.padding(.horizontal, 2)
                VStack(spacing: 0) {
                    ForEach(Array(store.cities.enumerated()), id: \.element.id) { index, city in
                        cityRow(city)
                        if index < store.cities.count - 1 { Divider().padding(.leading, 49).padding(.trailing, 14) }
                    }
                }
                .clockSurface()
            }
            .padding(20)
        }
    }

    private var primaryClock: some View {
        let city = store.primaryCity
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 6) {
                    Text(city.name).font(.system(size: 15, weight: .semibold))
                    Text(city.region).font(.system(size: 11)).foregroundStyle(Palette.secondaryInk)
                }
                Spacer()
                Label("菜单栏时区", systemImage: "pin.fill")
                    .font(.system(size: 10)).foregroundStyle(Palette.accent)
            }
            Text(ClockFormatter.time(at: store.now, in: city.timeZone, use24Hour: store.preferences.use24Hour,
                                     showSeconds: store.preferences.showSeconds, showAMPM: store.preferences.showAMPM))
                .font(.system(size: store.preferences.showSeconds ? 42 : 52, weight: .light, design: .rounded))
                .monospacedDigit().minimumScaleFactor(0.65).lineLimit(1)
                .accessibilityIdentifier("time.primaryTime")
            HStack {
                Text(ClockFormatter.date(at: store.now, in: city.timeZone))
                Spacer()
                Text(ClockFormatter.utcOffset(at: store.now, in: city.timeZone)).monospacedDigit()
            }
            .font(.system(size: 11)).foregroundStyle(Palette.secondaryInk)
        }
        .padding(18)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(LinearGradient(colors: [Palette.card, Palette.softCard.opacity(0.8)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
        }
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(Palette.shine.opacity(0.8), lineWidth: 1)
            .allowsHitTesting(false).accessibilityHidden(true))
        .shadow(color: Palette.accent.opacity(0.07), radius: 12, y: 4)
    }

    private func cityRow(_ city: ClockCity) -> some View {
        let isPrimary = city.id == store.preferences.primaryTimeZoneID
        let daytime = ClockFormatter.isDaytime(at: store.now, in: city.timeZone)
        let day = ClockFormatter.dayDifference(at: store.now, in: city.timeZone, comparedTo: store.primaryCity.timeZone)
        return HStack(spacing: 9) {
            Button { store.select(city) } label: {
                HStack(spacing: 11) {
                    ClockGlyph(symbol: daytime ? "sun.max.fill" : "moon.stars.fill",
                               color: daytime ? Palette.sun : Palette.accent, size: 26)
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 5) {
                            Text(city.name).font(.system(size: 12, weight: .medium))
                            if isPrimary { Image(systemName: "pin.fill").font(.system(size: 8)).foregroundStyle(Palette.accent) }
                        }
                        Text(isPrimary ? ClockFormatter.utcOffset(at: store.now, in: city.timeZone)
                             : ClockFormatter.relativeOffset(at: store.now, in: city.timeZone, comparedTo: store.primaryCity.timeZone))
                            .font(.system(size: 10)).foregroundStyle(Palette.secondaryInk)
                    }
                    Spacer(minLength: 4)
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(ClockFormatter.time(at: store.now, in: city.timeZone, use24Hour: store.preferences.use24Hour,
                                                 showAMPM: store.preferences.showAMPM))
                            .font(.system(size: 19, design: .rounded)).monospacedDigit()
                        Text(day == 0 ? "今天" : (day > 0 ? "+\(day) 天" : "\(day) 天"))
                            .font(.system(size: 9)).foregroundStyle(Palette.secondaryInk)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("在菜单栏显示\(city.name)时间")
            .accessibilityLabel("\(city.name)，设为菜单栏时区")
            Menu {
                Button("设为菜单栏时区") { store.select(city) }
                Button("移除城市", role: .destructive) { store.remove(city) }
                    .disabled(store.cities.count <= 1)
            } label: { Image(systemName: "ellipsis").frame(width: 16, height: 24) }
                .menuStyle(.borderlessButton).menuIndicator(.hidden).fixedSize()
                .accessibilityLabel("\(city.name)选项")
        }
        .padding(.horizontal, 13).padding(.vertical, 12)
    }

    private var cityPicker: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                ClockGlyph(symbol: "magnifyingglass", color: Palette.accent, size: 21)
                TextField("搜索城市、国家或时区", text: $query).textFieldStyle(.plain)
                    .accessibilityIdentifier("time.citySearch")
                if !query.isEmpty { iconButton("xmark.circle.fill", label: "清空搜索") { query = "" } }
            }
            .padding(11).clockSurface(radius: 12).padding(16)
            let matches = ClockCity.search(query)
            ScrollView {
                LazyVStack(spacing: 0) {
                    if matches.isEmpty {
                        VStack(spacing: 9) {
                            ClockGlyph(symbol: "globe", color: Palette.accent, size: 44)
                            Text("没有找到城市").font(.system(size: 13, weight: .medium))
                            Text("试试英文名称或 Asia/Shanghai 这样的时区标识")
                                .font(.system(size: 11)).foregroundStyle(Palette.secondaryInk)
                        }.padding(.vertical, 55)
                    }
                    ForEach(matches) { city in
                        let added = store.preferences.timeZoneIDs.contains(city.id)
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(city.name).font(.system(size: 12, weight: .medium))
                                Text("\(city.region) · \(city.id)").font(.system(size: 10)).foregroundStyle(Palette.secondaryInk).lineLimit(1)
                            }
                            Spacer()
                            Button { store.add(city) } label: {
                                Image(systemName: added ? "checkmark.circle.fill" : "plus.circle")
                                    .font(.system(size: 19)).foregroundStyle(added ? Palette.accent : Palette.secondaryInk)
                            }
                            .buttonStyle(.plain).disabled(added).help(added ? "已添加" : "添加\(city.name)")
                            .accessibilityLabel(added ? "\(city.name)已添加" : "添加\(city.name)")
                        }
                        .padding(.horizontal, 20).padding(.vertical, 11)
                        Divider().padding(.leading, 20)
                    }
                }
            }
        }
    }

    private var settings: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    ClockArtwork(size: 45)
                    VStack(alignment: .leading, spacing: 5) {
                        Text("菜单栏预览").font(.system(size: 10, weight: .medium)).foregroundStyle(Palette.secondaryInk)
                        Text(ClockFormatter.menuBarTitle(at: store.now, preferences: store.preferences))
                            .font(.system(size: 15, weight: .semibold, design: .rounded)).monospacedDigit()
                            .lineLimit(2).minimumScaleFactor(0.8)
                    }
                    Spacer(minLength: 0)
                    ClockSparkle().fill(Palette.accent.opacity(0.55)).frame(width: 12, height: 16)
                        .allowsHitTesting(false).accessibilityHidden(true)
                }
                .padding(13)
                .background {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(LinearGradient(colors: [Palette.card, Palette.softCard], startPoint: .topLeading, endPoint: .bottomTrailing))
                }
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Palette.shine.opacity(0.85), lineWidth: 1)
                    .allowsHitTesting(false).accessibilityHidden(true))
                .shadow(color: Palette.accent.opacity(0.065), radius: 10, y: 3)
                settingsGroup("时区") {
                    HStack(spacing: 8) {
                        ClockGlyph(symbol: "globe.asia.australia", color: Palette.accent, size: 20)
                        Text("菜单栏时区")
                        Spacer()
                        Menu {
                            ForEach(store.cities) { city in
                                Button { store.select(city) } label: {
                                    if city.id == store.preferences.primaryTimeZoneID {
                                        Label(city.name, systemImage: "checkmark")
                                    } else {
                                        Text(city.name)
                                    }
                                }
                            }
                            Divider()
                            Button("添加时区…") { query = ""; page = .cities }
                        } label: {
                            HStack(spacing: 6) {
                                Text(store.primaryCity.name).font(.system(size: 12, weight: .medium, design: .rounded))
                                    .foregroundStyle(Palette.accent).lineLimit(1)
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 8, weight: .semibold)).foregroundStyle(Palette.accent)
                            }
                            .frame(minWidth: 48, minHeight: 26, alignment: .trailing)
                        }
                        .menuStyle(.borderlessButton).menuIndicator(.hidden).fixedSize()
                        .accessibilityLabel("菜单栏时区：\(store.primaryCity.name)")
                    }
                    .frame(minHeight: 30)
                }
                settingsGroup("日期与时间") {
                    settingToggle("显示日期", symbol: "calendar", isOn: $store.preferences.showDate)
                    settingDivider
                    settingToggle("显示星期", symbol: "calendar.badge.checkmark", isOn: $store.preferences.showWeekday)
                    settingDivider
                    settingToggle("使用 24 小时制", symbol: "clock", isOn: $store.preferences.use24Hour)
                    settingDivider
                    settingToggle("显示上午 / 下午", symbol: "sun.max", isOn: $store.preferences.showAMPM)
                        .disabled(store.preferences.use24Hour)
                        .opacity(store.preferences.use24Hour ? 0.5 : 1)
                        .help("使用 12 小时制时，可显示上午或下午")
                    settingDivider
                    settingToggle("闪动时间分隔符", symbol: "sparkles", isOn: $store.preferences.blinkSeparators)
                    settingDivider
                    settingToggle("显示秒钟", symbol: "timer", isOn: $store.preferences.showSeconds)
                }
                settingsGroup("通用") {
                    settingToggle("登录时启动 Time", symbol: "power", isOn: Binding(get: { store.loginEnabled }, set: { store.setLoginEnabled($0) }))
                    if store.loginNeedsApproval {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("需要在系统设置中允许 Time 登录时启动。")
                                .font(.system(size: 10)).foregroundStyle(Palette.secondaryInk)
                            Button("打开登录项设置") { store.openLoginSettings() }.font(.system(size: 11))
                        }.padding(.vertical, 8)
                    }
                    if let error = store.loginError {
                        Text(error).font(.system(size: 10)).foregroundStyle(.red).padding(.vertical, 8)
                    }
                }
            }
            .padding(14)
        }
    }

    private var help: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 9) {
                    Label("精简原生时钟", systemImage: "clock").font(.system(size: 12, weight: .medium))
                    Text("macOS 会保留原生时钟。在系统设置的“菜单栏”（旧版本为“控制中心”）中打开“时钟选项”，关闭日期和星期，并选择指针样式，即可减少重复显示。")
                        .font(.system(size: 11)).foregroundStyle(Palette.secondaryInk).lineSpacing(4)
                    Button("打开时钟设置…") { store.openClockSettings() }.font(.system(size: 11))
                }
                Divider()
                VStack(alignment: .leading, spacing: 8) {
                    Label("调整菜单栏位置", systemImage: "cursorarrow.motionlines")
                        .font(.system(size: 12, weight: .medium))
                    Text("按住 ⌘ 拖动菜单栏中的时间文字，可移到系统允许的最右位置。原生时钟所在区域由 macOS 保留。")
                        .font(.system(size: 11)).foregroundStyle(Palette.secondaryInk).lineSpacing(4)
                }
                Divider()
                VStack(alignment: .leading, spacing: 8) {
                    Label("时间显示", systemImage: "textformat")
                        .font(.system(size: 12, weight: .medium))
                    Text("关闭 24 小时制后，可选择显示上午 / 下午。所有日期和时间均按所选时区显示，不改变系统时区。")
                        .font(.system(size: 11)).foregroundStyle(Palette.secondaryInk).lineSpacing(4)
                }
                Text("Time · 设置仅保存在这台 Mac 上")
                    .font(.system(size: 10)).foregroundStyle(Palette.mutedInk)
            }
            .padding(20)
        }
    }

    private var footer: some View {
        HStack {
            if page == .settings {
                Button { page = .help } label: {
                    HStack(spacing: 6) {
                        ClockGlyph(symbol: "questionmark", color: Palette.accent, size: 19)
                        Text("使用帮助")
                    }
                }
                .buttonStyle(.plain).foregroundStyle(Palette.secondaryInk)
            }
            Spacer()
            Button("退出 Time") { NSApp.terminate(nil) }.buttonStyle(.plain).foregroundStyle(Palette.secondaryInk)
        }
        .font(.system(size: 11)).padding(.horizontal, 16).padding(.vertical, 10)
        .background(Palette.card.opacity(0.25))
    }

    private func iconButton(_ symbol: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) { ClockGlyph(symbol: symbol, size: 27) }
            .buttonStyle(.plain).help(label).accessibilityLabel(label)
    }

    private func sectionLabel(_ title: String) -> some View {
        HStack(spacing: 5) {
            ClockSparkle().fill(Palette.accent.opacity(0.7)).frame(width: 7, height: 9)
                .allowsHitTesting(false).accessibilityHidden(true)
            Text(title).font(.system(size: 10, weight: .semibold, design: .rounded)).foregroundStyle(Palette.secondaryInk)
        }.padding(.leading, 3)
    }

    private func settingsGroup<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionLabel(title)
            VStack(alignment: .leading, spacing: 0, content: content)
                .font(.system(size: 12)).padding(.horizontal, 11).padding(.vertical, 4)
                .clockSurface(radius: 13)
        }
    }

    private var settingDivider: some View { Rectangle().fill(Palette.border.opacity(0.55)).frame(height: 0.5).padding(.leading, 28) }

    private func settingToggle(_ title: String, symbol: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 8) {
            ClockGlyph(symbol: symbol, size: 20)
            Text(title)
            Spacer(minLength: 12)
            Toggle(title, isOn: isOn).labelsHidden().toggleStyle(SwitchToggleStyle(tint: Palette.accent)).controlSize(.small)
        }
        .frame(minHeight: 30)
    }
}
