---
description: Scaffold a new feature with complete directory structure and boilerplate files
argument-hint: <feature-name>
allowed-tools: [Read, Glob, Grep, Bash, Write, Edit]
---

# Feature Scaffolding Command

Creates a complete feature directory structure with boilerplate code following Next.js best practices.

## Arguments

Feature name provided: $ARGUMENTS

**Required:** Feature name in kebab-case (e.g., `user-profile`, `order-management`)

## Feature Structure

This command creates the following structure:

```
src/features/[feature-name]/
├── api/
│   ├── route.ts                 # API route handlers
│   ├── service.ts               # Business logic
│   └── validation.ts            # Input validation schemas
├── components/
│   ├── List.tsx                 # Server Component for listing
│   ├── Detail.tsx               # Server Component for details
│   ├── Form.tsx                 # Client Component for forms
│   └── index.ts                 # Re-exports
├── hooks/
│   ├── use[FeatureName].ts      # Custom React hook
│   └── index.ts                 # Re-exports
├── types/
│   └── index.ts                 # TypeScript types/interfaces
├── actions/
│   └── index.ts                 # Server Actions
└── __tests__/
    ├── api.test.ts              # API route tests
    ├── components.test.tsx      # Component tests
    └── service.test.ts          # Service layer tests
```

## Implementation Steps

1. **Validate Feature Name:**
   - Check if feature name is in kebab-case
   - Convert to PascalCase for component names (e.g., `user-profile` → `UserProfile`)
   - Verify feature doesn't already exist

2. **Create Directory Structure:**
   ```bash
   mkdir -p src/features/[feature-name]/{api,components,hooks,types,actions,__tests__}
   ```

3. **Generate Boilerplate Files:**

### API Route Handler (`api/route.ts`)

```typescript
import { NextRequest, NextResponse } from 'next/server'
import { [featureName]Service } from './service'
import { [featureName]Schema } from './validation'

/**
 * GET /api/v1/[feature-name]
 * List all [feature-name] items
 */
export async function GET(req: NextRequest) {
  try {
    const items = await [featureName]Service.findAll()
    return NextResponse.json({ data: items })
  } catch (error) {
    console.error('Error fetching [feature-name]:', error)
    return NextResponse.json(
      {
        error: error instanceof Error ? error.message : 'Failed to fetch [feature-name]',
        code: 'FETCH_ERROR'
      },
      { status: 500 }
    )
  }
}

/**
 * POST /api/v1/[feature-name]
 * Create a new [feature-name] item
 */
export async function POST(req: NextRequest) {
  try {
    const body = await req.json()

    // Validate input
    const validatedData = [featureName]Schema.parse(body)

    const item = await [featureName]Service.create(validatedData)
    return NextResponse.json({ data: item }, { status: 201 })
  } catch (error) {
    console.error('Error creating [feature-name]:', error)
    return NextResponse.json(
      {
        error: error instanceof Error ? error.message : 'Failed to create [feature-name]',
        code: 'CREATE_ERROR'
      },
      { status: 400 }
    )
  }
}
```

### Service Layer (`api/service.ts`)

```typescript
import { prisma } from '@/lib/db'
import type { [FeatureName], Create[FeatureName]Input } from '../types'

export const [featureName]Service = {
  /**
   * Find all [feature-name] items
   */
  async findAll(): Promise<[FeatureName][]> {
    return prisma.[featureName].findMany({
      where: { deletedAt: null },
      orderBy: { createdAt: 'desc' }
    })
  },

  /**
   * Find [feature-name] by ID
   */
  async findById(id: string): Promise<[FeatureName] | null> {
    return prisma.[featureName].findUnique({
      where: { id }
    })
  },

  /**
   * Create new [feature-name]
   */
  async create(data: Create[FeatureName]Input): Promise<[FeatureName]> {
    return prisma.[featureName].create({
      data
    })
  },

  /**
   * Update [feature-name]
   */
  async update(id: string, data: Partial<Create[FeatureName]Input>): Promise<[FeatureName]> {
    return prisma.[featureName].update({
      where: { id },
      data
    })
  },

  /**
   * Soft delete [feature-name]
   */
  async delete(id: string): Promise<[FeatureName]> {
    return prisma.[featureName].update({
      where: { id },
      data: { deletedAt: new Date() }
    })
  }
}
```

### Validation Schema (`api/validation.ts`)

```typescript
import { z } from 'zod'

export const [featureName]Schema = z.object({
  name: z.string().min(1, 'Name is required'),
  description: z.string().optional(),
  // Add more fields based on your requirements
})

export type [FeatureName]Input = z.infer<typeof [featureName]Schema>
```

