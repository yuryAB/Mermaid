import { Application } from 'pixi.js';
import { useEffect, useMemo, useRef, useState, type CSSProperties } from 'react';
import { palette } from '../generated/palette';
import { MermaidRig } from '../engine/mermaid-rig';
import type { Direction, MermaidRigApi, MovementMode, ThemeName } from '../engine/types';

type RuntimeState = ReturnType<MermaidRig['getState']>;

const directions: Array<{ id: Direction; label: string; className: string }> = [
  { id: 'up', label: '↑', className: 'pad-up' },
  { id: 'left', label: '←', className: 'pad-left' },
  { id: 'right', label: '→', className: 'pad-right' },
  { id: 'down', label: '↓', className: 'pad-down' }
];

const modeLabels: Record<MovementMode, string> = {
  idle: 'Calm',
  swing: 'Swim',
  fast: 'Fast'
};

const themeLabels: Record<ThemeName, string> = {
  upper: 'Sunlit',
  main: 'Coral',
  abyss: 'Abyss'
};

const keyDirection: Record<string, Direction> = {
  ArrowUp: 'up',
  w: 'up',
  W: 'up',
  ArrowDown: 'down',
  s: 'down',
  S: 'down',
  ArrowLeft: 'left',
  a: 'left',
  A: 'left',
  ArrowRight: 'right',
  d: 'right',
  D: 'right'
};

