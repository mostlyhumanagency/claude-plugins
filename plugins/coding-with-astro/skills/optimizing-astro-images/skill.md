---
name: optimizing-astro-images
description: Use when working with images in Astro — the Image and Picture components from astro:assets, responsive images with layout prop, SVG components, remote image authorization, images in content collections with schema image() helper, getImage() for programmatic use, or image optimization configuration.
---

# Optimizing Images in Astro

## Overview

Astro provides built-in image optimization through the `astro:assets` module. The `Image` and `Picture` components produce optimized `<img>` and `<picture>` elements with automatic format conversion, responsive sizing, and Cumulative Layout Shift (CLS) prevention. Astro uses Sharp as its default image service for local and remote image processing.

## When to Use

- Displaying optimized images on Astro pages or components
- Serving images in multiple formats (WebP, AVIF)
- Generating responsive images with `srcset`
- Working with images in content collections
- Importing SVGs as interactive components
- Authorizing remote image domains for optimization
- Programmatically generating optimized image URLs with `getImage()`

## When Not to Use

- Images that must remain completely unprocessed -- place them in `public/` and use a standard `<img>` tag
- External image CDNs that already handle optimization -- use a standard `<img>` tag or a custom image service

## Image Storage Locations

| Location | Optimization | Use Case |
|---|---|---|
| `src/` (e.g., `src/assets/images/`) | Yes -- processed by Astro | Most images; lets Astro optimize, resize, and convert formats |
| `public/` | No -- served as-is | Favicons, OG images, or any file that must keep its exact path and format |
| Remote URLs | Yes -- if domain is authorized | Images hosted on external servers |

Images stored in `src/` are imported and passed to the `Image` or `Picture` component. Astro resolves dimensions automatically at build time.

Images in `public/` are referenced by URL string. Astro cannot determine their dimensions, so `width` and `height` must be provided manually.

## The Image Component

Import `Image` from `astro:assets`. Import local images from their file path. The `alt` attribute is always required.

### Local image

```astro
---
import { Image } from 'astro:assets';
import heroImage from '../assets/hero.jpg';
---

<Image src={heroImage} alt="A mountain landscape at sunrise" />
```

Astro infers `width` and `height` from the imported file. The output `<img>` tag includes these dimensions to prevent layout shift.

### Remote image

Remote images require explicit `width` and `height` because Astro cannot inspect the file at build time.

```astro
---
import { Image } from 'astro:assets';
---

<Image
  src="https://example.com/photos/landscape.jpg"
  alt="A mountain landscape at sunrise"
  width={1200}
  height={800}
/>
```

The remote domain must be authorized in `astro.config.mjs` (see Remote Image Authorization below).

### Image from public/

Files in `public/` are referenced by URL string and also require explicit dimensions.

```astro
---
import { Image } from 'astro:assets';
---

<Image
  src="/images/logo.png"
  alt="Company logo"
  width={200}
  height={60}
/>
```

### Common Image props

| Prop | Type | Required | Description |
|---|---|---|---|
| `src` | `ImageMetadata \| string` | Yes | Imported image or URL string |
| `alt` | `string` | Yes | Accessible alt text; use `alt=""` for decorative images |
| `width` | `number` | For remote/public images | Override or set the display width |
| `height` | `number` | For remote/public images | Override or set the display height |
| `format` | `string` | No | Output format: `webp`, `avif`, `png`, `jpg`, `svg` |
| `quality` | `number \| string` | No | Compression quality (0--100 or `low`, `mid`, `high`, `max`) |
| `densities` | `number[]` | No | Pixel densities for `srcset` generation, e.g., `[1.5, 2]` |
| `widths` | `number[]` | No | Explicit widths for `srcset` generation |
| `loading` | `"lazy" \| "eager"` | No | Defaults to `"lazy"` |
| `decoding` | `"async" \| "auto" \| "sync"` | No | Defaults to `"async"` |

All standard HTML `<img>` attributes (like `class`, `style`, `id`) are also supported and passed through.

### Overriding dimensions

