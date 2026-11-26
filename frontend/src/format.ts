export function formatTime(iso: string | null | undefined): string {
  return iso ? `${iso.replace("T", " ").slice(0, 19)} UTC` : "—";
}

export function messageOf(error: unknown): string {
  return error instanceof Error ? error.message : "Something went wrong.";
}

export function canReplay(status: string): boolean {
  return status === "dead" || status === "delivered";
}
