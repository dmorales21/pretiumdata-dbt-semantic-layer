# Cursor Prompt: Migration Tracker — Full-Stack Implementation
# Feature: Task tracker for dbt/Snowflake migration work, surfaced in Prism

---

## Context

A self-contained HTML prototype exists at:
  `docs/migration-todo-prism.html`

This prompt implements it as a real Prism feature — persistent in PostgreSQL,
served via strata_backend, rendered in strata-frontend.

Read these skill docs before writing any code:
  `strata-personal/docs/backend/STRATA_BACKEND_STRICT_RULES.md`
  `strata-personal/docs/frontend/FRONTEND-RULES.md`
  `strata-personal/discovery/strata_backend_discovery.md`
  `strata-personal/discovery/strata-frontend-structure.md`

---

## Data Model

### Prisma (PostgreSQL)

Add to `prisma/schema.prisma`:

```prisma
model MigrationTask {
  id          String   @id @default(uuid()) @db.Uuid
  user_sub_id String   @db.Uuid
  title       String
  notes       String?
  tag         String   // 'bug' | 'migration' | 'geo' | 'dbt' | 'schema' | 'feature'
  status      String   @default("open") // 'open' | 'blocked' | 'done'
  created_at  DateTime @default(now())
  updated_at  DateTime @updatedAt
  user        User     @relation(fields: [user_sub_id], references: [sub_id])

  @@index([user_sub_id])
  @@index([status])
  @@map("migration_tasks")
}
```

Run: `npx prisma migrate dev --name add_migration_tasks`

---

## Backend

### Endpoints

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/migration-tasks` | `authenticate, loadUser` | List all tasks for user |
| POST | `/migration-tasks` | `authenticate, loadUser` | Create a task |
| PATCH | `/migration-tasks/:id` | `authenticate, loadUser` | Update title/notes/tag/status |
| DELETE | `/migration-tasks/:id` | `authenticate, loadUser` | Delete a task |

### Files to create in `strata-personal/`

```
src/controllers/migrationTasks/
  migrationTasks.controller.ts   -- thin controllers, validate → service → respond
  migrationTasks.service.ts      -- all Prisma calls here
```

### Service contract

```typescript
// service functions needed:
listTasksForUser(userSub: string): Promise<MigrationTask[]>
createTask(userSub: string, data: CreateTaskInput): Promise<MigrationTask>
updateTask(id: string, userSub: string, data: UpdateTaskInput): Promise<MigrationTask>
deleteTask(id: string, userSub: string): Promise<void>

interface CreateTaskInput {
  title: string;
  notes?: string;
  tag: 'bug' | 'migration' | 'geo' | 'dbt' | 'schema' | 'feature';
  status?: 'open' | 'blocked' | 'done';
}

interface UpdateTaskInput {
  title?: string;
  notes?: string;
  tag?: string;
  status?: string;
}
```

### Controller rules (from strata_backend skill)
- Validate inputs before calling service
- Scope all DB operations to `req.user.sub` — never allow cross-user access
- Always `next(err)` for caught errors
- Response shape: `{ message: string, data?: T }`

### Route registration
Add to `src/routes/index.ts` inside `registerRoutes()`:
```typescript
import { listTasks, createTask, updateTask, deleteTask }
  from '../controllers/migrationTasks/migrationTasks.controller';

app.get('/migration-tasks', authenticate, loadUser, listTasks);
app.post('/migration-tasks', authenticate, loadUser, createTask);
app.patch('/migration-tasks/:id', authenticate, loadUser, updateTask);
app.delete('/migration-tasks/:id', authenticate, loadUser, deleteTask);
```

---

## Frontend

### Files to create in `strata-personal/`

```
src/types/
  migrationTask.types.ts         -- MigrationTask interface, tag/status enums

src/api/
  migrationTasks.api.ts          -- CRUD functions wrapping fetch, using getAccessToken()

src/pages/MigrationTracker/
  MigrationTracker.page.tsx      -- main page, matches prototype layout
  MigrationTracker.page.module.css
  components/
    TaskBoard.tsx                -- filterable task list
    TaskModal.tsx                -- add/edit modal
    TaskKPIs.tsx                 -- 4-kpi strip (total / open / blocked / done)
```

### Route
Add to `src/app/router.tsx`:
```typescript
{ path: '/migration-tracker', element: <MigrationTracker /> }
```

Add to sidebar nav in `src/layouts/MainLayout.tsx` under a "Dev" or "Data" section.

### Page behavior (match prototype exactly)
- On mount: fetch all tasks via GET `/migration-tasks`
- Sidebar nav filters by status (All / Open / Blocked / Done / Bugs / Migration)
- Tag filter bar across the top of the board
- Search box filters title + notes client-side
- KPI strip recalculates from filtered data
- Check/uncheck a row → PATCH status open ↔ done (optimistic update)
- Edit icon → opens TaskModal pre-filled
- Delete icon → DELETE with confirmation, optimistic removal
- "+ Add Task" → opens TaskModal empty
- Modal saves via POST (new) or PATCH (existing)

### Types
```typescript
export type TaskTag = 'bug' | 'migration' | 'geo' | 'dbt' | 'schema' | 'feature';
export type TaskStatus = 'open' | 'blocked' | 'done';

export interface MigrationTask {
  id: string;
  title: string;
  notes?: string;
  tag: TaskTag;
  status: TaskStatus;
  created_at: string;
  updated_at: string;
}
```

### API module pattern
```typescript
// src/api/migrationTasks.api.ts
// follow existing api modules — getAccessToken() for auth header,
// return { ok, status, data, error } shape
```

---

## Seed data (optional)

After migration, insert the 8 seed tasks from `docs/migration-todo-prism.html`
into the DB via a Prisma seed script or manually — they are pre-populated in the
prototype's SEED_TASKS constant.

---

## Output

Write all files to `strata-personal/` mirroring the target repo paths.
Present all files when done.
Do not write to `strata_backend/` or `strata-frontend/` directly.
