const GAME_WIDTH = 1600;
const GAME_HEIGHT = 900;
const GROUND_TILE = 160;
const WORLD_WIDTH = 5120;
const GROUND_Y = 740;
const FRAME_W = 64;
const FRAME_H = 64;


function addOrnamentalPanel(scene, x, y, w, h, textureKey = 'parchment') {
  const container = scene.add.container(0, 0);
  const panel = scene.add.tileSprite(x + w / 2, y + h / 2, w, h, textureKey);
  const source = scene.textures.get(textureKey).getSourceImage();
  panel.setTileScale(160 / source.width, 160 / source.height);
  panel.setAlpha(0.985);

  const shadow = scene.add.rectangle(x + w / 2 + 8, y + h / 2 + 10, w, h, 0x000000, 0.16);
  const outer = scene.add.rectangle(x + w / 2, y + h / 2, w, h, 0x000000, 0).setStrokeStyle(7, 0x5b3717, 1);
  const inner = scene.add.rectangle(x + w / 2, y + h / 2, w - 18, h - 18, 0x000000, 0).setStrokeStyle(2, 0xdab56a, 0.95);
  const inset = scene.add.rectangle(x + w / 2, y + h / 2, w - 42, h - 42, 0x000000, 0).setStrokeStyle(1, 0xe8d9b2, 0.7);

  const accents = [];
  const cornerLen = 28;
  const offset = 24;
  const makeCorner = (cx, cy, sx, sy) => {
    const hLine = scene.add.line(0, 0, cx, cy, cx + sx * cornerLen, cy, 0x8e6328, 0.9).setLineWidth(2, 2);
    const vLine = scene.add.line(0, 0, cx, cy, cx, cy + sy * cornerLen, 0x8e6328, 0.9).setLineWidth(2, 2);
    const dot = scene.add.circle(cx, cy, 2.5, 0x8e6328, 0.95);
    accents.push(hLine, vLine, dot);
  };
  makeCorner(x + offset, y + offset, 1, 1);
  makeCorner(x + w - offset, y + offset, -1, 1);
  makeCorner(x + offset, y + h - offset, 1, -1);
  makeCorner(x + w - offset, y + h - offset, -1, -1);

  const titleRuleLeft = scene.add.line(0, 0, x + 62, y + 78, x + w / 2 - 170, y + 78, 0xcea85d, 0.95).setLineWidth(2, 2);
  const titleRuleRight = scene.add.line(0, 0, x + w / 2 + 170, y + 78, x + w - 62, y + 78, 0xcea85d, 0.95).setLineWidth(2, 2);
  const titleGem = scene.add.circle(x + w / 2, y + 78, 4, 0x8e6328, 0.95);
  const titleGemInner = scene.add.circle(x + w / 2, y + 78, 2, 0xf5e2b6, 0.95);

  container.add([shadow, panel, outer, inner, inset, titleRuleLeft, titleRuleRight, titleGem, titleGemInner, ...accents]);
  return { container, panel, outer, inner, inset };
}

function addOutlinedButton(scene, x, y, w, h, label, active = false, fontSize = '28px') {
  const box = scene.add.rectangle(x, y, w, h, 0x000000, 0)
    .setStrokeStyle(active ? 4 : 3, active ? 0x6b4016 : 0xdab56a, 0.98);
  const inner = scene.add.rectangle(x, y, w - 12, h - 12, 0x000000, 0)
    .setStrokeStyle(active ? 1 : 1, active ? 0x3f2410 : 0xe7cd96, active ? 0.9 : 0.75);
  const textObj = scene.add.text(x, y, label, {
    fontFamily: 'Macondo Swash Caps',
    fontSize,
    color: active ? '#3c1d0d' : '#7f6131',
  }).setOrigin(0.5);

  return { box, inner, text: textObj, setActive(isActive) {
    box.setStrokeStyle(isActive ? 4 : 3, isActive ? 0x6b4016 : 0xdab56a, 0.98);
    inner.setStrokeStyle(1, isActive ? 0x3f2410 : 0xe7cd96, isActive ? 0.9 : 0.75);
    textObj.setColor(isActive ? '#3c1d0d' : '#7f6131');
  }};
}


const HEROES = {
  caelan: {
    key: 'caelan',
    name: 'Caelan',
    walk: 'assets/characters/caelan/walk.png',
    idle: 'assets/characters/caelan/idle.png',
    jump: 'assets/characters/caelan/jump.png',
  },
  nerisse: {
    key: 'nerisse',
    name: 'Nerisse',
    walk: 'assets/characters/nerisse/walk.png',
    idle: 'assets/characters/nerisse/idle.png',
    jump: 'assets/characters/nerisse/jump.png',
  },
};

