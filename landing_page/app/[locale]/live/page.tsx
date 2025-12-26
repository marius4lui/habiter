"use client";

import { Footer, Header } from "@/components";
import { Locale } from "@/lib/i18n";
import { useParams } from "next/navigation";
import { useEffect, useState } from "react";
import styles from "./live.module.css";

// Demo habits data
const DEMO_HABITS = [
    { id: "1", name: "Meditieren", icon: "🧘", description: "10 Minuten Achtsamkeit", category: "WELLNESS", color: "#D4A373", frequency: "1/day" },
    { id: "2", name: "Sport treiben", icon: "🏃", description: "30 Minuten Bewegung", category: "FITNESS", color: "#E76F51", frequency: "1/day" },
    { id: "3", name: "Wasser trinken", icon: "💧", description: "8 Gläser am Tag", category: "GESUNDHEIT", color: "#4ECDC4", frequency: "8/day" },
    { id: "4", name: "Lesen", icon: "📚", description: "20 Seiten lesen", category: "BILDUNG", color: "#9B59B6", frequency: "1/day" },
    { id: "5", name: "Journaling", icon: "✍️", description: "Gedanken aufschreiben", category: "WELLNESS", color: "#F39C12", frequency: "1/day" },
];

export default function LiveDemoPage() {
    const params = useParams();
    const locale = (params.locale as Locale) || "de";

    const [completedHabits, setCompletedHabits] = useState<string[]>([]);
    const [swipingHabit, setSwipingHabit] = useState<string | null>(null);
    const [swipeProgress, setSwipeProgress] = useState<Record<string, number>>({});
    const [showParticles, setShowParticles] = useState<string | null>(null);
    const [currentTime, setCurrentTime] = useState(new Date());

    useEffect(() => {
        const timer = setInterval(() => setCurrentTime(new Date()), 1000);
        return () => clearInterval(timer);
    }, []);

    const content = {
        de: {
            title: "Live Demo",
            subtitle: "Erlebe Habiter direkt im Browser - genau wie in der App!",
            greeting: getGreeting("de"),
            date: currentTime.toLocaleDateString("de-DE", { weekday: "long", day: "numeric", month: "long" }),
            completion: "Abschluss",
            active: "Aktiv",
            momentum: "Heutiges Momentum",
            slideHint: "Slide →",
            completed: "ERLEDIGT",
            tryIt: "Wische eine Habit nach rechts um sie abzuschließen!",
            reset: "Demo zurücksetzen",
            downloadCta: "Gefällt dir was du siehst?",
            downloadBtn: "App herunterladen",
        },
        en: {
            title: "Live Demo",
            subtitle: "Experience Habiter right in your browser - just like the app!",
            greeting: getGreeting("en"),
            date: currentTime.toLocaleDateString("en-US", { weekday: "long", month: "long", day: "numeric" }),
            completion: "Completion",
            active: "Active",
            momentum: "Today's Momentum",
            slideHint: "Slide →",
            completed: "COMPLETED",
            tryIt: "Swipe a habit to the right to complete it!",
            reset: "Reset Demo",
            downloadCta: "Like what you see?",
            downloadBtn: "Download the App",
        },
    };

    const c = content[locale] || content.de;

    const pendingHabits = DEMO_HABITS.filter(h => !completedHabits.includes(h.id));
    const completedCount = completedHabits.length;
    const totalCount = DEMO_HABITS.length;
    const completionRate = totalCount === 0 ? 0 : completedCount / totalCount;

    function handleSwipeStart(id: string) {
        setSwipingHabit(id);
    }

    function handleSwipeMove(id: string, progress: number) {
        setSwipeProgress(prev => ({ ...prev, [id]: progress }));
    }

    function handleSwipeEnd(id: string) {
        const progress = swipeProgress[id] || 0;
        if (progress > 0.5) {
            // Complete the habit
            setShowParticles(id);
            setTimeout(() => {
                setCompletedHabits(prev => [...prev, id]);
                setShowParticles(null);
            }, 400);
        }
        setSwipingHabit(null);
        setSwipeProgress(prev => ({ ...prev, [id]: 0 }));
    }

    function resetDemo() {
        setCompletedHabits([]);
        setSwipeProgress({});
    }

    return (
        <div className="container">
            <Header locale={locale} showFeatures={false} showDownload={true} />

            <div className={styles.demoPage}>
                <div className={styles.header}>
                    <h1>{c.title}</h1>
                    <p>{c.subtitle}</p>
                </div>

                {/* Phone Frame */}
                <div className={styles.phoneContainer}>
                    <div className={styles.phoneFrame}>
                        <div className={styles.phoneNotch}></div>
                        <div className={styles.phoneScreen}>
                            {/* Hero Header */}
                            <div className={styles.heroHeader}>
                                <div className={styles.heroContent}>
                                    <div className={styles.heroLeft}>
                                        <h2 className={styles.greeting}>{c.greeting}</h2>
                                        <p className={styles.date}>{c.date}</p>
                                    </div>
                                    <button className={styles.addBtn}>+</button>
                                </div>

                                <div className={styles.statsRow}>
                                    <div className={styles.stat}>
                                        <span className={styles.statIcon}>⚡</span>
                                        <div>
                                            <div className={styles.statValue}>{Math.round(completionRate * 100)}%</div>
                                            <div className={styles.statLabel}>{c.completion}</div>
                                        </div>
                                    </div>
                                    <div className={styles.stat}>
                                        <span className={styles.statIcon}>◐</span>
                                        <div>
                                            <div className={styles.statValue}>{totalCount}</div>
                                            <div className={styles.statLabel}>{c.active}</div>
                                        </div>
                                    </div>
                                </div>

                                <div className={styles.progressContainer}>
                                    <div
                                        className={styles.progressBar}
                                        style={{ width: `${completionRate * 100}%` }}
                                    ></div>
                                </div>

                                <div className={styles.momentumRow}>
                                    <span>{c.momentum}</span>
                                    <span className={styles.momentumCount}>{completedCount}/{totalCount}</span>
                                </div>
                            </div>

                            {/* Habit Cards */}
                            <div className={styles.habitList}>
                                {pendingHabits.length === 0 ? (
                                    <div className={styles.allDone}>
                                        <span>🎉</span>
                                        <p>{locale === "de" ? "Alle Habits erledigt!" : "All habits completed!"}</p>
                                    </div>
                                ) : (
                                    pendingHabits.map((habit, index) => (
                                        <HabitCard
                                            key={habit.id}
                                            habit={habit}
                                            isCompleted={false}
                                            swipeProgress={swipeProgress[habit.id] || 0}
                                            showParticles={showParticles === habit.id}
                                            slideHint={c.slideHint}
                                            onSwipeStart={() => handleSwipeStart(habit.id)}
                                            onSwipeMove={(p) => handleSwipeMove(habit.id, p)}
                                            onSwipeEnd={() => handleSwipeEnd(habit.id)}
                                            style={{ animationDelay: `${index * 0.1}s` }}
                                        />
                                    ))
                                )}

                                {/* Completed Section */}
                                {completedHabits.length > 0 && (
                                    <div className={styles.completedSection}>
                                        <h3>✅ {c.completed} ({completedCount})</h3>
                                        {DEMO_HABITS.filter(h => completedHabits.includes(h.id)).map(habit => (
                                            <div key={habit.id} className={styles.completedCard}>
                                                <span className={styles.habitIcon}>{habit.icon}</span>
                                                <span className={styles.habitName}>{habit.name}</span>
                                                <span className={styles.checkmark}>✓</span>
                                            </div>
                                        ))}
                                    </div>
                                )}
                            </div>
                        </div>
                    </div>

                    <p className={styles.tryIt}>{c.tryIt}</p>
                    <button className={styles.resetBtn} onClick={resetDemo}>
                        🔄 {c.reset}
                    </button>
                </div>

                {/* CTA */}
                <div className={styles.ctaSection}>
                    <h2>{c.downloadCta}</h2>
                    <a href={`/${locale}/test`} className={styles.ctaBtn}>
                        📱 {c.downloadBtn}
                    </a>
                </div>
            </div>

            <Footer locale={locale} />
        </div>
    );
}

