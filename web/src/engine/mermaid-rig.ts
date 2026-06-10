import { Application, Container, Graphics, Sprite, Texture, UPDATE_PRIORITY, type Ticker } from 'pixi.js';
import { gsap } from 'gsap';
import { palette } from '../generated/palette';
import { ActionBag } from './action-bag';
import { loadMermaidTextures, type MermaidTextures } from './assets';
import { MermaidMotionController } from './motion';
import { skAnchor, skPoint, skRotationDegrees, skY } from './spritekit';
import type { DepthZone, Direction, MermaidRigApi, MovementMode, ThemeName } from './types';

type TintRole = 'skinColor' | 'hairColor' | 'vibrant1' | 'vibrant2';

type TintSprite = {
  sprite: TintedSprite;
  role: TintRole;
};

class TintedSprite extends Container {
  private readonly fill = new Graphics();
  private readonly maskSprite: Sprite;
  private anchorX = 0.5;
  private anchorY = 0.5;
  private color = 0xffffff;

  constructor(texture: Texture) {
    super();
    this.maskSprite = new Sprite(texture);
    this.addChild(this.fill, this.maskSprite);
    this.fill.mask = this.maskSprite;
    this.sortableChildren = true;
    this.setAnchor(0.5, 0.5);
    this.setColor(this.color);
  }

  setAnchor(x: number, y: number) {
    this.anchorX = x;
    this.anchorY = y;
    this.maskSprite.anchor.set(x, y);
    this.redrawFill();
  }

  setColor(color: number) {
    this.color = color;
    this.redrawFill();
  }

  private redrawFill() {
    const width = this.maskSprite.texture.width;
    const height = this.maskSprite.texture.height;
    this.fill.clear();
    this.fill.rect(-width * this.anchorX, -height * this.anchorY, width, height);
    this.fill.fill(this.color);
  }
}

type MermaidParts = {
  headNode: TintedSprite;
  hairFrontNode: TintedSprite;
  hairBackBase: Container;
  hairBackNode: TintedSprite;
  faceBase: Container;
  body: TintedSprite;
  waist: TintedSprite;
  articulation: TintedSprite;
  waistScale: TintedSprite;
  fin: TintedSprite;
  finScale: TintedSprite;
  rightArm: TintedSprite;
  leftArm: TintedSprite;
  rightEye: Sprite;
  leftEye: Sprite;
  rightEyebrow: TintedSprite;
  leftEyebrow: TintedSprite;
  mouth: Sprite;
};

const ease = 'power1.inOut';
const autoDirections: Exclude<Direction, 'none'>[] = ['up', 'down', 'right', 'left'];
const desktopCameraScale = 3.3;
const compactCameraScale = 5;
const compactViewportWidth = 700;

export class MermaidRig implements MermaidRigApi {
  readonly app: Application;
  readonly world = new Container();
  readonly base = new Container();
  readonly motion = new MermaidMotionController();

  private parts: MermaidParts;
  private tints: TintSprite[] = [];
  private bodyActions = new ActionBag();
  private zActions = new ActionBag();
  private armActions = new ActionBag();
  private headActions = new ActionBag();
  private faceActions = new ActionBag();
  private camera = { x: 0, y: 0, scale: desktopCameraScale, fitScale: 1 };
  private autoDirectionTimer = 0;
  private autoDirectionActive = false;
  private lastManualInputAt = 0;
  private directionChangedAt = 0;
  private themeName: ThemeName = 'upper';
  private depthZone: DepthZone = 'mid';
  private onStateChange?: () => void;
  private stableVisuals = false;
  private destroyed = false;

  static async create(app: Application, options: { onStateChange?: () => void; stableVisuals?: boolean } = {}) {
    const textures = await loadMermaidTextures();
    return new MermaidRig(app, textures, options);
  }

  private constructor(app: Application, textures: MermaidTextures, options: { onStateChange?: () => void; stableVisuals?: boolean }) {
    this.app = app;
    this.onStateChange = options.onStateChange;
    this.stableVisuals = Boolean(options.stableVisuals);
    this.world.sortableChildren = true;
    this.base.sortableChildren = true;
    this.camera.scale = this.defaultCameraScale();
    this.parts = this.buildParts(textures);
    this.app.stage.addChild(this.world);
    this.world.addChild(this.base);
    this.setTheme('upper');
    this.setDepthZone('mid');
    this.setMovementMode('idle');
    this.app.ticker.add(this.tick, this, UPDATE_PRIORITY.NORMAL);
  }