function createHeroAnimations(scene, heroKey) {
  const rowStart = (row) => row * 13;
  const frameList = (sheet, row, start, end) => {
    const out = [];
    for (let i = start; i <= end; i += 1) {
      out.push({ key: sheet, frame: rowStart(row) + i });
    }
    return out;
  };

  const animations = [
    { key: `${heroKey}-walk-left`, sheet: `${heroKey}-walk`, row: 1, start: 0, end: 8, rate: 10, repeat: -1 },
    { key: `${heroKey}-walk-right`, sheet: `${heroKey}-walk`, row: 3, start: 0, end: 8, rate: 10, repeat: -1 },
    { key: `${heroKey}-idle-left`, sheet: `${heroKey}-idle`, row: 1, start: 0, end: 1, rate: 3, repeat: -1 },
    { key: `${heroKey}-idle-right`, sheet: `${heroKey}-idle`, row: 3, start: 0, end: 1, rate: 3, repeat: -1 },
    { key: `${heroKey}-jump-left`, sheet: `${heroKey}-jump`, row: 1, start: 0, end: 3, rate: 12, repeat: 0 },
    { key: `${heroKey}-jump-right`, sheet: `${heroKey}-jump`, row: 3, start: 0, end: 3, rate: 12, repeat: 0 },
  ];

  animations.forEach((anim) => {
    if (!scene.anims.exists(anim.key)) {
      scene.anims.create({
        key: anim.key,
        frames: frameList(anim.sheet, anim.row, anim.start, anim.end),
        frameRate: anim.rate,
        repeat: anim.repeat,
      });
    }
  });
}

class StartScene extends Phaser.Scene {
  constructor() {
    super('StartScene');
  }

  preload() {
    this.load.image('start-bg', 'assets/ui/celadune_start_screen_background.png');
    this.load.image('celadune-logo', 'assets/ui/celadune_logo.png');
    this.load.audio('celaduneTheme', 'assets/audio/celadune_theme.mp3');
  }

  create() {
    this.cameras.main.setBackgroundColor('#08111a');

    const bg = this.add.image(GAME_WIDTH / 2, GAME_HEIGHT / 2, 'start-bg');
    const bgTexture = this.textures.get('start-bg').getSourceImage();
    const bgScale = Math.max(GAME_WIDTH / bgTexture.width, GAME_HEIGHT / bgTexture.height);
    bg.setScale(bgScale);

    this.logo = this.add.image(GAME_WIDTH / 2, 350, 'celadune-logo');
    const logoTexture = this.textures.get('celadune-logo').getSourceImage();
    const maxLogoWidth = 1875;
    const maxLogoHeight = 775;
    const logoScale = Math.min(maxLogoWidth / logoTexture.width, maxLogoHeight / logoTexture.height);
    this.logo.setScale(logoScale);

    this.add.rectangle(GAME_WIDTH / 2, 768, 320, 88, 0x1e140a, 0.72).setStrokeStyle(4, 0xdab56a, 0.9);
    this.add.rectangle(GAME_WIDTH / 2, 768, 300, 68, 0x41250d, 0.94).setStrokeStyle(2, 0xf3dfae, 0.9);
    this.startButton = this.add.text(GAME_WIDTH / 2, 768, 'Start', {
      fontFamily: 'Macondo Swash Caps',
      fontSize: '42px',
      color: '#fff3d0',
      stroke: '#4f280a',
      strokeThickness: 6,
      shadow: {
        offsetX: 0,
        offsetY: 2,
        color: '#000000',
        blur: 6,
        fill: true,
      },
    }).setOrigin(0.5);

    this.promptText = this.add.text(GAME_WIDTH / 2, 838, 'Press Enter to begin', {
      fontFamily: 'Roboto Mono',
      fontSize: '22px',
      color: '#efe6cf',
      stroke: '#111111',
      strokeThickness: 3,
    }).setOrigin(0.5);

    this.createSheen();
    this.createAudio();

    this.input.keyboard.once('keydown-ENTER', () => this.startGame());
    this.input.keyboard.once('keydown-SPACE', () => this.startGame());
    this.input.once('pointerdown', () => this.startGame());
  }

  createSheen() {
    const maskImage = this.make.image({ x: this.logo.x, y: this.logo.y, key: 'celadune-logo', add: false });
    maskImage.setScale(this.logo.scaleX, this.logo.scaleY);
    const mask = maskImage.createBitmapMask();

    const sheen = this.add.rectangle(this.logo.x - 920, this.logo.y, 210, 980, 0xffffff, 0.20)
      .setAngle(-18)
      .setBlendMode(Phaser.BlendModes.SCREEN)
      .setVisible(false)
      .setDepth(this.logo.depth + 1);
    sheen.setMask(mask);

    const runSheen = () => {
      sheen.x = this.logo.x - 920;
      sheen.y = this.logo.y;
      sheen.setVisible(true);
      this.tweens.add({
        targets: sheen,
        x: this.logo.x + 920,
        duration: 950,
        ease: 'Sine.easeInOut',
        onComplete: () => {
          sheen.setVisible(false);
          this.time.delayedCall(4300, runSheen);
        },
      });
    };

    this.time.delayedCall(1400, runSheen);
  }

