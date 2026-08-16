"use client";

import { useEffect } from "react";

type Cleanup = () => void;

function clamp(value: number, minimum: number, maximum: number) {
  return Math.min(Math.max(value, minimum), maximum);
}

function setupCenteredScrollFocus(reducedMotion: boolean): Cleanup {
  const reveals = Array.from(document.querySelectorAll<HTMLElement>("[data-reveal]"));
  const principles = Array.from(document.querySelectorAll<HTMLElement>("[data-principle]"));
  const steps = Array.from(document.querySelectorAll<HTMLElement>("[data-step]"));
  const scenes = Array.from(document.querySelectorAll<HTMLElement>("[data-scene]"));
  const animated = [...reveals, ...principles, ...steps];
  let frame = 0;

  const updateElement = (element: HTMLElement, viewportCenter: number, viewportHeight: number) => {
    const rect = element.getBoundingClientRect();
    const elementCenter = rect.top + rect.height / 2;
    const distance = Math.abs(elementCenter - viewportCenter);
    const fullFocusRadius = Math.max(56, viewportHeight * 0.09);
    const fadeRadius = Math.max(fullFocusRadius + 1, viewportHeight * 0.48);
    const linearPresence = clamp(
      1 - (distance - fullFocusRadius) / (fadeRadius - fullFocusRadius),
      0,
      1,
    );
    const presence = linearPresence * linearPresence * (3 - 2 * linearPresence);
    const direction = clamp((elementCenter - viewportCenter) / fadeRadius, -1, 1);

    element.style.setProperty("--scroll-presence", presence.toFixed(3));
    element.style.setProperty("--scroll-shift", `${reducedMotion ? 0 : direction * 34}px`);
    element.style.setProperty("--scroll-scale", (0.975 + presence * 0.025).toFixed(4));
    element.classList.toggle("visible", presence > 0.01);

    return { element, distance, presence };
  };

  const update = () => {
    frame = 0;
    const viewportHeight = Math.max(window.innerHeight, 1);
    const viewportCenter = viewportHeight / 2;
    const states = new Map(
      animated.map((element) => [
        element,
        updateElement(element, viewportCenter, viewportHeight),
      ]),
    );

    const activateNearest = (elements: HTMLElement[]) => {
      const nearest = elements
        .map((element) => states.get(element))
        .filter((state): state is NonNullable<typeof state> => Boolean(state))
        .sort((left, right) => left.distance - right.distance)[0];
      const active = nearest && nearest.presence >= 0.5 ? nearest.element : null;
      elements.forEach((element) => element.classList.toggle("active", element === active));
      return active;
    };

    activateNearest(principles);
    const activeStep = activateNearest(steps);
    scenes.forEach((scene) => {
      scene.classList.toggle("active", scene.dataset.scene === activeStep?.dataset.step);
    });
  };

  const scheduleUpdate = () => {
    if (!frame) frame = requestAnimationFrame(update);
  };

  update();
  window.addEventListener("scroll", scheduleUpdate, { passive: true });
  window.addEventListener("resize", scheduleUpdate, { passive: true });

  return () => {
    cancelAnimationFrame(frame);
    window.removeEventListener("scroll", scheduleUpdate);
    window.removeEventListener("resize", scheduleUpdate);
  };
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
    cleanups.push(setupCenteredScrollFocus(reducedMotion));

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
