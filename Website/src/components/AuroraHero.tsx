export default function AuroraHero() {
  return (
    <div className="pointer-events-none absolute inset-0 overflow-hidden" aria-hidden="true">
      <div className="absolute -left-1/4 top-0 h-[520px] w-[520px] rounded-full bg-violet/30 blur-[120px] animate-aurora" />
      <div className="absolute -right-1/4 top-20 h-[480px] w-[480px] rounded-full bg-fuchsia/25 blur-[120px] animate-aurora [animation-delay:4s]" />
      <div className="absolute bottom-0 left-1/3 h-[400px] w-[400px] rounded-full bg-mint/15 blur-[100px] animate-aurora [animation-delay:8s]" />
      <div
        className="absolute inset-0 opacity-[0.04]"
        style={{
          backgroundImage:
            'radial-gradient(circle at 1px 1px, white 1px, transparent 0)',
          backgroundSize: '24px 24px',
        }}
      />
    </div>
  );
}