### Server Component - List (`components/List.tsx`)

```typescript
import { [featureName]Service } from '../api/service'
import type { [FeatureName] } from '../types'

export default async function [FeatureName]List() {
  const items = await [featureName]Service.findAll()

  if (items.length === 0) {
    return (
      <div className="text-center py-8 text-gray-500">
        No [feature-name] items found.
      </div>
    )
  }

  return (
    <div className="space-y-4">
      <h2 className="text-2xl font-bold">[FeatureName] List</h2>
      <ul className="divide-y divide-gray-200">
        {items.map((item) => (
          <li key={item.id} className="py-4">
            <div className="flex justify-between items-center">
              <div>
                <h3 className="text-lg font-medium">{item.name}</h3>
                {item.description && (
                  <p className="text-gray-600">{item.description}</p>
                )}
              </div>
              <a
                href={`/[feature-name]/${item.id}`}
                className="text-blue-600 hover:text-blue-800"
              >
                View Details
              </a>
            </div>
          </li>
        ))}
      </ul>
    </div>
  )
}
```

### Client Component - Form (`components/Form.tsx`)

```typescript
"use client"

import { useState } from 'react'
import { useRouter } from 'next/navigation'

interface [FeatureName]FormProps {
  initialData?: {
    name: string
    description?: string
  }
  onSubmit?: (data: any) => Promise<void>
}

export function [FeatureName]Form({ initialData, onSubmit }: [FeatureName]FormProps) {
  const router = useRouter()
  const [formData, setFormData] = useState({
    name: initialData?.name ?? '',
    description: initialData?.description ?? ''
  })
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setIsLoading(true)
    setError(null)

    try {
      if (onSubmit) {
        await onSubmit(formData)
      } else {
        const response = await fetch('/api/v1/[feature-name]', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(formData)
        })

        if (!response.ok) {
          const error = await response.json()
          throw new Error(error.error || 'Failed to submit')
        }

        router.push('/[feature-name]')
        router.refresh()
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'An error occurred')
    } finally {
      setIsLoading(false)
    }
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      {error && (
        <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">
          {error}
        </div>
      )}

      <div>
        <label htmlFor="name" className="block text-sm font-medium text-gray-700">
          Name
        </label>
        <input
          type="text"
          id="name"
          value={formData.name}
          onChange={(e) => setFormData({ ...formData, name: e.target.value })}
          className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
          required
        />
      </div>

      <div>
        <label htmlFor="description" className="block text-sm font-medium text-gray-700">
          Description
        </label>
        <textarea
          id="description"
          value={formData.description}
          onChange={(e) => setFormData({ ...formData, description: e.target.value })}
          rows={3}
          className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
        />
      </div>

      <div className="flex gap-2">
        <button
          type="submit"
          disabled={isLoading}
          className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 disabled:opacity-50"
        >
          {isLoading ? 'Submitting...' : 'Submit'}
        </button>
        <button
          type="button"
          onClick={() => router.back()}
          className="px-4 py-2 bg-gray-200 text-gray-700 rounded-md hover:bg-gray-300"
        >
          Cancel
        </button>
      </div>
    </form>
  )
}
```

### TypeScript Types (`types/index.ts`)

```typescript
/**
 * [FeatureName] entity type
 */
export interface [FeatureName] {
  id: string
  name: string
  description?: string
  createdAt: Date
  updatedAt: Date
  deletedAt?: Date | null
}

/**
 * Input type for creating [feature-name]
 */
export interface Create[FeatureName]Input {
  name: string
  description?: string
}

/**
 * Input type for updating [feature-name]
 */
export interface Update[FeatureName]Input extends Partial<Create[FeatureName]Input> {}
```

### Custom Hook (`hooks/use[FeatureName].ts`)

```typescript
"use client"

import { useState, useEffect } from 'react'
import type { [FeatureName] } from '../types'

export function use[FeatureName](id?: string) {
  const [data, setData] = useState<[FeatureName] | [FeatureName][] | null>(null)
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState<Error | null>(null)

  useEffect(() => {
    const fetchData = async () => {
      try {
        const endpoint = id
          ? `/api/v1/[feature-name]/${id}`
          : '/api/v1/[feature-name]'

        const response = await fetch(endpoint)

        if (!response.ok) {
          throw new Error('Failed to fetch [feature-name]')
        }

        const result = await response.json()
        setData(result.data)
      } catch (err) {
        setError(err instanceof Error ? err : new Error('Unknown error'))
      } finally {
        setIsLoading(false)
      }
    }

    fetchData()
  }, [id])

  return { data, isLoading, error }
}
```