You can override one dimension and Astro recalculates the other to preserve the aspect ratio.

```astro
---
import { Image } from 'astro:assets';
import photo from '../assets/photo.jpg';
---

<Image src={photo} width={600} alt="Resized photo" />
```

## The Picture Component

`Picture` generates a `<picture>` element with multiple `<source>` elements for different formats. The browser picks the best supported format.

```astro
---
import { Picture } from 'astro:assets';
import heroImage from '../assets/hero.jpg';
---

<Picture
  src={heroImage}
  formats={['avif', 'webp']}
  alt="A mountain landscape at sunrise"
/>
```

This produces a `<picture>` with an AVIF source, a WebP source, and a fallback `<img>` in the original format.

### Picture props

`Picture` accepts all the same props as `Image`, plus:

| Prop | Type | Default | Description |
|---|---|---|---|
| `formats` | `string[]` | `['webp']` | Output formats to generate sources for |
| `fallbackFormat` | `string` | Original format | Format for the fallback `<img>` |
| `pictureAttributes` | `HTMLAttributes` | -- | Attributes to apply to the outer `<picture>` element |

```astro
---
import { Picture } from 'astro:assets';
import banner from '../assets/banner.png';
---

<Picture
  src={banner}
  formats={['avif', 'webp']}
  fallbackFormat="png"
  pictureAttributes={{ class: 'hero-picture' }}
  alt="Site banner"
  class="hero-img"
/>
```

## Responsive Images

Astro supports responsive images with the `layout` prop on both `Image` and `Picture`. The `layout` prop controls how `srcset` and `sizes` are generated.

### layout: responsive (alias: constrained)

Scales the image up or down to fit its container, respecting the original aspect ratio, up to the original dimensions. Good for most content images.

```astro
---
import { Image } from 'astro:assets';
import photo from '../assets/photo.jpg';
---

<Image src={photo} alt="Responsive photo" layout="responsive" />
```

### layout: full-width

Scales to fill its container horizontally, maintaining aspect ratio. Ideal for hero images and banners.

```astro
---
import { Image } from 'astro:assets';
import hero from '../assets/hero.jpg';
---

<Image src={hero} alt="Full-width hero image" layout="full-width" />
```

### layout: fixed

Renders the image at its exact dimensions. Generates `srcset` for different pixel densities (1x, 2x) but does not scale.

```astro
---
import { Image } from 'astro:assets';
import icon from '../assets/icon.png';
---

<Image src={icon} alt="App icon" layout="fixed" width={64} height={64} />
```

### Global responsive image configuration

Set defaults for all images in `astro.config.mjs`:

```js
// astro.config.mjs
import { defineConfig } from 'astro/config';

export default defineConfig({
  image: {
    experimentalLayout: 'responsive',
  },
});
```

Individual components can override the global default by passing their own `layout` prop.

## SVG Components

Since Astro 5.x, `.svg` files can be imported as Astro components. The SVG markup is inlined, so you can style it with CSS and pass attributes as props.

```astro
---
import Logo from '../assets/logo.svg';
---

<Logo width={120} height={40} fill="currentColor" class="site-logo" />
```

Standard SVG attributes (`fill`, `stroke`, `width`, `height`, `viewBox`, etc.) and HTML attributes (`class`, `id`, `style`) can be passed as props.

The `aria-hidden` and `role` attributes are also supported for accessibility:

```astro
---
import Decoration from '../assets/decoration.svg';
---

<Decoration aria-hidden="true" class="bg-decoration" />
```

For SVGs that should not be interactive or inlined (e.g., very large files), place them in `public/` and reference them with a standard `<img>` tag instead.

## Remote Image Authorization

By default, Astro does not optimize remote images. To enable optimization for specific remote sources, configure `image.domains` and/or `image.remotePatterns` in `astro.config.mjs`.

### Authorizing specific domains

```js
// astro.config.mjs
import { defineConfig } from 'astro/config';

export default defineConfig({
  image: {
    domains: ['cdn.example.com', 'images.unsplash.com'],
  },
});
```

