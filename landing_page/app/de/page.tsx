import { Footer, Header } from "@/components";

export default function DePage() {
    return (
        <div className="container">
            <Header locale="de" />

            <section className="hero">
                <h1>Gewohnheiten, die bleiben.</h1>
                <p className="subtitle">
                    Erlebe eine moderne, organische Art, deine täglichen Routinen zu verfolgen.
                    Wunderschön gestaltet mit haptischem Feedback und flüssigen Animationen.
                </p>
                <a href="#download" className="btn btn-primary">
                    App herunterladen
                </a>
            </section>

            <section id="features" className="features">
                <div className="card">
                    <span className="feature-icon">✨</span>
                    <h3>Organisches Design</h3>
                    <p>
                        Eine Benutzeroberfläche, die sich lebendig anfühlt. Glassmorphismus,
                        unscharfe Hintergründe und weiche Übergänge machen das Tracking zum Vergnügen.
                    </p>
                </div>
                <div className="card">
                    <span className="feature-icon">📳</span>
                    <h3>Haptisches Feedback</h3>
                    <p>
                        Spüre deinen Fortschritt. Befriedigendes haptisches Feedback belohnt
                        dich für jede abgeschlossene Gewohnheit.
                    </p>
                </div>
                <div className="card">
                    <span className="feature-icon">🤖</span>
                    <h3>KI-Insights</h3>
                    <p>
                        Smarte Empfehlungen und Analysen deiner Gewohnheiten helfen dir,
                        am Ball zu bleiben und dich zu verbessern.
                    </p>
                </div>
            </section>

            <section id="download" className="hero" style={{ paddingTop: 0 }}>
                <h2>Starte deine Reise noch heute.</h2>
                <br />
                <p>Verfügbar für Android.</p>
            </section>

            <Footer locale="de" />
        </div>
    );
}