  setMovementMode(mode: MovementMode) {
    const wasAuto = this.autoDirectionActive;
    this.motion.setMovementMode(mode);

    if (mode === 'idle') {
      this.stopAutoDirection();
      this.applyIdleMoveMode();
    } else if (mode === 'swing') {
      this.applySwingMoveMode();
      if (!this.stableVisuals && (wasAuto || this.motion.direction === 'none')) this.startAutoDirection();
    } else {
      this.applyFastMoveMode();
      if (!this.stableVisuals && (wasAuto || this.motion.direction === 'none')) this.startAutoDirection();
    }

    this.emitStateChange();
  }

  setDirection(direction: Direction) {
    this.lastManualInputAt = performance.now();
    if (this.motion.direction === direction) return;
    this.applyDirection(direction);
  }

  setZoom(scale: number) {
    gsap.to(this.camera, { scale, duration: 1, ease });
  }

  setTheme(theme: ThemeName) {
    this.themeName = theme;
    const themePalette = palette.themes[theme];
    for (const tint of this.tints) {
      tint.sprite.setColor(themePalette[tint.role].pixi);
    }
    this.emitStateChange();
  }

  setDepthZone(zone: DepthZone) {
    this.depthZone = zone;
    this.emitStateChange();
  }

  startAutoDirection() {
    this.autoDirectionActive = true;
    this.autoDirectionTimer = 0;
  }

  stopAutoDirection() {
    this.autoDirectionActive = false;
    this.autoDirectionTimer = 0;
  }

  destroy() {
    if (this.destroyed) return;
    this.destroyed = true;
    this.stopAutoDirection();
    this.bodyActions.killAll();
    this.zActions.killAll();
    this.armActions.killAll();
    this.headActions.killAll();
    this.faceActions.killAll();
    this.app.ticker.remove(this.tick, this);
    this.world.destroy({ children: true });
  }

  getState() {
    return {
      movementMode: this.motion.movementMode,
      direction: this.motion.direction,
      distanceToTravel: this.motion.distanceToTravel,
      themeName: this.themeName,
      depthZone: this.depthZone,
      zoom: this.camera.scale,
      autoDirectionActive: this.autoDirectionActive
    };
  }

