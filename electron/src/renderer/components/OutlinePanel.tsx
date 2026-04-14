import React from 'react';
import type { OutlineHeading } from '../lib/types';

interface OutlinePanelProps {
  visible: boolean;
  headings: OutlineHeading[];
  activeHeadingId: string | null;
  onHeadingSelect: (id: string) => void;
}

export function OutlinePanel({ visible, headings, activeHeadingId, onHeadingSelect }: OutlinePanelProps) {
  const isOpen = visible && headings.length > 0;

  return (
    <nav
      aria-label="Document outline"
      className={`outline-panel${isOpen ? ' open' : ''}`}
    >
      <div className="outline-panel-inner">
        <div className="outline-heading">Outline</div>
        <div className="outline-list" role="list">
          {headings.map((heading) => (
            <button
              key={heading.id}
              className={`outline-item${activeHeadingId === heading.id ? ' active' : ''}`}
              style={{ paddingLeft: `calc(var(--space-3) + ${(heading.level - 1) * 12}px)` }}
              onClick={() => onHeadingSelect(heading.id)}
              type="button"
            >
              <span className="outline-item-text">{heading.text}</span>
            </button>
          ))}
        </div>
      </div>
    </nav>
  );
}
