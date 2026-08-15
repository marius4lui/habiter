import Image from "next/image";

export function BrandLogo({ large = false }: { large?: boolean }) {
  const size = large ? 78 : 36;
  return (
    <span className={`app-logo${large ? " big" : ""}`} aria-hidden="true">
      <Image src="/logo.png" alt="" width={size} height={size} priority={!large} />
    </span>
  );
}