### Authorizing with patterns

For more granular control, use `remotePatterns` with protocol, hostname, port, and pathname:

```js
// astro.config.mjs
import { defineConfig } from 'astro/config';

export default defineConfig({
  image: {
    remotePatterns: [
      {
        protocol: 'https',
        hostname: '**.example.com',
      },
      {
        protocol: 'https',
        hostname: 'cdn.photos.net',
        pathname: '/public/**',
      },
    ],
  },
});
```

`**` in `hostname` matches any subdomain. `**` in `pathname` matches any path segment.

Authorized remote images can then be used without `width` and `height` if the image service can infer them, but providing dimensions explicitly is still recommended for CLS prevention.

## Images in Content Collections

Use the `image()` schema helper from `astro:content` to validate frontmatter image paths and produce resolved `ImageMetadata` objects.

### Defining the schema

```ts
// src/content.config.ts
import { defineCollection, z } from 'astro:content';
import { glob } from 'astro/loaders';

const blog = defineCollection({
  loader: glob({ pattern: '**/*.md', base: './src/content/blog' }),
  schema: ({ image }) =>
    z.object({
      title: z.string(),
      cover: image(),
      coverAlt: z.string(),
    }),
});

export const collections = { blog };
```

The `image()` helper validates that the path resolves to a real image file and transforms it into `ImageMetadata` at build time.

### Frontmatter in the content file

```markdown
---
title: My Blog Post
cover: ./images/post-cover.jpg
coverAlt: A sunset over the ocean
---

Post content here.
```

The path is relative to the content file's location.

### Rendering in a layout

```astro
---
import { Image } from 'astro:assets';
import { getEntry } from 'astro:content';

const post = await getEntry('blog', Astro.params.slug);
const { title, cover, coverAlt } = post.data;
---

<Image src={cover} alt={coverAlt} />
```

Because `cover` is now an `ImageMetadata` object (not a string), it works directly as the `src` prop and Astro knows its dimensions.

## Images in Markdown and MDX

### Standard Markdown

Use standard Markdown image syntax. Images relative to the Markdown file in `src/` are resolved and optimized.

```markdown
![A cat sitting on a windowsill](./images/cat.jpg)
```

For images in `public/`, use an absolute path:

```markdown
![Logo](/images/logo.png)
```

### MDX

In `.mdx` files, you can use either Markdown syntax or import images and use the `Image` component directly:

```mdx
---
title: My MDX Post
---

import { Image } from 'astro:assets';
import diagram from './images/diagram.png';

Here is the architecture diagram:

<Image src={diagram} alt="System architecture diagram" />
```

## Images in Framework Components

When using images inside React, Vue, Svelte, or Solid components, import the image in the Astro parent and pass the `src` property (a URL string) to the framework component.

### Astro parent

```astro
---
import { Image } from 'astro:assets';
import photo from '../assets/photo.jpg';
import PhotoCard from '../components/PhotoCard.jsx';
---

<!-- Use Image component directly in Astro -->
<Image src={photo} alt="A scenic photo" />

<!-- Pass to a React component: use .src for the URL string -->
<PhotoCard src={photo.src} width={photo.width} height={photo.height} alt="A scenic photo" />
```

### React component

```jsx
// src/components/PhotoCard.jsx
export default function PhotoCard({ src, width, height, alt }) {
  return (
    <div className="photo-card">
      <img src={src} width={width} height={height} alt={alt} loading="lazy" />
    </div>
  );
}
```

The `.src` property on an imported image contains the resolved URL string after optimization. The `.width` and `.height` properties are also available.

## getImage() for Programmatic Use

`getImage()` generates an optimized image and returns its metadata without rendering an HTML element. Useful for API routes, generating OG images, or building custom image components.

```astro
---
import { getImage } from 'astro:assets';
import background from '../assets/background.jpg';

const optimized = await getImage({
  src: background,
  width: 1920,
  format: 'webp',
  quality: 80,
});
---

<div style={`background-image: url(${optimized.src}); width: ${optimized.attributes.width}px; height: ${optimized.attributes.height}px;`}>
  <slot />
</div>
```

