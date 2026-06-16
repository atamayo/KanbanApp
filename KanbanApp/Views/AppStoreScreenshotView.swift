import SwiftData
import SwiftUI

enum AppStoreScreenshotScene: String, CaseIterable {
    case dashboard
    case board
    case quickCapture
    case focusGuard
    case flowReview
    case search
    case wipChat

    static func fromLaunchArguments(_ arguments: [String] = CommandLine.arguments) -> AppStoreScreenshotScene? {
        guard let argument = arguments.first(where: { $0.hasPrefix("--app-store-screenshot=") }) else {
            return nil
        }

        let sceneName = argument.replacingOccurrences(of: "--app-store-screenshot=", with: "")
        return AppStoreScreenshotScene(rawValue: sceneName)
    }

    var caption: String {
        let language = AppStoreScreenshotLanguage.current

        switch self {
        case .dashboard:
            return language.text(
                en: "Know what to finish next",
                ca: "Saps què acabar després",
                es: "Sabe qué terminar después",
                de: "Wisse, was als Nächstes dran ist",
                ja: "次に終えるべき作業がわかる",
                hi: "जानें आगे क्या पूरा करना है",
                pt: "Saiba o que finalizar agora",
                ko: "다음에 끝낼 일을 파악하세요",
                fr: "Sachez quoi terminer ensuite",
                it: "Sai cosa finire dopo",
                nl: "Weet wat je nu afrondt",
                pl: "Wiedz, co skończyć dalej",
                zh: "知道下一步该完成什么"
            )
        case .board:
            return language.text(
                en: "See every task in motion",
                ca: "Veu cada tasca en moviment",
                es: "Ve cada tarea en movimiento",
                de: "Sieh jede Aufgabe im Fluss",
                ja: "すべてのタスクの流れを見る",
                hi: "हर काम की प्रगति देखें",
                pt: "Veja cada tarefa em movimento",
                ko: "모든 작업 흐름을 확인하세요",
                fr: "Voyez chaque tâche avancer",
                it: "Vedi ogni attività in movimento",
                nl: "Zie elke taak in beweging",
                pl: "Zobacz każdy ruch zadania",
                zh: "查看每个任务的流转"
            )
        case .quickCapture:
            return language.text(
                en: "Turn rough notes into clear tasks",
                ca: "Converteix notes en tasques clares",
                es: "Convierte notas en tareas claras",
                de: "Mach aus Notizen klare Aufgaben",
                ja: "ラフなメモを明確なタスクに",
                hi: "रफ़ नोट्स को साफ़ कार्य बनाएं",
                pt: "Transforme notas em tarefas claras",
                ko: "메모를 명확한 작업으로 바꾸세요",
                fr: "Transformez vos notes en tâches",
                it: "Trasforma note in attività chiare",
                nl: "Maak van notities heldere taken",
                pl: "Zamień notatki w jasne zadania",
                zh: "将零散笔记变成清晰任务"
            )
        case .focusGuard:
            return language.text(
                en: "Avoid taking on too much",
                ca: "Evita assumir massa feina",
                es: "Evita asumir demasiado",
                de: "Übernimm nicht zu viel",
                ja: "抱えすぎを防ぐ",
                hi: "बहुत ज़्यादा काम लेने से बचें",
                pt: "Evite assumir tarefas demais",
                ko: "너무 많은 일을 막으세요",
                fr: "Évitez d’en prendre trop",
                it: "Evita di prendere troppo",
                nl: "Neem niet te veel op je",
                pl: "Nie bierz na siebie za dużo",
                zh: "避免承担过多工作"
            )
        case .flowReview:
            return language.text(
                en: "Spot blocked and aging work",
                ca: "Detecta bloquejos i endarreriments",
                es: "Detecta bloqueos y retrasos",
                de: "Erkenne Blockaden und alte Arbeit",
                ja: "停滞や長引く作業を見つける",
                hi: "रुके और पुराने काम पहचानें",
                pt: "Encontre bloqueios e atrasos",
                ko: "막힌 일과 오래된 일을 찾으세요",
                fr: "Repérez blocages et retards",
                it: "Trova blocchi e attività ferme",
                nl: "Zie blokkades en oud werk",
                pl: "Wykryj blokady i zaległości",
                zh: "发现受阻和拖延的工作"
            )
        case .search:
            return language.text(
                en: "Find anything fast",
                ca: "Troba-ho tot ràpid",
                es: "Encuentra todo rápido",
                de: "Finde alles schnell",
                ja: "すばやく見つける",
                hi: "सब कुछ तेज़ी से खोजें",
                pt: "Encontre tudo rápido",
                ko: "무엇이든 빠르게 찾으세요",
                fr: "Trouvez tout rapidement",
                it: "Trova tutto in fretta",
                nl: "Vind alles snel",
                pl: "Znajdź wszystko szybko",
                zh: "快速找到任何内容"
            )
        case .wipChat:
            return language.text(
                en: "Ask WIP Coach what to do next",
                ca: "Pregunta al Coach WIP què fer després",
                es: "Pregunta al Coach WIP qué hacer después",
                de: "Frag den WIP-Coach, was als Nächstes dran ist",
                ja: "WIP コーチに次の一手を聞く",
                hi: "WIP Coach से पूछें आगे क्या करें",
                pt: "Pergunte ao Coach WIP o que fazer agora",
                ko: "WIP 코치에게 다음 할 일을 물어보세요",
                fr: "Demandez au coach WIP quoi faire ensuite",
                it: "Chiedi al coach WIP cosa fare dopo",
                nl: "Vraag WIP-coach wat je nu doet",
                pl: "Zapytaj Trenera WIP, co dalej",
                zh: "询问 WIP 教练下一步做什么"
            )
        }
    }