  private buildParts(textures: MermaidTextures): MermaidParts {
    const tinted = (texture: Texture, role: TintRole) => {
      const node = new TintedSprite(texture);
      this.tints.push({ sprite: node, role });
      return node;
    };
    const sprite = (texture: Texture) => {
      const node = new Sprite(texture);
      node.anchor.set(0.5);
      return node;
    };

    const headNode = tinted(textures.MermHead, 'skinColor');
    const hairFrontNode = tinted(textures.MermHairFront, 'hairColor');
    const hairBackBase = new Container();
    const hairBackNode = tinted(textures.MermHairBack, 'hairColor');
    const faceBase = new Container();

    const body = tinted(textures.roundPiece, 'skinColor');
    const waist = tinted(textures.roundPiece, 'skinColor');
    const articulation = tinted(textures.roundPiece, 'vibrant1');
    const waistScale = tinted(textures.waist, 'vibrant1');
    const fin = tinted(textures.finBack, 'vibrant2');
    const finScale = tinted(textures.finFront, 'vibrant1');
    const rightArm = tinted(textures.hand1, 'skinColor');
    const leftArm = tinted(textures.hand2, 'skinColor');

    const rightEye = sprite(textures.eye);
    const leftEye = sprite(textures.eye);
    const rightEyebrow = tinted(textures.eyeBrow, 'hairColor');
    const leftEyebrow = tinted(textures.eyeBrow, 'hairColor');
    const mouth = sprite(textures.mouth);

    headNode.addChild(hairBackBase, hairFrontNode, faceBase);
    hairBackBase.addChild(hairBackNode, body);
    body.addChild(waist, rightArm, leftArm);
    waist.addChild(articulation, waistScale);
    articulation.addChild(fin);
    fin.addChild(finScale);
    faceBase.addChild(rightEyebrow, leftEyebrow, rightEye, leftEye, mouth);
    this.base.addChild(headNode);

    headNode.zIndex = 0;
    hairBackBase.zIndex = -1;
    hairBackNode.zIndex = -1;
    hairFrontNode.zIndex = 1;
    faceBase.zIndex = 3;
    body.zIndex = 1;
    waistScale.zIndex = 1;
    finScale.zIndex = 1;
    leftArm.zIndex = 3;

    body.position.set(0, skY(-220));
    body.scale.set(1.2);
    waist.position.set(0, skY(-230));
    waist.scale.set(0.9);
    articulation.position.set(0, skY(-230));
    articulation.scale.set(0.9);
    fin.position.set(0, skY(-150));
    fin.scale.set(1.1);

    const finAnchor = skAnchor(0.5, 1);
    fin.setAnchor(finAnchor.x, finAnchor.y);
    finScale.setAnchor(finAnchor.x, finAnchor.y);

    const armAnchor = skAnchor(0.5, 1);
    rightArm.setAnchor(armAnchor.x, armAnchor.y);
    leftArm.setAnchor(armAnchor.x, armAnchor.y);
    rightArm.position.set(75, 0);
    leftArm.position.set(-75, 0);

    rightEye.position.x = 40;
    leftEye.position.x = -40;
    leftEye.scale.x = -1;

    rightEyebrow.position.x = 40;
    leftEyebrow.position.x = -40;
    rightEyebrow.rotation = skRotationDegrees(-6);
    leftEyebrow.rotation = skRotationDegrees(6);

    const eyebrowBase = new Container();
    const eyesBase = new Container();
    const mouthBase = new Container();
    eyebrowBase.position.y = skY(45);
    eyesBase.position.y = skY(15);
    mouthBase.position.y = skY(-15);
    eyebrowBase.addChild(rightEyebrow, leftEyebrow);
    eyesBase.addChild(rightEye, leftEye);
    mouthBase.addChild(mouth);
    faceBase.removeChildren();
    faceBase.addChild(eyebrowBase, eyesBase, mouthBase);

    return {
      headNode,
      hairFrontNode,
      hairBackBase,
      hairBackNode,
      faceBase,
      body,
      waist,
      articulation,
      waistScale,
      fin,
      finScale,
      rightArm,
      leftArm,
      rightEye,
      leftEye,
      rightEyebrow,
      leftEyebrow,
      mouth
    };
  }

  private tick(ticker: Ticker) {
    const seconds = ticker.deltaMS / 1000;
    if (!this.stableVisuals) {
      const velocity = this.motion.velocity();
      this.base.x += velocity.x * seconds;
      this.base.y += velocity.y * seconds;
    }

    if (!this.stableVisuals && this.autoDirectionActive && performance.now() - this.lastManualInputAt > 1500) {
      this.autoDirectionTimer -= seconds;
      if (this.autoDirectionTimer <= 0) {
        const next = autoDirections[Math.floor(Math.random() * autoDirections.length)];
        this.applyDirection(next, false);
        this.autoDirectionTimer = 10 + Math.random() * 30;
      }
    }

    const compactViewport = this.isCompactViewport();
    const cameraOffsetY = this.motion.direction === 'down'
      ? (compactViewport ? -450 : -650)
      : (compactViewport ? 1000 : 300);
    const targetCameraX = this.base.x;
    const targetCameraY = this.base.y + cameraOffsetY;
    if (this.stableVisuals) {
      this.camera.x = targetCameraX;
      this.camera.y = targetCameraY;
    } else {
      const followDuration = this.motion.direction === 'down' ? 0.12 : this.motion.movementMode === 'fast' ? 0.24 : 0.4;
      const follow = 1 - Math.exp(-seconds / followDuration);
      this.camera.x += (targetCameraX - this.camera.x) * follow;
      this.camera.y += (targetCameraY - this.camera.y) * follow;
      const targetFitScale = this.targetFitScale(true);
      const fitFollow = 1 - Math.exp(-seconds / 0.02);
      this.camera.fitScale += (targetFitScale - this.camera.fitScale) * fitFollow;
    }
    if (this.stableVisuals) this.camera.fitScale = this.targetFitScale(false);
    const drawScale = 1 / (this.camera.scale * this.camera.fitScale);
    this.world.scale.set(drawScale);
    this.world.position.set(
      this.app.screen.width / 2 - this.camera.x * drawScale,
      this.app.screen.height / 2 - this.camera.y * drawScale
    );
  }

