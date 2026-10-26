# Hours Legal WebView Implementation Audit

**Scope.** Audit of the current `Hours` target in this repository, including all tracked source and project configuration, plus a read-only retrieval of the two public legal documents and their shared stylesheet on 2026-07-17. This report describes the implementation that exists now; it does not infer functionality that is not present in source.

**Audit result.** Hours uses a small, reusable SwiftUI pattern: a `LegalDocument` enum owns each title and themed URL, `LegalDocumentSheet` provides the modal chrome, and `LegalWebView` is a transparent `WKWebView` `UIViewRepresentable`. The wrapper intentionally has no navigation delegate, UI delegate, loading/error state, or navigation restrictions.

## 1. Current user flow

1. `TimeDialScreen` owns `@State private var isSettingsSheetPresented = false`. The top-right `line.3.horizontal.decrease` button sets it to `true`.
2. `TimeDialScreen` presents `SettingsSheetView()` with `.sheet(isPresented:)`.
3. `SettingsSheetView` owns `@State private var presentedLegalDocument: LegalDocument?`.
4. Its `Privacy policy` and `Terms of use` `SettingsLinkRow` buttons set that state to `.privacy` and `.terms`, respectively.
5. `SettingsSheetView` presents `LegalDocumentSheet(document:)` using `.sheet(item: $presentedLegalDocument)`. Therefore, a legal document is a **second (nested) modal sheet**, not a `NavigationStack` destination and not an external browser.
6. `LegalDocumentSheet` contains a `NavigationStack` solely for its inline title bar and leading `xmark` toolbar button. Tapping that button calls `@Environment(\.dismiss)`, dismissing the legal sheet and returning to Settings. The Settings sheet has its own close button. No explicit presentation detent, drag-indicator, or interactive-dismiss restriction is applied to either legal sheet; the system sheet dismissal gesture remains available.

There is no back button or SwiftUI navigation route for web-history navigation. If a page loads another URL in the same web view, the sheet title remains the title of the originally selected enum case and the only app-provided exit is Close/dismiss.

## 2. Exact file inventory

| File | Responsibility | Relevant symbols / locations |
| --- | --- | --- |
| `Hours/TimeDialScreen.swift` | Opens Settings, the ancestor of the legal flow. | `isSettingsSheetPresented` (line 25); Settings `.sheet` (178–180); settings button (228–244). |
| `Hours/SettingsSheetView.swift` | Owns the selected legal document, renders both rows, and presents the nested legal sheet. | `SettingsLinkAction`, `presentedLegalDocument` (10–27); rows (71–98); legal `.sheet(item:)` (186–188); row actions (388–406). |
| `Hours/LegalDocument.swift` | Centralized legal-document model, title mapping, base URLs, and theme query construction. | `LegalDocument` (3–43). |
| `Hours/LegalDocumentSheet.swift` | Modal screen chrome: `NavigationStack`, theme-matched SwiftUI background, title, and Close button. | `LegalDocumentSheet` (3–34). |
| `Hours/LegalWebView.swift` | Entire WebKit bridge and reload-deduplication coordinator. | `LegalWebView` (4–34). |
| `Hours/HoursApp.swift` | Resolves the stored appearance choice against the system and injects `AppTheme` into the SwiftUI environment. | `ThemedRootView` (21–42). |
| `Hours/AppAppearancePreference.swift` | Defines System/Light/Dark storage and effective color-scheme rules. | `AppAppearancePreference` (3–39). |
| `Hours/AppTheme.swift` | Defines `AppTheme.variant` and the custom `appTheme` environment value consumed by the legal sheet/model. | `AppThemeVariant`, `AppTheme`, `EnvironmentValues.appTheme` (3–123). |
| `Hours/SheetStyle.swift` | Supplies the legal sheet's native SwiftUI background color. | `appScreenBackground(for:)` (3–6). |
| `Hours.xcodeproj/project.pbxproj` | The target uses a `PBXFileSystemSynchronizedRootGroup` for `Hours`; the source files above are included by the synchronized folder rather than individual PBX file entries. | `Hours` root group (66–83). |