    var supportingLine: String {
        let language = AppStoreScreenshotLanguage.current

        switch self {
        case .dashboard:
            return language.text(
                en: "A personal kanban coach for focused solo work.",
                ca: "Un coach kanban personal per treballar amb focus.",
                es: "Un coach kanban personal para trabajar con foco.",
                de: "Dein persönlicher Kanban-Coach für fokussierte Soloarbeit.",
                ja: "集中して進める個人作業のためのKanbanコーチ。",
                hi: "फोकस वाले व्यक्तिगत काम के लिए आपका Kanban कोच।",
                pt: "Um coach kanban pessoal para trabalho solo com foco.",
                ko: "집중하는 1인 작업을 위한 개인 칸반 코치.",
                fr: "Un coach kanban personnel pour travailler concentré.",
                it: "Un coach kanban personale per lavorare con focus.",
                nl: "Een persoonlijke kanban-coach voor gefocust solowerk.",
                pl: "Osobisty trener kanban do skupionej pracy solo.",
                zh: "专为个人专注工作打造的看板教练。"
            )
        case .board:
            return language.text(
                en: "Prioritize, pull, and close work without losing context.",
                ca: "Prioritza, agafa i tanca feina sense perdre context.",
                es: "Prioriza, empieza y termina sin perder contexto.",
                de: "Priorisieren, ziehen und abschließen, ohne Kontext zu verlieren.",
                ja: "文脈を失わずに、優先し、着手し、完了する。",
                hi: "संदर्भ खोए बिना प्राथमिकता दें, शुरू करें और पूरा करें।",
                pt: "Priorize, puxe e conclua sem perder contexto.",
                ko: "맥락을 잃지 않고 우선순위를 정하고 완료하세요.",
                fr: "Priorisez, lancez et terminez sans perdre le contexte.",
                it: "Dai priorità, avvia e chiudi senza perdere contesto.",
                nl: "Prioriteer, pak op en rond af zonder contextverlies.",
                pl: "Ustalaj priorytety, bierz i kończ bez utraty kontekstu.",
                zh: "不丢失上下文地排序、拉取并完成工作。"
            )
        case .quickCapture:
            return language.text(
                en: "Capture ideas from notes, photos, scans, or voice.",
                ca: "Captura idees de notes, fotos, escanejos o veu.",
                es: "Captura ideas desde notas, fotos, escaneos o voz.",
                de: "Erfasse Ideen aus Notizen, Fotos, Scans oder Sprache.",
                ja: "メモ、写真、スキャン、音声からアイデアを取り込む。",
                hi: "नोट्स, फ़ोटो, स्कैन या आवाज़ से विचार कैप्चर करें।",
                pt: "Capture ideias de notas, fotos, scans ou voz.",
                ko: "메모, 사진, 스캔, 음성에서 아이디어를 캡처하세요.",
                fr: "Capturez idées, photos, scans ou dictées.",
                it: "Cattura idee da note, foto, scansioni o voce.",
                nl: "Leg ideeën vast uit notities, foto’s, scans of stem.",
                pl: "Chwytaj pomysły z notatek, zdjęć, skanów lub głosu.",
                zh: "从笔记、照片、扫描或语音中捕捉想法。"
            )
        case .focusGuard:
            return language.text(
                en: "WIP limits protect your attention before overload wins.",
                ca: "Els límits WIP protegeixen l'atenció abans de la sobrecàrrega.",
                es: "Los límites WIP protegen tu atención antes de saturarte.",
                de: "WIP-Limits schützen deinen Fokus vor Überlastung.",
                ja: "WIP制限で、抱えすぎる前に集中を守る。",
                hi: "WIP सीमाएँ ओवरलोड से पहले आपका ध्यान बचाती हैं।",
                pt: "Limites de WIP protegem seu foco antes da sobrecarga.",
                ko: "WIP 제한이 과부하 전에 집중을 지켜줍니다.",
                fr: "Les limites WIP protègent votre attention avant la surcharge.",
                it: "I limiti WIP proteggono l’attenzione dal sovraccarico.",
                nl: "WIP-limieten beschermen je aandacht vóór overbelasting.",
                pl: "Limity WIP chronią uwagę przed przeciążeniem.",
                zh: "WIP 限制在过载前保护你的注意力。"
            )
        case .flowReview:
            return language.text(
                en: "See the work that needs a decision before it drifts.",
                ca: "Veu la feina que necessita decisió abans que s'encalli.",
                es: "Ve qué trabajo necesita una decisión antes de atascarse.",
                de: "Sieh Arbeit, die eine Entscheidung braucht, bevor sie driftet.",
                ja: "滞る前に、判断が必要な作業を見つける。",
                hi: "भटकने से पहले देखें किस काम पर निर्णय चाहिए।",
                pt: "Veja o que precisa de decisão antes de travar.",
                ko: "흐름이 막히기 전 결정이 필요한 일을 보세요.",
                fr: "Voyez le travail à décider avant qu’il ne dérive.",
                it: "Vedi cosa richiede una decisione prima che si fermi.",
                nl: "Zie welk werk een beslissing nodig heeft voordat het blijft liggen.",
                pl: "Zobacz pracę, która wymaga decyzji, zanim utknie.",
                zh: "在工作停滞前，看清哪些需要决策。"
            )
        case .search:
            return language.text(
                en: "Search titles, context, and definitions of done.",
                ca: "Cerca títols, context i definicions de fet.",
                es: "Busca títulos, contexto y criterios de terminado.",
                de: "Durchsuche Titel, Kontext und Definitionen von fertig.",
                ja: "タイトル、文脈、完了条件を検索。",
                hi: "शीर्षक, संदर्भ और पूर्णता मानदंड खोजें।",
                pt: "Busque títulos, contexto e definições de pronto.",
                ko: "제목, 맥락, 완료 기준을 검색하세요.",
                fr: "Cherchez titres, contexte et critères de terminé.",
                it: "Cerca titoli, contesto e definizioni di completato.",
                nl: "Zoek titels, context en definities van klaar.",
                pl: "Szukaj tytułów, kontekstu i definicji ukończenia.",
                zh: "搜索标题、上下文和完成标准。"
            )
        case .wipChat:
            return language.text(
                en: "Chat about what to finish, pull, or unblock before your flow drifts.",
                ca: "Xateja sobre què acabar, agafar o desbloquejar abans que el flux es desviï.",
                es: "Chatea sobre qué terminar, tomar o desbloquear antes de que el flujo se desvíe.",
                de: "Chatte darüber, was du abschließen, ziehen oder entblocken solltest, bevor dein Flow driftet.",
                ja: "流れが乱れる前に、何を終え、引き込み、解除するかをチャットで確認。",
                hi: "फ़्लो भटकने से पहले क्या पूरा, खींचना या अनब्लॉक करना है, उस पर चैट करें।",
                pt: "Converse sobre o que finalizar, puxar ou desbloquear antes que o fluxo se desvie.",
                ko: "흐름이 흔들리기 전에 무엇을 끝내고, 가져오고, 막힘을 풀지 대화하세요.",
                fr: "Discutez de ce qu’il faut finir, prendre ou débloquer avant que le flux dérive.",
                it: "Chatta su cosa finire, prendere o sbloccare prima che il flusso deragli.",
                nl: "Chat over wat je afrondt, oppakt of deblokkeert voordat je flow afdrijft.",
                pl: "Porozmawiaj o tym, co skończyć, wziąć lub odblokować, zanim przepływ się rozjedzie.",
                zh: "在流程漂移前，聊聊该完成、拉入或解除阻塞的工作。"
            )
        }
    }

    var accent: Color {
        switch self {
        case .dashboard, .board, .quickCapture, .search, .wipChat:
            return AppStyle.Colors.Status.todo
        case .focusGuard:
            return AppStyle.Colors.warning
        case .flowReview:
            return AppStyle.Colors.blocked
        }
    }
}

private enum AppStoreScreenshotLanguage: String {
    case en
    case ca
    case es
    case de
    case ja
    case hi
    case pt
    case ko
    case fr
    case it
    case nl
    case pl
    case zh

