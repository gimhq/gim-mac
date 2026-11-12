# Glossary

The words the app shows to people, and the older terms they replace. Use the
user-facing word in every piece of text a user reads, the same way on every
screen.

| Old term (code, logs, SDK) | User-facing word | What it means |
|---|---|---|
| Hub | Server | The computer that passes your messages on. It can't read them. |
| User ID | Account ID | A long code that is your account's real address. |
| Recovery code | Recovery key | A spare key that brings your account back on a new Mac or device. |
| Revoke device | Remove device | Sign a Mac, phone or tablet out of your account. |
| Verified hub | Connected | The app reached this server and it answered. |
| Unverified hub | Not checked | The app has not reached this server yet. |
| Home hub / Primary hub | Main server | The server your account lives on. |
| Keep server / gim-keep | Keep server | A server that backs up your privacy settings and receives the reports you send. Your backup is encrypted. |

Plurals follow the same mapping (hubs → servers).

There are no usernames: people find each other by Account ID only (QR code or
pasted ID). Never show or ask for a username.

"Keep server" has fixed translations: zh-Hans "Keep 服务器", zh-Hant "Keep 伺服器",
es "servidor Keep". "Keep" is never translated.

## Writing rules

Write for a 12-year-old. Signal and Telegram are the benchmark.

- Short sentences, one idea each. Plain everyday words; no protocol jargon
  ("federation", "session", "identity key", "payload", "endpoint").
- Say what to do next when there is a next step.
- Errors say what happened, then what to try: "Couldn't send. Check your
  internet and try again." Never blame the user. No raw error codes.
- Buttons and menu items are short verbs: "Remove", "Try again", "Copy".
- Titles use sentence case: "Linked devices", not "Linked Devices".
- Accessibility labels (`.accessibilityLabel`) say what the control does:
  "Send message", "Go back".
- Keep every format placeholder (`%@`, `%lld`, ...) with the same index, type
  and meaning, and keep plural variants.
- All user-visible text lives in the String Catalogs under `GIM/Resources`
  (one table per feature: `App`, `Explainer`, `Onboarding`, `Chat`,
  `Settings`), read with `String(localized:table:)` or `Text(_:tableName:)`;
  the `LanguageTablesTests` fail on a key that is missing a language.

## macOS wording

- Menu items and buttons are short verbs: "Remove", "Copy", "New window".
- Window titles and section headers use sentence case: "Linked devices".
- Keyboard shortcuts are written with the symbols ⌘, ⇧, ⌥ in text: "⌘N",
  "⇧⌘N", "⌥⌘S".

## Code keeps the old terms

Only the text a user reads changes. Code, Swift identifiers, String Catalog
keys, logs and GIMKit keep the old terms (hub, user ID, ...). Support
and developers can use the table above to map between what a user sees and
what the code and logs say.