No other tracked app, widget, plist, entitlement, package, or asset file references `LegalDocument`, `LegalDocumentSheet`, `LegalWebView`, either legal URL, or a second legal-display implementation.

## 3. WebView architecture

`LegalWebView` is a `UIViewRepresentable`, not a `UIViewControllerRepresentable`.

* `makeCoordinator()` returns `Coordinator`, but it is only a storage object containing `lastLoadedURL: URL?`. It does **not** conform to `WKNavigationDelegate` or `WKUIDelegate`.
* `makeUIView` creates `WKWebViewConfiguration()` with no mutations, then creates `WKWebView(frame: .zero, configuration: configuration)`.
* It makes the native view and its scroll view visually transparent: `isOpaque = false`, `backgroundColor = .clear`, and `scrollView.backgroundColor = .clear`.
* It sets `webView.scrollView.contentInsetAdjustmentBehavior = .never`. No other scroll-view property is set: no custom indicator, bounce, inset, gesture, or paging policy is added. WebKit defaults therefore govern those aspects.
* It performs `webView.load(URLRequest(url: url))` and records the exact URL after the load call. The request has no custom method, body, headers, cache policy, timeout, or user agent.
* `updateUIView` compares the incoming URL with `lastLoadedURL`. It reloads only when the URL differs, then stores the new URL. It does not inspect actual WebKit navigation state.

`LegalDocumentSheet` places this view in a `ZStack` under a `NavigationStack`. The `SheetStyle` background calls `.ignoresSafeArea()`, but `LegalWebView` itself does not. It is consequently laid out in the navigation content area while its web scroll view opts out of automatic inset adjustment. The clear native backgrounds allow the explicit SwiftUI screen background to show until the remote document paints; the current remote HTML/CSS itself paints an opaque theme-specific `body` background once loaded.

### WebKit configuration and JavaScript

The configuration is the platform default `WKWebViewConfiguration`; Hours does not set a process pool, website data store, preferences, user content controller, user scripts, content rules, media policy, custom user agent, `navigationDelegate`, or `uiDelegate`.

In particular, JavaScript is not disabled or explicitly enabled by Hours. The pages' inline JavaScript runs under WebKit's default content-JavaScript policy and parses the `theme` query string. There is no injected JavaScript, JavaScript message bridge, `evaluateJavaScript`, HTML data injection, or trait-collection callback in app source.

## 4. URL/configuration model

The URLs are centralized and hardcoded in `Hours/LegalDocument.swift`, rather than in an Info.plist, build setting, remote configuration, or a generic URL service:

| `LegalDocument` case | Title | Hardcoded base URL | Initial URL actually loaded |
| --- | --- | --- | --- |
| `.privacy` | `Privacy Policy` | `https://sergy.xyz/hours/privacy/` | `https://sergy.xyz/hours/privacy/?theme=light` or `?theme=dark` |
| `.terms` | `Terms of Use` | `https://sergy.xyz/hours/terms/` | `https://sergy.xyz/hours/terms/?theme=light` or `?theme=dark` |

`LegalDocument.url(for:)` creates `URLComponents` from the base string and replaces its query items with exactly one item: `theme=light` or `theme=dark`. The value derives from `AppTheme.variant`, so it always represents the app's *resolved* appearance; the URL never contains `theme=system`.

## 5. Light/dark theme synchronization

The complete synchronization chain is:

```text
AppStorage("appearancePreference") + system ColorScheme
  -> ThemedRootView.effectiveColorScheme
  -> AppTheme.forColorScheme(...)
  -> environment(\.appTheme, resolvedTheme)
  -> LegalDocument.url(for: theme)
  -> ?theme=light | ?theme=dark
  -> hosted inline script sets body[data-theme]
  -> legal.css changes CSS custom properties
```