    var locale: Locale {
        Locale(identifier: localeIdentifier)
    }

    var localeIdentifier: String {
        switch self {
        case .en: return "en"
        case .ca: return "ca"
        case .es: return "es_ES"
        case .de: return "de"
        case .ja: return "ja"
        case .hi: return "hi"
        case .pt: return "pt_BR"
        case .ko: return "ko"
        case .fr: return "fr_FR"
        case .it: return "it"
        case .nl: return "nl"
        case .pl: return "pl"
        case .zh: return "zh_Hans"
        }
    }

    static var current: AppStoreScreenshotLanguage {
        let explicitLanguage = CommandLine.arguments
            .first(where: { $0.hasPrefix("--app-store-language=") })?
            .replacingOccurrences(of: "--app-store-language=", with: "")

        let preferredLanguage = explicitLanguage ?? Locale.preferredLanguages.first ?? "en"

        if preferredLanguage.hasPrefix("ca") { return .ca }
        if preferredLanguage.hasPrefix("es") { return .es }
        if preferredLanguage.hasPrefix("de") { return .de }
        if preferredLanguage.hasPrefix("ja") { return .ja }
        if preferredLanguage.hasPrefix("hi") { return .hi }
        if preferredLanguage.hasPrefix("pt") { return .pt }
        if preferredLanguage.hasPrefix("ko") { return .ko }
        if preferredLanguage.hasPrefix("fr") { return .fr }
        if preferredLanguage.hasPrefix("it") { return .it }
        if preferredLanguage.hasPrefix("nl") { return .nl }
        if preferredLanguage.hasPrefix("pl") { return .pl }
        if preferredLanguage.hasPrefix("zh") { return .zh }
        return .en
    }

    func text(en: String, ca: String, es: String, de: String, ja: String, hi: String, pt: String, ko: String, fr: String, it: String, nl: String, pl: String, zh: String) -> String {
        switch self {
        case .en: return en
        case .ca: return ca
        case .es: return es
        case .de: return de
        case .ja: return ja
        case .hi: return hi
        case .pt: return pt
        case .ko: return ko
        case .fr: return fr
        case .it: return it
        case .nl: return nl
        case .pl: return pl
        case .zh: return zh
        }
    }
}

enum AppStoreScreenshotFixtures {
    @MainActor
    static func makeContainer() -> PersistenceBootstrapResult {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: TaskItem.self, configurations: configuration)

        seed(container.mainContext)

        return PersistenceBootstrapResult(
            container: container,
            syncMode: .localFallback
        )
    }

    @MainActor
    private static func seed(_ context: ModelContext) {
        let now = Date()

        let fixtures: [FixtureTask] = [
            FixtureTask(
                title: "Draft client proposal",
                description: "Turn the discovery notes into a clear scope, timeline, and pricing section.",
                completionCriteria: "Proposal PDF is ready to send.",
                status: .todo,
                priority: .high,
                ageDays: 5,
                order: 0
            ),
            FixtureTask(
                title: "Prepare Q2 tax checklist",
                description: "Collect receipts, contractor invoices, and quarterly revenue exports.",
                completionCriteria: "Checklist reviewed with accountant.",
                status: .todo,
                priority: .high,
                ageDays: 4,
                order: 1
            ),
            FixtureTask(
                title: "Outline launch email",
                description: "Write the first pass for the product update announcement.",
                completionCriteria: "Draft has subject line and CTA.",
                status: .todo,
                priority: .medium,
                ageDays: 2,
                order: 2
            ),
            FixtureTask(
                title: "Review invoice follow-ups",
                description: "Check open retainers and decide which reminders need to go out today.",
                completionCriteria: "All overdue invoices have next actions.",
                status: .todo,
                priority: .medium,
                ageDays: 1,
                order: 3
            ),
            FixtureTask(
                title: "Plan Friday workout",
                description: "Keep the routine simple around the launch deadline.",
                completionCriteria: "Workout block added to calendar.",
                status: .todo,
                priority: .low,
                ageDays: 1,
                order: 4
            ),
            FixtureTask(
                title: "Finish pricing page copy",
                description: "Tighten the offer, remove vague claims, and make the solo plan easier to compare.",
                completionCriteria: "Pricing page is ready for final review.",
                status: .inProgress,
                priority: .high,
                ageDays: 4,
                order: 0
            ),
            FixtureTask(
                title: "Book onboarding calls",
                description: "Waiting on two client replies before confirming times.",
                completionCriteria: "All calls are scheduled.",
                status: .inProgress,
                priority: .medium,
                isBlocked: true,
                ageDays: 2,
                order: 1
            ),
            FixtureTask(
                title: "Reconcile contractor invoices",
                description: "Match invoice line items against project milestones before payment.",
                completionCriteria: "Approved totals are ready for transfer.",
                status: .inProgress,
                priority: .medium,
                ageDays: 6,
                order: 2
            ),
            FixtureTask(
                title: "Send May retainer invoice",
                description: "Include the approved strategy sprint line item.",
                completionCriteria: "Invoice is sent and logged.",
                status: .done,
                priority: .high,
                ageDays: 1,
                order: 0
            ),
            FixtureTask(
                title: "Publish case study draft",
                description: "Share the cleaned-up story with the client for approval.",
                completionCriteria: "Draft is published for review.",
                status: .done,
                priority: .medium,
                ageDays: 3,
                order: 1
            ),
            FixtureTask(
                title: "Clean up launch notes",
                description: "Archive the old checklist and keep only active follow-ups.",
                completionCriteria: "Notes are ready for the next planning session.",
                status: .done,
                priority: .low,
                ageDays: 5,
                order: 2
            )
        ]

        for fixture in fixtures {
            let task = TaskItem(
                title: fixture.title,
                description: fixture.description,
                completionCriteria: fixture.completionCriteria,
                status: fixture.status,
                priority: fixture.priority,
                isBlocked: fixture.isBlocked,
                order: fixture.order
            )

            let referenceDate = Calendar.current.date(byAdding: .day, value: -fixture.ageDays, to: now) ?? now
            task.createdAt = referenceDate
            task.updatedAt = fixture.status == .done ? referenceDate : now
            task.lastStatusChange = referenceDate

            if fixture.status == .inProgress {
                task.enteredInProgressAt = referenceDate
            }

            if fixture.status == .done {
                task.finalizedAt = referenceDate
            }

            context.insert(task)
        }

        try? context.save()
    }

    private struct FixtureTask {
        let title: String
        let description: String
        let completionCriteria: String
        let status: TaskStatus
        let priority: TaskPriority
        var isBlocked = false
        let ageDays: Int
        let order: Int
    }
}

struct AppStoreScreenshotView: View {
    let scene: AppStoreScreenshotScene

    @Query(sort: \TaskItem.order) private var allTasks: [TaskItem]
    @State private var selectedSegment: TaskStatus = .todo
    @State private var searchText = "invoice"

