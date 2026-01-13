# GitHub Actions Quick Reference

## 🚀 Workflows

### APK Build
```bash
# Trigger: Push, PR, Manual, Release
Actions → Build APK → Run workflow
```
**Output**: Universal APK + Split APKs (arm64, armv7, x86_64)

### Comprehensive CI
```bash
# Trigger: Push, PR, Manual
# Läuft automatisch bei jedem Push/PR
```
**Checks**: Format, Analyze, Tests, Build, Security

---

## 📦 Artifacts Download

Nach erfolgreichem Build:

1. Actions → Workflow-Run auswählen
2. Scroll zu "Artifacts"
3. Download:
   - `habiter-v1.2.0+3-universal` (Universal APK)
   - `habiter-v1.2.0+3-split-apks` (Optimierte APKs)

---

## 🛡️ Branch Protection

Empfohlene Einstellungen für `main`:

Settings → Branches → Add rule

- ✅ Require pull request before merging
- ✅ Require status checks:
  - Code Quality Checks
  - Run Tests
  - Build Verification
- ✅ Require branches to be up to date

---

## 🐛 Troubleshooting

### Format-Fehler
```bash
dart format .
git add .
git commit -m "Format code"
```

### Analysis-Fehler
```bash
flutter analyze
# Beheben Sie die angezeigten Issues
```

---

## 📊 CI Status

Alle Workflows zeigen ihren Status in:
- Pull Requests (automatisch)
- Actions Tab (manuell)
- Commit-Status (Badge)

---

## 🎯 Nächste Schritte

1. ✅ Workflows sind erstellt und einsatzbereit
2. ⚠️ Branch Protection Rules einrichten
3. ⚠️ 83 Analysis-Issues beheben (separater Task)
4. 💡 Optional: Codecov für Coverage-Tracking