  createAudio() {
    this.music = this.sound.add('celaduneTheme', {
      loop: true,
      volume: 0.52,
    });

    if (!this.sound.locked) {
      this.music.play();
    } else {
      this.sound.once(Phaser.Sound.Events.UNLOCKED, () => {
        if (!this.music.isPlaying) {
          this.music.play();
        }
      });
    }

    this.events.once(Phaser.Scenes.Events.SHUTDOWN, () => {
      if (this.music) this.music.stop();
    });
    this.events.once(Phaser.Scenes.Events.DESTROY, () => {
      if (this.music) this.music.destroy();
    });
  }

  startGame() {
    if (this.transitioning) return;
    this.transitioning = true;
    this.cameras.main.fadeOut(500, 0, 0, 0);
    this.time.delayedCall(520, () => this.scene.start('HeroSelectScene'));
  }
}

class HeroSelectScene extends Phaser.Scene {
  constructor() {
    super('HeroSelectScene');
    this.selectedHeroIndex = 0;
    this.heroOrder = ['caelan', 'nerisse'];
  }

  preload() {
    this.load.image('start-bg', 'assets/ui/celadune_start_screen_background.png');
    this.load.image('parchment', 'assets/ui/parchment.png');

    Object.values(HEROES).forEach((hero) => {
      this.load.spritesheet(`${hero.key}-idle`, hero.idle, {
        frameWidth: FRAME_W,
        frameHeight: FRAME_H,
      });
    });
  }

