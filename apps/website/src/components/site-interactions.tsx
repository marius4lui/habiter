"use client";

import { useEffect } from "react";

type Cleanup = () => void;

function observe(
  selector: string,
  onVisible: (element: HTMLElement) => void,
  threshold = 0.12,
): Cleanup {
  const elements = Array.from(document.querySelectorAll<HTMLElement>(selector));

  if (!("IntersectionObserver" in window)) {
    elements.forEach(onVisible);
    return () => undefined;
  }

  const observer = new IntersectionObserver(
    (entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) onVisible(entry.target as HTMLElement);
      });
    },
    { threshold },
  );

  elements.forEach((element) => observer.observe(element));
  return () => observer.disconnect();
}

function setupAmbientCanvas(canvas: HTMLCanvasElement, reducedMotion: boolean): Cleanup {
  const context = canvas.getContext("2d");
  if (!context) return () => undefined;

  const particles = Array.from({ length: 50 }, () => ({
    x: Math.random(),
    y: Math.random(),
    size: 0.4 + Math.random() * 1.3,
    speed: 0.00002 + Math.random() * 0.00005,
    phase: Math.random() * Math.PI * 2,
    alpha: 0.025 + Math.random() * 0.07,
  }));
  let width = 1;
  let height = 1;
  let frame = 0;

  const resize = () => {
    const dpr = Math.min(window.devicePixelRatio || 1, 2);
    width = Math.max(window.innerWidth, 1);
    height = Math.max(window.innerHeight, 1);
    canvas.width = Math.round(width * dpr);
    canvas.height = Math.round(height * dpr);
    context.setTransform(dpr, 0, 0, dpr, 0, 0);
  };

  const draw = (time = 0) => {
    context.clearRect(0, 0, width, height);
    particles.forEach((particle) => {
      const x = particle.x * width + Math.sin(time * particle.speed + particle.phase) * 16;
      const y = particle.y * height + Math.cos(time * particle.speed * 0.7 + particle.phase) * 11;
      context.beginPath();
      context.arc(x, y, particle.size, 0, Math.PI * 2);
      context.fillStyle = `rgba(180,209,166,${particle.alpha})`;
      context.fill();
    });
    if (!reducedMotion) frame = requestAnimationFrame(draw);
  };

  resize();
  draw();
  window.addEventListener("resize", resize, { passive: true });
  return () => {
    cancelAnimationFrame(frame);
    window.removeEventListener("resize", resize);
  };
}

function setupGrowthCanvas(canvas: HTMLCanvasElement, reducedMotion: boolean): Cleanup {
  const context = canvas.getContext("2d");
  if (!context) return () => undefined;

  let width = 1;
  let height = 1;
  let dpr = 1;
  let frame = 0;
  let time = 0;
  const pointer = { x: 0.5, y: 0.5, targetX: 0.5, targetY: 0.5 };

  const resize = () => {
    const rect = canvas.getBoundingClientRect();
    width = Math.max(rect.width || canvas.clientWidth || 1, 1);
    height = Math.max(rect.height || canvas.clientHeight || 720, 1);
    dpr = Math.min(window.devicePixelRatio || 1, 2);
    canvas.width = Math.round(width * dpr);
    canvas.height = Math.round(height * dpr);
    context.setTransform(dpr, 0, 0, dpr, 0, 0);
  };

  const bloom = (x: number, y: number, radius: number) => {
    const gradient = context.createRadialGradient(x, y, 0, x, y, radius * 4);
    gradient.addColorStop(0, "rgba(164,204,154,.35)");
    gradient.addColorStop(1, "rgba(0,0,0,0)");
    context.fillStyle = gradient;
    context.beginPath();
    context.arc(x, y, radius * 4, 0, Math.PI * 2);
    context.fill();
  };

  const branch = (x: number, y: number, length: number, angle: number, depth: number) => {
    const endX = x + Math.cos(angle) * length;
    const endY = y + Math.sin(angle) * length;
    context.beginPath();
    context.moveTo(x, y);
    context.quadraticCurveTo((x + endX) / 2 + Math.sin(angle) * 20, (y + endY) / 2 - Math.cos(angle) * 20, endX, endY);
    context.strokeStyle = `rgba(136,176,131,${0.05 + depth * 0.025})`;
    context.lineWidth = Math.max(0.6, depth * 0.5);
    context.stroke();
    if (depth > 1) {
      branch(endX, endY, length * 0.72, angle - 0.38, depth - 1);
      branch(endX, endY, length * 0.7, angle + 0.42, depth - 1);
    } else bloom(endX, endY, 3.5 + Math.sin(time + x) * 0.3);
  };

  const draw = () => {
    time += 0.012;
    pointer.x += (pointer.targetX - pointer.x) * 0.025;
    pointer.y += (pointer.targetY - pointer.y) * 0.025;
    context.clearRect(0, 0, width, height);
    const mobile = width < 700;
    const centerX = width * (mobile ? 0.58 : 0.72) + (pointer.x - 0.5) * 22;
    const centerY = height * (mobile ? 0.55 : 0.57) + (pointer.y - 0.5) * 17;
    const aura = context.createRadialGradient(centerX, centerY, 0, centerX, centerY, Math.min(width, height) * 0.33);
    aura.addColorStop(0, "rgba(144,178,128,.13)");
    aura.addColorStop(0.42, "rgba(78,205,196,.035)");
    aura.addColorStop(1, "rgba(0,0,0,0)");
    context.fillStyle = aura;
    context.fillRect(0, 0, width, height);
    const count = mobile ? 5 : 8;
    for (let index = 0; index < count; index += 1) {
      branch(centerX, centerY, mobile ? 64 : 78, (Math.PI * 2 * index) / count + time * 0.015, mobile ? 3 : 4);
    }
    bloom(centerX, centerY, 18);
    if (!reducedMotion) frame = requestAnimationFrame(draw);
  };

  const move = (event: PointerEvent) => {
    const rect = canvas.getBoundingClientRect();
    pointer.targetX = (event.clientX - rect.left) / Math.max(rect.width, 1);
    pointer.targetY = (event.clientY - rect.top) / Math.max(rect.height, 1);
  };
  const leave = () => Object.assign(pointer, { targetX: 0.5, targetY: 0.5 });

  resize();
  draw();
  const resizeObserver = new ResizeObserver(resize);
  resizeObserver.observe(canvas);
  canvas.addEventListener("pointermove", move, { passive: true });
  canvas.addEventListener("pointerleave", leave);
  return () => {
    cancelAnimationFrame(frame);
    resizeObserver.disconnect();
    canvas.removeEventListener("pointermove", move);
    canvas.removeEventListener("pointerleave", leave);
  };
}

