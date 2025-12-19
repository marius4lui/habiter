import { Footer, Header } from "@/components";

export default function EnPage() {
    return (
        <div className="container">
            <Header locale="en" />

            <section className="hero">
                <h1>Build habits that stick.</h1>
                <p className="subtitle">
                    Experience a modern, organic way to track your daily routines.
                    Beautifully designed with haptic feedback and fluid animations.
                </p>
                <a href="#download" className="btn btn-primary">
                    Download App
                </a>
            </section>

            <section id="features" className="features">
                <div className="card">
                    <span className="feature-icon">✨</span>
                    <h3>Organic Design</h3>
                    <p>
                        A user interface that feels alive. Glassmorphism, blurred backgrounds,
                        and smooth transitions make tracking a delight.
                    </p>
                </div>
                <div className="card">
                    <span className="feature-icon">📳</span>
                    <h3>Haptic Feedback</h3>
                    <p>
                        Feel your progress. Satisfying haptic feedback rewards you for
                        every completed habit.
                    </p>
                </div>
                <div className="card">
                    <span className="feature-icon">🤖</span>
                    <h3>AI Insights</h3>
                    <p>
                        Smart recommendations and analysis of your habits to help you
                        stay on track and improve.
                    </p>
                </div>
            </section>

            <section id="download" className="hero" style={{ paddingTop: 0 }}>
                <h2>Start your journey today.</h2>
                <br />
                <p>Available for Android.</p>
            </section>

            <Footer locale="en" />
        </div>
    );
}
