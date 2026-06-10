import { describe, expect, it } from 'vitest';
import { ActionBag, type Killable } from './action-bag';
import { MermaidMotionController, velocityForDirection } from './motion';

describe('MermaidMotionController', () => {
  it('uses SpriteKit-equivalent 200 and 500 point movement distances', () => {
    const motion = new MermaidMotionController();

    motion.setMovementMode('swing');
    expect(motion.distanceToTravel).toBe(200);
    motion.setDirection('right');
    expect(motion.velocity()).toEqual({ x: 200, y: 0 });

    motion.setMovementMode('fast');
    expect(motion.distanceToTravel).toBe(500);
    motion.setDirection('up');
    expect(motion.velocity()).toEqual({ x: 0, y: -500 });
  });

  it('clears direction when entering idle without resetting the last swim distance', () => {
    const motion = new MermaidMotionController();
    motion.setMovementMode('fast');
    motion.setDirection('left');

    motion.setMovementMode('idle');

    expect(motion.direction).toBe('none');
    expect(motion.distanceToTravel).toBe(500);
    expect(motion.velocity()).toEqual({ x: 0, y: 0 });
  });
});

describe('velocityForDirection', () => {
  it('converts SpriteKit y-up directions into Pixi y-down screen velocity', () => {
    expect(velocityForDirection('up', 200)).toEqual({ x: 0, y: -200 });
    expect(velocityForDirection('down', 200)).toEqual({ x: 0, y: 200 });
    expect(velocityForDirection('none', 200)).toEqual({ x: 0, y: 0 });
  });
});

describe('ActionBag', () => {
  it('kills and clears all registered actions on state replacement', () => {
    const killed: string[] = [];
    const action = (id: string): Killable => ({ kill: () => killed.push(id) });
    const bag = new ActionBag();
    bag.add(action('body'));
    bag.add(action('tail'));

    bag.killAll();

    expect(killed).toEqual(['body', 'tail']);
    expect(bag.size).toBe(0);
  });
});
