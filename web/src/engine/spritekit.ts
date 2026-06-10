import { DEG_TO_RAD } from 'pixi.js';

export function skY(y: number) {
  return -y;
}

export function skPoint(x: number, y: number) {
  return { x, y: skY(y) };
}

export function skRotationDegrees(degrees: number) {
  return -degrees * DEG_TO_RAD;
}

export function skAnchor(x: number, y: number) {
  return { x, y: 1 - y };
}