    var body: some View {
        GeometryReader { geo in
            ZStack {
                screenshotBackground(accent: scene.accent)

                VStack(spacing: layout(for: geo.size).verticalSpacing) {
                    header
                    appPreview
                }
                .padding(.horizontal, layout(for: geo.size).horizontalPadding)
                .padding(.top, layout(for: geo.size).topPadding)
                .padding(.bottom, layout(for: geo.size).bottomPadding)
            }
        }
        .preferredColorScheme(.light)
        .environment(\.locale, AppStoreScreenshotLanguage.current.locale)
        .environment(\.dynamicTypeSize, .large)
        .task {
            configureSceneState()
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            Text(scene.caption)
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .foregroundStyle(AppStyle.Colors.primaryText)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.74)

            Text(scene.supportingLine)
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundStyle(AppStyle.Colors.secondaryText)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.82)
        }
        .frame(maxWidth: .infinity)
    }

    private var appPreview: some View {
        ScreenshotPreviewShell(accent: scene.accent) {
            sceneContent
        }
    }

    @ViewBuilder
    private var sceneContent: some View {
        switch scene {
        case .dashboard:
            NavigationStack {
                DashboardView(allTasks: allTasks)
            }
        case .board:
            NavigationStack {
                BoardScreenshotContent(allTasks: allTasks)
            }
        case .quickCapture:
            QuickCaptureScreenshotContent()
        case .focusGuard:
            NavigationStack {
                FocusGuardScreenshotContent(allTasks: allTasks)
            }
        case .flowReview:
            NavigationStack {
                FlowReviewScreenshotContent(allTasks: allTasks)
            }
        case .search:
            NavigationStack {
                SearchTasksView(allTasks: allTasks, searchText: $searchText)
                    .searchable(text: $searchText, prompt: "Search tasks")
            }
        case .wipChat:
            WIPChatScreenshotContent(allTasks: allTasks)
        }
    }

    private func configureSceneState() {
        switch scene {
        case .search:
            searchText = "invoice"
        default:
            selectedSegment = .todo
        }
    }

    private func screenshotBackground(accent: Color) -> some View {
        ZStack {
            AppStyle.Colors.background

            LinearGradient(
                colors: [
                    accent.opacity(0.18),
                    AppStyle.Colors.background,
                    AppStyle.Colors.Status.done.opacity(0.10)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .ignoresSafeArea()
    }

    private func layout(for size: CGSize) -> ScreenshotLayout {
        let isPad = size.width >= 700
        return ScreenshotLayout(
            horizontalPadding: isPad ? 88 : 28,
            topPadding: isPad ? 72 : 56,
            bottomPadding: isPad ? 72 : 42,
            verticalSpacing: isPad ? 34 : 24
        )
    }
}

private struct ScreenshotLayout {
    let horizontalPadding: CGFloat
    let topPadding: CGFloat
    let bottomPadding: CGFloat
    let verticalSpacing: CGFloat
}

private struct ScreenshotPreviewShell<Content: View>: View {
    let accent: Color
    @ViewBuilder var content: Content

    var body: some View {
        content
            .background(AppStyle.Colors.background)
            .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 34, style: .continuous)
                    .stroke(.white.opacity(0.72), lineWidth: 2)
            }
            .shadow(color: accent.opacity(0.20), radius: 28, x: 0, y: 18)
            .shadow(color: .black.opacity(0.10), radius: 18, x: 0, y: 8)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct BoardScreenshotContent: View {
    let allTasks: [TaskItem]

    private var currentTasks: [TaskItem] {
        allTasks.filter { !$0.isArchived }
    }

    var body: some View {
        VStack(spacing: AppStyle.Spacing.none) {
            header

            GeometryReader { geo in
                let compact = geo.size.width < 620

                HStack(alignment: .top, spacing: compact ? 8 : AppStyle.Spacing.medium) {
                    lane(.todo, compact: compact)
                    lane(.inProgress, compact: compact)
                    lane(.done, compact: compact)
                }
                .padding(.horizontal, compact ? AppStyle.Spacing.medium : AppStyle.Spacing.extraLarge)
                .padding(.vertical, compact ? AppStyle.Spacing.large : AppStyle.Spacing.extraLarge)
            }
        }
        .background(AppStyle.Colors.background)
    }

    private var header: some View {
        VStack(spacing: AppStyle.Spacing.tight) {
            Text("Kanban")
                .font(AppStyle.Typography.headerTitle)
                .foregroundStyle(AppStyle.Colors.primaryText)

            Text("To Do -> In Progress -> Done")
                .font(AppStyle.Typography.inlineHint)
                .foregroundStyle(AppStyle.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, AppStyle.Spacing.extraLarge)
        .padding(.vertical, AppStyle.Spacing.large)
        .background(AppStyle.Materials.chrome)
        .overlay(alignment: .bottom) {
            Divider().opacity(AppStyle.Opacity.divider)
        }
    }

    private func lane(_ status: TaskStatus, compact: Bool) -> some View {
        let tasks = currentTasks
            .filter { $0.status == status }
            .sorted { lhs, rhs in
                if lhs.priority.sortOrder != rhs.priority.sortOrder {
                    return lhs.priority.sortOrder < rhs.priority.sortOrder
                }
                return lhs.order < rhs.order
            }
        let tint = tintColor(for: status)

        return VStack(alignment: .leading, spacing: compact ? AppStyle.Spacing.small : AppStyle.Spacing.medium) {
            HStack(spacing: AppStyle.Spacing.small) {
                Circle()
                    .fill(tint)
                    .frame(width: AppStyle.Shapes.dotSize, height: AppStyle.Shapes.dotSize)

                Text(laneTitle(for: status, compact: compact))
                    .font(compact ? AppStyle.Typography.statusLabelHighlighted : AppStyle.Typography.columnHeader)
                    .foregroundStyle(AppStyle.Colors.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.68)

                Spacer(minLength: AppStyle.Spacing.micro)

                Text(tasks.count.formatted())
                    .font(AppStyle.Typography.zoneCount)
                    .foregroundStyle(AppStyle.Colors.secondaryText)
                    .padding(.horizontal, AppStyle.Spacing.badgeHorizontalPadding)
                    .padding(.vertical, AppStyle.Spacing.badgeVerticalPadding)
                    .background(AppStyle.Colors.badgeBackground, in: .capsule)
            }

            ForEach(Array(tasks.prefix(compact ? 3 : 4))) { task in
                compactTaskCard(task, tint: tint, compact: compact)
            }

            Spacer(minLength: AppStyle.Spacing.none)
        }
        .padding(compact ? AppStyle.Spacing.compact : AppStyle.Spacing.columnPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: AppStyle.Shapes.columnCornerRadius, style: .continuous)
                .fill(AppStyle.Materials.column)
        )
        .overlay {
            RoundedRectangle(cornerRadius: AppStyle.Shapes.columnCornerRadius, style: .continuous)
                .stroke(tint.opacity(status == .inProgress ? AppStyle.Opacity.warningBorder : AppStyle.Opacity.accentBorder), lineWidth: AppStyle.Shapes.emphasizedBorderWidth)
        }
    }

    private func compactTaskCard(_ task: TaskItem, tint: Color, compact: Bool) -> some View {
        VStack(alignment: .leading, spacing: compact ? AppStyle.Spacing.tiny : AppStyle.Spacing.small) {
            Text(task.title)
                .font(compact ? AppStyle.Typography.cardTitle : AppStyle.Typography.statusLabelHighlighted)
                .foregroundStyle(AppStyle.Colors.primaryText)
                .lineLimit(compact ? 3 : 2)
                .minimumScaleFactor(0.72)

            if !compact {
                Text(task.desc)
                    .font(AppStyle.Typography.cardDate)
                    .foregroundStyle(AppStyle.Colors.secondaryText)
                    .lineLimit(2)
            }

            HStack(spacing: AppStyle.Spacing.tiny) {
                Image(systemName: priorityIconName(task.priority))
                    .font(AppStyle.Typography.iconTiny)
                Text(task.priority.localizedName)
                    .font(AppStyle.Typography.cardDate)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .foregroundStyle(priorityColor(task.priority))
        }
        .padding(compact ? AppStyle.Spacing.small : AppStyle.Spacing.compactCardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppStyle.Colors.surface, in: RoundedRectangle(cornerRadius: AppStyle.Shapes.smallCornerRadius, style: .continuous))
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: AppStyle.Shapes.tinyCornerRadius, style: .continuous)
                .fill(tint)
                .frame(width: AppStyle.Shapes.sideBarWidth)
        }
        .overlay {
            RoundedRectangle(cornerRadius: AppStyle.Shapes.smallCornerRadius, style: .continuous)
                .stroke(AppStyle.Colors.surfaceBorder, lineWidth: AppStyle.Shapes.borderWidth)
        }
    }

    private func tintColor(for status: TaskStatus) -> Color {
        switch status {
        case .todo:
            return AppStyle.Colors.Status.todo
        case .inProgress:
            return AppStyle.Colors.warning
        case .done:
            return AppStyle.Colors.Status.done
        }
    }

    private func laneTitle(for status: TaskStatus, compact: Bool) -> String {
        if compact && status == .inProgress {
            return "Active"
        }

        return status.localizedName
    }

    private func priorityColor(_ priority: TaskPriority) -> Color {
        switch priority {
        case .high:
            return AppStyle.Colors.Priority.high
        case .medium:
            return AppStyle.Colors.Priority.medium
        case .low:
            return AppStyle.Colors.Priority.low
        }
    }

    private func priorityIconName(_ priority: TaskPriority) -> String {
        switch priority {
        case .high:
            return "exclamationmark.circle.fill"
        case .medium:
            return "minus.circle.fill"
        case .low:
            return "arrow.down.circle.fill"
        }
    }
}

private struct QuickCaptureScreenshotContent: View {
    var body: some View {
        VStack(spacing: AppStyle.Spacing.none) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: AppStyle.Spacing.extraLarge) {
                    quickCaptureHero
                    generatedTaskPreview
                    captureOptions
                }
                .padding(AppStyle.Spacing.extraLarge)
            }
        }
        .background(AppStyle.Colors.background)
    }

    private var header: some View {
        HStack {
            Text("New Task")
                .font(AppStyle.Typography.headerTitle)
            Spacer()
            Label("Capture", systemImage: "wand.and.stars")
                .font(AppStyle.Typography.buttonLabel)
                .foregroundStyle(AppStyle.Colors.Status.todo)
        }
        .padding(.horizontal, AppStyle.Spacing.extraLarge)
        .padding(.vertical, AppStyle.Spacing.large)
        .background(AppStyle.Materials.chrome)
        .overlay(alignment: .bottom) {
            Divider().opacity(AppStyle.Opacity.divider)
        }
    }

    private var quickCaptureHero: some View {
        VStack(alignment: .leading, spacing: AppStyle.Spacing.medium) {
            Label("Quick Capture", systemImage: "sparkles")
                .font(AppStyle.Typography.metricMedium)
                .foregroundStyle(AppStyle.Colors.Status.todo)

            Text("Paste a messy note and turn it into a clean task draft.")
                .font(AppStyle.Typography.formFooter)
                .foregroundStyle(AppStyle.Colors.secondaryText)
                .fixedSize(horizontal: false, vertical: true)

            Text("Follow up with Sam about the pricing page, send the revised copy, and confirm the launch date before Friday.")
                .font(AppStyle.Typography.formField)
                .foregroundStyle(AppStyle.Colors.primaryText)
                .padding(AppStyle.Spacing.normal)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppStyle.Colors.surface, in: RoundedRectangle(cornerRadius: AppStyle.Shapes.smallCornerRadius, style: .continuous))
        }
        .padding(AppStyle.Spacing.large)
        .accentCardStyle(tint: AppStyle.Colors.Status.todo)
    }

    private var generatedTaskPreview: some View {
        VStack(alignment: .leading, spacing: AppStyle.Spacing.medium) {
            Text("Generated Draft")
                .sectionHeaderStyle()

            VStack(alignment: .leading, spacing: AppStyle.Spacing.medium) {
                Text("Confirm launch date with Sam")
                    .font(AppStyle.Typography.metricMedium)
                    .foregroundStyle(AppStyle.Colors.primaryText)

                Text("Send revised pricing copy and confirm the launch date before Friday.")
                    .font(AppStyle.Typography.formFooter)
                    .foregroundStyle(AppStyle.Colors.secondaryText)

                HStack {
                    Label("High", systemImage: "exclamationmark.circle.fill")
                        .foregroundStyle(AppStyle.Colors.Priority.high)
                    Spacer()
                    Label("To Do", systemImage: "circle.fill")
                        .foregroundStyle(AppStyle.Colors.Status.todo)
                }
                .font(AppStyle.Typography.pillLabel)
            }
            .padding(AppStyle.Spacing.large)
            .cardStyle(cornerRadius: AppStyle.Shapes.cardCornerRadius)
        }
    }

    private var captureOptions: some View {
        HStack(spacing: AppStyle.Spacing.medium) {
            capturePill("Paste", "square.and.pencil")
            capturePill("Photo", "photo.on.rectangle.angled")
            capturePill("Scan", "camera.viewfinder")
            capturePill("Voice", "mic.fill")
        }
    }

    private func capturePill(_ title: String, _ icon: String) -> some View {
        VStack(spacing: AppStyle.Spacing.small) {
            Image(systemName: icon)
                .font(AppStyle.Typography.iconHero)
            Text(title)
                .font(AppStyle.Typography.priorityLabelBold)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppStyle.Spacing.normal)
        .background(AppStyle.Colors.Status.todo.opacity(AppStyle.Opacity.accentWash), in: RoundedRectangle(cornerRadius: AppStyle.Shapes.smallCornerRadius, style: .continuous))
        .foregroundStyle(AppStyle.Colors.Status.todo)
    }
}

