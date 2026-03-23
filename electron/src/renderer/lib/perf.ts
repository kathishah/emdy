// Set to true for profiling, or append ?perf to the renderer URL
const ENABLE_PERF = false;

export function perfMark(label: string) {
  if (!ENABLE_PERF) return;
  performance.mark(label);
}

export function perfMeasure(label: string, startMark: string) {
  if (!ENABLE_PERF) return;
  performance.mark(label + '-end');
  const measure = performance.measure(label, startMark, label + '-end');
  console.log(`[perf] ${label}: ${measure.duration.toFixed(1)}ms`);
}
