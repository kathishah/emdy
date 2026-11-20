import { describe, it, expect } from 'vitest';
import { classifyLink } from './link-target';

const current = '/Users/me/notes/guide/intro.md';

describe('classifyLink', () => {
  it('ignores empty hrefs', () => {
    expect(classifyLink(undefined, current)).toEqual({ kind: 'ignore' });
    expect(classifyLink('   ', current)).toEqual({ kind: 'ignore' });
  });

  it('treats http(s) and other schemes as external', () => {
    expect(classifyLink('https://example.com/a.md', current)).toEqual({
      kind: 'external',
      url: 'https://example.com/a.md',
    });
    expect(classifyLink('mailto:a@b.co', current).kind).toBe('external');
  });

  it('treats protocol-relative URLs as external, not paths', () => {
    expect(classifyLink('//example.com/x.md', current)).toEqual({
      kind: 'external',
      url: 'https://example.com/x.md',
    });
  });

  it('classifies #fragments as in-page anchors', () => {
    expect(classifyLink('#getting-started', current)).toEqual({ kind: 'anchor', id: 'getting-started' });
    expect(classifyLink('#', current)).toEqual({ kind: 'ignore' });
  });

  it('resolves sibling and nested relative markdown links', () => {
    expect(classifyLink('other.md', current)).toEqual({
      kind: 'file',
      path: '/Users/me/notes/guide/other.md',
      anchor: null,
    });
    expect(classifyLink('./sub/page.markdown', current)).toEqual({
      kind: 'file',
      path: '/Users/me/notes/guide/sub/page.markdown',
      anchor: null,
    });
  });

  it('resolves parent directory links', () => {
    expect(classifyLink('../README.md', current)).toEqual({
      kind: 'file',
      path: '/Users/me/notes/README.md',
      anchor: null,
    });
  });

  it('keeps the fragment of a file link and drops the query', () => {
    expect(classifyLink('other.md?plain=1#Setup', current)).toEqual({
      kind: 'file',
      path: '/Users/me/notes/guide/other.md',
      anchor: 'Setup',
    });
  });

  it('decodes percent-encoded paths', () => {
    expect(classifyLink('my%20notes.md', current)).toEqual({
      kind: 'file',
      path: '/Users/me/notes/guide/my notes.md',
      anchor: null,
    });
  });

  it('supports absolute paths and file: URLs', () => {
    expect(classifyLink('/Users/me/x.md', current).kind).toBe('file');
    expect(classifyLink('file:///Users/me/x%20y.md#top', current)).toEqual({
      kind: 'file',
      path: '/Users/me/x y.md',
      anchor: 'top',
    });
  });

  it('ignores non-markdown targets', () => {
    expect(classifyLink('image.png', current)).toEqual({ kind: 'ignore' });
    expect(classifyLink('script.sh', current)).toEqual({ kind: 'ignore' });
    expect(classifyLink('file:///etc/passwd', current)).toEqual({ kind: 'ignore' });
  });

  it('ignores relative links when no file is open', () => {
    expect(classifyLink('other.md', null)).toEqual({ kind: 'ignore' });
  });

  it('cannot climb above the filesystem root', () => {
    expect(classifyLink('../../../../../../x.md', '/a/b.md')).toEqual({
      kind: 'file',
      path: '/x.md',
      anchor: null,
    });
  });
});