private struct WIPChatScreenshotContent: View {
    let allTasks: [TaskItem]

    private var currentTasks: [TaskItem] {
        allTasks.filter { !$0.isArchived }
    }

    private var recommendation: WIPCoachRecommendation {
        WIPCoachEngine.evaluate(
            tasks: currentTasks,
            maxActiveTasks: 3,
            isFocusGuardEnabled: true
        )
    }

    private var activeTasks: [TaskItem] {
        recommendation.activeTasks
    }

    private var blockedTask: TaskItem? {
        activeTasks.first(where: \.isBlocked)
    }

    private var readyTask: TaskItem? {
        recommendation.readyAlternatives.first?.task
            ?? currentTasks
                .filter { $0.status == .todo && !$0.isBlocked }
                .sorted { lhs, rhs in
                    if lhs.priority.sortOrder != rhs.priority.sortOrder {
                        return lhs.priority.sortOrder < rhs.priority.sortOrder
                    }
                    return lhs.order < rhs.order
                }
                .first
    }

    private var referencedTasks: [TaskItem] {
        [
            blockedTask,
            activeTasks.first(where: { !$0.isBlocked }),
            readyTask
        ]
        .compactMap(\.self)
        .reduce(into: [TaskItem]()) { uniqueTasks, task in
            if !uniqueTasks.contains(where: { $0.id == task.id }) {
                uniqueTasks.append(task)
            }
        }
    }

