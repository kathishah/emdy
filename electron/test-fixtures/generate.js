#!/usr/bin/env node
/**
 * Performance test fixture generator for Emdy
 *
 * Generates three Markdown files of increasing size to benchmark
 * rendering performance in the app:
 *   - perf-small.md   (~500 lines)
 *   - perf-medium.md  (~3000 lines)
 *   - perf-large.md   (~10000 lines)
 */

const fs = require('fs');
const path = require('path');

// ---------------------------------------------------------------------------
// Helpers — each returns a string (with trailing newline)
// ---------------------------------------------------------------------------

function heading(level, text) {
  return `${'#'.repeat(level)} ${text}\n`;
}

function paragraph(sentences) {
  const defaults = [
    'The quick brown fox jumps over the lazy dog.',
    'Markdown rendering performance depends on the complexity of the document.',
    'Emdy reads files without modification, preserving the original content.',
    'A minimal tool does one thing and does it well, without ceremony.',
    'Syntax highlighting adds colour to otherwise monochrome code blocks.',
    'Tables, lists, and inline elements all contribute to render time.',
    'Line-by-line parsing builds the AST that drives the virtual DOM.',
  ];
  const pool = sentences || defaults;
  // cycle through the pool to fill ~3–5 sentences
  const count = 4;
  let out = '';
  for (let i = 0; i < count; i++) {
    out += pool[i % pool.length] + ' ';
  }
  return out.trim() + '\n\n';
}

function inlineCode(label) {
  return `Use \`${label}\` for inline references.\n\n`;
}

function link(text, url) {
  return `See [${text}](${url}) for details.\n\n`;
}

function fencedCodeBlock(language, lineCount) {
  const snippets = {
    javascript: (i) => `  const value${i} = computeResult(${i}, options);\n  console.log('step', ${i}, value${i});\n`,
    typescript: (i) => `  function transform${i}(input: string): string {\n    return input.trim().toLowerCase();\n  }\n`,
    python: (i) => `  def process_${i}(data):\n      return [x * ${i} for x in data if x is not None]\n`,
    rust: (i) => `  fn compute_${i}(n: u64) -> u64 {\n      (0..n).fold(1, |acc, x| acc.wrapping_mul(x + 1))\n  }\n`,
    go: (i) => `  func worker${i}(ch <-chan int) {\n      for v := range ch {\n          fmt.Println(v * ${i})\n      }\n  }\n`,
    java: (i) => `  public int compute${i}(int n) {\n      return IntStream.range(0, n).sum();\n  }\n`,
    ruby: (i) => `  def transform_${i}(list)\n    list.map { |x| x * ${i} }.compact\n  end\n`,
    bash: (i) => `  echo "step ${i}"\n  OUTPUT_${i}=$(cat /dev/stdin | tr '[:upper:]' '[:lower:]')\n`,
  };
  const gen = snippets[language] || snippets.javascript;
  let body = '';
  for (let i = 0; i < lineCount; i++) {
    body += gen(i + 1);
  }
  return `\`\`\`${language}\n${body}\`\`\`\n\n`;
}

function table(rows) {
  let out = '| ID | Name | Status | Count | Notes |\n';
  out += '|----|------|--------|-------|-------|\n';
  for (let i = 1; i <= rows; i++) {
    out += `| ${i} | Item ${i} | ${i % 2 === 0 ? 'active' : 'pending'} | ${i * 7} | Note for row ${i} |\n`;
  }
  return out + '\n';
}

function taskList(items) {
  let out = '';
  for (let i = 0; i < items; i++) {
    const done = i % 3 === 0;
    out += `- [${done ? 'x' : ' '}] Task ${i + 1}: ${done ? 'Completed item' : 'Pending item'} at index ${i}\n`;
  }
  return out + '\n';
}

function nestedList(depth, itemsPerLevel) {
  function buildLevel(currentDepth, maxDepth) {
    if (currentDepth > maxDepth) return '';
    let out = '';
    for (let i = 1; i <= itemsPerLevel; i++) {
      const indent = '  '.repeat(currentDepth - 1);
      out += `${indent}- Level ${currentDepth}, item ${i}\n`;
      if (currentDepth < maxDepth) {
        out += buildLevel(currentDepth + 1, maxDepth);
      }
    }
    return out;
  }
  return buildLevel(1, depth) + '\n';
}

function section(titleLevel, titleText, bodyFn) {
  return heading(titleLevel, titleText) + bodyFn();
}

// ---------------------------------------------------------------------------
// Document builders
// ---------------------------------------------------------------------------