  private defaultCameraScale() {
    return this.isCompactViewport() ? compactCameraScale : desktopCameraScale;
  }

  private isCompactViewport() {
    return this.app.screen.width <= compactViewportWidth;
  }

  private targetFitScale(includeTransition: boolean) {
    if (this.motion.direction !== 'down') return 1;
    if (!includeTransition) return 1.35;
    return performance.now() - this.directionChangedAt < 1000 ? 1.7 : 1.35;
  }

  private emitStateChange() {
    this.onStateChange?.();
  }

  private applyIdleMoveMode() {
    this.bodyActions.killAll();
    this.armActions.killAll();
    this.headActions.killAll();
    this.faceActions.killAll();
    this.applyBodyZPosition(false);
    this.runBodySwing(5, 2, 5.5, 2, 6, 2, 6.5, 2);
    this.runHeadIdle();
    this.runArmsIdle();
    this.runFaceMove(0, 0, 0.5);
  }

  private applySwingMoveMode() {
    this.bodyActions.killAll();
    this.runBodySwing(5, 0.5, 6, 0.5, 7, 0.5, 8, 0.5);
  }

  private applyFastMoveMode() {
    this.bodyActions.killAll();
    this.runBodySwing(5, 0.2, 5, 0.2, 5, 0.2, 6, 0.1);
  }

  private applyDirection(direction: Direction, manual = true) {
    if (manual) this.lastManualInputAt = performance.now();
    if (this.motion.direction === direction) return;
    this.directionChangedAt = performance.now();
    this.motion.setDirection(direction);
    switch (direction) {
      case 'up':
        this.setUpMoveMode();
        break;
      case 'down':
        this.setDownMoveMode();
        break;
      case 'right':
        this.setRightMoveMode();
        break;
      case 'left':
        this.setLeftMoveMode();
        break;
      case 'none':
        this.setNeutralDirectionPose();
        break;
    }
    this.emitStateChange();
  }

  private setNeutralDirectionPose() {
    this.applyBodyZPosition(false);
    this.runHeadIdle();
    this.runArmsIdle();
    this.runFaceMove(0, 0, 0.5);
  }

  private setUpMoveMode() {
    this.runHeadMove({ backX: 0, backY: -25, backRotation: 0, frontX: 0, frontY: 15, duration: 1 });
    this.applyBodyZPosition(false);
    this.runArmsUp();
    this.runFaceMove(0, 40, 0.5);
  }

  private setDownMoveMode() {
    this.runHeadMove({ backX: 0, backY: 150, backRotation: 180, frontX: 0, frontY: 0, duration: 1 });
    this.applyBodyZPosition(true);
    this.runArmsDown();
    this.runFaceMove(0, -10, 0.5);
  }

  private setRightMoveMode() {
    this.runHeadMove({ backX: -55, backY: 55, backRotation: -90, frontX: 0, frontY: 0, duration: 1 });
    this.applyBodyZPosition(false);
    this.runArmsHorizontal('right');
    this.runFaceMove(20, 0, 0.5);
  }

  private setLeftMoveMode() {
    this.runHeadMove({ backX: 55, backY: 55, backRotation: 90, frontX: 0, frontY: 0, duration: 1 });
    this.applyBodyZPosition(false);
    this.runArmsHorizontal('left');
    this.runFaceMove(-20, 0, 0.5);
  }

  private runBodySwing(
    bodyDegree: number,
    bodyDuration: number,
    waistDegree: number,
    waistDuration: number,
    articulationDegree: number,
    articulationDuration: number,
    finDegree: number,
    finDuration: number
  ) {
    if (this.stableVisuals) {
      this.parts.body.rotation = skRotationDegrees(bodyDegree);
      this.parts.waist.rotation = skRotationDegrees(waistDegree);
      this.parts.articulation.rotation = skRotationDegrees(articulationDegree);
      this.parts.fin.rotation = skRotationDegrees(finDegree);
      return;
    }
    this.bodyActions.add(this.swingTimeline(this.parts.body, bodyDegree, bodyDuration));
    this.bodyActions.add(gsap.delayedCall(0.1, () => {
      this.bodyActions.add(this.swingTimeline(this.parts.waist, waistDegree, waistDuration));
      this.bodyActions.add(this.swingTimeline(this.parts.articulation, articulationDegree, articulationDuration));
      this.bodyActions.add(this.swingTimeline(this.parts.fin, finDegree, finDuration));
    }));
  }

