#!/usr/bin/env python3
"""
Import edited prologue MD back into source CSV files.

Parses lines like:
  `[tl:testimony_wang_self:preamble:2] 凌瑶: 新台词`

And writes the updated text back to the corresponding source file.

Usage: python3 tools/import_prologue_md.py docs/prologue_full_script.md
"""

import csv
import re
import os
import sys

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TABLES = os.path.join(BASE, 'data', 'case_tables', 'prologue_ferry')

# ID pattern: `[tag] speaker [emotion]: text`
ID_RE = re.compile(r'^`\[([^\]]+)\]`\s+\*\*([^*]+)\*\*(?:\s+`\[([^\]]*)\]`)?:\s*(.*)$')

def parse_line(l):
    m = ID_RE.match(l.strip())
    if not m:
        return None
    tag = m.group(1)
    speaker = m.group(2).strip()
    text = m.group(4).strip()
    return tag, speaker, text

def parse_tag(tag):
    """Parse tag like 'tl:testimony_wang_self:preamble:2' into (type, params)."""
    parts = tag.split(':')
    prefix = parts[0]
    params = parts[1:]
    return prefix, params

class LineUpdater:
    def __init__(self):
        self.changes = {}  # filename -> {key -> new_text}
        self._preload_csvs()

    def _preload_csvs(self):
        """Load all CSV key structures for fast matching."""
        def _read_simple(fname):
            path = os.path.join(TABLES, fname)
            if not os.path.exists(path):
                return []
            with open(path, 'r', encoding='utf-8-sig') as f:
                rows = list(csv.DictReader(f))
            return [r for r in rows if not (list(r.values())[0] or '').strip().startswith('#')]

        # testimony_lines
        for row in _read_simple('testimony_lines.csv'):
            key = (row.get('testimony_id',''), row.get('section',''), row.get('order',''))
            self._add('testimony_lines.csv', key, row)

        # testimony_statements
        for row in _read_simple('testimony_statements.csv'):
            key = (row.get('testimony_id',''), row.get('statement_id',''))
            self._add('testimony_statements.csv', key, row)

        # prologue_lines
        for i, row in enumerate(_read_simple('prologue_lines.csv')):
            self._add('prologue_lines.csv', (str(i+1),), row)

        # dialogue_lines
        for row in _read_simple('dialogue_lines.csv'):
            key = (row.get('node_id',''), row.get('order',''))
            self._add('dialogue_lines.csv', key, row)

        # confrontation_lines
        for row in _read_simple('confrontation_lines.csv'):
            cid = row.get('confrontation_id', row.get('id', ''))
            key = (cid, row.get('section',''), row.get('order',''))
            self._add('confrontation_lines.csv', key, row)

        # day_event_lines
        for i, row in enumerate(_read_simple('day_event_lines.csv')):
            self._add('day_event_lines.csv', (row.get('order', str(i)),), row)

        # epilogue_lines
        for row in _read_simple('epilogue_lines.csv'):
            self._add('epilogue_lines.csv', (row.get('order',''),), row)

    def _read(self, fname):
        path = os.path.join(TABLES, fname)
        if not os.path.exists(path):
            return [], []
        with open(path, 'r', encoding='utf-8-sig') as f:
            reader = csv.DictReader(f)
            fieldnames = reader.fieldnames
            rows = []
            for row in reader:
                first_val = list(row.values())[0] if row else ''
                if first_val and str(first_val).strip().startswith('#'):
                    continue
                rows.append(row)
            return rows, fieldnames

    def _add(self, fname, key, row):
        if fname not in self.changes:
            self.changes[fname] = {}
        self.changes[fname][key] = row

    def apply_change(self, tag, new_text):
        prefix, params = parse_tag(tag)
        filename, key = self._resolve(prefix, params)
        if filename and key:
            if filename in self.changes and key in self.changes[filename]:
                self.changes[filename][key]['text'] = new_text
                return True
        return False

    def _resolve(self, prefix, params):
        """Map tag prefix to (filename, key)."""
        if prefix == 'tl':
            # tl:testimony_id:section:order
            return 'testimony_lines.csv', (params[0], params[1], params[2])
        elif prefix == 'ts':
            return 'testimony_statements.csv', (params[0], params[1])
        elif prefix == 'prologue_l':
            return 'prologue_lines.csv', (params[0],)
        elif prefix == 'dl':
            return 'dialogue_lines.csv', (params[0], params[1])
        elif prefix == 'cl':
            return 'confrontation_lines.csv', (params[0], params[1], params[2])
        elif prefix == 'del':
            return 'day_event_lines.csv', (params[0],)
        elif prefix == 'ep':
            return 'epilogue_lines.csv', (params[0],)
        return None, None

    def write_back(self):
        for fname, keys in self.changes.items():
            path = os.path.join(TABLES, fname)
            if not os.path.exists(path):
                continue
            with open(path, 'r', encoding='utf-8-sig') as f:
                reader = csv.DictReader(f)
                fieldnames = [fn for fn in reader.fieldnames if fn]  # remove None
                rows = list(reader)

            changed = False
            for row in rows:
                key = self._make_key(fname, row)
                if key and key in keys:
                    new_text = keys[key].get('text', '')
                    old_text = row.get('text', '')
                    if new_text != old_text:
                        row['text'] = new_text
                        changed = True

            if changed:
                with open(path, 'w', encoding='utf-8', newline='') as f:
                    writer = csv.DictWriter(f, fieldnames=fieldnames, extrasaction='ignore')
                    writer.writeheader()
                    writer.writerows(rows)
                print(f"  Updated: {fname} ({len(keys)} changes tracked)")

    def _make_key(self, fname, row):
        if fname == 'testimony_lines.csv':
            return (row.get('testimony_id',''), row.get('section',''), row.get('order',''))
        elif fname == 'testimony_statements.csv':
            return (row.get('testimony_id',''), row.get('statement_id',''))
        elif fname == 'prologue_lines.csv':
            return None  # handled differently
        elif fname == 'dialogue_lines.csv':
            return (row.get('node_id',''), row.get('order',''))
        elif fname == 'confrontation_lines.csv':
            return (row.get('confrontation_id','') or row.get('id',''), row.get('section',''), row.get('order',''))
        elif fname == 'day_event_lines.csv':
            return (row.get('order',''),)
        elif fname == 'epilogue_lines.csv':
            return (row.get('order',''),)
        return None

def main():
    if len(sys.argv) < 2:
        print("Usage: python3 tools/import_prologue_md.py <path_to_edited_md>")
        print("  Reads edited MD, writes changes back to CSV source files.")
        sys.exit(1)

    md_path = sys.argv[1]
    if not os.path.exists(md_path):
        print(f"File not found: {md_path}")
        sys.exit(1)

    updater = LineUpdater()
    changes_applied = 0

    with open(md_path, 'r', encoding='utf-8') as f:
        for l in f:
            parsed = parse_line(l)
            if not parsed:
                continue
            tag, speaker, text = parsed
            if updater.apply_change(tag, text):
                changes_applied += 1

    updater.write_back()
    print(f"\nTotal changes applied: {changes_applied}")

if __name__ == '__main__':
    main()
