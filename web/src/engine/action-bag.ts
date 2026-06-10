import { gsap } from 'gsap';

export type Killable = {
  kill(): void;
};

export class ActionBag {
  private actions = new Set<Killable>();

  add<T extends Killable>(action: T) {
    this.actions.add(action);
    return action;
  }

  killAll() {
    for (const action of this.actions) {
      action.kill();
    }
    this.actions.clear();
  }

  killTweensOf(targets: gsap.TweenTarget) {
    gsap.killTweensOf(targets);
  }

  get size() {
    return this.actions.size;
  }
}
