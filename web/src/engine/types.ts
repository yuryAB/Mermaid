import type { DepthZone as GeneratedDepthZone, ThemeName as GeneratedThemeName } from '../generated/palette';

export type MovementMode = 'idle' | 'swing' | 'fast';
export type Direction = 'up' | 'down' | 'right' | 'left' | 'none';
export type DepthZone = GeneratedDepthZone;
export type ThemeName = GeneratedThemeName;

export type MermaidRigApi = {
  setMovementMode(mode: MovementMode): void;
  setDirection(direction: Direction): void;
  setZoom(scale: 1.2 | 5 | 9 | number): void;
  setTheme(theme: ThemeName): void;
  startAutoDirection(): void;
  stopAutoDirection(): void;
  getState?(): {
    movementMode: MovementMode;
    direction: Direction;
    distanceToTravel: number;
    themeName: ThemeName;
    depthZone: DepthZone;
    zoom: number;
    autoDirectionActive: boolean;
  };
  destroy(): void;
};
