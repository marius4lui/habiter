"use client";

export default function ErrorPage({ reset }: { reset: () => void }) {
  return <main className="state-page"><h1>Something went wrong</h1><button onClick={reset}>Try again</button></main>;
}
