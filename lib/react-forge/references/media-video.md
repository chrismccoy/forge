# Media and Video Performance

Load this file when a UI renders `<video>` or `<audio>` elements: preventing remounts, portals that move players, lazy-loading video, mobile video attributes, or many simultaneous decoders.

## Contents

- [Why Video Remounts Are Costly](#why-video-remounts-are-costly)
- [Preventing Video Remounting with Stable Keys](#preventing-video-remounting-with-stable-keys)
- [Ref-Based Video Element Management](#ref-based-video-element-management)
- [Memoizing Video Components](#memoizing-video-components)
- [Portal Lifecycle and Video Elements](#portal-lifecycle-and-video-elements)
- [Intersection Observer for Lazy Video Loading](#intersection-observer-for-lazy-video-loading)
- [Mobile-Specific Video Attributes](#mobile-specific-video-attributes)
- [Multiple Simultaneous Video Decoders](#multiple-simultaneous-video-decoders)

Video and audio elements require special attention in React because the browser's media pipeline is **stateful and expensive to initialize**. Unlike most DOM elements, a `<video>` element manages hardware decoder instances, buffered data, and playback state. When React unmounts and remounts a video element, the browser must tear down the entire decoder pipeline and restart it from scratch --- a process called **decoder churn**.

## Why Video Remounts Are Costly

A plain re-render does not touch the `<video>` DOM node: React reuses the element and only updates changed attributes. The element is destroyed and recreated (remounted) only when its `key` changes, when the element or component type at that position in the tree changes, or when a conditional moves it to a different place in the tree (for example, inline versus inside a portal).

Decoder churn is most visible on mobile devices, which have fewer hardware decoders, slower decoder initialization, and tighter battery budgets. A remount typically shows as a black frame or a restart of playback. Measure on the target devices with the browser Performance and Media panels rather than relying on generic numbers.

When a `<video>` element remounts, the browser:
1. Destroys the existing hardware decoder instance
2. Releases all buffered video data
3. Allocates a new decoder (may fail if device limit reached)
4. Re-fetches and re-buffers the video stream
5. Restarts playback from the beginning (or seeks back)

## Preventing Video Remounting with Stable Keys

The most common cause of video remounting is **unstable keys** or **conditional rendering** that changes the component tree structure:

```tsx
// BAD - index keys: when the filter changes, each <video> slot is reused for a
// different video, so its src changes and it reloads from scratch
function VideoFeed({ videos, filter }: Props) {
  const filtered = videos.filter(v => v.category === filter);

  return (
    <div>
      {filtered.map((video, index) => (
        // key={index} ties the DOM element to a position, not to a video
        <video key={index} src={video.src} />
      ))}
    </div>
  );
}

// GOOD - stable keys keep each video bound to its own element
function VideoFeed({ videos, filter }: Props) {
  const filtered = videos.filter(v => v.category === filter);

  return (
    <div>
      {filtered.map((video) => (
        // Stable ID keeps the same DOM element for the same video across re-renders
        <video key={video.id} src={video.src} />
      ))}
    </div>
  );
}
```

## Ref-Based Video Element Management

Use `useRef` to interact with video elements imperatively, avoiding state-driven patterns that trigger re-renders:

```tsx
import { useRef } from 'react';

function VideoPlayer({ src, poster }: { src: string; poster?: string }) {
  const videoRef = useRef<HTMLVideoElement>(null);

  // Imperative control: no state update, so no re-render
  const play = () => {
    videoRef.current?.play();
  };

  const pause = () => {
    videoRef.current?.pause();
  };

  const seek = (time: number) => {
    if (videoRef.current) {
      videoRef.current.currentTime = time;
    }
  };

  return (
    <div>
      <video
        ref={videoRef}
        src={src}
        poster={poster}
        playsInline
        preload="metadata"
        onPlay={() => {/* update UI without re-rendering video */}}
        onPause={() => {/* update UI without re-rendering video */}}
      />
      <button onClick={play}>Play</button>
      <button onClick={pause}>Pause</button>
    </div>
  );
}
```

## Memoizing Video Components

Re-renders do not remount a `<video>`, so memoization is not needed to protect playback. Consider `React.memo` only when the Profiler shows a list of video cards re-rendering often and those renders are costly (for example, a large feed where a parent updates frequently). In that case, memo works only if every non-primitive prop is stable, which is what the `useCallback`s below are for. With React Compiler enabled, skip this manual memoization.

```tsx
import { memo, useCallback, useRef } from 'react';

interface VideoCardProps {
  id: string;
  src: string;
  title: string;
  onPlay: (id: string) => void;
  onTimeUpdate: (id: string, time: number) => void;
}

const VideoCard = memo(function VideoCard({
  id,
  src,
  title,
  onPlay,
  onTimeUpdate,
}: VideoCardProps) {
  // Handlers inside the memoized card do not need useCallback; the <video>
  // is a DOM element, not a memoized component
  return (
    <div>
      <h3>{title}</h3>
      <video
        playsInline
        preload="metadata"
        onPlay={() => onPlay(id)}
        onTimeUpdate={(e) => onTimeUpdate(id, e.currentTarget.currentTime)}
      >
        <source src={src} type="video/mp4" />
      </video>
    </div>
  );
});

// Parent: callbacks are stable so the memo boundary on VideoCard holds
function VideoList({ videos }: { videos: Video[] }) {
  const progressRef = useRef(new Map<string, number>());

  const handlePlay = useCallback((id: string) => {
    console.log('Playing:', id);
  }, []);

  const handleTimeUpdate = useCallback((id: string, time: number) => {
    // Track progress in a ref; timeupdate fires several times per second
    progressRef.current.set(id, time);
  }, []);

  return (
    <div>
      {videos.map((video) => (
        <VideoCard
          key={video.id}
          id={video.id}
          src={video.src}
          title={video.title}
          onPlay={handlePlay}
          onTimeUpdate={handleTimeUpdate}
        />
      ))}
    </div>
  );
}
```

## Portal Lifecycle and Video Elements

Switching a video between inline rendering and a portal changes its position in the React tree, so React unmounts the old `<video>` and mounts a new one, destroying the decoder and playback state:

```tsx
import { useState, useRef, useLayoutEffect } from 'react';
import { createPortal } from 'react-dom';

// BAD - video remounts when switching between inline and modal
function VideoWithModal({ src }: { src: string }) {
  const [isModal, setIsModal] = useState(false);

  if (isModal) {
    return createPortal(
      <div className="modal">
        {/* This creates a NEW video element, losing playback state */}
        <video src={src} playsInline />
        <button onClick={() => setIsModal(false)}>Close</button>
      </div>,
      document.body
    );
  }

  return (
    <div>
      <video src={src} playsInline />
      <button onClick={() => setIsModal(true)}>Expand</button>
    </div>
  );
}

// GOOD - always render the video through one portal into a host node that is
// created once. React owns the video (inside the host) but never the host
// node itself, so the host can be moved between slots without React noticing.
function VideoWithModal({ src }: { src: string }) {
  const [isModal, setIsModal] = useState(false);
  // The host node is created on the client after mount; `document` does not
  // exist during server rendering, so never create it in render or a useState initializer
  const [videoHost, setVideoHost] = useState<HTMLDivElement | null>(null);
  const inlineSlotRef = useRef<HTMLDivElement>(null);
  const modalSlotRef = useRef<HTMLDivElement>(null);

  useLayoutEffect(() => {
    const host = document.createElement('div');
    setVideoHost(host);
    // Detach the host on unmount; React has already removed the video from it
    return () => host.remove();
  }, []);

  // Move the host (not a React-managed node) into the active slot before paint.
  // The move happens in the same task as the commit, so playback continues.
  useLayoutEffect(() => {
    if (!videoHost) return;
    const slot = isModal ? modalSlotRef.current : inlineSlotRef.current;
    slot?.appendChild(videoHost);
  }, [isModal, videoHost]);

  return (
    <>
      {/* Empty slot with no React children; only the host node is placed here */}
      <div ref={inlineSlotRef} />
      {!isModal && <button onClick={() => setIsModal(true)}>Expand</button>}

      {isModal &&
        createPortal(
          <div className="modal">
            <div ref={modalSlotRef} />
            <button onClick={() => setIsModal(false)}>Close</button>
          </div>,
          document.body
        )}

      {/* Same tree position on every render, so the <video> never remounts.
          Nothing renders here until the host exists on the client. */}
      {videoHost && createPortal(<video src={src} playsInline controls />, videoHost)}
    </>
  );
}
```

Never `appendChild` a node that React renders directly (such as the `<video>` itself): React still tracks it under its original parent and throws a `removeChild` error when it unmounts. Move only nodes React does not own, such as a portal container.

## Intersection Observer for Lazy Video Loading

On mobile, loading all videos simultaneously wastes bandwidth, drains battery, and can exhaust the device's limited hardware decoder slots. Use Intersection Observer to load and play videos only when visible:

```tsx
import { useRef, useEffect, useState } from 'react';

export function LazyVideo({
  src,
  title,
  poster,
  preloadMargin = '200px',
}: {
  src: string;
  title: string;
  poster?: string;
  preloadMargin?: string;
}) {
  const containerRef = useRef<HTMLDivElement>(null);
  const videoRef = useRef<HTMLVideoElement>(null);
  // isVisible stays true once the video has been near the viewport, so src is kept;
  // isInView tracks the current intersection and drives play/pause
  const [isVisible, setIsVisible] = useState(false);
  const [isInView, setIsInView] = useState(false);

  useEffect(() => {
    const container = containerRef.current;
    if (!container) return;

    const observer = new IntersectionObserver(
      ([entry]) => {
        setIsInView(entry.isIntersecting);
        if (entry.isIntersecting) setIsVisible(true);
      },
      {
        rootMargin: preloadMargin, // Start loading before fully visible
        threshold: 0.25,
      }
    );

    observer.observe(container);

    return () => observer.disconnect();
  }, [preloadMargin]);

  // Play or pause after React has committed the change. On the first
  // intersection this runs after `src` is on the element, so play() has a source.
  useEffect(() => {
    const video = videoRef.current;
    if (!video || !isVisible) return;

    if (isInView) {
      video.play().catch(() => {
        // Autoplay blocked by browser policy - this is expected
      });
    } else {
      // Pause when scrolled out of view to save resources
      video.pause();
    }
  }, [isVisible, isInView]);

  return (
    <div ref={containerRef} style={{ aspectRatio: '16/9' }}>
      <video
        ref={videoRef}
        aria-label={title} // Accessible name; also lets tests use getByLabelText
        // Only set src when near viewport to prevent premature loading
        src={isVisible ? src : undefined}
        poster={poster}
        playsInline
        muted
        loop
        preload={isVisible ? 'auto' : 'none'}
        style={{ width: '100%', height: '100%', objectFit: 'cover' }}
      />
    </div>
  );
}

// Usage in a feed - only visible videos consume decoder slots
function VideoFeed({ videos }: { videos: VideoItem[] }) {
  return (
    <div>
      {videos.map((video) => (
        <LazyVideo
          key={video.id}
          src={video.src}
          title={video.title}
          poster={video.poster}
        />
      ))}
    </div>
  );
}
```

## Mobile-Specific Video Attributes

Include `playsInline` on every inline video. Add the others when their behavior is wanted:

```tsx
<video
  ref={videoRef}
  src={src}
  playsInline          // Keeps playback inline instead of iOS Safari fullscreen takeover
  autoPlay             // Only for videos that should start on their own...
  muted                // ...which browsers allow only when muted
  preload="metadata"   // Load dimensions/duration only, not full video
  poster={posterUrl}   // Show image while video loads (saves bandwidth)
  controls
/>
```

- `muted` is required only for `autoPlay`. Leave it off for user-started playback with sound.
- `disablePictureInPicture` hides the picture-in-picture option; use it only when PiP would break the experience.
- `controlsList="nodownload noremoteplayback"` (or `nofullscreen`) trims the native control menu. It is Chromium-only, other browsers ignore it, and it is not a security control.

## Multiple Simultaneous Video Decoders

Mobile devices often support only a small number of simultaneous hardware video decoders, and the limit varies by device. Exceeding this limit causes videos to fall back to software decoding (slow, battery-draining) or fail entirely:

Keep the set of videos allowed to hold a decoder in state, and let each video derive its `src` from that state. Do not strip `src` from a React-rendered `<video>` with `removeAttribute`: React still believes the attribute is set and will not put it back when the video becomes active again.

```tsx
import { useEffect, useReducer, useRef, type Dispatch } from 'react';

// Limit active video decoders across the application; tune for your target devices
const MAX_ACTIVE_VIDEOS = 3;

type PoolAction = { type: 'activate' | 'deactivate'; id: string };

// Active ids in activation order; when the pool is full the oldest is evicted
function poolReducer(activeIds: string[], action: PoolAction): string[] {
  const rest = activeIds.filter((id) => id !== action.id);
  if (action.type === 'deactivate') return rest;
  return [...rest, action.id].slice(-MAX_ACTIVE_VIDEOS);
}

function PooledVideo({
  id,
  src,
  title,
  isActive,
  dispatch,
}: {
  id: string;
  src: string;
  title: string;
  isActive: boolean;
  dispatch: Dispatch<PoolAction>; // stable identity, safe as an effect dependency
}) {
  const videoRef = useRef<HTMLVideoElement>(null);

  // Request a decoder slot while visible, give it up when scrolled away
  useEffect(() => {
    const video = videoRef.current;
    if (!video) return;

    const observer = new IntersectionObserver(
      ([entry]) => {
        dispatch({ type: entry.isIntersecting ? 'activate' : 'deactivate', id });
      },
      { threshold: 0.25 }
    );
    observer.observe(video);

    return () => {
      observer.disconnect();
      dispatch({ type: 'deactivate', id });
    };
  }, [id, dispatch]);

  // Runs after React has added or removed `src`
  useEffect(() => {
    const video = videoRef.current;
    if (!video) return;

    if (isActive) {
      video.play().catch(() => {
        // Autoplay blocked by browser policy - this is expected
      });
    } else {
      video.pause();
      video.load(); // With src gone, load() resets the element and releases the decoder
    }
  }, [isActive]);

  return (
    <video
      ref={videoRef}
      aria-label={title}
      src={isActive ? src : undefined}
      playsInline
      muted
      loop
      preload="none"
      style={{ width: '100%', aspectRatio: '16/9' }}
    />
  );
}

function PooledVideoFeed({ videos }: { videos: VideoItem[] }) {
  const [activeIds, dispatch] = useReducer(poolReducer, []);

  return (
    <div>
      {videos.map((video) => (
        <PooledVideo
          key={video.id}
          id={video.id}
          src={video.src}
          title={video.title}
          isActive={activeIds.includes(video.id)}
          dispatch={dispatch}
        />
      ))}
    </div>
  );
}
```