### Test Files

**API Tests (`__tests__/api.test.ts`):**
```typescript
import { describe, it, expect, beforeEach } from 'vitest'
import { [featureName]Service } from '../api/service'

describe('[FeatureName] API', () => {
  beforeEach(async () => {
    // Setup test database
  })

  it('should create a new [feature-name]', async () => {
    const data = {
      name: 'Test Item',
      description: 'Test description'
    }

    const result = await [featureName]Service.create(data)

    expect(result).toMatchObject(data)
    expect(result.id).toBeDefined()
  })

  it('should list all [feature-name] items', async () => {
    const items = await [featureName]Service.findAll()
    expect(Array.isArray(items)).toBe(true)
  })
})
```

**Component Tests (`__tests__/components.test.tsx`):**
```typescript
import { describe, it, expect } from 'vitest'
import { render, screen } from '@testing-library/react'
import { [FeatureName]Form } from '../components/Form'

describe('[FeatureName]Form', () => {
  it('should render form fields', () => {
    render(<[FeatureName]Form />)

    expect(screen.getByLabelText(/name/i)).toBeInTheDocument()
    expect(screen.getByLabelText(/description/i)).toBeInTheDocument()
  })

  it('should submit form data', async () => {
    // Add form submission test
  })
})
```

4. **Update Documentation:**

Add entry to `docs/ARCHITECTURE.md`:

```markdown
### [FeatureName]

**Purpose:** [Brief description]

**Components:**
- `[FeatureName]List`: Server component for listing items
- `[FeatureName]Form`: Client component for creating/editing items

**API Endpoints:**
- `GET /api/v1/[feature-name]`: List all items
- `POST /api/v1/[feature-name]`: Create new item

**Database:**
See Prisma schema for `[FeatureName]` model.
```

5. **Generate Next Steps Report:**

```markdown
# Feature Scaffolding Complete: [feature-name]

## Created Files

✓ API route handler
✓ Service layer
✓ Validation schema
✓ Server components (List, Detail)
✓ Client component (Form)
✓ Custom hook
✓ TypeScript types
✓ Test files

## Next Steps

1. **Update Database Schema:**
   ```bash
   # Edit prisma/schema.prisma and add:
   model [FeatureName] {
     id          String   @id @default(cuid())
     name        String
     description String?
     createdAt   DateTime @default(now())
     updatedAt   DateTime @updatedAt
     deletedAt   DateTime?

     @@index([deletedAt])
   }
   ```

2. **Generate Migration:**
   ```bash
   npm run db:migration -- --name add_[feature_name]
   npm run db:push
   ```

3. **Create App Router Pages:**
   ```bash
   mkdir -p src/app/[feature-name]

   # Create page files:
   # src/app/[feature-name]/page.tsx (list view)
   # src/app/[feature-name]/new/page.tsx (create form)
   # src/app/[feature-name]/[id]/page.tsx (detail view)
   ```

4. **Implement Business Logic:**
   - Review and customize `api/service.ts`
   - Add validation rules in `api/validation.ts`
   - Implement additional methods as needed

5. **Customize Components:**
   - Update styling in components
   - Add feature-specific fields
   - Implement error boundaries

6. **Write Tests:**
   - Complete test coverage in `__tests__/`
   - Run: `npm run test -- [feature-name]`
   - Aim for 80%+ coverage

7. **Verify Architecture:**
   ```bash
   /verify-arch
   ```

## Usage Example

```typescript
// In a page component
import [FeatureName]List from '@/features/[feature-name]/components/List'

export default function [FeatureName]Page() {
  return (
    <div>
      <h1>[FeatureName]</h1>
      <[FeatureName]List />
    </div>
  )
}
```

## API Integration

```typescript
// Fetch items
const response = await fetch('/api/v1/[feature-name]')
const { data } = await response.json()

// Create item
const response = await fetch('/api/v1/[feature-name]', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ name: 'New Item' })
})
```

## Files Location

All files created in: `src/features/[feature-name]/`
```

## Usage Examples

```bash
# Scaffold user profile feature
/scaffold-feature user-profile

# Scaffold order management feature
/scaffold-feature order-management

# Scaffold notification system
/scaffold-feature notifications
```

## Validation

Before scaffolding, verify:
- Feature name is valid (kebab-case, alphanumeric + hyphens)
- Feature doesn't already exist
- Parent directory (`src/features/`) exists

## Notes

- All generated code follows Next.js 14+ App Router conventions
- Components default to Server Components unless interactivity is needed
- API routes follow standardized response format
- Database operations use Prisma
- Tests use Vitest and React Testing Library
- TypeScript strict mode enabled
