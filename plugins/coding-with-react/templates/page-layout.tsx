// Root Layout Template
// Copy this to app/layout.tsx (Next.js) or adapt for React Router / Vite.
//
// What this demonstrates:
// - Metadata configuration for SEO (Next.js App Router)
// - Provider composition pattern — each layer has a specific responsibility
// - Suspense boundaries at the route level for streaming
// - ErrorBoundary wrapping dynamic content
// - Proper TypeScript types for layout props
// - Layer ordering rationale explained in comments
//
// Provider ordering (outermost to innermost):
// 1. ThemeProvider   — affects all visual rendering, must wrap everything
// 2. AuthProvider    — gates access, determines what content loads
// 3. QueryProvider   — data fetching, depends on auth for tokens
// 4. ErrorBoundary   — catches render errors in the page content
// 5. Suspense        — shows loading state while page content streams in
// 6. {children}      — the actual page component
//
// Each layer wraps the next because it provides context or error handling
// that the inner layers depend on. Changing the order would break things:
// e.g., QueryProvider needs auth tokens, so it must be inside AuthProvider.

import { Suspense, type ReactNode } from "react";
import type { Metadata } from "next";

// These imports reference the other templates in this project.
// Replace with your actual provider and component paths.
// import { ThemeProvider } from "@/context/theme-context";
// import { ErrorBoundary, ErrorFallback } from "@/components/error-boundary";

// -- Metadata ---------------------------------------------------------------

// Next.js App Router exports a Metadata object for SEO. This is statically
// analyzed at build time — no runtime overhead.
// For dynamic metadata (e.g., blog post titles), export generateMetadata() instead.
export const metadata: Metadata = {
  title: {
    // template: "%s | My App" means child pages can set just their title
    // and it automatically appends " | My App".
    template: "%s | My App",
    default: "My App",
  },
  description: "A modern React application",
  // Open Graph metadata for social sharing previews
  openGraph: {
    type: "website",
    locale: "en_US",
    siteName: "My App",
  },
};

// -- Provider wrappers ------------------------------------------------------

// Separating providers into a client component keeps the root layout as a
// Server Component (no "use client"), which allows metadata to be statically
// analyzed. Only the Providers component needs to be a client component.

// This would normally live in a separate file: components/providers.tsx
// "use client";
//
// import { ThemeProvider } from "@/context/theme-context";
// import { AuthProvider } from "@/context/auth-context";
// import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
// import { useState, type ReactNode } from "react";
//
// export function Providers({ children }: { children: ReactNode }) {
//   // useState ensures one QueryClient per component instance (not shared
//   // across requests during SSR, which would leak data between users).
//   const [queryClient] = useState(
//     () =>
//       new QueryClient({
//         defaultOptions: {
//           queries: {
//             // With SSR, we don't want to refetch on mount since data is fresh
//             staleTime: 60 * 1000,
//           },
//         },
//       }),
//   );
//
//   return (
//     <ThemeProvider defaultTheme="system">
//       <AuthProvider>
//         <QueryClientProvider client={queryClient}>
//           {children}
//         </QueryClientProvider>
//       </AuthProvider>
//     </ThemeProvider>
//   );
// }

// -- Loading fallback -------------------------------------------------------

/** Route-level loading indicator shown while the page component streams in. */
function PageSkeleton() {
  return (
    <div className="flex min-h-[50vh] items-center justify-center">
      <div className="h-8 w-8 animate-spin rounded-full border-4 border-gray-200 border-t-indigo-600" />
    </div>
  );
}

// -- Error fallback ---------------------------------------------------------

/** Route-level error fallback shown when the page component throws during render. */
function PageError({
  error,
  resetErrorBoundary,
}: {
  error: Error;
  resetErrorBoundary: () => void;
}) {
  return (
    <div className="flex min-h-[50vh] flex-col items-center justify-center gap-4">
      <h2 className="text-xl font-semibold text-red-800">
        Something went wrong
      </h2>
      <p className="text-sm text-red-600">{error.message}</p>
      <button
        onClick={resetErrorBoundary}
        className="rounded-md bg-red-600 px-4 py-2 text-sm text-white hover:bg-red-500"
      >
        Try again
      </button>
    </div>
  );
}

// -- Root Layout ------------------------------------------------------------

/**
 * The root layout wraps every page in the application.
 *
 * In Next.js App Router, this file is special:
 * - It must export a default function that renders <html> and <body>
 * - It's a Server Component by default (no "use client")
 * - It persists across navigations (not re-mounted on route changes)
 * - Metadata is statically extracted from the export above
 */
export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <html lang="en" suppressHydrationWarning>
      {/*
        suppressHydrationWarning on <html> prevents a mismatch warning when
        the theme provider adds a class to <html> on the client. The server
        doesn't know the user's theme preference, so the initial render may
        differ — this is expected and harmless.
      */}
      <body className="min-h-screen bg-white text-gray-900 antialiased dark:bg-gray-950 dark:text-gray-100">
        {/*
          Providers is a client component that wraps Theme, Auth, and Query
          providers. Keeping it separate lets this layout stay as a Server
          Component for metadata extraction.
        */}
        {/* <Providers> */}

        {/* Skip-to-content link for keyboard / screen reader users */}
        <a
          href="#main-content"
          className="sr-only focus:not-sr-only focus:fixed focus:left-4 focus:top-4 focus:z-50 focus:rounded-md focus:bg-white focus:px-4 focus:py-2 focus:shadow-lg"
        >
          Skip to content
        </a>

        {/* Navigation would go here */}
        {/* <Navbar /> */}

        <main id="main-content">
          {/*
              ErrorBoundary catches render errors in the page.
              Suspense shows PageSkeleton while the page streams in.
              Order: ErrorBoundary outside Suspense, so a thrown error
              shows the error UI rather than being stuck on the loader.
            */}
          {/* <ErrorBoundary fallback={(props) => <PageError {...props} />}> */}
          <Suspense fallback={<PageSkeleton />}>{children}</Suspense>
          {/* </ErrorBoundary> */}
        </main>

        {/* <Footer /> */}

        {/* </Providers> */}
      </body>
    </html>
  );
}

// -- React Router variant ---------------------------------------------------
//
// If you are using React Router (Vite, Remix) instead of Next.js App Router,
// the layout pattern is similar but without the metadata export:
//
//   // src/layouts/root-layout.tsx
//   import { Outlet } from "react-router-dom";
//   import { Providers } from "@/components/providers";
//
//   export function RootLayout() {
//     return (
//       <Providers>
//         <Navbar />
//         <main>
//           <Suspense fallback={<PageSkeleton />}>
//             <Outlet />   {/* React Router renders child routes here */}
//           </Suspense>
//         </main>
//         <Footer />
//       </Providers>
//     );
//   }
//
//   // In your router config:
//   const router = createBrowserRouter([
//     {
//       element: <RootLayout />,
//       errorElement: <RootErrorPage />,  // React Router's error boundary
//       children: [
//         { path: "/", element: <HomePage /> },
//         { path: "/about", element: <AboutPage /> },
//       ],
//     },
//   ]);
