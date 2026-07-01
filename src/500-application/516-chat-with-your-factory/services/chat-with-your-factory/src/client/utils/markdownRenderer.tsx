import { Fragment, type CSSProperties } from 'react'

const codeStyle: CSSProperties = {
  fontFamily: 'monospace',
  fontSize: '0.9em',
  padding: '1px 4px',
  borderRadius: '3px',
  backgroundColor: 'var(--colorNeutralBackground4)',
}

export function renderInline(text: string, keyPrefix: string) {
  const parts = text.split(/(\*\*[^*]+\*\*|`[^`]+`)/g).filter(Boolean)
  return parts.map((part, i) => {
    if (part.startsWith('**') && part.endsWith('**'))
      return <strong key={`${keyPrefix}-b-${i}`}>{part.slice(2, -2)}</strong>
    if (part.startsWith('`') && part.endsWith('`'))
      return <code key={`${keyPrefix}-c-${i}`} style={codeStyle}>{part.slice(1, -1)}</code>
    return <Fragment key={`${keyPrefix}-t-${i}`}>{part}</Fragment>
  })
}

const tableStyle: CSSProperties = {
  borderCollapse: 'collapse',
  width: '100%',
  fontSize: '0.9em',
  margin: '4px 0',
}

const thStyle: CSSProperties = {
  textAlign: 'left',
  padding: '4px 8px',
  borderBottom: '2px solid var(--colorNeutralStroke1)',
  fontWeight: 600,
}

const tdStyle: CSSProperties = {
  padding: '4px 8px',
  borderBottom: '1px solid var(--colorNeutralStroke2)',
}

function parseTableRow(line: string): string[] {
  return line.split('|').slice(1, -1).map(cell => cell.trim())
}

function isTableSeparator(line: string): boolean {
  return /^\|[\s:]*-{2,}[\s:]*(\|[\s:]*-{2,}[\s:]*)+\|?\s*$/.test(line.trim())
}

function renderTable(lines: string[], keyPrefix: string) {
  // Find header, separator, and body rows
  const headerLine = lines[0]
  const bodyLines = lines.filter((_, i) => i >= 2) // skip header and separator
  const headers = parseTableRow(headerLine)

  return (
    <table key={keyPrefix} style={tableStyle}>
      <thead>
        <tr>
          {headers.map((h, i) => (
            <th key={`${keyPrefix}-th-${i}`} style={thStyle}>{renderInline(h, `${keyPrefix}-th-${i}`)}</th>
          ))}
        </tr>
      </thead>
      <tbody>
        {bodyLines.map((row, ri) => {
          const cells = parseTableRow(row)
          return (
            <tr key={`${keyPrefix}-tr-${ri}`}>
              {headers.map((_, ci) => (
                <td key={`${keyPrefix}-td-${ri}-${ci}`} style={tdStyle}>
                  {renderInline(cells[ci] ?? '', `${keyPrefix}-td-${ri}-${ci}`)}
                </td>
              ))}
            </tr>
          )
        })}
      </tbody>
    </table>
  )
}

export function renderAssistantContent(content: string) {
  // Split on double newlines into blocks
  const blocks = content.split(/\n\s*\n/).filter(block => block.trim().length > 0)

  return blocks.map((block, blockIndex) => {
    const lines = block.split('\n').filter(line => line.trim().length > 0)
    if (lines.length === 0) return null

    // Detect markdown table: lines with pipes and a separator row
    const hasPipes = lines.every(l => l.includes('|'))
    const hasSeparator = lines.some(l => isTableSeparator(l))
    if (hasPipes && hasSeparator && lines.length >= 3) {
      return renderTable(lines, `tbl-${blockIndex}`)
    }

    // Classify each line
    const classified = lines.map(line => {
      const numMatch = line.match(/^(\s*)(\d+\.\s+)/)
      if (numMatch) {
        const indent = numMatch[1].replace(/\t/g, '  ').length
        return { indent: Math.floor(indent / 2), text: line.trim(), type: 'numbered' as const }
      }
      const bulletMatch = line.match(/^(\s*)([-*]\s+)/)
      if (bulletMatch) {
        const indent = bulletMatch[1].replace(/\t/g, '  ').length
        return { indent: Math.floor(indent / 2), text: line.trim(), type: 'bulleted' as const }
      }
      const headingMatch = line.match(/^(#{1,3})\s+(.+)/)
      if (headingMatch) {
        return { indent: 0, text: headingMatch[2], type: 'heading' as const, level: headingMatch[1].length }
      }
      return { indent: 0, text: line.trim(), type: 'text' as const }
    })

    const hasLists = classified.some(c => c.type === 'numbered' || c.type === 'bulleted')
    const hasHeadings = classified.some(c => c.type === 'heading')

    // Heading-only or heading+body
    if (hasHeadings && !hasLists) {
      return (
        <div key={`h-${blockIndex}`}>
          {classified.map((item, i) => {
            if (item.type === 'heading') {
              return <p key={`h-${blockIndex}-${i}`} style={{ fontWeight: 600, marginTop: i > 0 ? '8px' : 0, marginBottom: '2px' }}>
                {renderInline(item.text, `h-${blockIndex}-${i}`)}
              </p>
            }
            return <p key={`p-${blockIndex}-${i}`}>{renderInline(item.text, `p-${blockIndex}-${i}`)}</p>
          })}
        </div>
      )
    }

    // Has lists (pure or mixed)
    if (hasLists) {
      return (
        <div key={`list-${blockIndex}`}>
          {classified.map((item, i) => {
            if (item.type === 'heading') {
              return <p key={`lh-${blockIndex}-${i}`} style={{ fontWeight: 600, marginBottom: '2px' }}>
                {renderInline(item.text, `lh-${blockIndex}-${i}`)}
              </p>
            }
            if (item.type === 'numbered' || item.type === 'bulleted') {
              const prefix = item.type === 'numbered' ? '' : '• '
              const displayText = item.type === 'bulleted'
                ? item.text.replace(/^[-*]\s+/, '')
                : item.text
              return (
                <div key={`li-${blockIndex}-${i}`} style={{
                  marginLeft: `${item.indent * 16 + 8}px`,
                  marginTop: '2px',
                  marginBottom: '2px',
                }}>
                  {prefix ? <span>{prefix}</span> : null}
                  {renderInline(displayText, `li-${blockIndex}-${i}`)}
                </div>
              )
            }
            return <p key={`lt-${blockIndex}-${i}`} style={{ marginTop: '4px' }}>
              {renderInline(item.text, `lt-${blockIndex}-${i}`)}
            </p>
          })}
        </div>
      )
    }

    // Plain paragraph
    return (
      <p key={`p-${blockIndex}`} style={{ margin: '4px 0' }}>
        {lines.map((line, i) => (
          <Fragment key={`p-${blockIndex}-${i}`}>
            {renderInline(line.trimStart(), `p-${blockIndex}-${i}`)}
            {i < lines.length - 1 && <br />}
          </Fragment>
        ))}
      </p>
    )
  })
}