    var body: some View {
        GeometryReader { geo in
            let compact = geo.size.width < 620

            VStack(spacing: AppStyle.Spacing.none) {
                header(compact: compact)

                ScrollView {
                    LazyVStack(spacing: compact ? AppStyle.Spacing.medium : AppStyle.Spacing.regular) {
                        userMessage
                        assistantMessage(compact: compact)
                    }
                    .padding(.horizontal, compact ? AppStyle.Spacing.normal : AppStyle.Spacing.outerHorizontal)
                    .padding(.vertical, compact ? AppStyle.Spacing.normal : AppStyle.Spacing.outerVertical)
                }
                .scrollDisabled(compact)

                Divider()

                composer(compact: compact)
            }
            .background(AppStyle.Colors.background)
        }
    }

    private func header(compact: Bool) -> some View {
        ZStack {
            HStack {
                Text("Clear")
                    .font(AppStyle.Typography.secondaryAction)
                    .foregroundStyle(AppStyle.Colors.disabledControl)

                Spacer()

                Text("Done")
                    .font(AppStyle.Typography.secondaryAction)
                    .foregroundStyle(AppStyle.Colors.Status.todo)
            }

            HStack(spacing: AppStyle.Spacing.small) {
                Image(systemName: "scope")
                    .font(AppStyle.Typography.iconSmall)
                    .foregroundStyle(AppStyle.Colors.Status.todo)
                    .accessibilityHidden(true)

                Text("WIP Coach")
                    .font(AppStyle.Typography.headerTitle)
                    .foregroundStyle(AppStyle.Colors.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }
        }
        .padding(.horizontal, compact ? AppStyle.Spacing.normal : AppStyle.Spacing.extraLarge)
        .padding(.vertical, compact ? AppStyle.Spacing.medium : AppStyle.Spacing.large)
        .background(AppStyle.Materials.chrome)
        .overlay(alignment: .bottom) {
            Divider().opacity(AppStyle.Opacity.divider)
        }
    }

    private var userMessage: some View {
        HStack(alignment: .bottom) {
            Spacer(minLength: AppStyle.Spacing.extraLarge)

            Text("Can I pull more work?")
                .font(AppStyle.Typography.body)
                .foregroundStyle(AppStyle.Colors.inverseText)
                .padding(.horizontal, AppStyle.Spacing.normal)
                .padding(.vertical, AppStyle.Spacing.medium)
                .background(
                    AppStyle.Colors.Status.todo,
                    in: RoundedRectangle(cornerRadius: AppStyle.Shapes.smallCornerRadius, style: .continuous)
                )
                .frame(maxWidth: 420, alignment: .trailing)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    private func assistantMessage(compact: Bool) -> some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: compact ? AppStyle.Spacing.small : AppStyle.Spacing.medium) {
                Text(assistantAnswer)
                    .font(AppStyle.Typography.body)
                    .foregroundStyle(AppStyle.Colors.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, AppStyle.Spacing.normal)
                    .padding(.vertical, AppStyle.Spacing.medium)
                    .background(
                        AppStyle.Colors.surface,
                        in: RoundedRectangle(cornerRadius: AppStyle.Shapes.smallCornerRadius, style: .continuous)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: AppStyle.Shapes.smallCornerRadius, style: .continuous)
                            .stroke(AppStyle.Colors.surfaceBorder, lineWidth: AppStyle.Shapes.borderWidth)
                    }

                answerSources(compact: compact)
                referencedTaskChips(compact: compact)
            }
            .frame(maxWidth: compact ? 420 : 560, alignment: .leading)

            Spacer(minLength: AppStyle.Spacing.extraLarge)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func answerSources(compact: Bool) -> some View {
        VStack(alignment: .leading, spacing: AppStyle.Spacing.small) {
            HStack(spacing: AppStyle.Spacing.small) {
                Image(systemName: "checkmark.seal.fill")
                    .font(AppStyle.Typography.iconSmall)
                    .foregroundStyle(AppStyle.Colors.Status.done)
                    .accessibilityHidden(true)

                Text("Answer sources")
                    .font(AppStyle.Typography.statusLabelHighlighted)
                    .foregroundStyle(AppStyle.Colors.primaryText)
            }

            VStack(alignment: .leading, spacing: AppStyle.Spacing.tiny) {
                sourceRow(
                    label: "WIP Limit",
                    value: "\(recommendation.stats.activeCount) / \(recommendation.stats.wipLimit)",
                    systemImage: "gauge.with.dots.needle.67percent",
                    tint: AppStyle.Colors.warning
                )

                sourceRow(
                    label: "Blocked active work",
                    value: blockedTask?.title ?? fallbackNone,
                    systemImage: "pause.circle.fill",
                    tint: AppStyle.Colors.blocked
                )

                if !compact {
                    sourceRow(
                        label: "Ready to pull",
                        value: readyTask?.title ?? fallbackNone,
                        systemImage: "tray.and.arrow.down.fill",
                        tint: AppStyle.Colors.Status.todo
                    )
                }
            }
        }
        .padding(AppStyle.Spacing.compactCardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppStyle.Colors.spotlightSurface, in: RoundedRectangle(cornerRadius: AppStyle.Shapes.smallCornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppStyle.Shapes.smallCornerRadius, style: .continuous)
                .stroke(AppStyle.Colors.surfaceBorder, lineWidth: AppStyle.Shapes.borderWidth)
        }
    }

    private func sourceRow(label: LocalizedStringKey, value: String, systemImage: String, tint: Color) -> some View {
        HStack(alignment: .center, spacing: AppStyle.Spacing.small) {
            Image(systemName: systemImage)
                .font(AppStyle.Typography.iconSmall)
                .foregroundStyle(tint)
                .frame(width: AppStyle.Spacing.iconFrameWidth)
                .accessibilityHidden(true)

            Text(label)
                .font(AppStyle.Typography.cardDate)
                .foregroundStyle(AppStyle.Colors.tertiaryText)
                .frame(width: 112, alignment: .leading)
                .lineLimit(2)

            Text(value)
                .font(AppStyle.Typography.cardTitle)
                .foregroundStyle(AppStyle.Colors.secondaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func referencedTaskChips(compact: Bool) -> some View {
        VStack(alignment: .leading, spacing: AppStyle.Spacing.tiny) {
            ForEach(Array(referencedTasks.prefix(compact ? 2 : 3))) { task in
                HStack(spacing: AppStyle.Spacing.small) {
                    Image(systemName: statusIcon(for: task))
                        .font(AppStyle.Typography.iconSmall)
                        .foregroundStyle(statusColor(for: task))
                        .frame(width: AppStyle.Spacing.iconFrameWidth)
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: AppStyle.Spacing.micro) {
                        Text(task.title)
                            .font(AppStyle.Typography.cardTitle)
                            .foregroundStyle(AppStyle.Colors.primaryText)
                            .lineLimit(1)
                            .minimumScaleFactor(0.76)

                        Text("\(task.status.localizedName) - \(task.priority.localizedName)")
                            .font(AppStyle.Typography.cardDate)
                            .foregroundStyle(AppStyle.Colors.secondaryText)
                            .lineLimit(1)
                    }

                    Spacer(minLength: AppStyle.Spacing.small)

                    Image(systemName: "chevron.right")
                        .font(AppStyle.Typography.iconTiny)
                        .foregroundStyle(AppStyle.Colors.tertiaryText)
                        .accessibilityHidden(true)
                }
                .padding(.horizontal, AppStyle.Spacing.regular)
                .padding(.vertical, AppStyle.Spacing.small)
                .frame(maxWidth: .infinity, minHeight: AppStyle.Shapes.minimumTapTarget, alignment: .leading)
                .background(AppStyle.Colors.spotlightSurface, in: RoundedRectangle(cornerRadius: AppStyle.Shapes.smallCornerRadius, style: .continuous))
            }
        }
    }

    private func composer(compact: Bool) -> some View {
        VStack(alignment: .leading, spacing: AppStyle.Spacing.small) {
            if !compact {
                HStack(spacing: AppStyle.Spacing.small) {
                    Text("UNBLOCK FIRST")
                        .font(AppStyle.Typography.pillLabel)
                        .foregroundStyle(AppStyle.Colors.blocked)
                        .padding(.horizontal, AppStyle.Spacing.emphasizedPillHorizontalPadding)
                        .padding(.vertical, AppStyle.Spacing.emphasizedPillVerticalPadding)
                        .background(AppStyle.Colors.blocked.opacity(AppStyle.Opacity.accentWash), in: Capsule())

                    Text("Can I pull more work?")
                        .font(AppStyle.Typography.pillLabel)
                        .foregroundStyle(AppStyle.Colors.Status.todo)
                        .padding(.horizontal, AppStyle.Spacing.emphasizedPillHorizontalPadding)
                        .padding(.vertical, AppStyle.Spacing.emphasizedPillVerticalPadding)
                        .background(AppStyle.Colors.Status.todo.opacity(AppStyle.Opacity.accentWash), in: Capsule())
                }
            }

            HStack(alignment: .center, spacing: AppStyle.Spacing.small) {
                Text("Ask about tasks")
                    .font(AppStyle.Typography.body)
                    .foregroundStyle(AppStyle.Colors.tertiaryText)
                    .lineLimit(1)
                    .padding(.horizontal, AppStyle.Spacing.normal)
                    .padding(.vertical, AppStyle.Spacing.medium)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppStyle.Colors.surface, in: RoundedRectangle(cornerRadius: AppStyle.Shapes.smallCornerRadius, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: AppStyle.Shapes.smallCornerRadius, style: .continuous)
                            .stroke(AppStyle.Colors.surfaceBorder, lineWidth: AppStyle.Shapes.borderWidth)
                    }

                Image(systemName: "arrow.up.circle.fill")
                    .font(AppStyle.Typography.iconHero)
                    .foregroundStyle(AppStyle.Colors.Status.todo)
                    .frame(width: AppStyle.Shapes.minimumTapTarget, height: AppStyle.Shapes.minimumTapTarget)
                    .accessibilityLabel(Text("Send"))
            }
        }
        .padding(.horizontal, compact ? AppStyle.Spacing.normal : AppStyle.Spacing.outerHorizontal)
        .padding(.top, AppStyle.Spacing.medium)
        .padding(.bottom, AppStyle.Spacing.normal)
        .background(AppStyle.Colors.background)
    }

    private var assistantAnswer: String {
        AppStoreScreenshotLanguage.current.text(
            en: "Not yet. Your active lane is full and one task is blocked. Unblock Book onboarding calls or finish active work before pulling Draft client proposal.",
            ca: "Encara no. El carril actiu és ple i una tasca està bloquejada. Desbloqueja Book onboarding calls o acaba feina activa abans d'agafar Draft client proposal.",
            es: "Todavía no. Tu carril activo está lleno y una tarea está bloqueada. Desbloquea Book onboarding calls o termina trabajo activo antes de tomar Draft client proposal.",
            de: "Noch nicht. Deine aktive Spur ist voll und eine Aufgabe ist blockiert. Entblocke Book onboarding calls oder schließe aktive Arbeit ab, bevor du Draft client proposal ziehst.",
            ja: "まだです。アクティブレーンはいっぱいで、1件がブロックされています。Draft client proposal を引き込む前に、Book onboarding calls を解除するか、アクティブな作業を終えましょう。",
            hi: "अभी नहीं। आपकी सक्रिय लेन भरी है और एक कार्य रुका हुआ है। Draft client proposal खींचने से पहले Book onboarding calls को अनब्लॉक करें या सक्रिय काम पूरा करें।",
            pt: "Ainda não. Sua raia ativa está cheia e uma tarefa está bloqueada. Desbloqueie Book onboarding calls ou finalize trabalho ativo antes de puxar Draft client proposal.",
            ko: "아직은 아닙니다. 활성 레인이 가득 찼고 작업 하나가 막혀 있습니다. Draft client proposal을 가져오기 전에 Book onboarding calls의 막힘을 풀거나 활성 작업을 끝내세요.",
            fr: "Pas encore. Votre voie active est pleine et une tâche est bloquée. Débloquez Book onboarding calls ou terminez du travail actif avant de prendre Draft client proposal.",
            it: "Non ancora. La corsia attiva è piena e un'attività è bloccata. Sblocca Book onboarding calls o finisci il lavoro attivo prima di prendere Draft client proposal.",
            nl: "Nog niet. Je actieve kolom is vol en één taak is geblokkeerd. Deblokkeer Book onboarding calls of rond actief werk af voordat je Draft client proposal oppakt.",
            pl: "Jeszcze nie. Aktywna kolumna jest pełna, a jedno zadanie jest zablokowane. Odblokuj Book onboarding calls albo skończ bieżącą pracę przed wzięciem Draft client proposal.",
            zh: "还不行。你的进行中栏已满，而且有一项任务被阻塞。先解除 Book onboarding calls 的阻塞，或完成进行中的工作，再拉入 Draft client proposal。"
        )
    }

    private var fallbackNone: String {
        AppStoreScreenshotLanguage.current.text(
            en: "None",
            ca: "Cap",
            es: "Ninguna",
            de: "Keine",
            ja: "なし",
            hi: "कोई नहीं",
            pt: "Nenhuma",
            ko: "없음",
            fr: "Aucune",
            it: "Nessuna",
            nl: "Geen",
            pl: "Brak",
            zh: "无"
        )
    }

    private func statusIcon(for task: TaskItem) -> String {
        switch task.status {
        case .todo:
            return "circle"
        case .inProgress:
            return task.isBlocked ? "pause.circle.fill" : "clock.fill"
        case .done:
            return "checkmark.circle.fill"
        }
    }

    private func statusColor(for task: TaskItem) -> Color {
        if task.status == .inProgress && task.isBlocked {
            return AppStyle.Colors.blocked
        }

        switch task.status {
        case .todo:
            return AppStyle.Colors.Status.todo
        case .inProgress:
            return AppStyle.Colors.Status.inProgress
        case .done:
            return AppStyle.Colors.Status.done
        }
    }
}

private struct FocusGuardScreenshotContent: View {
    let allTasks: [TaskItem]

    private var currentTasks: [TaskItem] {
        allTasks.filter { !$0.isArchived }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppStyle.Spacing.compactSectionSpacing) {
                StatusView(
                    todoCount: currentTasks.filter { $0.status == .todo }.count,
                    inProgressCount: currentTasks.filter { $0.status == .inProgress }.count,
                    doneCount: currentTasks.filter { $0.status == .done }.count,
                    totalCount: currentTasks.count,
                    maxActiveTasks: 3,
                    isFocusGuardEnabled: true,
                    selectedStatus: .inProgress
                )

                WIPView(
                    allTasks: currentTasks,
                    maxActiveTasks: 3,
                    isFocusGuardEnabled: true,
                    onOpenCoach: {}
                )

                focusGuardCard
            }
            .padding(.horizontal, AppStyle.Spacing.outerHorizontal)
            .padding(.vertical, AppStyle.Spacing.outerVertical)
        }
        .background(AppStyle.Colors.background)
        .navigationTitle("Focus Guard")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var focusGuardCard: some View {
        HStack(alignment: .top, spacing: AppStyle.Spacing.statusRowGap) {
            Image(systemName: "brain.head.profile")
                .font(AppStyle.Typography.iconLarge)
                .foregroundStyle(AppStyle.Colors.warning)

            VStack(alignment: .leading, spacing: AppStyle.Spacing.small) {
                Text("Finish one before pulling another.")
                    .font(AppStyle.Typography.metricMedium)
                    .foregroundStyle(AppStyle.Colors.primaryText)

                Text("Your active lane is full. KanbanApp keeps the next task visible, but protects your focus first.")
                    .font(AppStyle.Typography.formFooter)
                    .foregroundStyle(AppStyle.Colors.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(AppStyle.Spacing.large)
        .accentCardStyle(tint: AppStyle.Colors.warning)
    }
}

private struct FlowReviewScreenshotContent: View {
    let allTasks: [TaskItem]

    private var currentTasks: [TaskItem] {
        allTasks.filter { !$0.isArchived }
    }

    private var agingSummary: TaskAgingSummary {
        TaskAgingEvaluator.evaluate(
            tasks: currentTasks,
            now: Date(),
            agingDays: 3,
            stalledDays: 5
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppStyle.Spacing.compactSectionSpacing) {
                Text("Flow Review")
                    .sectionHeaderStyle()

                flowCard(
                    title: "Blocked Work",
                    count: currentTasks.filter { $0.status == .inProgress && $0.isBlocked }.count,
                    description: "Blocked tasks need attention before more work is pulled.",
                    icon: "pause.circle.fill",
                    tint: AppStyle.Colors.blocked
                )

                flowCard(
                    title: "Aging Tasks",
                    count: agingSummary.agingTasks.count,
                    description: "These tasks are staying active long enough to risk drag.",
                    icon: "clock.badge.exclamationmark",
                    tint: AppStyle.Colors.Priority.medium
                )

                flowCard(
                    title: "Stalled Tasks",
                    count: agingSummary.stalledTasks.count,
                    description: "These tasks have sat too long in progress and may need a decision.",
                    icon: "exclamationmark.circle.fill",
                    tint: AppStyle.Colors.Priority.high
                )

                WIPView(
                    allTasks: currentTasks,
                    maxActiveTasks: 3,
                    isFocusGuardEnabled: true,
                    onOpenCoach: {}
                )
            }
            .padding(.horizontal, AppStyle.Spacing.outerHorizontal)
            .padding(.vertical, AppStyle.Spacing.outerVertical)
        }
        .background(AppStyle.Colors.background)
        .navigationTitle("Flow Review")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func flowCard(title: String, count: Int, description: String, icon: String, tint: Color) -> some View {
        HStack(alignment: .top, spacing: AppStyle.Spacing.regular) {
            ZStack {
                RoundedRectangle(cornerRadius: AppStyle.Shapes.smallCornerRadius, style: .continuous)
                    .fill(tint.opacity(AppStyle.Opacity.accentWashStrong))
                    .frame(width: AppStyle.Shapes.iconBadgeSmall, height: AppStyle.Shapes.iconBadgeSmall)

                Image(systemName: icon)
                    .font(AppStyle.Typography.iconMedium)
                    .foregroundStyle(tint)
            }

            VStack(alignment: .leading, spacing: AppStyle.Spacing.tiny) {
                HStack {
                    Text(title)
                        .font(AppStyle.Typography.statusLabelHighlighted)
                        .foregroundStyle(AppStyle.Colors.primaryText)

                    Spacer()

                    Text("\(count)")
                        .font(AppStyle.Typography.metricMedium)
                        .foregroundStyle(tint)
                }

                Text(description)
                    .font(AppStyle.Typography.formFooter)
                    .foregroundStyle(AppStyle.Colors.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(AppStyle.Spacing.cardContentPadding)
        .cardStyle(cornerRadius: AppStyle.Shapes.cardCornerRadius)
    }
}