export function SiteInteractions() {
  useEffect(() => {
    const cleanups: Cleanup[] = [];
    const reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    const nav = document.querySelector("#nav");
    const updateNav = () => nav?.classList.toggle("scrolled", window.scrollY > 40);
    updateNav();
    window.addEventListener("scroll", updateNav, { passive: true });
    cleanups.push(() => window.removeEventListener("scroll", updateNav));
    cleanups.push(observe("[data-reveal]", (element) => element.classList.add("visible")));

    const principles = Array.from(document.querySelectorAll<HTMLElement>("[data-principle]"));
    cleanups.push(observe("[data-principle]", (active) => {
      principles.forEach((principle) => principle.classList.toggle("active", principle === active));
    }, 0.55));

    const steps = Array.from(document.querySelectorAll<HTMLElement>("[data-step]"));
    const scenes = Array.from(document.querySelectorAll<HTMLElement>("[data-scene]"));
    cleanups.push(observe("[data-step]", (active) => {
      steps.forEach((step) => step.classList.toggle("active", step === active));
      scenes.forEach((scene) => scene.classList.toggle("active", scene.dataset.scene === active.dataset.step));
    }, 0.6));

    const habits = Array.from(document.querySelectorAll<HTMLElement>("[data-demo-habit]"));
    const updateProgress = () => {
      const percentage = Math.round((habits.filter((habit) => habit.classList.contains("done")).length / Math.max(habits.length, 1)) * 100);
      const label = document.querySelector("#heroPercent");
      const ring = document.querySelector<HTMLElement>("#heroProgress");
      if (label) label.textContent = `${percentage}%`;
      if (ring) ring.style.background = `conic-gradient(#b7d7a7 0deg ${percentage * 3.6}deg,rgba(255,255,255,.055) ${percentage * 3.6}deg 360deg)`;
    };
    habits.forEach((habit) => {
      const toggle = () => { habit.classList.toggle("done"); updateProgress(); };
      habit.addEventListener("click", toggle);
      cleanups.push(() => habit.removeEventListener("click", toggle));
    });
    updateProgress();

    const glow = document.querySelector<HTMLElement>("#cursorGlow");
    if (glow && !reducedMotion && matchMedia("(pointer:fine)").matches) {
      const move = (event: PointerEvent) => {
        glow.style.left = `${event.clientX}px`;
        glow.style.top = `${event.clientY}px`;
      };
      window.addEventListener("pointermove", move, { passive: true });
      cleanups.push(() => window.removeEventListener("pointermove", move));
    }

    const ambient = document.querySelector<HTMLCanvasElement>("#ambientCanvas");
    const growth = document.querySelector<HTMLCanvasElement>("#growthCanvas");
    if (ambient) cleanups.push(setupAmbientCanvas(ambient, reducedMotion));
    if (growth) cleanups.push(setupGrowthCanvas(growth, reducedMotion));
    return () => cleanups.forEach((cleanup) => cleanup());
  }, []);

  return null;
}