function getGreeting(locale: string) {
    const hour = new Date().getHours();
    if (locale === "de") {
        if (hour < 12) return "Guten Morgen";
        if (hour < 18) return "Guten Tag";
        return "Guten Abend";
    }
    if (hour < 12) return "Good morning";
    if (hour < 18) return "Good afternoon";
    return "Good evening";
}

// Habit Card Component with Swipe
interface HabitCardProps {
    habit: typeof DEMO_HABITS[0];
    isCompleted: boolean;
    swipeProgress: number;
    showParticles: boolean;
    slideHint: string;
    onSwipeStart: () => void;
    onSwipeMove: (progress: number) => void;
    onSwipeEnd: () => void;
    style?: React.CSSProperties;
}

function HabitCard({ habit, swipeProgress, showParticles, slideHint, onSwipeStart, onSwipeMove, onSwipeEnd, style }: HabitCardProps) {
    const [startX, setStartX] = useState(0);
    const [isDragging, setIsDragging] = useState(false);

    const handleTouchStart = (e: React.TouchEvent) => {
        setStartX(e.touches[0].clientX);
        setIsDragging(true);
        onSwipeStart();
    };

    const handleTouchMove = (e: React.TouchEvent) => {
        if (!isDragging) return;
        const diff = e.touches[0].clientX - startX;
        const progress = Math.max(0, Math.min(1, diff / 150));
        onSwipeMove(progress);
    };

    const handleTouchEnd = () => {
        setIsDragging(false);
        onSwipeEnd();
    };

    const handleMouseDown = (e: React.MouseEvent) => {
        setStartX(e.clientX);
        setIsDragging(true);
        onSwipeStart();
    };

    const handleMouseMove = (e: React.MouseEvent) => {
        if (!isDragging) return;
        const diff = e.clientX - startX;
        const progress = Math.max(0, Math.min(1, diff / 150));
        onSwipeMove(progress);
    };

    const handleMouseUp = () => {
        if (isDragging) {
            setIsDragging(false);
            onSwipeEnd();
        }
    };

    const handleMouseLeave = () => {
        if (isDragging) {
            setIsDragging(false);
            onSwipeEnd();
        }
    };

    return (
        <div
            className={styles.habitCardWrapper}
            style={style}
        >
            {/* Background reveal */}
            <div
                className={styles.swipeReveal}
                style={{
                    opacity: swipeProgress,
                    background: `linear-gradient(90deg, ${habit.color}40, ${habit.color}10)`
                }}
            >
                <span className={styles.revealCheck} style={{ opacity: swipeProgress }}>✓</span>
            </div>

            {/* Card */}
            <div
                className={`${styles.habitCard} ${showParticles ? styles.completing : ""}`}
                style={{ transform: `translateX(${swipeProgress * 80}px)` }}
                onTouchStart={handleTouchStart}
                onTouchMove={handleTouchMove}
                onTouchEnd={handleTouchEnd}
                onMouseDown={handleMouseDown}
                onMouseMove={handleMouseMove}
                onMouseUp={handleMouseUp}
                onMouseLeave={handleMouseLeave}
            >
                <div
                    className={styles.habitIconCircle}
                    style={{ backgroundColor: `${habit.color}20` }}
                >
                    <span>{habit.icon}</span>
                </div>
                <div className={styles.habitInfo}>
                    <div className={styles.habitName}>{habit.name}</div>
                    <div className={styles.habitDesc}>{habit.description}</div>
                </div>
                <div className={styles.habitMeta}>
                    <span className={styles.frequency}>{habit.frequency}</span>
                    <span className={styles.category}>{habit.category}</span>
                </div>
                {swipeProgress === 0 && (
                    <span className={styles.slideHint}>{slideHint}</span>
                )}
            </div>

            {/* Particles */}
            {showParticles && (
                <div className={styles.particles}>
                    {[...Array(12)].map((_, i) => (
                        <span
                            key={i}
                            className={styles.particle}
                            style={{
                                backgroundColor: habit.color,
                                animationDelay: `${i * 0.05}s`,
                                transform: `rotate(${i * 30}deg) translateY(-20px)`
                            }}
                        />
                    ))}
                </div>
            )}
        </div>
    );
}