  create() {
    this.cameras.main.setBackgroundColor('#08111a');

    const bg = this.add.image(GAME_WIDTH / 2, GAME_HEIGHT / 2, 'start-bg');
    const bgTexture = this.textures.get('start-bg').getSourceImage();
    const bgScale = Math.max(GAME_WIDTH / bgTexture.width, GAME_HEIGHT / bgTexture.height);
    bg.setScale(bgScale);

    const panelX = 245;
    const panelY = 118;
    const panelW = 1110;
    const panelH = 620;
    const panelBits = addOrnamentalPanel(this, panelX, panelY, panelW, panelH, 'parchment');

    this.add.text(GAME_WIDTH / 2, panelY + 66, 'Select Your Hero', {
      fontFamily: 'Macondo Swash Caps',
      fontSize: '52px',
      color: '#4a2411',
      stroke: '#f5e2b6',
      strokeThickness: 3,
    }).setOrigin(0.5);

    this.add.text(GAME_WIDTH / 2, panelY + 108, 'Choose the champion who will begin your journey into Celadune', {
      fontFamily: 'Roboto Mono',
      fontSize: '16px',
      color: '#6d5634',
    }).setOrigin(0.5);

    const instructionPlate = this.add.rectangle(GAME_WIDTH / 2, panelY + panelH - 52, 470, 44, 0x000000, 0)
      .setStrokeStyle(2, 0xdab56a, 0.95);
    const instructionInner = this.add.rectangle(GAME_WIDTH / 2, panelY + panelH - 52, 456, 32, 0x000000, 0)
      .setStrokeStyle(1, 0xe7cd96, 0.75);
    this.add.text(GAME_WIDTH / 2, panelY + panelH - 52, 'Left / Right to choose  •  Enter to confirm', {
      fontFamily: 'Roboto Mono',
      fontSize: '18px',
      color: '#4e3720',
    }).setOrigin(0.5);
    panelBits.container.add([instructionPlate, instructionInner]);

    this.heroCards = this.heroOrder.map((heroKey, index) => {
      const x = index === 0 ? 620 : 980;
      const y = 438;

      const cardPanel = addOrnamentalPanel(this, x - 140, y - 150, 280, 340, 'parchment');
      cardPanel.outer.setStrokeStyle(4, 0xdab56a, 0.98);
      cardPanel.inner.setStrokeStyle(2, 0xe7cd96, 0.82);
      cardPanel.inset.setStrokeStyle(1, 0xf1e6c9, 0.5);
      const portraitStage = this.add.rectangle(x, y - 18, 168, 168, 0x9b7740, 0.06)
        .setStrokeStyle(1, 0xb88945, 0.22);
      const sprite = this.add.sprite(x, y - 24, `${heroKey}-idle`, 39).setScale(3.35);
      const name = this.add.text(x, y + 88, HEROES[heroKey].name, {
        fontFamily: 'Macondo Swash Caps',
        fontSize: '34px',
        color: '#4a2411',
      }).setOrigin(0.5);
      const role = this.add.text(x, y + 118, heroKey === 'caelan' ? 'Fighter' : 'Mage', {
        fontFamily: 'Roboto Mono',
        fontSize: '17px',
        color: '#5c4528',
      }).setOrigin(0.5);
      const flavor = this.add.text(x, y + 148, heroKey === 'caelan' ? 'Steel, grit, and close combat' : 'Arcane talent and ancient insight', {
        fontFamily: 'Roboto Mono',
        fontSize: '13px',
        color: '#7a6340',
        align: 'center',
      }).setOrigin(0.5);

      return { key: heroKey, panel: cardPanel, portraitStage, sprite, name, role, flavor };
    });

    this.ensurePreviewAnimations();
    this.heroCards.forEach((card) => card.sprite.play(`${card.key}-preview`, true));
    this.refreshSelection();

    this.cursors = this.input.keyboard.createCursorKeys();
    this.enterKey = this.input.keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.ENTER);
    this.spaceKey = this.input.keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.SPACE);
    this.escapeKey = this.input.keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.ESC);
  }

  ensurePreviewAnimations() {
    this.heroOrder.forEach((heroKey) => {
      const key = `${heroKey}-preview`;
      if (!this.anims.exists(key)) {
        this.anims.create({
          key,
          frames: [
            { key: `${heroKey}-idle`, frame: 39 },
            { key: `${heroKey}-idle`, frame: 40 },
          ],
          frameRate: 3,
          repeat: -1,
        });
      }
    });
  }

  refreshSelection() {
    this.heroCards.forEach((card, index) => {
      const active = index === this.selectedHeroIndex;
      card.panel.outer.setStrokeStyle(active ? 5 : 4, active ? 0x6b4016 : 0xdab56a, 0.98);
      card.panel.inner.setStrokeStyle(active ? 2 : 1, active ? 0x3f2410 : 0xe7cd96, active ? 0.95 : 0.72);
      card.panel.inset.setStrokeStyle(1, active ? 0x8e6328 : 0xf1e6c9, active ? 0.55 : 0.4);
      card.portraitStage.setAlpha(active ? 0.12 : 0.06);
      card.portraitStage.setStrokeStyle(1, active ? 0x8e6328 : 0xb88945, active ? 0.5 : 0.22);
      card.name.setColor(active ? '#3a1b0a' : '#6d4f24');
      card.role.setColor(active ? '#4a311a' : '#7e6541');
      card.flavor.setColor(active ? '#604527' : '#8f7751');
      card.sprite.setScale(active ? 3.45 : 3.25);
    });
  }

  confirmSelection() {
    if (this.transitioning) return;
    this.transitioning = true;
    const selectedHero = this.heroOrder[this.selectedHeroIndex];
    this.cameras.main.fadeOut(400, 0, 0, 0);
    this.time.delayedCall(420, () => this.scene.start('PrototypeScene', { heroKey: selectedHero }));
  }

  update() {
    if (Phaser.Input.Keyboard.JustDown(this.cursors.left)) {
      this.selectedHeroIndex = Phaser.Math.Wrap(this.selectedHeroIndex - 1, 0, this.heroOrder.length);
      this.refreshSelection();
    }
    if (Phaser.Input.Keyboard.JustDown(this.cursors.right)) {
      this.selectedHeroIndex = Phaser.Math.Wrap(this.selectedHeroIndex + 1, 0, this.heroOrder.length);
      this.refreshSelection();
    }
    if (Phaser.Input.Keyboard.JustDown(this.enterKey) || Phaser.Input.Keyboard.JustDown(this.spaceKey)) {
      this.confirmSelection();
    }
    if (Phaser.Input.Keyboard.JustDown(this.escapeKey)) {
      this.scene.start('StartScene');
    }
  }
}

class PrototypeScene extends Phaser.Scene {
  constructor() {
    super('PrototypeScene');
    this.facing = 'right';
    this.selectedMenuIndex = 0;
    this.menuPages = ['Inventory', 'Controls'];
    this.inventoryItems = [
      { icon: '◆', name: 'Traveler\'s Cloak' },
      { icon: '✦', name: 'Forest Map' },
      { icon: '✧', name: 'Field Rations' },
    ];
  }

  init(data) {
    this.heroKey = data?.heroKey || 'caelan';
  }

  preload() {
    this.load.image('forest', 'assets/bg/forest.png');
    this.load.image('ground1', 'assets/tiles/ground_tile_1.png');
    this.load.image('ground2', 'assets/tiles/ground_tile_2.png');
    this.load.image('ground3', 'assets/tiles/ground_tile_3.png');
    this.load.image('parchment', 'assets/ui/parchment.png');
    this.load.audio('forestTheme', 'assets/audio/celadune_forest.mp3');

    Object.values(HEROES).forEach((hero) => {
      this.load.spritesheet(`${hero.key}-walk`, hero.walk, {
        frameWidth: FRAME_W,
        frameHeight: FRAME_H,
      });
      this.load.spritesheet(`${hero.key}-idle`, hero.idle, {
        frameWidth: FRAME_W,
        frameHeight: FRAME_H,
      });
      this.load.spritesheet(`${hero.key}-jump`, hero.jump, {
        frameWidth: FRAME_W,
        frameHeight: FRAME_H,
      });
    });
  }

