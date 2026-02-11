---
name: masking-tanstack-router-routes
description: Use when working with TanStack Router route masking — displaying a different URL than the actual route, mask option on Link or navigate, createRouteMask for declarative masking, routeMasks in createRouter, unmaskOnReload option, modal and overlay URL patterns, or hiding search params from the URL bar.
---

# Route Masking

Route masking displays a different URL in the browser than the actual route being rendered. Useful for modals, overlays, and cleaner URLs.

## Use Cases

- Show `/photos/5` while rendering `/photos/5/modal`
- Display `/posts/5` while accessing `/posts/5/comments`
- Hide search params like `?modal=settings` → show `/settings`
- Show clean URLs for complex internal routing

## How It Works

The real location is stored in `location.state.__tempLocation`. The browser shows the masked URL. When a masked URL is shared (copied/pasted), the mask is lost — the user sees the real route.

## Imperative Masking (on Link)

```tsx
<Link
  to="/photos/$photoId/modal"
  params={{ photoId: '5' }}
  mask={{
    to: '/photos/$photoId',
    params: { photoId: '5' },
  }}
>
  Open Photo
</Link>
```

With `navigate()`:

```tsx
navigate({
  to: '/photos/$photoId/modal',
  params: { photoId: '5' },
  mask: {
    to: '/photos/$photoId',
    params: { photoId: '5' },
  },
})
```

## Declarative Masking (on Router)

Define masks globally with `createRouteMask`:

```tsx
import { createRouteMask, createRouter } from '@tanstack/react-router'

const photoModalMask = createRouteMask({
  routeTree,
  from: '/photos/$photoId/modal',
  to: '/photos/$photoId',
  params: (prev) => ({ photoId: prev.photoId }),
})

const router = createRouter({
  routeTree,
  routeMasks: [photoModalMask],
})
```

Now ALL navigations to `/photos/$photoId/modal` are automatically masked.

## Masking Search Params

Hide query strings from the URL:

```tsx
<Link
  to="/dashboard"
  search={{ modal: 'settings', tab: 'profile' }}
  mask={{ to: '/settings' }}
>
  Settings
</Link>
// Browser shows /settings, but actually renders /dashboard?modal=settings&tab=profile
```

## Unmasking Behavior

### URL Sharing

Masked URLs automatically unmask when shared — the mask data only exists in the local browser history. Pasting a masked URL navigates to the masked route, not the real one.

### Page Reload

By default, masks persist through local page reloads. To unmask on reload:

```tsx
// Per-mask
const mask = createRouteMask({
  ...options,
  unmaskOnReload: true,
})

// Per-navigation
<Link mask={{ to: '/photos/5', unmaskOnReload: true }}>

// Global default
const router = createRouter({
  routeTree,
  defaultUnmaskOnReload: true,
})
```

## Modal Pattern Example

```tsx
// Route: /photos/$photoId/modal — renders a modal overlay
export const Route = createFileRoute('/photos/$photoId/modal')({
  component: () => {
    const { photoId } = Route.useParams()
    return (
      <div className="modal-overlay">
        <PhotoDetail id={photoId} />
        <Link to="/photos/$photoId" params={{ photoId }}>Close</Link>
      </div>
    )
  },
})

// Mask: browser shows /photos/5 while modal is open
const photoModalMask = createRouteMask({
  routeTree,
  from: '/photos/$photoId/modal',
  to: '/photos/$photoId',
  params: (prev) => ({ photoId: prev.photoId }),
})
```

## Accessing Mask Info

The original masked location is available at `location.maskedLocation` — useful for DevTools debugging.

## Common Mistakes

- Expecting masked URLs to survive sharing — masks are local to the browser history
- Not handling the unmasked route — users who paste the masked URL navigate to that route, not the real one
- Over-masking — if the URL structure is confusing, consider simplifying routes instead
- Forgetting `unmaskOnReload` when masks should be temporary
