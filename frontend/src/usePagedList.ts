import { useEffect, useRef, useState } from "react";
import type { Page } from "./api";
import { messageOf } from "./format";

// Loads the first page whenever the filter changes; loadMore appends the next page.
export function usePagedList<T, F>(load: (filter: F, before?: number) => Promise<Page<T>>, filter: F) {
  const [items, setItems] = useState<T[]>([]);
  const [cursor, setCursor] = useState<number | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const loadRef = useRef(load);
  loadRef.current = load;
  const filterKey = JSON.stringify(filter);

  useEffect(() => {
    let cancelled = false;
    setLoading(true);
    setError(null);
    loadRef
      .current(JSON.parse(filterKey) as F, undefined)
      .then((page) => {
        if (cancelled) return;
        setItems(page.data);
        setCursor(page.next_cursor);
      })
      .catch((e: unknown) => !cancelled && setError(messageOf(e)))
      .finally(() => !cancelled && setLoading(false));
    return () => {
      cancelled = true;
    };
  }, [filterKey]);

  async function loadMore() {
    if (cursor === null) return;
    setLoading(true);
    try {
      const page = await loadRef.current(JSON.parse(filterKey) as F, cursor);
      setItems((current) => [...current, ...page.data]);
      setCursor(page.next_cursor);
    } catch (e) {
      setError(messageOf(e));
    } finally {
      setLoading(false);
    }
  }

  return { items, setItems, hasMore: cursor !== null, loading, error, loadMore };
}