export function MermaidExperience() {
  const hostRef = useRef<HTMLDivElement | null>(null);
  const appRef = useRef<Application | null>(null);
  const rigRef = useRef<MermaidRig | null>(null);
  const [ready, setReady] = useState(false);
  const [state, setState] = useState<RuntimeState | null>(null);
  const debug = useMemo(() => new URLSearchParams(window.location.search).has('debug'), []);
  const stableVisuals = useMemo(() => new URLSearchParams(window.location.search).has('stable'), []);

  useEffect(() => {
    let cancelled = false;
    const host = hostRef.current;
    if (!host) return;

    const boot = async () => {
      const app = new Application();
      await app.init({
        resizeTo: host,
        backgroundAlpha: 0,
        antialias: true,
        autoDensity: true,
        resolution: Math.min(window.devicePixelRatio || 1, 2)
      });
      if (cancelled) {
        app.destroy(true);
        return;
      }
      app.canvas.className = 'mermaid-canvas';
      app.canvas.dataset.testid = 'mermaid-canvas';
      host.appendChild(app.canvas);
      appRef.current = app;

      const rig = await MermaidRig.create(app, {
        onStateChange: () => setState(rigRef.current?.getState() ?? null),
        stableVisuals
      });
      if (cancelled) {
        rig.destroy();
        app.destroy(true);
        return;
      }
      rigRef.current = rig;
      setState(rig.getState());
      setReady(true);
      window.__MERMAID_RIG__ = {
        setMovementMode: (mode) => rig.setMovementMode(mode),
        setDirection: (direction) => rig.setDirection(direction),
        setZoom: (scale) => rig.setZoom(scale),
        setTheme: (theme) => rig.setTheme(theme),
        startAutoDirection: () => rig.startAutoDirection(),
        stopAutoDirection: () => rig.stopAutoDirection(),
        getState: () => rig.getState(),
        destroy: () => rig.destroy()
      };
    };

    boot();
    return () => {
      cancelled = true;
      delete window.__MERMAID_RIG__;
      rigRef.current?.destroy();
      appRef.current?.destroy(true);
      rigRef.current = null;
      appRef.current = null;
    };
  }, []);

  useEffect(() => {
    const activeKeys = new Map<string, Direction>();
    const applyActiveDirection = () => {
      const nextDirection = Array.from(activeKeys.values()).at(-1) ?? 'none';
      if (rigRef.current?.getState().direction === nextDirection) return;
      rigRef.current?.setDirection(nextDirection);
      setState(rigRef.current?.getState() ?? null);
    };
    const onKeyDown = (event: KeyboardEvent) => {
      const direction = keyDirection[event.key];
      if (!direction) return;
      event.preventDefault();
      const alreadyActive = activeKeys.has(event.key);
      activeKeys.set(event.key, direction);
      if (event.repeat && alreadyActive) return;
      applyActiveDirection();
    };
    const onKeyUp = (event: KeyboardEvent) => {
      if (!keyDirection[event.key]) return;
      activeKeys.delete(event.key);
      applyActiveDirection();
    };
    window.addEventListener('keydown', onKeyDown);
    window.addEventListener('keyup', onKeyUp);
    return () => {
      window.removeEventListener('keydown', onKeyDown);
      window.removeEventListener('keyup', onKeyUp);
    };
  }, []);

  useEffect(() => {
    const background = palette.waters[state?.depthZone ?? 'mid'];
    document.documentElement.style.setProperty('--water-p3', background.p3);
    document.documentElement.style.setProperty('--water-rgb', background.rgb);
  }, [state?.depthZone]);

  const rigAction = (fn: (rig: MermaidRigApi) => void) => {
    const rig = rigRef.current;
    if (!rig) return;
    fn(rig);
    setState(rig.getState());
  };

  return (
    <main className="experience-shell" aria-busy={!ready}>
      <div className="scene-host" ref={hostRef} />
      <div className="surface-vignette" aria-hidden="true" />
      <div className="top-bar">
        <div className="brand-mark" aria-label="Mermaid">
          <span className="brand-title">Mermaid</span>
          <span className="brand-status">{state?.movementMode ?? 'loading'}</span>
        </div>
        <div className="theme-switcher" aria-label="Theme">
          {(Object.keys(themeLabels) as ThemeName[]).map((theme) => (
            <button
              key={theme}
              type="button"
              className="swatch-button"
              aria-label={themeLabels[theme]}
              aria-pressed={state?.themeName === theme}
              style={{
                '--swatch-hair': palette.themes[theme].hairColor.p3,
                '--swatch-tail': palette.themes[theme].vibrant2.p3
              } as CSSProperties}
              onClick={() => rigAction((rig) => rig.setTheme(theme))}
            />
          ))}
        </div>
      </div>

      <div className="control-dock" aria-label="Movement controls">
        <div className="direction-pad">
          {directions.map((direction) => (
            <button
              key={direction.id}
              type="button"
              className={`icon-button ${direction.className}`}
              aria-label={direction.id}
              onPointerDown={(event) => {
                event.currentTarget.setPointerCapture(event.pointerId);
                rigAction((rig) => rig.setDirection(direction.id));
              }}
              onPointerUp={() => rigAction((rig) => rig.setDirection('none'))}
              onPointerCancel={() => rigAction((rig) => rig.setDirection('none'))}
              onLostPointerCapture={() => rigAction((rig) => rig.setDirection('none'))}
            >
              {direction.label}
            </button>
          ))}
        </div>

        <div className="mode-segment" aria-label="Swim mode">
          {(Object.keys(modeLabels) as MovementMode[]).map((mode) => (
            <button
              key={mode}
              type="button"
              className="mode-button"
              aria-pressed={state?.movementMode === mode}
              onClick={() => rigAction((rig) => rig.setMovementMode(mode))}
            >
              {modeLabels[mode]}
            </button>
          ))}
        </div>
      </div>

      {!ready && <div className="loading-mark">Loading</div>}

      {debug && state && (
        <div className="debug-panel">
          <div>{state.direction}</div>
          <div>{state.distanceToTravel}px/s</div>
          <div className="zoom-row">
            {[1.2, 5, 9].map((zoom) => (
              <button key={zoom} type="button" onClick={() => rigAction((rig) => rig.setZoom(zoom))}>
                {zoom}
              </button>
            ))}
          </div>
        </div>
      )}
    </main>
  );
}

declare global {
  interface Window {
    __MERMAID_RIG__?: MermaidRigApi;
  }
}
