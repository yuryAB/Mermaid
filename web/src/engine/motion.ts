import type { Direction, MovementMode } from './types';

export const movementDistances: Record<Exclude<MovementMode, 'idle'>, number> = {
  swing: 200,
  fast: 500
};

export function velocityForDirection(direction: Direction, distancePerSecond: number) {
  switch (direction) {
    case 'up':
      return { x: 0, y: -distancePerSecond };
    case 'down':
      return { x: 0, y: distancePerSecond };
    case 'right':
      return { x: distancePerSecond, y: 0 };
    case 'left':
      return { x: -distancePerSecond, y: 0 };
    case 'none':
      return { x: 0, y: 0 };
  }
}

export class MermaidMotionController {
  movementMode: MovementMode = 'idle';
  direction: Direction = 'none';
  distanceToTravel = 200;

  setMovementMode(mode: MovementMode) {
    this.movementMode = mode;
    if (mode === 'idle') {
      this.direction = 'none';
      return;
    }
    this.distanceToTravel = movementDistances[mode];
  }

  setDirection(direction: Direction) {
    this.direction = direction;
  }

  velocity() {
    return velocityForDirection(this.direction, this.distanceToTravel);
  }
}
