import { Footer, Header } from "@/components";
import type { Metadata } from "next";

export const metadata: Metadata = {
    title: "Privacy Policy - Habiter",
};

export default function EnPrivacyPage() {
    return (
        <div className="container">
            <Header locale="en" showFeatures={false} showDownload={true} />

            <section className="legal-content">
                <h1>Privacy Policy</h1>
                <p>Last updated: December 16, 2025</p>

                <h2>1. Introduction</h2>
                <p>
                    Welcome to Habiter. We respect your privacy and are committed to protecting
                    your personal data. This privacy policy will inform you about how we look
                    after your personal data when you visit our app and tell you about your
                    privacy rights and how the law protects you.
                </p>

                <h2>2. Data We Collect</h2>
                <p>
                    Habiter is designed to be privacy-first. By default, your habit data is
                    stored locally on your device.
                </p>
                <ul>
                    <li>
                        <strong>Local Data:</strong> Habits, completion history, and preferences
                        are stored on your device.
                    </li>
                    <li>
                        <strong>Usage Data:</strong> We may collect anonymous usage data to improve
                        app performance and stability (e.g., crash reports).
                    </li>
                </ul>

                <h2>3. AI Features</h2>
                <p>
                    If you enable AI Insights, your habit data (names, descriptions, completion
                    history) may be processed by our AI provider to generate insights. This data
                    is not used to train the AI models and is only used to provide you with
                    personalized feedback.
                </p>

                <h2>4. Data Security</h2>
                <p>
                    We have put in place appropriate security measures to prevent your personal
                    data from being accidentally lost, used, or accessed in an unauthorized way.
                </p>

                <h2>5. Your Rights</h2>
                <p>
                    Under certain circumstances, you have rights under data protection laws in
                    relation to your personal data, including the right to request access,
                    correction, erasure, restriction, transfer, or to object to processing.
                </p>

                <h2>6. Contact Us</h2>
                <p>
                    If you have any questions about this privacy policy or our privacy practices,
                    please contact us at:
                </p>
                <p>
                    Sebastian Lui<br />
                    mariusstudio@pm.me<br />
                    Ziegeleistr. 1/2, 70825 Korntal-Münchingen, Deutschland
                </p>
            </section>

            <Footer locale="en" />
        </div>
    );
}