### getImage() return value

| Property | Type | Description |
|---|---|---|
| `src` | `string` | The resolved URL of the optimized image |
| `attributes` | `object` | HTML attributes including `width`, `height`, `src`, `srcset` |
| `rawOptions` | `object` | The original options passed to `getImage()` |

### Using getImage() in an endpoint

```ts
// src/pages/og/[slug].png.ts
import type { APIRoute } from 'astro';
import { getImage } from 'astro:assets';
import ogTemplate from '../../assets/og-template.png';

export const GET: APIRoute = async ({ params }) => {
  const image = await getImage({
    src: ogTemplate,
    width: 1200,
    height: 630,
    format: 'png',
  });

  return new Response(null, {
    headers: { Location: image.src },
    status: 302,
  });
};
```

## Custom Image Components

Wrap the built-in `Image` component to enforce defaults across a project.

```astro
---
// src/components/OptimizedImage.astro
import { Image } from 'astro:assets';
import type { ImageMetadata } from 'astro';

interface Props {
  src: ImageMetadata | string;
  alt: string;
  width?: number;
  height?: number;
  class?: string;
}

const { src, alt, width, height, class: className } = Astro.props;
---

<Image
  src={src}
  alt={alt}
  width={width}
  height={height}
  format="webp"
  quality="mid"
  loading="lazy"
  decoding="async"
  class={className}
/>
```

Use it throughout the project:

```astro
---
import OptimizedImage from '../components/OptimizedImage.astro';
import photo from '../assets/photo.jpg';
---

<OptimizedImage src={photo} alt="A scenic photo" class="rounded" />
```

## Accessibility

The `alt` attribute is required on both `Image` and `Picture`. Astro will throw a build error if `alt` is omitted.

- **Informative images**: Describe the content or function of the image. Example: `alt="A bar chart showing quarterly revenue growth"`.
- **Decorative images**: Use an empty string. Example: `alt=""`. The image is then ignored by screen readers.
- **Linked images**: Describe the link destination if no other text is present. Example: `alt="Go to homepage"`.

```astro
---
import { Image } from 'astro:assets';
import divider from '../assets/divider.svg';
import chart from '../assets/chart.png';
---

<!-- Decorative: empty alt -->
<Image src={divider} alt="" />

<!-- Informative: descriptive alt -->
<Image src={chart} alt="Bar chart showing Q3 revenue increased 15% over Q2" />
```

## Image Service Configuration

Astro uses Sharp by default. Configuration is set in `astro.config.mjs` under the `image` key.

### Configuring the Sharp service

```js
// astro.config.mjs
import { defineConfig } from 'astro/config';

export default defineConfig({
  image: {
    service: {
      entrypoint: 'astro/assets/services/sharp',
      config: {
        limitInputPixels: false,
      },
    },
  },
});
```

### Setting default format and quality globally

```js
// astro.config.mjs
import { defineConfig } from 'astro/config';

export default defineConfig({
  image: {
    service: {
      entrypoint: 'astro/assets/services/sharp',
      config: {
        png: { quality: 80 },
        jpeg: { quality: 80 },
        webp: { quality: 80 },
        avif: { quality: 60 },
      },
    },
  },
});
```

### Disabling image optimization

For environments where Sharp is not available (some serverless platforms), use the no-op passthrough service:

```js
// astro.config.mjs
import { defineConfig } from 'astro/config';

export default defineConfig({
  image: {
    service: {
      entrypoint: 'astro/assets/services/noop',
    },
  },
});
```

## Caching

Astro caches optimized images in `node_modules/.astro/` during development and in the build output during production builds. The cache key is based on the source file contents and transformation options. If the source image or options change, a new optimized variant is generated.

To clear the cache during development, delete `node_modules/.astro/`.

```bash
rm -rf node_modules/.astro
```

For production, each build generates fresh optimized images. If using an SSR adapter, the image service processes images on-demand per request, and caching depends on the hosting platform's cache headers.
