---
name: virtualizing-tables
description: Use when virtualizing HTML tables or integrating TanStack Virtual with TanStack Table — virtualizing table rows, sorting with virtual scroll, column spans, translateY offset for tbody
---

### Table Virtualization Pattern
Virtualize only the tbody rows while keeping thead static:

```tsx
import { useVirtualizer } from '@tanstack/react-virtual'

function VirtualTable({ rows }: { rows: DataRow[] }) {
  const parentRef = React.useRef<HTMLDivElement>(null)

  const virtualizer = useVirtualizer({
    count: rows.length,
    getScrollElement: () => parentRef.current,
    estimateSize: () => 34,
    overscan: 20,
  })

  return (
    <div ref={parentRef} style={{ height: '500px', overflow: 'auto' }}>
      <table style={{ width: '100%' }}>
        <thead>
          <tr>
            <th>Name</th>
            <th>Age</th>
            <th>Status</th>
          </tr>
        </thead>
        <tbody
          style={{
            height: `${virtualizer.getTotalSize()}px`,
            position: 'relative',
            display: 'grid',
          }}
        >
          {virtualizer.getVirtualItems().map((virtualRow) => {
            const row = rows[virtualRow.index]
            return (
              <tr
                key={virtualRow.key}
                style={{
                  position: 'absolute',
                  transform: `translateY(${virtualRow.start}px)`,
                  width: '100%',
                  display: 'flex',
                }}
              >
                <td style={{ flex: 1 }}>{row.name}</td>
                <td style={{ flex: 1 }}>{row.age}</td>
                <td style={{ flex: 1 }}>{row.status}</td>
              </tr>
            )
          })}
        </tbody>
      </table>
    </div>
  )
}
```

### With TanStack Table
Combine @tanstack/react-table for column definitions and sorting with virtual rows:

```tsx
import { useReactTable, getCoreRowModel, getSortedRowModel, flexRender } from '@tanstack/react-table'
import { useVirtualizer } from '@tanstack/react-virtual'

function VirtualSortableTable({ data, columns }) {
  const [sorting, setSorting] = React.useState([])
  const parentRef = React.useRef<HTMLDivElement>(null)

  const table = useReactTable({
    data,
    columns,
    state: { sorting },
    onSortingChange: setSorting,
    getCoreRowModel: getCoreRowModel(),
    getSortedRowModel: getSortedRowModel(),
  })

  const { rows } = table.getRowModel()

  const virtualizer = useVirtualizer({
    count: rows.length,
    getScrollElement: () => parentRef.current,
    estimateSize: () => 34,
    overscan: 20,
  })

  return (
    <div ref={parentRef} style={{ height: '600px', overflow: 'auto' }}>
      <table>
        <thead>
          {table.getHeaderGroups().map((headerGroup) => (
            <tr key={headerGroup.id}>
              {headerGroup.headers.map((header) => (
                <th
                  key={header.id}
                  onClick={header.column.getToggleSortingHandler()}
                  style={{ cursor: 'pointer' }}
                >
                  {flexRender(header.column.columnDef.header, header.getContext())}
                  {{ asc: ' 🔼', desc: ' 🔽' }[header.column.getIsSorted() as string] ?? ''}
                </th>
              ))}
            </tr>
          ))}
        </thead>
        <tbody style={{ height: `${virtualizer.getTotalSize()}px`, position: 'relative' }}>
          {virtualizer.getVirtualItems().map((virtualRow) => {
            const row = rows[virtualRow.index]
            return (
              <tr
                key={row.id}
                style={{
                  position: 'absolute',
                  transform: `translateY(${virtualRow.start}px)`,
                  width: '100%',
                  display: 'flex',
                }}
              >
                {row.getVisibleCells().map((cell) => (
                  <td key={cell.id} style={{ flex: 1 }}>
                    {flexRender(cell.column.columnDef.cell, cell.getContext())}
                  </td>
                ))}
              </tr>
            )
          })}
        </tbody>
      </table>
    </div>
  )
}
```

### Tips
- Set higher overscan (10-20) for tables — users scan more aggressively
- tbody needs position: relative + explicit height for absolute positioning
- tr needs display: flex for proper column alignment with absolute positioning
- When data changes (sorting, filtering), virtualizer automatically adjusts
- For fixed headers: use sticky positioning on thead or a separate header table