  create() {
    this.physics.world.gravity.y = 1800;

    this.createParallaxBackground();
    this.createGround();
    this.createAnimations();
    this.createPlayer();
    this.createAtmosphere();
    this.createCamera();
    this.createUI();
    this.createAudio();
    this.createMenu();

    this.cursors = this.input.keyboard.createCursorKeys();
    this.menuKey = this.input.keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.M);
    this.enterKey = this.input.keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.ENTER);
    this.spaceKey = this.input.keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.SPACE);
    this.escapeKey = this.input.keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.ESC);
    this.backspaceKey = this.input.keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.BACKSPACE);
  }

  createParallaxBackground() {
    const forestTexture = this.textures.get('forest').getSourceImage();
    const scale = GAME_HEIGHT / forestTexture.height;

    this.bg = this.add.tileSprite(0, 0, GAME_WIDTH, GAME_HEIGHT, 'forest')
      .setOrigin(0, 0)
      .setScrollFactor(0)
      .setDepth(-20);

    this.bg.setTileScale(scale, scale);
  }

  createGround() {
    this.ground = this.physics.add.staticGroup();
    this.groundBack = this.add.group();

    const tilesAcross = Math.ceil(WORLD_WIDTH / GROUND_TILE);
    const groundKeys = ['ground1', 'ground2', 'ground3'];
    const rng = this.createSeededRandom(0xC0FFEE);
    let previousKey = null;

    for (let i = 0; i < tilesAcross; i += 1) {
      let tileKey = groundKeys[Math.floor(rng() * groundKeys.length)];

      if (groundKeys.length > 1 && tileKey === previousKey) {
        tileKey = groundKeys[(groundKeys.indexOf(tileKey) + 1 + Math.floor(rng() * (groundKeys.length - 1))) % groundKeys.length];
      }

      previousKey = tileKey;

      const x = i * GROUND_TILE + GROUND_TILE / 2;
      const y = GROUND_Y + GROUND_TILE / 2;

      const backTile = this.add.image(x, y, tileKey)
        .setDisplaySize(GROUND_TILE, GROUND_TILE)
        .setDepth(2);
      this.groundBack.add(backTile);

      const body = this.ground.create(x, y, tileKey);
      body.setVisible(false);
      body.setDisplaySize(GROUND_TILE, GROUND_TILE);
      body.refreshBody();
    }

    this.groundShadow = this.add.rectangle(WORLD_WIDTH / 2, GROUND_Y - 4, WORLD_WIDTH, 18, 0x13210f, 0.35)
      .setDepth(3);
  }

  createSeededRandom(seed) {
    let value = seed >>> 0;
    return () => {
      value += 0x6D2B79F5;
      let t = value;
      t = Math.imul(t ^ (t >>> 15), t | 1);
      t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
      return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
    };
  }

  createAnimations() {
    Object.keys(HEROES).forEach((heroKey) => createHeroAnimations(this, heroKey));
  }

  createPlayer() {
    this.player = this.physics.add.sprite(300, 634, `${this.heroKey}-idle`, 39);
    this.player.setScale(3.1);
    this.player.setCollideWorldBounds(true);
    this.player.setDepth(10);
    this.player.body.setSize(20, 34);
    this.player.body.setOffset(22, 28);
    this.player.body.setMaxVelocity(350, 1200);
    this.player.body.setDragX(1800);
    this.player.body.setBounce(0);

    this.physics.add.collider(this.player, this.ground);
  }

  createAtmosphere() {
    this.createLightBeamTexture();
    this.createVignetteTexture();

    this.beams = this.add.container(0, 0).setScrollFactor(0).setDepth(40);
    const beamConfigs = [
      { x: 110, y: -90, scaleX: 0.72, scaleY: 1.45, alpha: 0.10, angle: -10 },
      { x: 290, y: -70, scaleX: 1.35, scaleY: 1.25, alpha: 0.15, angle: -6 },
      { x: 520, y: -100, scaleX: 0.58, scaleY: 1.55, alpha: 0.08, angle: 2 },
      { x: 760, y: -80, scaleX: 1.05, scaleY: 1.30, alpha: 0.12, angle: 5 },
      { x: 1030, y: -75, scaleX: 1.55, scaleY: 1.18, alpha: 0.10, angle: 8 },
      { x: 1325, y: -95, scaleX: 0.82, scaleY: 1.48, alpha: 0.09, angle: 12 },
      { x: 1490, y: -85, scaleX: 1.18, scaleY: 1.22, alpha: 0.11, angle: 6 },
    ];

    beamConfigs.forEach((config, index) => {
      const beam = this.add.image(config.x, config.y, 'light-beam')
        .setOrigin(0.5, 0)
        .setScale(config.scaleX, config.scaleY)
        .setAlpha(config.alpha)
        .setAngle(config.angle)
        .setBlendMode(Phaser.BlendModes.SCREEN);

      this.beams.add(beam);

      this.tweens.add({
        targets: beam,
        alpha: { from: config.alpha * 0.65, to: config.alpha * 1.28 },
        x: config.x + (index % 2 === 0 ? 26 : -24),
        angle: config.angle + (index % 3 === 0 ? 2.5 : -2),
        duration: 3600 + index * 650,
        yoyo: true,
        repeat: -1,
        ease: 'Sine.easeInOut',
      });
    });

    this.screenTint = this.add.rectangle(0, 0, GAME_WIDTH, GAME_HEIGHT, 0x173019, 0.12)
      .setOrigin(0, 0)
      .setScrollFactor(0)
      .setDepth(41)
      .setBlendMode(Phaser.BlendModes.MULTIPLY);

    this.vignette = this.add.image(GAME_WIDTH / 2, GAME_HEIGHT / 2, 'vignette')
      .setOrigin(0.5, 0.5)
      .setScrollFactor(0)
      .setDepth(42)
      .setScale(1.12, 1.12)
      .setBlendMode(Phaser.BlendModes.MULTIPLY)
      .setAlpha(1);
  }

  createLightBeamTexture() {
    if (this.textures.exists('light-beam')) return;

    const width = 520;
    const height = 1100;
    const canvas = this.textures.createCanvas('light-beam', width, height);
    const ctx = canvas.getContext();

    ctx.clearRect(0, 0, width, height);
    ctx.save();
    ctx.filter = 'blur(22px)';
    ctx.shadowColor = 'rgba(255, 247, 214, 0.45)';
    ctx.shadowBlur = 28;

    const outer = ctx.createLinearGradient(width / 2, 0, width / 2, height);
    outer.addColorStop(0, 'rgba(255, 251, 228, 0.78)');
    outer.addColorStop(0.14, 'rgba(255, 248, 218, 0.34)');
    outer.addColorStop(0.56, 'rgba(255, 243, 204, 0.10)');
    outer.addColorStop(1, 'rgba(255, 240, 190, 0.00)');

    ctx.fillStyle = outer;
    ctx.beginPath();
    ctx.moveTo(width * 0.42, 0);
    ctx.lineTo(width * 0.58, 0);
    ctx.lineTo(width * 0.95, height);
    ctx.lineTo(width * 0.05, height);
    ctx.closePath();
    ctx.fill();

    const inner = ctx.createLinearGradient(width / 2, 0, width / 2, height);
    inner.addColorStop(0, 'rgba(255, 255, 245, 0.34)');
    inner.addColorStop(0.2, 'rgba(255, 252, 232, 0.18)');
    inner.addColorStop(0.8, 'rgba(255, 245, 210, 0.00)');

    ctx.fillStyle = inner;
    ctx.beginPath();
    ctx.moveTo(width * 0.48, 0);
    ctx.lineTo(width * 0.52, 0);
    ctx.lineTo(width * 0.68, height);
    ctx.lineTo(width * 0.32, height);
    ctx.closePath();
    ctx.fill();
    ctx.restore();
    canvas.refresh();
  }

  createVignetteTexture() {
    if (this.textures.exists('vignette')) return;

    const canvas = this.textures.createCanvas('vignette', GAME_WIDTH, GAME_HEIGHT);
    const ctx = canvas.getContext();
    const gradient = ctx.createRadialGradient(
      GAME_WIDTH / 2,
      GAME_HEIGHT / 2,
      GAME_HEIGHT * 0.10,
      GAME_WIDTH / 2,
      GAME_HEIGHT / 2,
      GAME_WIDTH * 0.56,
    );

    gradient.addColorStop(0, 'rgba(0, 0, 0, 0.00)');
    gradient.addColorStop(0.30, 'rgba(0, 0, 0, 0.05)');
    gradient.addColorStop(0.52, 'rgba(0, 0, 0, 0.18)');
    gradient.addColorStop(0.72, 'rgba(0, 0, 0, 0.42)');
    gradient.addColorStop(0.88, 'rgba(0, 0, 0, 0.70)');
    gradient.addColorStop(1, 'rgba(0, 0, 0, 0.94)');

    ctx.clearRect(0, 0, GAME_WIDTH, GAME_HEIGHT);
    ctx.fillStyle = gradient;
    ctx.fillRect(0, 0, GAME_WIDTH, GAME_HEIGHT);
    canvas.refresh();
  }

  createAudio() {
    this.music = this.sound.add('forestTheme', {
      loop: true,
      volume: 0.42,
    });

    if (!this.sound.locked) {
      this.music.play();
    } else {
      this.sound.once(Phaser.Sound.Events.UNLOCKED, () => {
        if (!this.music.isPlaying) this.music.play();
      });
    }

    this.events.once(Phaser.Scenes.Events.SHUTDOWN, () => {
      if (this.music) this.music.stop();
    });

    this.events.once(Phaser.Scenes.Events.DESTROY, () => {
      if (this.music) this.music.destroy();
    });
  }

  createCamera() {
    this.physics.world.setBounds(0, 0, WORLD_WIDTH, GAME_HEIGHT);
    this.cameras.main.setBounds(0, 0, WORLD_WIDTH, GAME_HEIGHT);
    this.cameras.main.startFollow(this.player, true, 0.08, 0.08);
    this.cameras.main.setDeadzone(220, 120);
  }

  createUI() {
    this.hud = this.add.text(22, 18, 'Press M for Menu', {
      fontFamily: 'Roboto Mono',
      fontSize: '24px',
      color: '#eef7ff',
      stroke: '#0a1218',
      strokeThickness: 5,
    }).setScrollFactor(0).setDepth(60);
  }

  createMenu() {
    this.menuOverlay = this.add.container(0, 0).setScrollFactor(0).setDepth(200).setVisible(false);

    const dim = this.add.rectangle(0, 0, GAME_WIDTH, GAME_HEIGHT, 0x05070a, 0.62).setOrigin(0, 0);
    this.menuOverlay.add(dim);

    const panelX = 168;
    const panelY = 102;
    const panelW = 1264;
    const panelH = 696;
    const panelBits = addOrnamentalPanel(this, panelX, panelY, panelW, panelH, 'parchment');
    this.menuOverlay.add(panelBits.container);

    this.menuTitle = this.add.text(panelX + panelW / 2, panelY + 64, 'Inventory', {
      fontFamily: 'Macondo Swash Caps',
      fontSize: '50px',
      color: '#4a2411',
      stroke: '#f5e2b6',
      strokeThickness: 3,
    }).setOrigin(0.5);
    this.menuOverlay.add(this.menuTitle);

    this.menuHint = this.add.text(panelX + panelW - 38, panelY + 34, 'M / Esc / Backspace to close', {
      fontFamily: 'Roboto Mono',
      fontSize: '16px',
      color: '#4e3720',
    }).setOrigin(1, 0);
    this.menuOverlay.add(this.menuHint);

    this.tabButtons = [];
    const tabStartY = panelY + 176;
    this.menuPages.forEach((page, index) => {
      const button = addOutlinedButton(this, panelX + 146, tabStartY + index * 92, 232, 60, page, index === this.selectedMenuIndex, '28px');
      this.tabButtons.push(button);
      this.menuOverlay.add([button.box, button.inner, button.text]);
    });

    const dividerX = panelX + 282;
    this.contentDivider = this.add.line(0, 0, dividerX, panelY + 124, dividerX, panelY + panelH - 124, 0x6b4016, 0.8)
      .setLineWidth(2, 2);
    this.menuOverlay.add(this.contentDivider);

    this.contentFrameOuter = this.add.rectangle(panelX + 762, panelY + 390, 884, 498, 0x000000, 0)
      .setStrokeStyle(2, 0xdab56a, 0.6);
    this.contentFrameInner = this.add.rectangle(panelX + 762, panelY + 390, 866, 480, 0x000000, 0)
      .setStrokeStyle(1, 0xe7cd96, 0.45);
    this.menuOverlay.add([this.contentFrameOuter, this.contentFrameInner]);

    this.contentBody = this.add.text(panelX + 344, panelY + 166, '', {
      fontFamily: 'Roboto Mono',
      fontSize: '22px',
      color: '#2b1b0f',
      lineSpacing: 14,
      wordWrap: { width: 790 },
    });
    this.menuOverlay.add(this.contentBody);

    this.inventoryList = this.add.container(panelX + 344, panelY + 166);
    this.menuOverlay.add(this.inventoryList);

    this.refreshMenuPage();
  }

  openMenu() {
    if (this.isMenuOpen) return;
    this.isMenuOpen = true;
    this.menuOverlay.setVisible(true);
    this.physics.world.pause();
    this.player.anims.pause();
  }

  closeMenu() {
    if (!this.isMenuOpen) return;
    this.isMenuOpen = false;
    this.menuOverlay.setVisible(false);
    this.physics.world.resume();
  }

  changeMenuPage(direction) {
    this.selectedMenuIndex = Phaser.Math.Wrap(this.selectedMenuIndex + direction, 0, this.menuPages.length);
    this.refreshMenuPage();
  }

  refreshMenuPage() {
    this.tabButtons.forEach((button, index) => {
      button.setActive(index === this.selectedMenuIndex);
    });

    const currentPage = this.menuPages[this.selectedMenuIndex];
    this.menuTitle.setText(currentPage);

    this.inventoryList.removeAll(true);
    this.contentBody.setVisible(false);

    if (currentPage === 'Inventory') {
      let y = 0;
      this.inventoryItems.forEach((item, index) => {
        const rowOuter = this.add.rectangle(370, y + 22, 740, 52, 0x000000, 0)
          .setStrokeStyle(index === 0 ? 2 : 1, index === 0 ? 0xdab56a : 0xe7cd96, index === 0 ? 0.55 : 0.35);
        const rowInner = this.add.rectangle(370, y + 22, 724, 38, 0x9b7740, 0.05)
          .setStrokeStyle(1, 0xf1e6c9, 0.18);
        const icon = this.add.text(28, y + 5, item.icon, {
          fontFamily: 'Macondo Swash Caps',
          fontSize: '28px',
          color: '#6b4016',
        });
        const label = this.add.text(76, y + 8, item.name, {
          fontFamily: 'Roboto Mono',
          fontSize: '20px',
          color: '#2b1b0f',
        });
        const desc = this.add.text(520, y + 10, index === 0 ? 'Worn and weatherproof' : index === 1 ? 'Shows the nearby wilds' : 'A few days of provisions', {
          fontFamily: 'Roboto Mono',
          fontSize: '15px',
          color: '#7a6340',
        }).setOrigin(0.5, 0);
        this.inventoryList.add([rowOuter, rowInner, icon, label, desc]);
        y += 68;
      });
      this.inventoryList.setVisible(true);
    } else {
      this.inventoryList.setVisible(false);
      this.contentBody.setVisible(true);
      this.contentBody.setText(
        'Keyboard\n' +
        'Arrow Left / Right   Move\n' +
        'Arrow Up             Jump\n' +
        'Enter                Confirm / Interact\n' +
        'Space                Action\n' +
        'M                    Open Menu\n' +
        'Esc / Backspace      Cancel / Close\n\n' +
        'Controller (planned)\n' +
        'D-pad / Left Stick   Move / Navigate\n' +
        'South Button         Confirm / Interact\n' +
        'East Button          Cancel / Back\n' +
        'Menu / Start         Open Menu'
      );
    }
  }

  update() {
    if (Phaser.Input.Keyboard.JustDown(this.menuKey)) {
      if (this.isMenuOpen) {
        this.closeMenu();
      } else {
        this.openMenu();
      }
    }

    if (this.isMenuOpen) {
      if (Phaser.Input.Keyboard.JustDown(this.cursors.up)) this.changeMenuPage(-1);
      if (Phaser.Input.Keyboard.JustDown(this.cursors.down)) this.changeMenuPage(1);
      if (Phaser.Input.Keyboard.JustDown(this.escapeKey) || Phaser.Input.Keyboard.JustDown(this.backspaceKey)) {
        this.closeMenu();
      }
      return;
    }

    const moveSpeed = 260;
    const body = this.player.body;
    const onGround = body.blocked.down || body.touching.down;
    let velocityX = 0;

    if (this.cursors.left.isDown) {
      velocityX = -moveSpeed;
      this.facing = 'left';
    } else if (this.cursors.right.isDown) {
      velocityX = moveSpeed;
      this.facing = 'right';
    }

    this.player.setVelocityX(velocityX);

    if (Phaser.Input.Keyboard.JustDown(this.cursors.up) && onGround) {
      this.player.setVelocityY(-760);
    }

    const animPrefix = this.facing === 'left' ? 'left' : 'right';

    if (!onGround) {
      this.player.anims.play(`${this.heroKey}-jump-${animPrefix}`, true);
      if (this.player.body.velocity.y > -20) {
        this.player.anims.pause(this.player.anims.currentFrame);
      }
      this.player.setDepth(10);
    } else if (Math.abs(velocityX) > 5) {
      this.player.anims.play(`${this.heroKey}-walk-${animPrefix}`, true);
      this.player.setDepth(10);
    } else {
      this.player.anims.play(`${this.heroKey}-idle-${animPrefix}`, true);
      this.player.setDepth(10);
    }

    this.bg.tilePositionX = this.cameras.main.scrollX * 0.28;
  }
}

const config = {
  type: Phaser.AUTO,
  width: GAME_WIDTH,
  height: GAME_HEIGHT,
  parent: 'game-wrap',
  pixelArt: true,
  backgroundColor: '#08111a',
  physics: {
    default: 'arcade',
    arcade: {
      gravity: { y: 0 },
      debug: false,
    },
  },
  scene: [StartScene, HeroSelectScene, PrototypeScene],
  scale: {
    mode: Phaser.Scale.FIT,
    autoCenter: Phaser.Scale.CENTER_BOTH,
  },
};

new Phaser.Game(config);
