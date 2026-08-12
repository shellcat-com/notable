import { proofPoints } from "@/lib/site";

export function VerifiedProof() {
  return (
    <section aria-label="Verified Parcel facts" className="border-b bg-background">
      <dl className="mx-auto grid max-w-6xl grid-cols-2 px-4 py-7 md:grid-cols-4 md:py-9">
        {proofPoints.map((point, index) => (
          <div
            key={point.label}
            className={`px-4 py-3 text-center md:px-8 ${index % 2 === 1 ? "border-l" : ""} ${index > 1 ? "border-t md:border-t-0" : ""} ${index === 2 ? "md:border-l" : ""}`}
          >
            <dt className="text-2xl font-semibold tracking-tight md:text-3xl">{point.value}</dt>
            <dd className="mt-1 font-mono text-[10px] uppercase tracking-[0.16em] text-muted-foreground md:text-xs">{point.label}</dd>
          </div>
        ))}
      </dl>
    </section>
  );
}
