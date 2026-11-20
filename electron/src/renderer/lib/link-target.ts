export type LinkTarget =
  | { kind: 'external'; url: string }
  | { kind: 'anchor'; id: string }
  | { kind: 'file'; path: string; anchor: string | null }
  | { kind: 'ignore' };

const SCHEME_PATTERN = /^[a-zA-Z][a-zA-Z0-9+.-]*:/;
const MARKDOWN_EXTENSION = /\.(md|markdown)$/i;

function safeDecode(value: string): string {
  try {
    return decodeURIComponent(value);
  } catch {
    return value;
  }
}

function dirname(filePath: string): string {
  const index = filePath.lastIndexOf('/');
  return index <= 0 ? '/' : filePath.slice(0, index);
}

/** Join and normalize a POSIX path, collapsing "." and ".." segments. */
function resolvePath(baseDir: string, relative: string): string {
  const segments = (relative.startsWith('/') ? relative : `${baseDir}/${relative}`).split('/');
  const out: string[] = [];
  for (const segment of segments) {
    if (!segment || segment === '.') continue;
    if (segment === '..') out.pop();
    else out.push(segment);
  }
  return `/${out.join('/')}`;
}

/**
 * Decide what a clicked markdown link should do.
 *
 * - http(s)/other schemes go to the system handler (main process filters them)
 * - "#heading" scrolls within the current document
 * - relative or absolute paths to markdown files open in a new window
 */
export function classifyLink(href: string | undefined, currentFilePath: string | null | undefined): LinkTarget {
  if (!href) return { kind: 'ignore' };
  const trimmed = href.trim();
  if (!trimmed) return { kind: 'ignore' };

  if (trimmed.startsWith('#')) {
    const id = safeDecode(trimmed.slice(1));
    return id ? { kind: 'anchor', id } : { kind: 'ignore' };
  }

  let pathPart: string;
  let hashPart: string | null = null;

  if (SCHEME_PATTERN.test(trimmed)) {
    if (!/^file:/i.test(trimmed)) return { kind: 'external', url: trimmed };
    let url: URL;
    try {
      url = new URL(trimmed);
    } catch {
      return { kind: 'ignore' };
    }
    pathPart = safeDecode(url.pathname);
    hashPart = url.hash ? safeDecode(url.hash.slice(1)) : null;
  } else if (trimmed.startsWith('//')) {
    // Protocol-relative URL — treat as external, never as a file path
    return { kind: 'external', url: `https:${trimmed}` };
  } else {
    const hashIndex = trimmed.indexOf('#');
    const withoutHash = hashIndex === -1 ? trimmed : trimmed.slice(0, hashIndex);
    hashPart = hashIndex === -1 ? null : safeDecode(trimmed.slice(hashIndex + 1)) || null;
    const queryIndex = withoutHash.indexOf('?');
    const rawPath = queryIndex === -1 ? withoutHash : withoutHash.slice(0, queryIndex);
    if (!rawPath) return { kind: 'ignore' };
    const decoded = safeDecode(rawPath);
    if (decoded.startsWith('/')) {
      pathPart = decoded;
    } else {
      if (!currentFilePath) return { kind: 'ignore' };
      pathPart = resolvePath(dirname(currentFilePath), decoded);
    }
  }

  const normalized = resolvePath('/', pathPart);
  if (!MARKDOWN_EXTENSION.test(normalized)) return { kind: 'ignore' };
  return { kind: 'file', path: normalized, anchor: hashPart };
}
