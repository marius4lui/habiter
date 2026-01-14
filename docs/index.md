# Habiter

<style>
.hero-title {
  font-size: 3.5rem;
  font-weight: 800;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
  margin-bottom: 0.25rem;
  line-height: 1.1;
}
.hero-subtitle {
  font-size: 2rem;
  font-weight: 700;
  color: var(--md-default-fg-color);
  margin-bottom: 0.5rem;
}
.hero-desc {
  font-size: 1.1rem;
  color: var(--md-default-fg-color--light);
  margin-bottom: 1.5rem;
}
.hero-buttons {
  display: flex;
  gap: 0.75rem;
  flex-wrap: wrap;
  margin-bottom: 3rem;
}
.hero-btn {
  display: inline-block;
  padding: 0.6rem 1.25rem;
  border-radius: 8px;
  font-weight: 600;
  text-decoration: none !important;
  transition: all 0.2s;
}
.hero-btn-primary {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white !important;
}
.hero-btn-primary:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(102, 126, 234, 0.4);
}
.hero-btn-secondary {
  background: var(--md-default-bg-color);
  border: 1px solid var(--md-default-fg-color--lightest);
  color: var(--md-default-fg-color) !important;
}
.hero-btn-secondary:hover {
  border-color: var(--md-typeset-a-color);
}
</style>

<div class="hero-title">Habiter</div>
<div class="hero-subtitle">Build Habits. Break Limits.</div>
<p class="hero-desc">The beautifully designed, privacy-focused habit tracker for people who want to stick to their goals.</p>

<div class="hero-buttons">
  <a href="https://github.com/marius4lui/habiter/releases" class="hero-btn hero-btn-primary">Download</a>
  <a href="guide/getting-started/" class="hero-btn hero-btn-secondary">Getting Started</a>
  <a href="developer/architecture/" class="hero-btn hero-btn-secondary">Contribute</a>
</div>

---

<div class="grid cards" markdown>

-   :material-creation: **Beautiful UI**

    Stunning glassmorphism design with animated backgrounds that feel alive.

-   :material-lock: **App Lock**

    Lock distracting apps (like TikTok or Instagram) until you complete your daily habits.

-   :material-chart-box: **Analytics**

    Visualize your progress with detailed charts and streak tracking.

-   :material-shield-account: **Privacy First**

    Your data stays on your device. No cloud account required.

-   :material-sync: **Classly Sync**

    Sync your homework and tasks from Classly as daily habits.

</div>

---

## Tech Stack

| Component | Technology |
|-----------|------------|
| Framework | Flutter 3.x |
| State | Provider |
| Storage | SharedPreferences / Hive |
| Architecture | Feature-first, Clean Architecture |

## License

This project is licensed under the MIT License.