The hosted pages initially declare `<body data-theme="light">`. Their identical inline script reads `new URLSearchParams(window.location.search).get("theme")` and sets `data-theme` only for the literal values `light` and `dark`. Their shared `https://sergy.xyz/hours/legal.css` defines light colors in `:root` and dark colors in `body[data-theme="dark"]`.

Therefore Hours uses **a URL query parameter plus page-owned JavaScript and a CSS data attribute**. It does not use `prefers-color-scheme`, an injected CSS class, WebKit trait updates, injected JavaScript, JavaScript messages, or HTML supplied by the app.

## 6. Live theme-update behavior

An already-open legal page reacts when, and only when, the *resolved* `AppTheme.variant` changes. SwiftUI recomputes `document.url(for: theme)`; because the query URL differs, `updateUIView` calls `load` again. This is a **full page reload**, not a live DOM style change. It loses the WebView's current scroll position and any in-page history/state.

| Appearance action while legal sheet is open | Result |
| --- | --- |
| System → Light | Reloads to `theme=light` only if the system was dark. If the system was already light, the effective URL is unchanged and does not reload. |
| System → Dark | Reloads to `theme=dark` only if the system was light. If the system was already dark, there is no reload. |
| Light → Dark | Always reloads the selected document with `theme=dark`. |
| Dark → Light | Always reloads the selected document with `theme=light`. |
| Light → System | Reloads only when the current system appearance is dark; otherwise the effective theme remains light and no reload occurs. |
| Dark → System | Reloads only when the current system appearance is light; otherwise the effective theme remains dark and no reload occurs. |
| System mode and the device changes Light ↔ Dark | Reloads the selected document for the new resolved system theme. |

This behavior is driven by the root view's `@AppStorage` and `@Environment(\.colorScheme)` values; the legal wrapper does not observe traits itself.

## 7. Loading and error behavior

There is no app-provided loading indicator, progress observer, error view, retry control, timeout handling, or offline state. `LegalWebView` has no navigation delegate, so it does not receive or render `didStart`, `didFinish`, `didFail`, or provisional-navigation failure events. The user sees only WebKit's normal rendering/failure behavior inside the legal sheet.

Likewise, there is no `webViewWebContentProcessDidTerminate` implementation and no process-termination reload logic. The only app-triggered reload is the URL change described above.

## 8. Link/navigation rules

Hours implements no link policy. With no `WKNavigationDelegate`, all normal WebKit navigation decisions use WebKit's default behavior; with no `WKUIDelegate`, Hours does not create or route new WebView windows.

The public pages retrieved for this audit currently contain no `target` attributes and no links to an external HTTPS host. Their links and the resulting app-controlled behavior are:

| Link type | Current page occurrences | Hours behavior |
| --- | --- | --- |
| Same-domain root HTTPS | Both pages link to `https://sergy.xyz`. | Normal main-frame WebKit navigation; it remains in the existing legal WebView. It is not opened with SwiftUI `openURL` or Safari. |
| Privacy canonical HTTPS | Privacy links to itself; Terms links to Privacy. | Normal main-frame WebKit navigation. The link has no `theme` query, so the loaded Privacy HTML falls back to its initial light `data-theme`. For a Terms → Privacy click, SwiftUI still believes `.terms` is selected, so the navigation title remains `Terms of Use`. A later resolved-theme change reloads the original Terms URL. |
| Terms canonical HTTPS | Terms links to itself. The current Privacy page does not contain a Terms cross-link. | Normal main-frame WebKit navigation. The no-query link likewise defaults the HTML to light, while the SwiftUI title remains `Terms of Use`. |
| `mailto: hi@sergy.xyz` | Privacy and Terms. | Hours does not intercept the scheme, invoke its own `openURL`, or embed `MFMailComposeViewController` for web content. The link is handed to WebKit/iOS default scheme handling; any handoff to an installed mail handler is platform-controlled, not app-defined. It is not an in-WebView HTML page and there is no Hours fallback/error UI. |
| External HTTPS (hypothetical) | No current external HTTPS link exists. | Not allow-listed or redirected externally by Hours. A future ordinary main-frame HTTPS link would be allowed to navigate in this same WebView under default WebKit behavior. |
| `target="_blank"` / new-window request (hypothetical) | None exists in the retrieved markup. | There is no `WKUIDelegate` `createWebViewWith` implementation, no Safari handoff, and no app-defined new-window destination. Hours supplies no handling for this request type. |

