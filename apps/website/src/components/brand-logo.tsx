export function BrandLogo({ large = false }: { large?: boolean }) {
  return (
    <span className={`brand-mark${large ? " brand-mark-large" : ""}`} aria-hidden="true">
      <svg viewBox="0 0 32 32" role="presentation">
        <path className="brand-mark-leaf" d="M24.8 6.1c-7.2.4-11.7 3.1-13.7 8.1-1.2 3-.6 6.1 1.5 8.2 2.1-5.2 5.5-8.8 10.2-10.9-3.7 2.8-6.2 6.5-7.5 11.3 2.8.4 5.4-.7 7.1-3 2.5-3.3 3.3-7.8 2.4-13.7Z" />
        <path className="brand-mark-stem" d="M8.1 25.5c1.9-5.3 4.8-9.5 8.9-12.5" />
        <path className="brand-mark-check" d="m7.2 15.6 2.3 2.3 4.2-4.8" />
      </svg>
    </span>
  );
}
