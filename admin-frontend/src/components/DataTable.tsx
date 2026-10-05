import React, { useState, useMemo } from 'react';
import { Search, ChevronLeft, ChevronRight, ArrowUpDown, ArrowUp, ArrowDown, Database } from 'lucide-react';

export interface Column<T> {
  header: string;
  accessorKey?: keyof T | string; // Optional if cell is provided without a direct data mapping
  cell?: (item: T) => React.ReactNode;
  sortable?: boolean;
}

export interface DataTableProps<T> {
  data: T[];
  columns: Column<T>[];
  searchPlaceholder?: string;
  searchableKeys?: (keyof T | string)[];
  loading?: boolean;
  emptyStateMessage?: string;
  emptyStateIcon?: React.ReactNode;
  toolbarExtras?: React.ReactNode;
}

const PAGE_SIZE_OPTIONS = [10, 50, 100];

export function DataTable<T extends Record<string, any>>({
  data,
  columns,
  searchPlaceholder = 'Search...',
  searchableKeys = [],
  loading = false,
  emptyStateMessage = 'No data found.',
  emptyStateIcon = <Database size={36} className="text-border" />,
  toolbarExtras
}: DataTableProps<T>) {
  const [search, setSearch] = useState('');
  const [pageSize, setPageSize] = useState(10);
  const [currentPage, setCurrentPage] = useState(1);
  const [sortConfig, setSortConfig] = useState<{ key: string; direction: 'asc' | 'desc' } | null>(null);

  // Helper to safely get nested values (e.g. "user.name")
  const getNestedValue = (obj: any, path: string) => {
    return path.split('.').reduce((acc, part) => acc && acc[part], obj);
  };

  // 1. Search Filtering
  const filteredData = useMemo(() => {
    if (!search || searchableKeys.length === 0) return data;
    const lowerSearch = search.toLowerCase();
    
    return data.filter(item => {
      return searchableKeys.some(key => {
        const val = getNestedValue(item, key as string);
        if (val == null) return false;
        return String(val).toLowerCase().includes(lowerSearch);
      });
    });
  }, [data, search, searchableKeys]);

  // 2. Sorting
  const sortedData = useMemo(() => {
    let sortableItems = [...filteredData];
    if (sortConfig !== null) {
      sortableItems.sort((a, b) => {
        const aVal = getNestedValue(a, sortConfig.key);
        const bVal = getNestedValue(b, sortConfig.key);
        
        if (aVal < bVal) return sortConfig.direction === 'asc' ? -1 : 1;
        if (aVal > bVal) return sortConfig.direction === 'asc' ? 1 : -1;
        return 0;
      });
    }
    return sortableItems;
  }, [filteredData, sortConfig]);

  // 3. Pagination
  const totalPages = Math.max(1, Math.ceil(sortedData.length / pageSize));
  const safePage = Math.min(currentPage, totalPages);
  
  const paginatedData = useMemo(() => {
    const start = (safePage - 1) * pageSize;
    return sortedData.slice(start, start + pageSize);
  }, [sortedData, safePage, pageSize]);

  // Handlers
  const handleSort = (key: string) => {
    let direction: 'asc' | 'desc' = 'asc';
    if (sortConfig && sortConfig.key === key && sortConfig.direction === 'asc') {
      direction = 'desc';
    }
    setSortConfig({ key, direction });
    setCurrentPage(1); // Reset to first page on sort
  };

  const handleSearchChange = (val: string) => {
    setSearch(val);
    setCurrentPage(1); // Reset to first page on search
  };

  const handlePageSizeChange = (val: number) => {
    setPageSize(val);
    setCurrentPage(1); // Reset to first page on page size change
  };

  // Pagination UI Helpers
  const getPageNumbers = () => {
    const pages: (number | '...')[] = [];
    if (totalPages <= 7) {
      for (let i = 1; i <= totalPages; i++) pages.push(i);
    } else {
      pages.push(1);
      if (safePage > 3) pages.push('...');
      for (let i = Math.max(2, safePage - 1); i <= Math.min(totalPages - 1, safePage + 1); i++) pages.push(i);
      if (safePage < totalPages - 2) pages.push('...');
      pages.push(totalPages);
    }
    return pages;
  };

  return (
    <div className="card">
      {/* Toolbar */}
      <div className="p-4 border-b border-border flex flex-wrap justify-between items-center gap-3 bg-gray-50/50">
        <div className="flex flex-wrap items-center gap-3 w-full md:w-auto">
          <div className="relative w-full md:w-72">
            <Search className="absolute left-3 top-2.5 text-borderDark" size={18} />
            <input
              type="text"
              value={search}
              onChange={(e) => handleSearchChange(e.target.value)}
              placeholder={searchPlaceholder}
              className="input-field pl-10 bg-white w-full"
            />
          </div>
          {toolbarExtras}
        </div>
        <span className="text-sm font-medium text-secondaryText">
          {filteredData.length} {filteredData.length === 1 ? 'result' : 'results'}
        </span>
      </div>

      {/* Table */}
      <div className="overflow-x-auto">
        <table className="w-full text-left border-collapse min-w-[800px]">
          <thead>
            <tr className="border-b border-border text-sm text-secondaryText bg-backgroundLight/50">
              <th className="p-4 font-semibold w-16">#</th>
              {columns.map((col, idx) => (
                <th key={idx} className="p-4 font-semibold whitespace-nowrap">
                  {col.sortable && col.accessorKey ? (
                    <button
                      onClick={() => handleSort(col.accessorKey as string)}
                      className="flex items-center gap-1.5 hover:text-primaryText transition-colors outline-none"
                    >
                      {col.header}
                      {sortConfig?.key === col.accessorKey ? (
                        sortConfig.direction === 'asc' ? <ArrowUp size={14} className="text-primaryBrand" /> : <ArrowDown size={14} className="text-primaryBrand" />
                      ) : (
                        <ArrowUpDown size={14} className="opacity-40" />
                      )}
                    </button>
                  ) : (
                    col.header
                  )}
                </th>
              ))}
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <tr>
                <td colSpan={columns.length + 1} className="text-center p-12">
                  <div className="flex flex-col items-center gap-3">
                    <div className="w-8 h-8 border-4 border-primaryBrand border-t-transparent rounded-full animate-spin" />
                    <span className="text-secondaryText text-sm">Loading data…</span>
                  </div>
                </td>
              </tr>
            ) : paginatedData.length === 0 ? (
              <tr>
                <td colSpan={columns.length + 1} className="text-center p-12">
                  <div className="flex flex-col items-center gap-3">
                    {emptyStateIcon}
                    <span className="text-secondaryText">{emptyStateMessage}</span>
                  </div>
                </td>
              </tr>
            ) : (
              paginatedData.map((row, idx) => {
                const rowNum = (safePage - 1) * pageSize + idx + 1;
                return (
                  <tr key={idx} className="border-b border-border hover:bg-gray-50/50 transition-colors">
                    <td className="p-4 text-secondaryText text-sm">{rowNum}</td>
                    {columns.map((col, colIdx) => (
                      <td key={colIdx} className="p-4">
                        {col.cell ? col.cell(row) : (col.accessorKey ? getNestedValue(row, col.accessorKey as string) : '—')}
                      </td>
                    ))}
                  </tr>
                );
              })
            )}
          </tbody>
        </table>
      </div>

      {/* Pagination */}
      {!loading && filteredData.length > 0 && (
        <div className="px-4 py-4 flex flex-wrap items-center justify-between gap-3 bg-gray-50/30 rounded-b-xl">
          <p className="text-sm text-secondaryText">
            Showing{' '}
            <span className="font-semibold text-primaryText">
              {(safePage - 1) * pageSize + 1}–{Math.min(safePage * pageSize, filteredData.length)}
            </span>{' '}
            of{' '}
            <span className="font-semibold text-primaryText">{filteredData.length}</span>
          </p>

          <div className="flex items-center gap-4">
            {/* Page Size Selector */}
            <div className="flex items-center gap-2">
              <span className="text-sm text-secondaryText hidden sm:inline">Show</span>
              <select
                value={pageSize}
                onChange={(e) => handlePageSizeChange(Number(e.target.value))}
                className="px-3 py-1.5 rounded-lg border border-border bg-white text-sm text-primaryText focus:outline-none focus:ring-2 focus:ring-primaryBrand/30"
              >
                {PAGE_SIZE_OPTIONS.map((s) => (
                  <option key={s} value={s}>{s} items</option>
                ))}
              </select>
            </div>

            {/* Pagination Controls */}
            <div className="flex items-center gap-1.5">
              <button
                onClick={() => setCurrentPage((p) => Math.max(1, p - 1))}
                disabled={safePage === 1}
                className="flex items-center gap-1 px-3 py-1.5 rounded-lg border border-border text-sm font-medium text-secondaryText hover:bg-backgroundLight disabled:opacity-40 disabled:cursor-not-allowed transition-colors"
              >
                <ChevronLeft size={16} /> <span className="hidden sm:inline">Prev</span>
              </button>

              <div className="hidden sm:flex items-center gap-1.5">
                {getPageNumbers().map((pg, i) =>
                  pg === '...' ? (
                    <span key={`ellipsis-${i}`} className="px-2 text-secondaryText select-none">…</span>
                  ) : (
                    <button
                      key={pg}
                      onClick={() => setCurrentPage(pg as number)}
                      className={`w-9 h-9 rounded-lg text-sm font-semibold transition-colors ${
                        pg === safePage
                          ? 'bg-primaryBrand text-white shadow-sm'
                          : 'border border-border text-secondaryText hover:bg-backgroundLight'
                      }`}
                    >
                      {pg}
                    </button>
                  )
                )}
              </div>

              <button
                onClick={() => setCurrentPage((p) => Math.min(totalPages, p + 1))}
                disabled={safePage === totalPages}
                className="flex items-center gap-1 px-3 py-1.5 rounded-lg border border-border text-sm font-medium text-secondaryText hover:bg-backgroundLight disabled:opacity-40 disabled:cursor-not-allowed transition-colors"
              >
                <span className="hidden sm:inline">Next</span> <ChevronRight size={16} />
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