These rules also mean a WebView traversal has no explicit in-app Back control. `allowsBackForwardNavigationGestures` is not configured; even if WebKit accumulates history, the Hours UI offers no app command to go back.

## 9. Security/privacy behavior

### Navigation and transport

* The two initial URLs are HTTPS and hardcoded to `sergy.xyz`, but there is **no allowed-domain list** and no navigation-policy code. Redirects and arbitrary subsequent navigations are not blocked by Hours.
* `Hours/Info.plist` contains no App Transport Security exception. The app does not loosen the platform transport policy in source/configuration.
* There are no custom headers, app/user identifiers, locale, device information, authentication data, or analytics parameters attached to the legal `URLRequest`. The only source-controlled query metadata is `theme=light|dark`.
* WebKit itself necessarily sends ordinary browser/network request metadata (for example, a system WebKit user agent and network connection information); Hours does not customize it.

### Storage and cache

* Hours does not select `WKWebsiteDataStore.nonPersistent()`, a custom process pool, or cookie policy. `WKWebViewConfiguration()` consequently uses the standard WebKit default configuration, including the default persistent website data store unless platform behavior changes.
* Hours does not clear cookies, local storage, website data, or cache on dismissal. It also uses a default `URLRequest`, with no explicit cache override.
* There is no custom user agent, no content blocker/rule list, and no download delegate.

### Scripts and analytics

* The app source has no legal-WebView analytics, tracker, JavaScript injection, JavaScript bridge, or script-message handler.
* The hosted pages retrieved for this audit reference only the first-party shared stylesheet and contain only the inline theme-query script; no third-party script or analytics tag is present in that retrieved HTML. This does not make a claim about server access logging or future hosted-content changes.

## 10. Components safe to reuse

### Copy almost directly

* The three-part separation: an `Identifiable` document enum/model, a SwiftUI sheet shell, and a `UIViewRepresentable` WebKit bridge.
* The URL-deduplication coordinator (`lastLoadedURL`) if Aumo also wants changes to its document URL to cause one reload rather than every SwiftUI update.
* The transparent WebView/background arrangement and `contentInsetAdjustmentBehavior = .never` if Aumo's hosted page paints its own fully opaque background and it wants the same layout behavior.
* The nested-sheet presentation pattern when Aumo wants legal content to open above its Settings sheet, with a close button rather than navigation push.

### Replace for Aumo

* `LegalDocument`, its case names/titles, both `sergy.xyz` URLs, the `theme` web contract, and all Hours copy/branding.
* `AppTheme`, `AppAppearancePreference`, `SheetStyle`, and the custom `appTheme` environment. Aumo should adapt to its existing appearance source rather than copying Hours colors or storage key.
* The Settings row titles/actions and their placement in the Aumo settings surface.
* The remote HTML/CSS/inline script. Those documents belong to Hours and must be replaced by Aumo-owned legal endpoints/content.

### Do not copy as a security feature

The minimal `LegalWebView` must not be treated as a safe generic browser. It has no host allow-list, external-link policy, loading/error UI, recovery, or privacy-isolated data store. Retain those omissions only if Aumo deliberately requires an exact Hours behavioral clone; otherwise add the safeguards in the recommended implementation below.

## 11. Exact recommended Aumo implementation

To reproduce the Hours architecture and appearance contract while making the intentional product decisions explicit:

1. Create `AumoLegalDocument: String, Identifiable` with `.privacy` and `.terms`, a display title, and `url(for resolvedTheme:)`. Put Aumo's two HTTPS base URLs in that model and generate exactly one `theme=light|dark` query item.
2. Create `AumoLegalDocumentSheet(document:)`. Use `NavigationStack`, an inline title, a leading `xmark` dismiss button, an Aumo theme background that ignores safe areas, and a full-size legal WebView that itself respects navigation-content safe areas.
3. Create `AumoLegalWebView(url:)` as a `UIViewRepresentable`. If behavioral parity is required, use the same transparent WebKit setup, `.never` content-inset adjustment, and `lastLoadedURL` comparison; changes to the resolved query URL will then reload the page.
4. In Aumo Settings, hold `@State private var presentedLegalDocument: AumoLegalDocument?`; each row assigns its case and `.sheet(item:)` presents the legal sheet. This preserves the Hours nested-sheet presentation and Close behavior.
5. Ensure Aumo's hosted documents read `theme` and use `body[data-theme]`/CSS variables (or consciously change both web and iOS sides together). Preserve `light` as the default HTML theme so direct no-query browser visits are readable.
6. Preserve the Hours live-update semantics only if desired: have the URL depend on Aumo's resolved appearance so changes cause a full reload. If Aumo needs scroll-position preservation or a true live transition, that is intentionally a different behavior and requires a JS/DOM update implementation.
7. Before shipping Aumo, make an explicit link decision. The safer recommendation is: permit only Aumo's legal hosts/paths in the main WebView; open approved external HTTPS and `mailto:` through `openURL`; cancel unapproved or unsupported schemes; handle `target=_blank` through the same policy; use a nonpersistent `WKWebsiteDataStore` if legal browsing should not retain web data; and supply loading, failure/retry, and process-termination recovery UI. These safeguards are recommended improvements, not Hours parity.

## 12. Exact files expected to change in Aumo

The Aumo repository is not present in this checkout, so exact existing Aumo filenames cannot be verified. The implementation should create or modify the following logical files (use Aumo's actual equivalents if they already exist):

| Aumo file | Change |
| --- | --- |
| `Aumo/Legal/AumoLegalDocument.swift` | New document enum/model; replace URLs, titles, and theme-query contract. |
| `Aumo/Legal/AumoLegalDocumentSheet.swift` | New nested modal shell and Close UI using Aumo theme. |
| `Aumo/Legal/AumoLegalWebView.swift` | New `WKWebView` bridge; choose exact Hours parity or add the recommended navigation/privacy/error controls. |
| Aumo's Settings view (for example, `Aumo/Settings/SettingsView.swift`) | Add the two rows, selected-document state, and `.sheet(item:)` presentation. |
| Aumo's root appearance/theme provider | Ensure it exposes the resolved light/dark value consumed by `AumoLegalDocument.url(for:)`. |
| Aumo-owned legal site/content repository | Add Privacy and Terms endpoints plus theme-aware HTML/CSS. This is outside the iOS project if Aumo hosts the pages elsewhere. |
| Aumo project file only if it does not use a synchronized source folder | Add the three new Swift files to the application target. No package/dependency addition is required; `WebKit` is an Apple system framework. |

No Hours source should be copied wholesale into unrelated Aumo support/contact or appearance code. In particular, `SettingsSheetView` contains Hours-only review, share, support-mail metadata, haptics, illustration, and row-layout code unrelated to legal display.

## Audit constraints and final repository status

This audit added this report only. It made no source-code change, dependency change, or commit.

Final `git status --short`:

```text
?? docs/
```

With untracked directories expanded, the only untracked file is:

```text
?? docs/HOURS_LEGAL_WEBVIEW_IMPLEMENTATION_AUDIT.md
```

Final branch status:

```text
## v1-0-2-fixed...origin/v1-0-2-fixed
?? docs/
```