  private swingTimeline(target: Container, degrees: number, duration: number) {
    return gsap
      .timeline({ repeat: -1 })
      .to(target, { rotation: skRotationDegrees(degrees), duration, ease })
      .to(target, { rotation: skRotationDegrees(-degrees), duration, ease });
  }

  private applyBodyZPosition(isDownMoveMode: boolean) {
    const zIndex = isDownMoveMode ? -2 : 1;
    this.zActions.killAll();
    if (this.stableVisuals) {
      this.parts.body.zIndex = zIndex;
      this.parts.body.parent?.sortChildren();
      return;
    }
    this.zActions.add(gsap.delayedCall(0.5, () => {
      this.parts.body.zIndex = zIndex;
      this.parts.body.parent?.sortChildren();
    }));
  }

  private runHeadIdle() {
    this.headActions.killAll();
    if (this.stableVisuals) {
      this.parts.hairBackNode.scale.set(1);
      this.parts.hairBackBase.position.set(0, 0);
      this.parts.hairBackBase.rotation = 0;
      this.parts.hairFrontNode.position.set(0, 0);
      this.parts.hairFrontNode.rotation = 0;
      return;
    }
    this.headActions.add(
      gsap
        .timeline({ repeat: -1 })
        .to(this.parts.hairBackNode.scale, { x: 1.07, y: 1.07, duration: 0.8, ease })
        .to(this.parts.hairBackNode.scale, { x: 1, y: 1, duration: 0.8, ease })
    );
    this.headActions.add(gsap.to(this.parts.hairBackBase, { ...skPoint(0, 0), rotation: 0, duration: 0.5, ease }));
    this.headActions.add(gsap.to(this.parts.hairFrontNode, { ...skPoint(0, 0), rotation: 0, duration: 0.5, ease }));
  }

  private runHeadMove(options: {
    backX: number;
    backY: number;
    backRotation: number;
    frontX: number;
    frontY: number;
    duration: number;
  }) {
    this.headActions.killTweensOf([this.parts.hairBackBase, this.parts.hairFrontNode]);
    if (this.stableVisuals) {
      const back = skPoint(options.backX, options.backY);
      const front = skPoint(options.frontX, options.frontY);
      this.parts.hairBackBase.position.set(back.x, back.y);
      this.parts.hairBackBase.rotation = skRotationDegrees(options.backRotation);
      this.parts.hairFrontNode.position.set(front.x, front.y);
      return;
    }
    this.headActions.add(
      gsap.to(this.parts.hairBackBase, {
        ...skPoint(options.backX, options.backY),
        rotation: skRotationDegrees(options.backRotation),
        duration: options.duration,
        ease
      })
    );
    this.headActions.add(
      gsap.to(this.parts.hairFrontNode, {
        ...skPoint(options.frontX, options.frontY),
        duration: options.duration,
        ease
      })
    );
  }

  private runArmsIdle() {
    this.armActions.killAll();
    this.moveArms('vertical');
    this.setArmZ(-1, 3);
    const timeline = gsap.timeline({ repeat: -1 })
      .to([this.parts.rightArm, this.parts.leftArm], { rotation: skRotationDegrees(5), duration: 3, ease })
      .to([this.parts.rightArm, this.parts.leftArm], { rotation: skRotationDegrees(-5), duration: 3, ease });
    this.armActions.add(timeline);
  }