function buildSmall() {
  const lines = [];

  lines.push(heading(1, 'Performance Test: Small Document'));
  lines.push(paragraph());
  lines.push(inlineCode('perf-small'));
  lines.push(link('Emdy on GitHub', 'https://github.com/example/emdy'));

  for (let s = 1; s <= 55; s++) {
    lines.push(heading(2, `Section ${s}`));
    lines.push(paragraph());
    lines.push(paragraph());
    lines.push(paragraph());
    lines.push(inlineCode(`module.section${s}`));
    if (s % 5 === 0) {
      lines.push(link(`Reference ${s}`, `https://example.com/ref/${s}`));
    }
  }

  return lines.join('');
}

function buildMedium() {
  const lines = [];

  lines.push(heading(1, 'Performance Test: Medium Document'));
  lines.push(paragraph());

  const codeLanguages = ['javascript', 'typescript', 'python', 'rust', 'go', 'java', 'ruby', 'bash', 'javascript', 'typescript'];

  for (let s = 1; s <= 38; s++) {
    lines.push(heading(2, `Chapter ${s}`));
    lines.push(paragraph());
    lines.push(paragraph());
    lines.push(paragraph());
    lines.push(inlineCode(`api.chapter${s}.init`));

    // Code block in every other chapter
    if (s % 2 === 0) {
      const lang = codeLanguages[(s - 1) % codeLanguages.length];
      const blockLines = 30 + (s % 5) * 8; // 30–62 lines
      lines.push(heading(3, `Code example for chapter ${s}`));
      lines.push(fencedCodeBlock(lang, blockLines));
    }

    if (s % 8 === 0) {
      lines.push(heading(3, `Table for chapter ${s}`));
      lines.push(table(25));
    }

    if (s % 10 === 0) {
      lines.push(heading(3, `Task list for chapter ${s}`));
      lines.push(taskList(20));
    }

    lines.push(paragraph());
  }

  return lines.join('');
}

function buildLarge() {
  const lines = [];

  lines.push(heading(1, 'Performance Test: Large Document'));
  lines.push(paragraph());

  const codeLanguages = ['javascript', 'typescript', 'python', 'rust', 'go', 'java', 'ruby', 'bash'];

  for (let part = 1; part <= 3; part++) {
    lines.push(heading(1, `Part ${part}`));
    lines.push(paragraph());

    for (let ch = 1; ch <= 7; ch++) {
      const globalCh = (part - 1) * 8 + ch;
      lines.push(heading(2, `Chapter ${globalCh}`));
      lines.push(paragraph());
      lines.push(paragraph());
      lines.push(inlineCode(`emdy.chapter${globalCh}.render`));
      lines.push(link(`Chapter ${globalCh} reference`, `https://example.com/chapter/${globalCh}`));

      // 2 subsections per chapter; code block in the first subsection only
      for (let sub = 1; sub <= 2; sub++) {
        lines.push(heading(3, `Section ${globalCh}.${sub}`));
        lines.push(paragraph());

        if (sub === 1) {
          const lang = codeLanguages[(globalCh + sub) % codeLanguages.length];
          const blockLines = 20 + (globalCh % 8) * 3; // 20–41 lines
          lines.push(fencedCodeBlock(lang, blockLines));
        }

        lines.push(paragraph());
      }

      // Table every 3 chapters (100-row table)
      if (ch % 3 === 0) {
        lines.push(heading(3, `Data table — Chapter ${globalCh}`));
        lines.push(table(70));
      }

      // Task list every 4 chapters
      if (ch % 4 === 0) {
        lines.push(heading(3, `Task list — Chapter ${globalCh}`));
        lines.push(taskList(30));
      }

      // Deeply nested list every 4 chapters
      if (ch % 4 === 2) {
        lines.push(heading(3, `Nested list — Chapter ${globalCh}`));
        lines.push(nestedList(5, 4));
      }

      lines.push(paragraph());
    }
  }

  return lines.join('');
}

// ---------------------------------------------------------------------------
// Write files and report
// ---------------------------------------------------------------------------

const outDir = __dirname;

const files = [
  { name: 'perf-small.md', build: buildSmall },
  { name: 'perf-medium.md', build: buildMedium },
  { name: 'perf-large.md', build: buildLarge },
];

console.log('Generating performance test fixtures...\n');

for (const { name, build } of files) {
  const content = build();
  const filePath = path.join(outDir, name);
  fs.writeFileSync(filePath, content, 'utf8');

  const lineCount = content.split('\n').length;
  const sizeKb = (Buffer.byteLength(content, 'utf8') / 1024).toFixed(1);
  console.log(`  ${name.padEnd(20)} ${String(lineCount).padStart(6)} lines   ${sizeKb.padStart(8)} KB`);
}

console.log('\nDone.');
