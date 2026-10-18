# Testing Media Components

Load this file when testing video or audio components: mocking `play()`/`pause()`/`load()` and media properties in jsdom, asserting playback state transitions, mocking IntersectionObserver for lazy-loaded media, and firing media events such as `timeupdate`, `loadedmetadata`, and `error`. The matching performance guidance (lazy loading, preload, and playback cost) is in [media-video.md](media-video.md); general test setup and principles are in [testing.md](testing.md).

## Contents

- [Mocking HTMLMediaElement in jsdom](#mocking-htmlmediaelement-in-jsdom)
- [Testing Video State Transitions](#testing-video-state-transitions)
- [Mocking IntersectionObserver for Lazy-Loaded Video](#mocking-intersectionobserver-for-lazy-loaded-video)
- [Testing Video Event Handlers](#testing-video-event-handlers)

## Mocking HTMLMediaElement in jsdom

jsdom does not implement the HTML5 media API. Methods like `play()`, `pause()`, and `load()` throw "Not implemented" errors. Mock them in the shared test setup file:

```typescript
// src/test/setup.ts (add to existing setup file)
import { vi } from 'vitest';

// Mock HTMLMediaElement methods not implemented by jsdom
Object.defineProperty(window.HTMLMediaElement.prototype, 'play', {
  configurable: true,
  value: vi.fn().mockResolvedValue(undefined),
});

Object.defineProperty(window.HTMLMediaElement.prototype, 'pause', {
  configurable: true,
  value: vi.fn(),
});

Object.defineProperty(window.HTMLMediaElement.prototype, 'load', {
  configurable: true,
  value: vi.fn(),
});

// Mock read-only media properties
Object.defineProperty(window.HTMLMediaElement.prototype, 'duration', {
  configurable: true,
  get() { return 120; }, // 2 minutes
});

Object.defineProperty(window.HTMLMediaElement.prototype, 'paused', {
  configurable: true,
  writable: true,
  value: true,
});
```

## Testing Video State Transitions

```tsx
// VideoPlayer.tsx
import { useRef, useState } from 'react';

type VideoEvent = React.SyntheticEvent<HTMLVideoElement>;

interface VideoPlayerProps {
  src: string;
  onPlay?: () => void;
  onPause?: () => void;
  onEnded?: () => void;
  onTimeUpdate?: (event: VideoEvent) => void;
  onLoadedMetadata?: (event: VideoEvent) => void;
  onError?: (event: VideoEvent) => void;
}

export function VideoPlayer({
  src,
  onPlay,
  onPause,
  onEnded,
  onTimeUpdate,
  onLoadedMetadata,
  onError,
}: VideoPlayerProps) {
  const videoRef = useRef<HTMLVideoElement>(null);
  const [status, setStatus] = useState<'idle' | 'loading' | 'playing' | 'paused' | 'ended' | 'error'>('idle');

  const togglePlayback = () => {
    const video = videoRef.current;
    if (!video) return;
    if (video.paused) {
      video.play();
    } else {
      video.pause();
    }
  };

  return (
    <div>
      <video
        ref={videoRef}
        src={src}
        // <video> has no implicit ARIA role, so a test ID is the practical query here
        data-testid="video-element"
        onLoadedMetadata={(e) => {
          setStatus('idle');
          onLoadedMetadata?.(e);
        }}
        onPlay={() => {
          setStatus('playing');
          onPlay?.();
        }}
        onPause={() => {
          setStatus('paused');
          onPause?.();
        }}
        onEnded={() => {
          setStatus('ended');
          onEnded?.();
        }}
        onTimeUpdate={onTimeUpdate}
        onError={(e) => {
          setStatus('error');
          onError?.(e);
        }}
        onWaiting={() => setStatus('loading')}
        playsInline
      />
      <button onClick={togglePlayback}>
        {status === 'playing' ? 'Pause' : 'Play'}
      </button>
      <span data-testid="status">{status}</span>
    </div>
  );
}
```

```tsx
// VideoPlayer.test.tsx
import { render, screen, fireEvent } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { VideoPlayer } from './VideoPlayer';

describe('VideoPlayer', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('renders video element with correct src', () => {
    render(<VideoPlayer src="test-video.mp4" />);
    const video = screen.getByTestId('video-element') as HTMLVideoElement;
    expect(video).toBeInTheDocument();
    expect(video).toHaveAttribute('src', 'test-video.mp4');
  });

  it('calls play() on the video element when Play button is clicked', async () => {
    const user = userEvent.setup();
    render(<VideoPlayer src="test-video.mp4" />);

    const playButton = screen.getByRole('button', { name: /play/i });
    await user.click(playButton);

    const video = screen.getByTestId('video-element') as HTMLVideoElement;
    expect(video.play).toHaveBeenCalled();
  });

  it('transitions to playing state on play event', () => {
    render(<VideoPlayer src="test-video.mp4" />);
    const video = screen.getByTestId('video-element');

    fireEvent.play(video);

    expect(screen.getByTestId('status')).toHaveTextContent('playing');
  });

  it('transitions to paused state on pause event', () => {
    render(<VideoPlayer src="test-video.mp4" />);
    const video = screen.getByTestId('video-element');

    fireEvent.play(video);
    expect(screen.getByTestId('status')).toHaveTextContent('playing');

    fireEvent.pause(video);
    expect(screen.getByTestId('status')).toHaveTextContent('paused');
  });

  it('transitions to ended state on ended event', () => {
    render(<VideoPlayer src="test-video.mp4" />);
    const video = screen.getByTestId('video-element');

    fireEvent.play(video);
    fireEvent.ended(video);

    expect(screen.getByTestId('status')).toHaveTextContent('ended');
  });

  it('calls onPlay callback when video starts playing', () => {
    const handlePlay = vi.fn();
    render(<VideoPlayer src="test-video.mp4" onPlay={handlePlay} />);

    fireEvent.play(screen.getByTestId('video-element'));

    expect(handlePlay).toHaveBeenCalledTimes(1);
  });

  it('calls onEnded callback when video finishes', () => {
    const handleEnded = vi.fn();
    render(<VideoPlayer src="test-video.mp4" onEnded={handleEnded} />);

    fireEvent.ended(screen.getByTestId('video-element'));

    expect(handleEnded).toHaveBeenCalledTimes(1);
  });

  it('shows loading state during buffering', () => {
    render(<VideoPlayer src="test-video.mp4" />);

    fireEvent.waiting(screen.getByTestId('video-element'));

    expect(screen.getByTestId('status')).toHaveTextContent('loading');
  });
});
```

## Mocking IntersectionObserver for Lazy-Loaded Video

```tsx
// src/test/mocks/intersection-observer.ts
import { vi } from 'vitest';

export function mockIntersectionObserver() {
  const observerMap = new Map<Element, (entries: IntersectionObserverEntry[]) => void>();

  // Use a `function` implementation (not an arrow function): the component calls
  // `new IntersectionObserver(...)`, and Vitest 3+/4 mocks must be constructible.
  // Returning an object from a constructor makes `new` produce that object.
  const MockIntersectionObserver = vi.fn(function (callback: IntersectionObserverCallback) {
    return {
      observe: vi.fn((element: Element) => {
        observerMap.set(element, (entries) => callback(entries, {} as IntersectionObserver));
      }),
      unobserve: vi.fn((element: Element) => {
        observerMap.delete(element);
      }),
      disconnect: vi.fn(() => {
        observerMap.clear();
      }),
    };
  });

  window.IntersectionObserver = MockIntersectionObserver as any;

  // Helper to simulate an element entering the viewport
  function simulateIntersection(element: Element, isIntersecting: boolean) {
    const callback = observerMap.get(element);
    if (callback) {
      callback([{ isIntersecting, target: element } as IntersectionObserverEntry]);
    }
  }

  return { MockIntersectionObserver, simulateIntersection };
}
```

The `LazyVideo` component under test is defined in [media-video.md](media-video.md).

```tsx
// LazyVideo.test.tsx
import { render, screen, act } from '@testing-library/react';
import { describe, it, expect, beforeEach, vi } from 'vitest';
import { LazyVideo } from './LazyVideo';
import { mockIntersectionObserver } from '../test/mocks/intersection-observer';

describe('LazyVideo', () => {
  let simulateIntersection: (element: Element, isIntersecting: boolean) => void;

  beforeEach(() => {
    vi.clearAllMocks(); // play/pause mocks live on the shared prototype
    const mock = mockIntersectionObserver();
    simulateIntersection = mock.simulateIntersection;
  });

  // LazyVideo (see media-video.md) labels the <video> with its title and
  // observes the video's parent container
  function renderLazyVideo() {
    render(<LazyVideo src="lazy-video.mp4" title="Demo clip" />);
    const video = screen.getByLabelText('Demo clip') as HTMLVideoElement;
    return { video, container: video.parentElement! };
  }

  it('does not load video source until visible', () => {
    const { video } = renderLazyVideo();

    // Video should not have src set yet
    expect(video).not.toHaveAttribute('src');
  });

  it('loads video source when element enters viewport', () => {
    const { video, container } = renderLazyVideo();

    act(() => {
      simulateIntersection(container, true);
    });

    expect(video).toHaveAttribute('src', 'lazy-video.mp4');
  });

  it('pauses video when scrolled out of viewport', () => {
    const { video, container } = renderLazyVideo();

    // Simulate entering viewport
    act(() => {
      simulateIntersection(container, true);
    });

    // Simulate leaving viewport
    act(() => {
      simulateIntersection(container, false);
    });

    expect(video.pause).toHaveBeenCalled();
  });
});
```

## Testing Video Event Handlers

```tsx
// Test onTimeUpdate and onLoadedMetadata handlers
import { render, screen, fireEvent } from '@testing-library/react';
import { describe, it, expect, vi } from 'vitest';
import { VideoPlayer } from './VideoPlayer';

describe('Video event handlers', () => {
  it('handles onTimeUpdate events', () => {
    const handleTimeUpdate = vi.fn();
    render(
      <VideoPlayer src="test.mp4" onTimeUpdate={handleTimeUpdate} />
    );

    const video = screen.getByTestId('video-element');

    // Simulate time update with a specific currentTime
    Object.defineProperty(video, 'currentTime', {
      writable: true,
      value: 30.5,
    });

    fireEvent.timeUpdate(video);

    expect(handleTimeUpdate).toHaveBeenCalled();
  });

  it('handles onLoadedMetadata to get video dimensions and duration', () => {
    const handleMetadata = vi.fn();
    render(
      <VideoPlayer src="test.mp4" onLoadedMetadata={handleMetadata} />
    );

    const video = screen.getByTestId('video-element');

    // Set video metadata properties before firing event
    Object.defineProperty(video, 'videoWidth', { value: 1920 });
    Object.defineProperty(video, 'videoHeight', { value: 1080 });
    Object.defineProperty(video, 'duration', { value: 120 });

    fireEvent.loadedMetadata(video);

    expect(handleMetadata).toHaveBeenCalled();
  });

  it('handles onError events', () => {
    const handleError = vi.fn();
    render(
      <VideoPlayer src="nonexistent.mp4" onError={handleError} />
    );

    const video = screen.getByTestId('video-element');
    fireEvent.error(video);

    expect(handleError).toHaveBeenCalled();
  });
});
```