  private runArmsUp() {
    this.armActions.killAll();
    this.moveArms('vertical');
    this.setArmZ(3, 3);
    if (this.stableVisuals) {
      this.parts.rightArm.rotation = skRotationDegrees(7);
      this.parts.leftArm.rotation = skRotationDegrees(-7);
      return;
    }
    this.armActions.add(
      gsap.timeline({ repeat: -1 })
        .to(this.parts.rightArm, { rotation: skRotationDegrees(0), duration: 1, ease })
        .to(this.parts.rightArm, { rotation: skRotationDegrees(7), duration: 0.5, ease })
        .to(this.parts.rightArm, { rotation: skRotationDegrees(-7), duration: 1.5, ease })
    );
    this.armActions.add(
      gsap.timeline({ repeat: -1 })
        .to(this.parts.leftArm, { rotation: skRotationDegrees(0), duration: 1, ease })
        .to(this.parts.leftArm, { rotation: skRotationDegrees(-7), duration: 0.5, ease })
        .to(this.parts.leftArm, { rotation: skRotationDegrees(7), duration: 1.5, ease })
    );
  }

  private runArmsDown() {
    this.armActions.killAll();
    this.moveArms('vertical', false);
    this.setArmZ(-3, -3);
    if (this.stableVisuals) {
      this.parts.rightArm.rotation = skRotationDegrees(180);
      this.parts.leftArm.rotation = skRotationDegrees(-180);
      this.parts.rightArm.y = skY(200);
      this.parts.leftArm.y = skY(200);
      return;
    }
    for (const [index, arm] of [this.parts.rightArm, this.parts.leftArm].entries()) {
      const downRotation = index === 0 ? skRotationDegrees(180) : skRotationDegrees(-180);
      this.armActions.add(
        gsap.timeline({
          onComplete: () => {
            if (this.destroyed || this.motion.direction !== 'down') return;
            this.armActions.add(
              gsap.timeline({ repeat: -1 })
                .to(arm, { rotation: skRotationDegrees(6), duration: 1, ease })
                .to(arm, { rotation: skRotationDegrees(-6), duration: 1, ease })
            );
          }
        })
          .to(arm, { rotation: downRotation, y: skY(200), duration: 1, ease, overwrite: 'auto' })
          .to(arm, { duration: 2 })
          .to(arm, { rotation: 0, y: 0, duration: 0.5, ease, overwrite: 'auto' })
      );
    }
  }

  private runArmsHorizontal(direction: 'left' | 'right') {
    this.armActions.killAll();
    this.moveArms('horizontal');
    this.setArmZ(-1, 3);
    const firstDegree = direction === 'right' ? -5 : 5;
    const lastDegree = direction === 'right' ? 12 : -12;
    if (this.stableVisuals) {
      this.parts.rightArm.rotation = skRotationDegrees(firstDegree);
      this.parts.leftArm.rotation = skRotationDegrees(firstDegree);
      return;
    }
    this.armActions.add(gsap.timeline({ repeat: -1 })
      .to([this.parts.rightArm, this.parts.leftArm], { rotation: skRotationDegrees(firstDegree), duration: 1, ease })
      .to([this.parts.rightArm, this.parts.leftArm], { rotation: skRotationDegrees(lastDegree), duration: 2, ease }));
  }

  private moveArms(orientation: 'horizontal' | 'vertical', includeY = true) {
    const increment = orientation === 'vertical' ? 0 : 45;
    if (this.stableVisuals) {
      this.parts.rightArm.x = 75 - increment;
      this.parts.leftArm.x = -75 + increment;
      if (includeY) {
        this.parts.rightArm.y = 0;
        this.parts.leftArm.y = 0;
      }
      return;
    }
    const rightTarget = includeY ? { x: 75 - increment, y: 0 } : { x: 75 - increment };
    const leftTarget = includeY ? { x: -75 + increment, y: 0 } : { x: -75 + increment };
    this.armActions.add(gsap.to(this.parts.rightArm, { ...rightTarget, duration: 1, ease, overwrite: 'auto' }));
    this.armActions.add(gsap.to(this.parts.leftArm, { ...leftTarget, duration: 1, ease, overwrite: 'auto' }));
  }

  private setArmZ(rightZ: number, leftZ: number) {
    this.parts.rightArm.zIndex = rightZ;
    this.parts.leftArm.zIndex = leftZ;
    this.parts.body.sortChildren();
  }

  private runFaceMove(x: number, y: number, duration: number) {
    this.faceActions.killAll();
    if (this.stableVisuals) {
      const point = skPoint(x, y);
      this.parts.faceBase.position.set(point.x, point.y);
      return;
    }
    this.faceActions.add(gsap.to(this.parts.faceBase, { ...skPoint(x, y), duration, ease }));
  }
}
