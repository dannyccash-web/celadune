const GAME_WIDTH = 1600;
const GAME_HEIGHT = 900;
const GROUND_TILE = 160;
const WORLD_WIDTH = 5120;
const GROUND_Y = 740;
const FRAME_W = 64;
const FRAME_H = 64;
const BLACK_TILE_GROUND_Y = GROUND_Y + 39;
const PROP_BASELINE_OFFSET_Y = -24;
const WAGON_BASELINE_Y = BLACK_TILE_GROUND_Y + PROP_BASELINE_OFFSET_Y;
const HUT_BASELINE_Y = BLACK_TILE_GROUND_Y + PROP_BASELINE_OFFSET_Y;
const ONION_PATCH_BASELINE_Y = BLACK_TILE_GROUND_Y + PROP_BASELINE_OFFSET_Y;

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

const FOREST_LADY = {
  key: 'forestLady',
  name: 'Mirelle',
  idle: 'assets/npcs/forest_lady/idle.png',
  walk: 'assets/npcs/forest_lady/walk.png',
  emote: 'assets/npcs/forest_lady/emote.png',
};

function lpcFrameList(sheet, row, start, end) {
  const out = [];
  const rowStart = row * 13;
  for (let i = start; i <= end; i += 1) {
    out.push({ key: sheet, frame: rowStart + i });
  }
  return out;
}

function createHeroAnimations(scene, heroKey) {
  const animations = [
    { key: `${heroKey}-walk-left`, sheet: `${heroKey}-walk`, row: 1, start: 0, end: 8, rate: 10, repeat: -1 },
    { key: `${heroKey}-walk-right`, sheet: `${heroKey}-walk`, row: 3, start: 0, end: 8, rate: 10, repeat: -1 },
    { key: `${heroKey}-idle-left`, sheet: `${heroKey}-idle`, row: 1, start: 0, end: 0, rate: 1, repeat: -1 },
    { key: `${heroKey}-idle-right`, sheet: `${heroKey}-idle`, row: 3, start: 0, end: 0, rate: 1, repeat: -1 },
    { key: `${heroKey}-jump-left`, sheet: `${heroKey}-jump`, row: 1, start: 0, end: 3, rate: 12, repeat: 0 },
    { key: `${heroKey}-jump-right`, sheet: `${heroKey}-jump`, row: 3, start: 0, end: 3, rate: 12, repeat: 0 },
  ];

  animations.forEach((anim) => {
    if (!scene.anims.exists(anim.key)) {
      scene.anims.create({
        key: anim.key,
        frames: lpcFrameList(anim.sheet, anim.row, anim.start, anim.end),
        frameRate: anim.rate,
        repeat: anim.repeat,
      });
    }
  });
}

function createHeroTopDownAnimations(scene, heroKey) {
  const animations = [
    { key: `${heroKey}-topdown-walk-down`, sheet: `${heroKey}-walk`, row: 2, start: 0, end: 8, rate: 10, repeat: -1 },
    { key: `${heroKey}-topdown-walk-left`, sheet: `${heroKey}-walk`, row: 1, start: 0, end: 8, rate: 10, repeat: -1 },
    { key: `${heroKey}-topdown-walk-up`, sheet: `${heroKey}-walk`, row: 0, start: 0, end: 8, rate: 10, repeat: -1 },
    { key: `${heroKey}-topdown-walk-right`, sheet: `${heroKey}-walk`, row: 3, start: 0, end: 8, rate: 10, repeat: -1 },
    { key: `${heroKey}-topdown-idle-down`, sheet: `${heroKey}-idle`, row: 2, start: 0, end: 0, rate: 1, repeat: -1 },
    { key: `${heroKey}-topdown-idle-left`, sheet: `${heroKey}-idle`, row: 1, start: 0, end: 0, rate: 1, repeat: -1 },
    { key: `${heroKey}-topdown-idle-up`, sheet: `${heroKey}-idle`, row: 0, start: 0, end: 0, rate: 1, repeat: -1 },
    { key: `${heroKey}-topdown-idle-right`, sheet: `${heroKey}-idle`, row: 3, start: 0, end: 0, rate: 1, repeat: -1 },
  ];

  animations.forEach((anim) => {
    if (!scene.anims.exists(anim.key)) {
      scene.anims.create({
        key: anim.key,
        frames: lpcFrameList(anim.sheet, anim.row, anim.start, anim.end),
        frameRate: anim.rate,
        repeat: anim.repeat,
      });
    }
  });
}

function createForestLadyAnimations(scene) {
  const animations = [
    { key: 'forestLady-idle-left', sheet: 'forestLady-idle', row: 1, start: 0, end: 1, rate: 3, repeat: -1 },
    { key: 'forestLady-idle-right', sheet: 'forestLady-idle', row: 3, start: 0, end: 1, rate: 3, repeat: -1 },
    { key: 'forestLady-walk-left', sheet: 'forestLady-walk', row: 1, start: 0, end: 8, rate: 8, repeat: -1 },
    { key: 'forestLady-walk-right', sheet: 'forestLady-walk', row: 3, start: 0, end: 8, rate: 8, repeat: -1 },
  ];

  animations.forEach((anim) => {
    if (!scene.anims.exists(anim.key)) {
      scene.anims.create({
        key: anim.key,
        frames: lpcFrameList(anim.sheet, anim.row, anim.start, anim.end),
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
    this.load.image('start-bg', 'assets/ui/celadune_start_screen_background.jpeg');
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
    const maxLogoWidth = 1550;
    const maxLogoHeight = 650;
    const logoScale = Math.min(maxLogoWidth / logoTexture.width, maxLogoHeight / logoTexture.height);
    this.logo.setScale(logoScale);

    this.add.rectangle(GAME_WIDTH / 2, 768, 320, 88, 0x1e140a, 0.72).setStrokeStyle(4, 0xdab56a, 0.9);
    this.add.rectangle(GAME_WIDTH / 2, 768, 300, 68, 0x41250d, 0.94).setStrokeStyle(2, 0xf3dfae, 0.9);
    this.add.text(GAME_WIDTH / 2, 768, 'Start', {
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

    this.add.text(GAME_WIDTH / 2, 838, 'Press Enter to begin', {
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

    const sheen = this.add.rectangle(this.logo.x - 900, this.logo.y, 210, 980, 0xffffff, 0.2)
      .setAngle(-18)
      .setBlendMode(Phaser.BlendModes.SCREEN)
      .setVisible(false)
      .setDepth(this.logo.depth + 1);
    sheen.setMask(mask);

    const runSheen = () => {
      sheen.x = this.logo.x - 900;
      sheen.y = this.logo.y;
      sheen.setVisible(true);
      this.tweens.add({
        targets: sheen,
        x: this.logo.x + 900,
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
    this.music = this.sound.add('celaduneTheme', { loop: true, volume: 0.52 });

    if (!this.sound.locked) {
      this.music.play();
    } else {
      this.sound.once(Phaser.Sound.Events.UNLOCKED, () => {
        if (!this.music.isPlaying) this.music.play();
      });
    }

    this.events.once(Phaser.Scenes.Events.SHUTDOWN, () => this.music?.stop());
    this.events.once(Phaser.Scenes.Events.DESTROY, () => this.music?.destroy());
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
    this.load.image('hero-select-bg', 'assets/ui/celadune_hero_select_screen_background.jpeg');
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

    const bg = this.add.image(GAME_WIDTH / 2, GAME_HEIGHT / 2, 'hero-select-bg');
    const bgTexture = this.textures.get('hero-select-bg').getSourceImage();
    const bgScale = Math.max(GAME_WIDTH / bgTexture.width, GAME_HEIGHT / bgTexture.height);
    bg.setScale(bgScale);

    const panelX = 265;
    const panelY = 152;
    const panelW = 1070;
    const panelH = 596;

    const parchment = this.add.tileSprite(panelX + panelW / 2, panelY + panelH / 2, panelW, panelH, 'parchment');
    const parchmentSource = this.textures.get('parchment').getSourceImage();
    parchment.setTileScale(160 / parchmentSource.width, 160 / parchmentSource.height);
    parchment.setAlpha(0.98);

    this.add.rectangle(panelX + panelW / 2, panelY + panelH / 2, panelW, panelH, 0x000000, 0)
      .setStrokeStyle(6, 0x5b3717, 1);
    this.add.rectangle(panelX + panelW / 2, panelY + panelH / 2, panelW - 18, panelH - 18, 0x000000, 0)
      .setStrokeStyle(2, 0xdab56a, 0.95);

    this.add.text(GAME_WIDTH / 2, panelY + 62, 'Select Your Hero', {
      fontFamily: 'Macondo Swash Caps',
      fontSize: '48px',
      color: '#4a2411',
      stroke: '#f5e2b6',
      strokeThickness: 3,
    }).setOrigin(0.5);

    this.add.text(GAME_WIDTH / 2, panelY + panelH - 54, 'Left / Right to choose  •  Enter to confirm', {
      fontFamily: 'Roboto Mono',
      fontSize: '20px',
      color: '#4e3720',
    }).setOrigin(0.5);

    this.heroCards = this.heroOrder.map((heroKey, index) => {
      const x = index === 0 ? 640 : 960;
      const y = 448;

      const outer = this.add.rectangle(x, y, 250, 332, 0x000000, 0).setStrokeStyle(4, 0xdab56a, 0.98);
      const inner = this.add.rectangle(x, y, 232, 314, 0x000000, 0).setStrokeStyle(2, 0xe9cf96, 0.92);
      const portraitGlow = this.add.rectangle(x, y - 34, 166, 196, 0xa37a3f, 0.08).setStrokeStyle(1, 0xb88945, 0.22);
      const sprite = this.add.sprite(x, y - 36, `${heroKey}-idle`, 39).setScale(3.2);
      const name = this.add.text(x, y + 104, HEROES[heroKey].name, {
        fontFamily: 'Macondo Swash Caps',
        fontSize: '34px',
        color: '#4a2411',
      }).setOrigin(0.5);
      const role = this.add.text(x, y + 138, heroKey === 'caelan' ? 'Fighter' : 'Mage', {
        fontFamily: 'Roboto Mono',
        fontSize: '18px',
        color: '#5c4528',
      }).setOrigin(0.5);

      return { key: heroKey, outer, inner, portraitGlow, sprite, name, role };
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
      card.outer.setStrokeStyle(active ? 4 : 3, active ? 0x6b4016 : 0xdab56a, 0.98);
      card.inner.setStrokeStyle(active ? 2 : 1, active ? 0x3f2410 : 0xe9cf96, active ? 0.98 : 0.82);
      card.portraitGlow.setAlpha(active ? 0.12 : 0.05);
      card.name.setColor(active ? '#3a1b0a' : '#6d4f24');
      card.role.setColor(active ? '#4a311a' : '#7e6541');
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
  constructor(sceneKey = 'PrototypeScene') {
    super(sceneKey);
    this.facing = 'right';
    this.selectedMenuIndex = 0;
    this.menuPages = ['Inventory', 'Equipment', 'Controls'];
    this.menuMode = 'categories';
    this.menuSectionIndex = 0;
    this.menuItemIndex = 0;
    this.menuActionIndex = 0;
    this.inventoryItems = [];
    this.equipmentItems = [];
    this.pendingItemPopupQueue = [];

    this.npcState = 'idle';
    this.npcFacing = 'right';
    this.dialogueChoiceIndex = 0;
    this.questState = 'notOffered';
    this.scriptedNpcTargetX = null;
    this.scriptedNpcCallback = null;
    this.isTransitioningToInterior = false;
    this.isSceneTransitioning = false;
  }

  init(data) {
    this.heroKey = data?.heroKey || 'caelan';
    this.startX = data?.startX ?? 300;
    this.startY = data?.startY ?? 620;
    this.inventoryItems = Array.isArray(data?.inventoryItems) ? data.inventoryItems.map((item) => ({ ...item })) : [];
    this.equipmentItems = Array.isArray(data?.equipmentItems) ? data.equipmentItems.map((item) => ({ ...item })) : [];
    this.isSceneTransitioning = false;
    this.isTransitioningToInterior = false;
    if (this.input?.keyboard) {
      this.input.keyboard.enabled = true;
      this.input.keyboard.resetKeys();
    }
  }

  preload() {
    this.load.image('forest', 'assets/bg/forest.png');
    this.load.image('cityBg', 'assets/bg/city_background.jpeg');
    this.load.image('blackTile', 'assets/tiles/black_tile.png');
    this.load.image('ground0', 'assets/tiles/ground_tile.png');
    this.load.image('ground1', 'assets/tiles/ground_tile_1.png');
    this.load.image('ground2', 'assets/tiles/ground_tile_2.png');
    this.load.image('ground3', 'assets/tiles/ground_tile_3.png');
    this.load.image('cityGround1', 'assets/tiles/cobblestone_tile_1.png');
    this.load.image('cityGround2', 'assets/tiles/cobblestone_tile_2.png');
    this.load.image('cityGround3', 'assets/tiles/cobblestone_tile_3.png');
    this.load.image('parchment', 'assets/ui/parchment.png');
    this.load.image('forestHut', 'assets/props/forest_hut.png');
    this.load.image('forestHutInterior', 'assets/bg/forest_hut_interior.jpeg');
    this.load.image('brokenWagon', 'assets/props/broken_wagon.png');
    this.load.image('onionPatch', 'assets/props/onion_patch.png');
    this.load.image('menuOnions', 'assets/ui/onions.png');
    this.load.audio('forestTheme', 'assets/audio/celadune_forest.mp3');
    // Optional city track can be dropped in as assets/audio/city_theme.mp3 for the City scene.
    this.load.audio('cityTheme', 'assets/audio/city_theme.mp3');
    this.load.audio('writingSfx', 'assets/sfx/writing.mp3');
    this.load.spritesheet('forestLady-idle', FOREST_LADY.idle, { frameWidth: FRAME_W, frameHeight: FRAME_H });
    this.load.spritesheet('forestLady-walk', FOREST_LADY.walk, { frameWidth: FRAME_W, frameHeight: FRAME_H });
    this.load.spritesheet('forestLady-emote', FOREST_LADY.emote, { frameWidth: FRAME_W, frameHeight: FRAME_H });
    this.load.spritesheet('forestLady-portrait', 'assets/npcs/forest_lady/portrait.png', { frameWidth: FRAME_W, frameHeight: 48 });

    Object.values(HEROES).forEach((hero) => {
      this.load.spritesheet(`${hero.key}-walk`, hero.walk, { frameWidth: FRAME_W, frameHeight: FRAME_H });
      this.load.spritesheet(`${hero.key}-idle`, hero.idle, { frameWidth: FRAME_W, frameHeight: FRAME_H });
      this.load.spritesheet(`${hero.key}-jump`, hero.jump, { frameWidth: FRAME_W, frameHeight: FRAME_H });
    });
  }

  create() {
    this.physics.world.gravity.y = 1800;

    this.createParallaxBackground();
    this.createGround();
    this.createAnimations();
    this.createPlayer();
    this.createNPC();
    this.createProps();
    this.createAtmosphere();
    this.createCamera();
    this.createUI();
    this.createItemReceiveUI();
    this.createAudio();
    this.createMenu();
    this.createDialogueUI();

    this.player.setPosition(this.startX, this.startY);

    this.cursors = this.input.keyboard.createCursorKeys();
    this.menuKey = this.input.keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.M);
    this.enterKey = this.input.keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.ENTER);
    this.spaceKey = this.input.keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.SPACE);
    this.escapeKey = this.input.keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.ESC);
    this.backspaceKey = this.input.keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.BACKSPACE);
  }

  getMusicConfig() {
    return { key: 'forestTheme', volume: 0.42 };
  }

  configureBackgroundTexture(textureKey) {
    const texture = this.textures.get(textureKey);
    if (texture?.setFilter) {
      texture.setFilter(Phaser.Textures.FilterMode.LINEAR);
    }
    return texture?.getSourceImage?.() ?? null;
  }

  disableKeyboardDuringTransition() {
    if (!this.input?.keyboard) return;
    this.input.keyboard.enabled = false;
    this.input.keyboard.resetKeys();
  }

  enableKeyboardInput() {
    if (!this.input?.keyboard) return;
    this.input.keyboard.enabled = true;
    this.input.keyboard.resetKeys();
  }

  createParallaxBackground() {
    const forestTexture = this.configureBackgroundTexture('forest');
    const scale = GAME_HEIGHT / forestTexture.height;
    this.bgScale = scale;

    this.bg = this.add.tileSprite(0, 0, GAME_WIDTH, GAME_HEIGHT, 'forest')
      .setOrigin(0, 0)
      .setScrollFactor(0)
      .setDepth(-20);

    this.bg.setTileScale(scale, scale);
  }

  createGround() {
    this.ground = this.physics.add.staticGroup();
    this.groundBack = this.add.group();
    this.groundFront = this.add.group();

    const tilesAcross = Math.ceil(WORLD_WIDTH / GROUND_TILE);
    const decorativeKeys = ['ground0', 'ground1', 'ground2', 'ground3'];
    const rng = this.createSeededRandom(0xC0FFEE);
    let previousKey = null;

    const blackVisualOffsetY = 34;
    const collisionStripY = GROUND_Y + 24;
    const collisionStripHeight = 22;

    for (let i = 0; i < tilesAcross; i += 1) {
      let tileKey = decorativeKeys[Math.floor(rng() * decorativeKeys.length)];
      if (decorativeKeys.length > 1 && tileKey === previousKey) {
        tileKey = decorativeKeys[(decorativeKeys.indexOf(tileKey) + 1 + Math.floor(rng() * (decorativeKeys.length - 1))) % decorativeKeys.length];
      }
      previousKey = tileKey;

      const x = i * GROUND_TILE + GROUND_TILE / 2;
      const visualY = GROUND_Y + GROUND_TILE / 2;

      const blackBase = this.add.image(x, visualY + blackVisualOffsetY, 'blackTile')
        .setDisplaySize(GROUND_TILE, 150)
        .setDepth(2);
      this.groundBack.add(blackBase);

      const collider = this.add.rectangle(x, collisionStripY, GROUND_TILE, collisionStripHeight, 0x000000, 0);
      this.physics.add.existing(collider, true);
      this.ground.add(collider);

      const frontTile = this.add.image(x, visualY, tileKey)
        .setDisplaySize(GROUND_TILE, GROUND_TILE)
        .setDepth(12);
      this.groundFront.add(frontTile);
    }

    this.groundShadow = this.add.rectangle(WORLD_WIDTH / 2, GROUND_Y + 10, WORLD_WIDTH, 18, 0x13210f, 0.12)
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
    Object.keys(HEROES).forEach((heroKey) => {
      createHeroAnimations(this, heroKey);
      createHeroTopDownAnimations(this, heroKey);
    });
    createForestLadyAnimations(this);
  }

  createPlayer() {
    this.player = this.physics.add.sprite(300, 620, `${this.heroKey}-idle`, 39);
    this.playerBaseScaleX = 3.1;
    this.playerBaseScaleY = 3.1;
    this.player.setScale(this.playerBaseScaleX, this.playerBaseScaleY);
    this.player.setCollideWorldBounds(false);
    this.player.setDepth(9);
    this.player.body.setSize(20, 34);
    this.player.body.setOffset(22, 28);
    this.player.body.setMaxVelocity(350, 1200);
    this.player.body.setDragX(1800);
    this.player.body.setBounce(0);

    this.physics.add.collider(this.player, this.ground);

  }

  createNPC() {
    this.npc = this.physics.add.sprite(2540, 620, 'forestLady-idle', 26);
    this.npc.setScale(3.0);
    this.npc.setDepth(9);
    this.npc.body.setSize(20, 34);
    this.npc.body.setOffset(22, 28);
    this.npc.body.setCollideWorldBounds(true);
    this.npc.setImmovable(false);
    this.npcMinX = 2420;
    this.npcMaxX = 2660;
    this.physics.add.collider(this.npc, this.ground);
    this.npc.anims.play('forestLady-idle-right', true);

    this.npcTooltip = this.add.container(0, 0).setDepth(30).setVisible(false);
    const tooltipBg = this.add.rectangle(0, 0, 110, 30, 0x1c1209, 0.82).setStrokeStyle(2, 0xdab56a, 0.95);
    const tooltipText = this.add.text(0, 0, FOREST_LADY.name, {
      fontFamily: 'Roboto Mono',
      fontSize: '16px',
      color: '#f7edd6',
    }).setOrigin(0.5);
    this.npcTooltip.add([tooltipBg, tooltipText]);

    this.scheduleNpcBehavior(500);
  }

  scheduleNpcBehavior(delay = Phaser.Math.Between(900, 1800)) {
    this.npcBehaviorEvent?.remove(false);
    this.npcBehaviorEvent = this.time.delayedCall(delay, () => {
      if (this.isDialogueOpen || this.isMenuOpen) {
        this.scheduleNpcBehavior(700);
        return;
      }

      const action = Phaser.Math.RND.pick(['idle', 'idle', 'walkLeft', 'walkRight']);
      if (action === 'idle') {
        this.npcState = 'idle';
        this.npc.setVelocityX(0);
        this.npc.anims.play(this.npcFacing === 'left' ? 'forestLady-idle-left' : 'forestLady-idle-right', true);
        this.scheduleNpcBehavior();
      } else if (action === 'walkLeft') {
        this.npcState = 'walk';
        this.npcFacing = 'left';
        this.npc.setVelocityX(-55);
        this.npc.anims.play('forestLady-walk-left', true);
        this.scheduleNpcBehavior(Phaser.Math.Between(900, 1500));
      } else {
        this.npcState = 'walk';
        this.npcFacing = 'right';
        this.npc.setVelocityX(55);
        this.npc.anims.play('forestLady-walk-right', true);
        this.scheduleNpcBehavior(Phaser.Math.Between(900, 1500));
      }
    });
  }


  createProps() {
    this.propDepth = 7;

    this.wagon = this.add.image(360, WAGON_BASELINE_Y, 'brokenWagon')
      .setOrigin(0.5, 1)
      .setScale(0.44)
      .setDepth(this.propDepth);

    this.hut = this.add.image(2240, HUT_BASELINE_Y, 'forestHut')
      .setOrigin(0.5, 1)
      .setScale(0.80)
      .setDepth(this.propDepth);

    this.hutDoorZone = this.add.zone(this.hut.x + 34, HUT_BASELINE_Y - 80, 150, 132).setOrigin(0.5, 0.5);
    this.physics.add.existing(this.hutDoorZone, true);

    this.hutTooltip = this.add.container(0, 0).setDepth(30).setVisible(false);
    const hutTooltipBg = this.add.rectangle(0, 0, 150, 30, 0x1c1209, 0.82).setStrokeStyle(2, 0xdab56a, 0.95);
    const hutTooltipText = this.add.text(0, 0, "Mirelle's Hut", {
      fontFamily: 'Roboto Mono',
      fontSize: '16px',
      color: '#f7edd6',
    }).setOrigin(0.5);
    this.hutTooltip.add([hutTooltipBg, hutTooltipText]);

    this.onionPatch = this.add.image(2790, ONION_PATCH_BASELINE_Y, 'onionPatch')
      .setOrigin(0.5, 1)
      .setScale(0.34)
      .setDepth(this.propDepth);

    this.onionPatchTooltip = this.add.container(0, 0).setDepth(30).setVisible(false);
    const onionTooltipBg = this.add.rectangle(0, 0, 132, 30, 0x1c1209, 0.82).setStrokeStyle(2, 0xdab56a, 0.95);
    const onionTooltipText = this.add.text(0, 0, 'Onion Patch', {
      fontFamily: 'Roboto Mono',
      fontSize: '16px',
      color: '#f7edd6',
    }).setOrigin(0.5);
    this.onionPatchTooltip.add([onionTooltipBg, onionTooltipText]);
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

  getMusicConfig() {
    return { key: 'forestTheme', volume: 0.42 };
  }

  fadeOutMusic(duration = 220) {
    if (!this.music || !this.music.isPlaying) return;
    this.tweens.add({
      targets: this.music,
      volume: 0,
      duration,
      ease: 'Linear',
      onComplete: () => {
        this.music?.stop();
        if (this.music) this.music.volume = this.musicTargetVolume ?? 0.42;
      },
    });
  }

  createAudio() {
    const musicConfig = this.getMusicConfig();
    this.musicTargetVolume = musicConfig.volume;
    this.music = this.sound.add(musicConfig.key, { loop: true, volume: 0 });
    this.writingSound = this.sound.add('writingSfx', { loop: true, volume: 0.18 });

    const startMusic = () => {
      if (!this.music.isPlaying) {
        this.music.play();
      }
      this.tweens.killTweensOf(this.music);
      this.music.volume = 0;
      this.tweens.add({
        targets: this.music,
        volume: this.musicTargetVolume,
        duration: 320,
        ease: 'Linear',
      });
    };

    if (!this.sound.locked) {
      startMusic();
    } else {
      this.sound.once(Phaser.Sound.Events.UNLOCKED, startMusic);
    }

    this.events.once(Phaser.Scenes.Events.SHUTDOWN, () => {
      this.music?.stop();
      this.writingSound?.stop();
    });

    this.events.once(Phaser.Scenes.Events.DESTROY, () => {
      this.music?.destroy();
      this.writingSound?.destroy();
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

  createItemReceiveUI() {
    this.itemReceiveTimer = null;
    this.itemReceiveQueueTimer = null;
    this.itemReceiveContainer = this.add.container(0, 0).setDepth(250).setVisible(false);

    this.itemReceiveIcon = this.add.image(0, -62, 'menuOnions')
      .setOrigin(0.5, 1)
      .setDisplaySize(60, 60)
      .setVisible(false);

    this.itemReceiveBg = this.add.rectangle(0, 0, 180, 34, 0x1c1209, 0.86)
      .setStrokeStyle(2, 0xdab56a, 0.95);

    this.itemReceiveText = this.add.text(0, 0, '', {
      fontFamily: 'Roboto Mono',
      fontSize: '16px',
      color: '#f7edd6',
      fontStyle: 'bold',
      align: 'center',
    }).setOrigin(0.5);

    this.itemReceiveContainer.add([this.itemReceiveIcon, this.itemReceiveBg, this.itemReceiveText]);
  }

  queueItemReceivePopup(item) {
    if (!item?.name) return;
    this.pendingItemPopupQueue.push({ ...item });
  }

  flushQueuedItemReceivePopups() {
    if (this.isDialogueOpen || !this.pendingItemPopupQueue.length) return;
    if (this.itemReceiveContainer?.visible || this.itemReceiveQueueTimer) return;

    const nextItem = this.pendingItemPopupQueue.shift();
    if (!nextItem) return;
    this.showItemReceivePopup(nextItem);
  }

  showItemReceivePopup(item) {
    if (!item?.name) return;

    if (this.isDialogueOpen) {
      this.queueItemReceivePopup(item);
      return;
    }

    const hasTexture = !!item.texture;
    this.itemReceiveTimer?.remove(false);
    this.itemReceiveQueueTimer?.remove(false);

    this.itemReceiveText.setText(item.name);
    const textWidth = Math.ceil(this.itemReceiveText.width) + 34;
    this.itemReceiveBg.setSize(Math.max(150, textWidth), 34);

    this.itemReceiveIcon.setVisible(hasTexture);
    if (hasTexture) {
      this.itemReceiveIcon.setTexture(item.texture).setDisplaySize(60, 60).setY(-62);
    }

    this.itemReceiveContainer.setAlpha(1).setVisible(true);
    this.itemReceiveContainer.setPosition(this.player.x, this.player.y - 116);

    this.itemReceiveTimer = this.time.delayedCall(3000, () => {
      this.itemReceiveContainer.setVisible(false);
      this.itemReceiveTimer = null;
      if (this.pendingItemPopupQueue.length && !this.isDialogueOpen) {
        this.itemReceiveQueueTimer = this.time.delayedCall(0, () => {
          this.itemReceiveQueueTimer = null;
          this.flushQueuedItemReceivePopups();
        });
      }
    });
  }

  createMenu() {
    this.menuOverlay = this.add.container(0, 0).setScrollFactor(0).setDepth(200).setVisible(false);

    const dim = this.add.rectangle(0, 0, GAME_WIDTH, GAME_HEIGHT, 0x05070a, 0.62).setOrigin(0, 0);
    this.menuOverlay.add(dim);

    const panelX = 180;
    const panelY = 110;
    const panelW = 1240;
    const panelH = 680;
    this.menuPanel = { x: panelX, y: panelY, w: panelW, h: panelH };

    const parchment = this.add.tileSprite(panelX + panelW / 2, panelY + panelH / 2, panelW, panelH, 'parchment');
    const parchmentSource = this.textures.get('parchment').getSourceImage();
    parchment.setTileScale(160 / parchmentSource.width, 160 / parchmentSource.height);
    parchment.setAlpha(0.98);
    this.menuOverlay.add(parchment);

    const borderOuter = this.add.rectangle(panelX + panelW / 2, panelY + panelH / 2, panelW, panelH, 0x000000, 0)
      .setStrokeStyle(6, 0x5b3717, 1);
    const borderInner = this.add.rectangle(panelX + panelW / 2, panelY + panelH / 2, panelW - 18, panelH - 18, 0x000000, 0)
      .setStrokeStyle(2, 0xdab56a, 0.95);
    this.menuOverlay.add(borderOuter);
    this.menuOverlay.add(borderInner);

    this.menuTitle = this.add.text(panelX + 410, panelY + 56, 'Inventory', {
      fontFamily: 'Macondo Swash Caps',
      fontSize: '46px',
      color: '#4a2411',
      stroke: '#f5e2b6',
      strokeThickness: 3,
    }).setOrigin(0.5, 0.5);
    this.menuOverlay.add(this.menuTitle);

    this.menuHint = this.add.text(panelX + panelW - 40, panelY + 38, 'M / Esc / Backspace to close', {
      fontFamily: 'Roboto Mono',
      fontSize: '16px',
      color: '#4e3720',
    }).setOrigin(1, 0);
    this.menuOverlay.add(this.menuHint);

    this.categoryButtons = [];
    const tabStartY = panelY + 152;
    this.menuPages.forEach((page, index) => {
      const tabBox = this.add.rectangle(panelX + 135, tabStartY + index * 88, 220, 58, 0x000000, 0)
        .setStrokeStyle(3, 0xdab56a, 0.95);
      const tabText = this.add.text(panelX + 135, tabStartY + index * 88, page, {
        fontFamily: 'Macondo Swash Caps',
        fontSize: '28px',
        color: '#5b3417',
      }).setOrigin(0.5);
      this.categoryButtons.push({ box: tabBox, text: tabText });
      this.menuOverlay.add(tabBox);
      this.menuOverlay.add(tabText);
    });

    this.contentDivider = this.add.rectangle(panelX + 265, panelY + panelH / 2, 2, panelH - 120, 0x6b4016, 0.8)
      .setOrigin(0.5, 0.5);
    this.menuOverlay.add(this.contentDivider);

    this.gridContainer = this.add.container(panelX + 322, panelY + 102);
    this.menuOverlay.add(this.gridContainer);

    this.controlsContainer = this.add.container(panelX + 322, panelY + 126);
    this.menuOverlay.add(this.controlsContainer);

    this.emptyStateText = this.add.text(panelX + 322, panelY + 150, '', {
      fontFamily: 'Roboto Mono',
      fontSize: '24px',
      color: '#5d4322',
    }).setVisible(false);
    this.menuOverlay.add(this.emptyStateText);

    this.actionMenuContainer = this.add.container(panelX + 878, panelY + 182).setVisible(false);
    this.actionMenuBg = this.add.rectangle(0, 0, 230, 0, 0xf0e0b8, 0.96)
      .setOrigin(0, 0)
      .setStrokeStyle(3, 0x5b3717, 0.95);
    this.actionMenuTitle = this.add.text(18, 14, 'Actions', {
      fontFamily: 'Macondo Swash Caps',
      fontSize: '28px',
      color: '#4a2411',
    });
    this.actionMenuList = this.add.container(0, 0);
    this.actionMenuContainer.add([this.actionMenuBg, this.actionMenuTitle, this.actionMenuList]);
    this.menuOverlay.add(this.actionMenuContainer);

    this.controlsHeadingKeyboard = this.add.text(0, 0, 'KEYBOARD', {
      fontFamily: 'Roboto Mono',
      fontSize: '24px',
      fontStyle: 'bold',
      color: '#3f2411',
    });
    this.controlsKeyboardBody = this.add.text(0, 38, '', {
      fontFamily: 'Roboto Mono',
      fontSize: '21px',
      color: '#2b1b0f',
      lineSpacing: 10,
    });
    this.controlsHeadingController = this.add.text(0, 282, 'CONTROLLER (PLANNED)', {
      fontFamily: 'Roboto Mono',
      fontSize: '24px',
      fontStyle: 'bold',
      color: '#3f2411',
    });
    this.controlsControllerBody = this.add.text(0, 320, '', {
      fontFamily: 'Roboto Mono',
      fontSize: '21px',
      color: '#2b1b0f',
      lineSpacing: 10,
    });
    this.controlsContainer.add([
      this.controlsHeadingKeyboard,
      this.controlsKeyboardBody,
      this.controlsHeadingController,
      this.controlsControllerBody,
    ]);

    this.refreshMenuPage();
  }

  getCurrentSectionItems() {
    const currentPage = this.menuPages[this.menuSectionIndex];
    if (currentPage === 'Inventory') return this.inventoryItems;
    if (currentPage === 'Equipment') return this.equipmentItems;
    return [];
  }

  openItemActionMenu() {
    const items = this.getCurrentSectionItems();
    const item = items[this.menuItemIndex];
    if (!item || !item.actions?.length) return;
    this.menuMode = 'actions';
    this.menuActionIndex = 0;
    this.refreshMenuPage();
  }

  performMenuAction(actionLabel) {
    const items = this.getCurrentSectionItems();
    const item = items[this.menuItemIndex];
    if (!item) return;

    if (item.name === 'Onions' && actionLabel === 'Eat') {
      items.splice(this.menuItemIndex, 1);
      this.menuItemIndex = Math.max(0, Math.min(this.menuItemIndex, items.length - 1));
      this.menuMode = 'section';
      this.refreshMenuPage();
      return;
    }

    this.menuMode = 'section';
    this.refreshMenuPage();
  }

  refreshMenuPage() {
    this.selectedMenuIndex = this.menuSectionIndex;
    this.menuPages.forEach((page, index) => {
      const focused = index === this.menuSectionIndex;
      const active = this.menuMode === 'categories' ? focused : (this.menuMode !== 'categories' && focused);
      const strokeColor = active ? 0x6b4016 : 0xdab56a;
      const strokeWidth = active ? 4 : 3;
      this.categoryButtons[index].box.setStrokeStyle(strokeWidth, strokeColor, 0.98);
      this.categoryButtons[index].text.setColor(active ? '#3c1d0d' : '#7f6131');
      this.categoryButtons[index].box.setFillStyle(this.menuMode === 'categories' && focused ? 0x9b7740 : 0x000000, this.menuMode === 'categories' && focused ? 0.08 : 0);
    });

    const currentPage = this.menuPages[this.menuSectionIndex];
    this.menuTitle.setText(currentPage);

    this.gridContainer.removeAll(true);
    this.actionMenuList.removeAll(true);
    this.gridContainer.setVisible(false);
    this.controlsContainer.setVisible(false);
    this.actionMenuContainer.setVisible(false);
    this.emptyStateText.setVisible(false);

    if (currentPage === 'Controls') {
      this.controlsContainer.setVisible(true);
      this.controlsKeyboardBody.setText(
        'Arrow Left / Right  Move\n' +
        'Arrow Up            Jump\n' +
        'Enter               Confirm / Interact\n' +
        'Space               Action\n' +
        'M                   Open Menu\n' +
        'Esc / Backspace     Cancel / Close'
      );
      this.controlsControllerBody.setText(
        'D-pad / Left Stick  Move / Navigate\n' +
        'South Button        Confirm / Interact\n' +
        'East Button         Cancel / Back\n' +
        'Menu / Start        Open Menu'
      );
      return;
    }

    const items = this.getCurrentSectionItems();
    this.gridContainer.setVisible(true);

    const cols = 6;
    const slotSize = 120;
    const gapX = 24;
    const gapY = 30;
    const labelGap = 8;
    const stepX = slotSize + gapX;
    const stepY = slotSize + 48 + gapY;

    if (!items.length) {
      this.emptyStateText.setText(currentPage === 'Equipment' ? 'No equipment yet.' : 'No items yet.');
      this.emptyStateText.setVisible(true);
    }

    items.forEach((item, index) => {
      const col = index % cols;
      const row = Math.floor(index / cols);
      const x = col * stepX;
      const y = row * stepY;
      const slot = this.add.rectangle(x, y, slotSize, slotSize, 0x000000, 0)
        .setOrigin(0, 0)
        .setStrokeStyle(3, 0xdab56a, 0.98);

      const isSelected = this.menuMode !== 'categories' && index === this.menuItemIndex;
      if (isSelected) {
        slot.setStrokeStyle(4, 0x6b4016, 1);
      }

      const children = [slot];
      if (item.texture) {
        const icon = this.add.image(x + slotSize / 2, y + slotSize / 2 - 6, item.texture)
          .setDisplaySize(86, 86)
          .setOrigin(0.5);
        children.push(icon);
      }

      const label = this.add.text(x + slotSize / 2, y + slotSize + labelGap, item.name, {
        fontFamily: 'Roboto Mono',
        fontSize: '14px',
        color: '#2b1b0f',
        align: 'center',
        wordWrap: { width: slotSize + 12 },
      }).setOrigin(0.5, 0);
      children.push(label);
      this.gridContainer.add(children);
    });

    if (this.menuMode === 'actions') {
      const item = items[this.menuItemIndex];
      if (!item) {
        this.menuMode = 'section';
        return this.refreshMenuPage();
      }
      this.actionMenuContainer.setVisible(true);
      this.actionMenuTitle.setText(item.name);
      const menuWidth = 230;
      const rowHeight = 42;
      const menuHeight = 54 + item.actions.length * rowHeight + 14;
      this.actionMenuBg.setSize(menuWidth, menuHeight);
      item.actions.forEach((action, index) => {
        const optionBg = this.add.rectangle(14, 54 + index * rowHeight, menuWidth - 28, rowHeight - 2, 0x000000, 0)
          .setOrigin(0, 0)
          .setStrokeStyle(index === this.menuActionIndex ? 3 : 2, index === this.menuActionIndex ? 0x6b4016 : 0xdab56a, 0.95)
          .setFillStyle(index === this.menuActionIndex ? 0x9b7740 : 0x000000, index === this.menuActionIndex ? 0.08 : 0);
        const optionText = this.add.text(30, 61 + index * rowHeight, action, {
          fontFamily: 'Roboto Mono',
          fontSize: '20px',
          color: '#2b1b0f',
        });
        this.actionMenuList.add([optionBg, optionText]);
      });
    }
  }

  createDialogueUI() {
    this.dialogueOverlay = this.add.container(0, 0).setScrollFactor(0).setDepth(230).setVisible(false);
    const dim = this.add.rectangle(0, 0, GAME_WIDTH, GAME_HEIGHT, 0x05070a, 0.54).setOrigin(0, 0);
    this.dialogueOverlay.add(dim);

    const panelW = 1100;
    const panelH = 440;
    const panelX = Math.round((GAME_WIDTH - panelW) / 2);
    const panelY = Math.round((GAME_HEIGHT - panelH) / 2);
    this.dialoguePanel = { x: panelX, y: panelY, w: panelW, h: panelH };

    const parchment = this.add.tileSprite(panelX + panelW / 2, panelY + panelH / 2, panelW, panelH, 'parchment');
    const parchmentSource = this.textures.get('parchment').getSourceImage();
    parchment.setTileScale(160 / parchmentSource.width, 160 / parchmentSource.height);
    parchment.setAlpha(0.98);
    this.dialogueOverlay.add(parchment);

    const borderOuter = this.add.rectangle(panelX + panelW / 2, panelY + panelH / 2, panelW, panelH, 0x000000, 0)
      .setStrokeStyle(6, 0x5b3717, 1);
    const borderInner = this.add.rectangle(panelX + panelW / 2, panelY + panelH / 2, panelW - 18, panelH - 18, 0x000000, 0)
      .setStrokeStyle(2, 0xdab56a, 0.95);
    this.dialogueOverlay.add(borderOuter);
    this.dialogueOverlay.add(borderInner);

    const contentLeft = panelX + 36;
    const contentTop = panelY + 30;
    const contentRight = panelX + panelW - 36;
    const portraitSize = 188;
    const portraitInner = portraitSize - 4;
    const portraitX = contentLeft + portraitSize / 2;
    const portraitY = contentTop + portraitSize / 2;
    const textX = panelX + 290;
    const textRight = contentRight;

    this.portraitFrame = this.add.rectangle(portraitX, portraitY, portraitSize, portraitSize, 0x000000, 0)
      .setStrokeStyle(2, 0xdab56a, 0.95);
    this.dialogueOverlay.add(this.portraitFrame);

    this.dialoguePortraitRect = {
      left: portraitX - portraitInner / 2,
      top: portraitY - portraitInner / 2,
      width: portraitInner,
      height: portraitInner,
      bottom: portraitY + portraitInner / 2,
      centerX: portraitX,
      centerY: portraitY,
    };

    this.portraitSceneBg = this.add.tileSprite(portraitX, portraitY, portraitInner, portraitInner, 'forest').setOrigin(0.5);
    this.portraitSceneBg.setTileScale(this.bgScale || 1, this.bgScale || 1);
    this.dialogueOverlay.add(this.portraitSceneBg);

    this.portraitMaskGraphics = this.add.graphics();
    this.portraitMaskGraphics.setScrollFactor(0).setDepth(229).setVisible(false);
    this.portraitMaskGraphics.fillStyle(0xffffff, 1);
    this.portraitMaskGraphics.fillRect(
      this.dialoguePortraitRect.left,
      this.dialoguePortraitRect.top,
      this.dialoguePortraitRect.width,
      this.dialoguePortraitRect.height
    );
    this.portraitMask = this.portraitMaskGraphics.createGeometryMask();
    this.portraitSceneBg.setMask(this.portraitMask);

    this.npcPortrait = this.add.sprite(portraitX, this.dialoguePortraitRect.bottom + 82, 'forestLady-idle', 26)
      .setOrigin(0.5, 1)
      .setScale(5.1)
      .setMask(this.portraitMask)
      .setVisible(true);
    this.dialogueOverlay.add(this.npcPortrait);

    this.dialogueSpeakerText = this.add.text(textX, contentTop + 10, FOREST_LADY.name, {
      fontFamily: 'Macondo Swash Caps',
      fontSize: '34px',
      color: '#4a2411',
    });
    this.dialogueOverlay.add(this.dialogueSpeakerText);

    this.dialogueText = this.add.text(textX, contentTop + 66, '', {
      fontFamily: 'Roboto Mono',
      fontSize: '20px',
      color: '#2b1b0f',
      lineSpacing: 10,
      wordWrap: { width: textRight - textX },
      maxLines: 5,
    });
    this.dialogueOverlay.add(this.dialogueText);

    this.dialogueOptionWidth = panelW - 72;
    this.dialogueOptions = this.add.container(contentLeft, panelY + panelH - 142);
    this.dialogueOverlay.add(this.dialogueOptions);

    this.dialogueHint = this.add.text(panelX + panelW - 34, panelY + 18, 'Enter to choose', {
      fontFamily: 'Roboto Mono',
      fontSize: '16px',
      color: '#4e3720',
    }).setOrigin(1, 0);
    this.dialogueOverlay.add(this.dialogueHint);
  }

  syncDialoguePortraitBackground() {
    if (!this.portraitSceneBg || !this.dialoguePortraitRect) return;
    this.portraitSceneBg.tilePositionX = (this.bg?.tilePositionX || 0) + this.dialoguePortraitRect.left;
    this.portraitSceneBg.tilePositionY = this.dialoguePortraitRect.top;
  }


  hasInventoryItem(name) {
    return this.inventoryItems.some((item) => item.name === name);
  }

  addInventoryItem(item) {
    if (this.hasInventoryItem(item.name)) return;
    this.inventoryItems.push(item);
    this.showItemReceivePopup(item);
    if (this.isMenuOpen && this.menuPages[this.selectedMenuIndex] === 'Inventory') {
      this.refreshMenuPage();
    }
  }

  hasEquipmentItem(name) {
    return this.equipmentItems.some((item) => item.name === name);
  }

  addEquipmentItem(item) {
    if (this.hasEquipmentItem(item.name)) return;
    this.equipmentItems.push(item);
    this.showItemReceivePopup(item);
    if (this.isMenuOpen && this.menuPages[this.selectedMenuIndex] === 'Equipment') {
      this.refreshMenuPage();
    }
  }

  beginOnionPatchInteraction() {
    if (this.isDialogueOpen || this.isMenuOpen || this.scriptedNpcTargetX !== null) return;
    this.npcBehaviorEvent?.remove(false);
    this.player.setVelocityX(0);
    this.npc.setVelocityX(0);
    const targetX = this.player.x - 84;
    this.scriptedNpcTargetX = Phaser.Math.Clamp(targetX, this.npcMinX - 120, this.onionPatch.x + 90);
    this.scriptedNpcCallback = () => this.openDialogue('onionQuest');
  }

  updateScriptedNpcMovement() {
    if (this.scriptedNpcTargetX === null || !this.npc) return false;
    const delta = this.scriptedNpcTargetX - this.npc.x;
    if (Math.abs(delta) <= 10) {
      this.npc.setVelocityX(0);
      this.npcFacing = delta < 0 ? 'left' : 'right';
      this.npc.anims.play(this.npcFacing === 'left' ? 'forestLady-idle-left' : 'forestLady-idle-right', true);
      const callback = this.scriptedNpcCallback;
      this.scriptedNpcTargetX = null;
      this.scriptedNpcCallback = null;
      callback?.();
      return true;
    }

    if (delta < 0) {
      this.npcFacing = 'left';
      this.npc.setVelocityX(-95);
      this.npc.anims.play('forestLady-walk-left', true);
    } else {
      this.npcFacing = 'right';
      this.npc.setVelocityX(95);
      this.npc.anims.play('forestLady-walk-right', true);
    }
    return true;
  }

  enterHut() {
    if (this.isDialogueOpen || this.isMenuOpen || this.isTransitioningToInterior) return;
    this.isTransitioningToInterior = true;
    this.player.setVelocity(0, 0);
    this.npc.setVelocityX(0);
    this.hutTooltip?.setVisible(false);
    this.onionPatchTooltip?.setVisible(false);
    this.npcTooltip?.setVisible(false);
    this.scene.launch('HutInteriorScene', {
      heroKey: this.heroKey,
      returnSceneKey: this.scene.key,
      returnPosition: {
        x: this.hutDoorZone.x,
        y: this.player.y,
      },
    });
    this.scene.pause();
  }

  returnFromHut(returnPosition) {
    this.isTransitioningToInterior = false;
    this.enableKeyboardInput();
    this.isSceneTransitioning = false;
    if (returnPosition) {
      this.player.setPosition(returnPosition.x, returnPosition.y);
    }
    this.player.setVelocity(0, 0);
    this.facing = 'right';
    this.player.anims.play(`${this.heroKey}-idle-right`, true);
    this.scene.resume();
  }

  transitionToScene(targetSceneKey, startX, startY) {
    if (this.isSceneTransitioning) return;
    this.isSceneTransitioning = true;
    const safeStartY = Phaser.Math.Clamp(startY, 0, GROUND_Y - 4);
    this.player.setVelocity(0, 0);
    this.player.body?.stop?.();
    if (this.npc) this.npc.setVelocity(0, 0);
    this.disableKeyboardDuringTransition();
    this.fadeOutMusic(220);
    this.cameras.main.fadeOut(220, 0, 0, 0);
    this.time.delayedCall(230, () => {
      this.scene.start(targetSceneKey, {
        heroKey: this.heroKey,
        startX,
        startY: safeStartY,
        inventoryItems: this.inventoryItems,
        equipmentItems: this.equipmentItems,
      });
    });
  }

  handleSceneBoundaries(velocityX, onGround) {
    if (this.isMenuOpen || this.isDialogueOpen || this.isTransitioningToInterior || this.isSceneTransitioning) return;
    if (!onGround) return;
    if (velocityX > 0 && this.player.x >= WORLD_WIDTH - 12) {
      this.transitionToScene('CityScene', 24, this.player.y);
    }
  }

  openMenu() {
    if (this.isMenuOpen || this.isDialogueOpen) return;
    this.isMenuOpen = true;
    this.menuMode = 'categories';
    this.menuSectionIndex = 0;
    this.menuItemIndex = 0;
    this.menuActionIndex = 0;
    this.menuOverlay.setVisible(true);
    this.refreshMenuPage();
    this.physics.world.pause();
    this.player.anims.pause();
    this.npc.anims.pause();
  }

  closeMenu() {
    if (!this.isMenuOpen) return;
    this.isMenuOpen = false;
    this.menuMode = 'categories';
    this.menuOverlay.setVisible(false);
    this.physics.world.resume();
    this.player.anims.resume();
    this.npc.anims.resume();
  }

  changeMenuPage(direction) {
    this.menuSectionIndex = Phaser.Math.Wrap(this.menuSectionIndex + direction, 0, this.menuPages.length);
    this.refreshMenuPage();
  }

  handleMenuNavigation() {
    const currentPage = this.menuPages[this.menuSectionIndex];
    const items = this.getCurrentSectionItems();

    if (Phaser.Input.Keyboard.JustDown(this.cursors.up)) {
      if (this.menuMode === 'categories') {
        this.changeMenuPage(-1);
      } else if (this.menuMode === 'section' && currentPage !== 'Controls' && items.length) {
        this.menuItemIndex = Phaser.Math.Wrap(this.menuItemIndex - 6, 0, items.length);
        this.refreshMenuPage();
      } else if (this.menuMode === 'actions') {
        const item = items[this.menuItemIndex];
        this.menuActionIndex = Phaser.Math.Wrap(this.menuActionIndex - 1, 0, item.actions.length);
        this.refreshMenuPage();
      }
    }

    if (Phaser.Input.Keyboard.JustDown(this.cursors.down)) {
      if (this.menuMode === 'categories') {
        this.changeMenuPage(1);
      } else if (this.menuMode === 'section' && currentPage !== 'Controls' && items.length) {
        this.menuItemIndex = Phaser.Math.Wrap(this.menuItemIndex + 6, 0, items.length);
        this.refreshMenuPage();
      } else if (this.menuMode === 'actions') {
        const item = items[this.menuItemIndex];
        this.menuActionIndex = Phaser.Math.Wrap(this.menuActionIndex + 1, 0, item.actions.length);
        this.refreshMenuPage();
      }
    }

    if (Phaser.Input.Keyboard.JustDown(this.cursors.right)) {
      if (this.menuMode === 'categories') {
        this.menuMode = 'section';
        this.menuItemIndex = 0;
        this.refreshMenuPage();
      } else if (this.menuMode === 'section' && currentPage !== 'Controls' && items.length) {
        this.menuItemIndex = Phaser.Math.Wrap(this.menuItemIndex + 1, 0, items.length);
        this.refreshMenuPage();
      }
    }

    if (Phaser.Input.Keyboard.JustDown(this.cursors.left)) {
      if (this.menuMode === 'actions') {
        this.menuMode = 'section';
        this.refreshMenuPage();
      } else if (this.menuMode === 'section') {
        this.menuMode = 'categories';
        this.refreshMenuPage();
      }
    }

    if (Phaser.Input.Keyboard.JustDown(this.enterKey) || Phaser.Input.Keyboard.JustDown(this.spaceKey)) {
      if (this.menuMode === 'categories') {
        this.menuMode = 'section';
        this.refreshMenuPage();
      } else if (this.menuMode === 'section' && currentPage !== 'Controls') {
        this.openItemActionMenu();
      } else if (this.menuMode === 'actions') {
        const item = items[this.menuItemIndex];
        if (item) this.performMenuAction(item.actions[this.menuActionIndex]);
      }
    }

    if (Phaser.Input.Keyboard.JustDown(this.escapeKey) || Phaser.Input.Keyboard.JustDown(this.backspaceKey)) {
      if (this.menuMode === 'actions') {
        this.menuMode = 'section';
        this.refreshMenuPage();
      } else if (this.menuMode === 'section') {
        this.menuMode = 'categories';
        this.refreshMenuPage();
      } else {
        this.closeMenu();
      }
    }
  }

  openDialogue(sequence = 'intro') {
    if (this.isDialogueOpen || this.isMenuOpen) return;
    this.activeDialogueSequence = sequence;
    this.isDialogueOpen = true;
    this.dialogueOverlay.setVisible(true);
    this.physics.world.pause();
    this.player.setVelocity(0, 0);
    this.npc.setVelocityX(0);
    this.player.anims.play(`${this.heroKey}-idle-${this.facing}`, true);
    this.npc.anims.play(this.npcFacing === 'left' ? 'forestLady-idle-left' : 'forestLady-idle-right', true);
    this.portraitSceneBg?.setVisible(true);
    this.npcPortrait?.setVisible(true);
    this.syncDialoguePortraitBackground();
    this.startDialogueSequence(sequence);
  }

  closeDialogue() {
    this.isDialogueOpen = false;
    this.dialogueOverlay.setVisible(false);
    this.clearDialogueOptions();
    this.stopTypewriter();
    this.physics.world.resume();
    this.scheduleNpcBehavior(900);
    this.flushQueuedItemReceivePopups();
  }

  startDialogueSequence(sequence = 'intro') {
    this.dialogueChoiceIndex = 0;

    if (sequence === 'onionQuest') {
      if (this.questState === 'accepted') {
        this.dialogueState = 'questAcceptedReminder';
        this.showDialogueLine({
          speaker: FOREST_LADY.name,
          speakerType: 'npc',
          text: 'Those onions should still be good. If you are headed into the city, the tavern owner will be glad to see them.',
          choices: ['I will deliver them.', 'Not today.'],
        });
        return;
      }

      if (this.questState === 'declined') {
        this.dialogueState = 'questReoffer';
        this.showDialogueLine({
          speaker: FOREST_LADY.name,
          speakerType: 'npc',
          text: 'I am still sorting onions for the tavern. If you have changed your mind, I would appreciate the help.',
          choices: ['I can take the onions.', 'I still cannot help.'],
        });
        return;
      }

      this.dialogueState = 'onionOffer';
      this.showDialogueLine({
        speaker: FOREST_LADY.name,
        speakerType: 'npc',
        text: 'These are my onions. I grow them here and sell them to the tavern owner in the city. I am behind on my work today. Would you take a bundle to the tavern for me?',
        choices: ['I will take them to the tavern owner.', 'I cannot help right now.'],
      });
      return;
    }

    this.dialogueState = 'intro';
    this.showDialogueLine({
      speaker: FOREST_LADY.name,
      speakerType: 'npc',
      text: 'What are you up to out here, traveler?',
      choices: [
        'My wagon broke down on the road to the city.',
        'I was on my way to pick up supplies for my village.',
      ],
    });
  }

  showDialogueLine(line) {
    this.currentDialogueLine = line;
    this.dialogueSpeakerText.setText(line.speaker);
    this.dialogueText.setText('');
    this.clearDialogueOptions();
    this.dialogueAwaitingChoice = false;
    this.typewriterText = line.text;
    this.typewriterIndex = 0;
    this.isTyping = true;
    if (line.speakerType === 'npc') {
      this.npcPortrait.setTexture('forestLady-idle').setFrame(26);
    }
    this.talkPortrait(line.speakerType === 'npc');

    this.typewriterEvent?.remove(false);
    this.typewriterEvent = this.time.addEvent({
      delay: 24,
      repeat: Math.max(line.text.length - 1, 0),
      callback: () => {
        this.typewriterIndex += 1;
        this.dialogueText.setText(this.typewriterText.slice(0, this.typewriterIndex));
        if (this.typewriterIndex >= this.typewriterText.length) {
          this.finishTyping();
        }
      },
    });
  }

  finishTyping() {
    if (!this.isTyping) return;
    this.isTyping = false;
    this.dialogueText.setText(this.typewriterText);
    this.stopTalkingPortrait();
    this.typewriterEvent?.remove(false);
    this.typewriterEvent = null;

    if (this.currentDialogueLine?.choices) {
      this.dialogueAwaitingChoice = true;
      this.dialogueChoiceIndex = 0;
      this.renderDialogueOptions(this.currentDialogueLine.choices);
    } else if (this.dialogueState === 'npcReply') {
      this.dialogueAwaitingChoice = true;
    }
  }

  stopTypewriter() {
    this.typewriterEvent?.remove(false);
    this.typewriterEvent = null;
    this.isTyping = false;
    this.stopTalkingPortrait();
  }

  talkPortrait(active) {
    this.stopTalkingPortrait();
    if (!active) {
      this.npcPortrait.setTexture('forestLady-idle').setFrame(26);
      return;
    }
    if (!this.writingSound.isPlaying) this.writingSound.play();
    const talkFrames = [
      { texture: 'forestLady-idle', frame: 26 },
      { texture: 'forestLady-idle', frame: 27 },
    ];
    let talkIndex = 0;
    this.portraitTalkEvent = this.time.addEvent({
      delay: 120,
      loop: true,
      callback: () => {
        const next = talkFrames[talkIndex % talkFrames.length];
        this.npcPortrait.setTexture(next.texture).setFrame(next.frame);
        talkIndex += 1;
      },
    });
  }

  stopTalkingPortrait() {
    this.portraitTalkEvent?.remove(false);
    this.portraitTalkEvent = null;
    this.npcPortrait.setTexture('forestLady-idle').setFrame(26);
    if (this.writingSound?.isPlaying) this.writingSound.stop();
  }

  renderDialogueOptions(options) {
    this.clearDialogueOptions();
    this.dialogueOptionEntries = options.map((option, index) => {
      const y = index * 56;
      const box = this.add.rectangle(0, y, this.dialogueOptionWidth, 42, 0x000000, 0)
        .setOrigin(0, 0)
        .setStrokeStyle(2, 0xdab56a, 0.92);
      const text = this.add.text(14, y + 8, option, {
        fontFamily: 'Roboto Mono',
        fontSize: '16px',
        color: '#3e2514',
        wordWrap: { width: this.dialogueOptionWidth - 28 },
      });
      this.dialogueOptions.add([box, text]);
      return { box, text };
    });
    this.refreshDialogueOptions();
  }

  refreshDialogueOptions() {
    if (!this.dialogueOptionEntries) return;
    this.dialogueOptionEntries.forEach((entry, index) => {
      const active = index === this.dialogueChoiceIndex;
      entry.box.setStrokeStyle(active ? 3 : 2, active ? 0x6b4016 : 0xdab56a, 0.98);
      entry.text.setColor(active ? '#2b1207' : '#6d4f24');
    });
  }

  clearDialogueOptions() {
    this.dialogueOptions.removeAll(true);
    this.dialogueOptionEntries = [];
  }

  chooseDialogueOption() {
    if (!this.dialogueAwaitingChoice) return;
    const selectedText = this.currentDialogueLine.choices[this.dialogueChoiceIndex];
    this.clearDialogueOptions();
    this.dialogueAwaitingChoice = false;

    if (this.dialogueState === 'intro') {
      this.dialogueState = 'npcReply';
      const reply = selectedText === 'I was on my way to pick up supplies for my village.'
        ? 'Then you are in luck. The city gate is very nearby, and the supply road runs straight through it.'
        : 'A broken wagon on the city road is bad luck, but the gate is very nearby. You will have help soon enough.';
      this.showDialogueLine({
        speaker: FOREST_LADY.name,
        speakerType: 'npc',
        text: reply,
        choices: ['Thank you.', 'I should get moving.'],
      });
    } else if (this.dialogueState === 'npcReply') {
      this.closeDialogue();
    } else if (this.dialogueState === 'onionOffer' || this.dialogueState === 'questReoffer') {
      if (selectedText === 'I will take them to the tavern owner.' || selectedText === 'I can take the onions.') {
        this.questState = 'accepted';
        this.addInventoryItem({ name: 'Onions', texture: 'menuOnions', actions: ['Eat'] });
        this.dialogueState = 'questAccepted';
        this.showDialogueLine({
          speaker: FOREST_LADY.name,
          speakerType: 'npc',
          text: 'Thank you. Take this bundle to the tavern owner in the city for me. I will be grateful for the help.',
          choices: ['I will deliver the onions.'],
        });
      } else {
        this.questState = 'declined';
        this.dialogueState = 'questDeclined';
        this.showDialogueLine({
          speaker: FOREST_LADY.name,
          speakerType: 'npc',
          text: 'Very well. If you change your mind, speak to me near the patch and I will set some aside for you.',
          choices: ['Understood.'],
        });
      }
    } else if (
      this.dialogueState === 'questAccepted' ||
      this.dialogueState === 'questDeclined' ||
      this.dialogueState === 'questAcceptedReminder'
    ) {
      this.closeDialogue();
    }
  }

  updateNPCBehavior() {
    if (!this.npc) return;

    if (this.scriptedNpcTargetX !== null) {
      this.npcTooltip.setVisible(false);
      return;
    }

    if (this.isMenuOpen || this.isDialogueOpen) return;

    if (this.npc.x <= this.npcMinX) {
      this.npcFacing = 'right';
      this.npc.setVelocityX(55);
      this.npc.anims.play('forestLady-walk-right', true);
    }
    if (this.npc.x >= this.npcMaxX) {
      this.npcFacing = 'left';
      this.npc.setVelocityX(-55);
      this.npc.anims.play('forestLady-walk-left', true);
    }

    if (Math.abs(this.npc.body.velocity.x) < 5 && this.npcState !== 'idle') {
      this.npcState = 'idle';
      this.npc.anims.play(this.npcFacing === 'left' ? 'forestLady-idle-left' : 'forestLady-idle-right', true);
    }

    const distance = Phaser.Math.Distance.Between(this.player.x, this.player.y, this.npc.x, this.npc.y);
    const canInteract = distance < 150;
    this.npcTooltip.setVisible(canInteract);
    if (canInteract) {
      this.npcTooltip.setPosition(this.player.x, this.player.y - 96);
    }
  }

  update() {
    this.updateNPCBehavior();

    const onionDistance = this.onionPatch ? Phaser.Math.Distance.Between(this.player.x, this.player.y, this.onionPatch.x, this.onionPatch.y - 40) : 9999;
    const nearOnionPatch = onionDistance < 180;
    this.onionPatchTooltip?.setVisible(nearOnionPatch && !this.isDialogueOpen && !this.isMenuOpen && this.scriptedNpcTargetX === null);
    if (nearOnionPatch) {
      this.onionPatchTooltip.setPosition(this.player.x, this.player.y - 96);
    }

    const nearHutDoor = this.hutDoorZone ? this.physics.overlap(this.player, this.hutDoorZone) : false;
    this.hutTooltip?.setVisible(nearHutDoor && !this.isDialogueOpen && !this.isMenuOpen && this.scriptedNpcTargetX === null);
    if (nearHutDoor) {
      this.hutTooltip.setPosition(this.player.x, this.player.y - 96);
    }

    if (this.itemReceiveContainer?.visible) {
      this.itemReceiveContainer.setPosition(this.player.x, this.player.y - 116);
    }

    if (this.updateScriptedNpcMovement()) {
      this.bg.tilePositionX = this.cameras.main.scrollX * 0.28;
      return;
    }

    if (Phaser.Input.Keyboard.JustDown(this.menuKey)) {
      if (this.isMenuOpen) {
        this.closeMenu();
      } else if (!this.isDialogueOpen) {
        this.openMenu();
      }
    }

    if (this.isDialogueOpen) {
      if (this.isTyping && (Phaser.Input.Keyboard.JustDown(this.enterKey) || Phaser.Input.Keyboard.JustDown(this.spaceKey))) {
        this.dialogueText.setText(this.typewriterText);
        this.finishTyping();
        return;
      }
      if (this.dialogueAwaitingChoice) {
        if (Phaser.Input.Keyboard.JustDown(this.cursors.up)) {
          this.dialogueChoiceIndex = Phaser.Math.Wrap(this.dialogueChoiceIndex - 1, 0, this.currentDialogueLine.choices.length);
          this.refreshDialogueOptions();
        }
        if (Phaser.Input.Keyboard.JustDown(this.cursors.down)) {
          this.dialogueChoiceIndex = Phaser.Math.Wrap(this.dialogueChoiceIndex + 1, 0, this.currentDialogueLine.choices.length);
          this.refreshDialogueOptions();
        }
        if (Phaser.Input.Keyboard.JustDown(this.enterKey) || Phaser.Input.Keyboard.JustDown(this.spaceKey)) {
          this.chooseDialogueOption();
        }
      }
      if (Phaser.Input.Keyboard.JustDown(this.escapeKey) || Phaser.Input.Keyboard.JustDown(this.backspaceKey)) {
        this.closeDialogue();
      }
      return;
    }

    if (this.isMenuOpen) {
      this.handleMenuNavigation();
      return;
    }

    const upJustPressed = Phaser.Input.Keyboard.JustDown(this.cursors.up);
    const interactPressed = Phaser.Input.Keyboard.JustDown(this.enterKey) || Phaser.Input.Keyboard.JustDown(this.spaceKey);
    const hutPressed = upJustPressed || Phaser.Input.Keyboard.JustDown(this.enterKey) || Phaser.Input.Keyboard.JustDown(this.spaceKey);
    const nearNpc = Phaser.Math.Distance.Between(this.player.x, this.player.y, this.npc.x, this.npc.y) < 150;
    if (nearHutDoor && hutPressed) {
      this.enterHut();
      return;
    }
    if (nearOnionPatch && interactPressed) {
      this.beginOnionPatchInteraction();
      return;
    }
    if (nearNpc && interactPressed) {
      this.openDialogue('intro');
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

    if (upJustPressed && onGround) {
      this.player.setVelocityY(-760);
    }

    const animPrefix = this.facing === 'left' ? 'left' : 'right';
    if (!onGround) {
      this.player.setScale(this.playerBaseScaleX, this.playerBaseScaleY);
      this.player.anims.play(`${this.heroKey}-jump-${animPrefix}`, true);
      if (this.player.body.velocity.y > -20) {
        this.player.anims.pause(this.player.anims.currentFrame);
      }
    } else if (Math.abs(velocityX) > 5) {
      this.player.setScale(this.playerBaseScaleX, this.playerBaseScaleY);
      this.player.anims.play(`${this.heroKey}-walk-${animPrefix}`, true);
    } else {
      this.player.setScale(this.playerBaseScaleX, this.playerBaseScaleY);
      this.player.anims.play(`${this.heroKey}-idle-${animPrefix}`, true);
    }

    this.player.setDepth(9);
    this.npc.setDepth(9);
    this.handleSceneBoundaries(velocityX, onGround);
    this.bg.tilePositionX = this.cameras.main.scrollX * 0.28;
  }
}



class CityScene extends PrototypeScene {
  constructor() {
    super('CityScene');
    this.facing = 'right';
    this.selectedMenuIndex = 0;
    this.menuPages = ['Inventory', 'Equipment', 'Controls'];
    this.menuMode = 'categories';
    this.menuSectionIndex = 0;
    this.menuItemIndex = 0;
    this.menuActionIndex = 0;
    this.inventoryItems = [];
    this.equipmentItems = [];
    this.pendingItemPopupQueue = [];
  }

  init(data) {
    super.init(data);
    this.startX = data?.startX ?? 120;
    this.startY = data?.startY ?? 620;
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
    this.createItemReceiveUI();
    this.createAudio();
    this.createMenu();

    this.player.setPosition(this.startX, this.startY);

    this.cursors = this.input.keyboard.createCursorKeys();
    this.menuKey = this.input.keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.M);
    this.enterKey = this.input.keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.ENTER);
    this.spaceKey = this.input.keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.SPACE);
    this.escapeKey = this.input.keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.ESC);
    this.backspaceKey = this.input.keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.BACKSPACE);
  }

  createParallaxBackground() {
    const cityTexture = this.configureBackgroundTexture('cityBg');
    const scale = GAME_HEIGHT / cityTexture.height;
    this.bgScale = scale;

    this.bg = this.add.tileSprite(0, 0, GAME_WIDTH, GAME_HEIGHT, 'cityBg')
      .setOrigin(0, 0)
      .setScrollFactor(0)
      .setDepth(-20);

    this.bg.setTileScale(scale, scale);
  }

  createGround() {
    this.ground = this.physics.add.staticGroup();
    this.groundBack = this.add.group();
    this.groundFront = this.add.group();

    const tilesAcross = Math.ceil(WORLD_WIDTH / GROUND_TILE);
    const decorativeKeys = ['cityGround1', 'cityGround2', 'cityGround3'];
    const rng = this.createSeededRandom(0xC17AD0);
    let previousKey = null;

    const blackVisualOffsetY = 34;
    const collisionStripY = GROUND_Y + 24;
    const collisionStripHeight = 22;

    for (let i = 0; i < tilesAcross; i += 1) {
      let tileKey = decorativeKeys[Math.floor(rng() * decorativeKeys.length)];
      if (decorativeKeys.length > 1 && tileKey === previousKey) {
        tileKey = decorativeKeys[(decorativeKeys.indexOf(tileKey) + 1 + Math.floor(rng() * (decorativeKeys.length - 1))) % decorativeKeys.length];
      }
      previousKey = tileKey;

      const x = i * GROUND_TILE + GROUND_TILE / 2;
      const visualY = GROUND_Y + GROUND_TILE / 2;

      const blackBase = this.add.image(x, visualY + blackVisualOffsetY, 'blackTile')
        .setDisplaySize(GROUND_TILE, 150)
        .setDepth(2);
      this.groundBack.add(blackBase);

      const collider = this.add.rectangle(x, collisionStripY, GROUND_TILE, collisionStripHeight, 0x000000, 0);
      this.physics.add.existing(collider, true);
      this.ground.add(collider);

      const frontTile = this.add.image(x, visualY, tileKey)
        .setDisplaySize(GROUND_TILE, GROUND_TILE)
        .setDepth(12);
      this.groundFront.add(frontTile);
    }

    this.groundShadow = this.add.rectangle(WORLD_WIDTH / 2, GROUND_Y + 10, WORLD_WIDTH, 18, 0x13210f, 0.12)
      .setDepth(3);
  }

  createNPC() {}
  createProps() {}
  createDialogueUI() {}
  updateNPCBehavior() {}
  openDialogue() {}
  beginOnionPatchInteraction() {}
  updateScriptedNpcMovement() { return false; }

  openMenu() {
    if (this.isMenuOpen) return;
    this.isMenuOpen = true;
    this.menuMode = 'categories';
    this.menuSectionIndex = 0;
    this.menuItemIndex = 0;
    this.menuActionIndex = 0;
    this.menuOverlay.setVisible(true);
    this.refreshMenuPage();
    this.physics.world.pause();
    this.player.anims.pause();
  }

  closeMenu() {
    if (!this.isMenuOpen) return;
    this.isMenuOpen = false;
    this.menuMode = 'categories';
    this.menuOverlay.setVisible(false);
    this.physics.world.resume();
    this.player.anims.resume();
  }

  handleSceneBoundaries(velocityX, onGround) {
    if (this.isMenuOpen || this.isSceneTransitioning) return;
    if (!onGround) return;
    if (velocityX < 0 && this.player.x <= 12) {
      this.transitionToScene('PrototypeScene', WORLD_WIDTH - 24, this.player.y);
    }
  }

  update() {
    if (this.itemReceiveContainer?.visible) {
      this.itemReceiveContainer.setPosition(this.player.x, this.player.y - 116);
    }

    if (Phaser.Input.Keyboard.JustDown(this.menuKey)) {
      if (this.isMenuOpen) {
        this.closeMenu();
      } else {
        this.openMenu();
      }
    }

    if (this.isMenuOpen) {
      this.handleMenuNavigation();
      return;
    }

    const upJustPressed = Phaser.Input.Keyboard.JustDown(this.cursors.up);
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

    if (upJustPressed && onGround) {
      this.player.setVelocityY(-760);
    }

    const animPrefix = this.facing === 'left' ? 'left' : 'right';
    if (!onGround) {
      this.player.setScale(this.playerBaseScaleX, this.playerBaseScaleY);
      this.player.anims.play(`${this.heroKey}-jump-${animPrefix}`, true);
      if (this.player.body.velocity.y > -20) {
        this.player.anims.pause(this.player.anims.currentFrame);
      }
    } else if (Math.abs(velocityX) > 5) {
      this.player.setScale(this.playerBaseScaleX, this.playerBaseScaleY);
      this.player.anims.play(`${this.heroKey}-walk-${animPrefix}`, true);
    } else {
      this.player.setScale(this.playerBaseScaleX, this.playerBaseScaleY);
      this.player.anims.play(`${this.heroKey}-idle-${animPrefix}`, true);
    }

    this.player.setDepth(9);
    this.handleSceneBoundaries(velocityX, onGround);
    this.bg.tilePositionX = this.cameras.main.scrollX * 0.28;
  }
}

class HutInteriorScene extends Phaser.Scene {
  constructor() {
    super('HutInteriorScene');
    this.topDownFacing = 'up';
  }

  init(data) {
    this.heroKey = data?.heroKey || 'caelan';
    this.returnSceneKey = data?.returnSceneKey || 'PrototypeScene';
    this.returnPosition = data?.returnPosition || { x: 2240, y: 620 };
  }

  preload() {
    this.load.image('forestHutInterior', 'assets/bg/forest_hut_interior.jpeg');

    Object.values(HEROES).forEach((hero) => {
      if (!this.textures.exists(`${hero.key}-walk`)) {
        this.load.spritesheet(`${hero.key}-walk`, hero.walk, { frameWidth: FRAME_W, frameHeight: FRAME_H });
      }
      if (!this.textures.exists(`${hero.key}-idle`)) {
        this.load.spritesheet(`${hero.key}-idle`, hero.idle, { frameWidth: FRAME_W, frameHeight: FRAME_H });
      }
    });
  }

  create() {
    Object.keys(HEROES).forEach((heroKey) => createHeroTopDownAnimations(this, heroKey));

    this.cameras.main.setBackgroundColor('#050607');

    const bgTexture = this.textures.get('forestHutInterior').getSourceImage();
    const bgScale = GAME_HEIGHT / bgTexture.height;
    this.interior = this.add.image(GAME_WIDTH / 2, GAME_HEIGHT / 2, 'forestHutInterior')
      .setScale(bgScale)
      .setDepth(0);

    this.interiorBounds = {
      left: this.interior.x - (bgTexture.width * bgScale) / 2,
      right: this.interior.x + (bgTexture.width * bgScale) / 2,
      top: this.interior.y - (bgTexture.height * bgScale) / 2,
      bottom: this.interior.y + (bgTexture.height * bgScale) / 2,
      scale: bgScale,
    };

    this.physics.world.setBounds(
      this.interiorBounds.left + 86,
      this.interiorBounds.top + 218,
      (this.interiorBounds.right - this.interiorBounds.left) - 172,
      (this.interiorBounds.bottom - this.interiorBounds.top) - 250
    );

    this.blockers = this.physics.add.staticGroup();
    this.addBlocker(216, 676, 292, 332);
    this.addBlocker(759, 596, 292, 252);
    this.addBlocker(900, 544, 110, 92);
    this.addBlocker(430, 464, 196, 92);

    const doorwayX = this.scaleCoordX(575);
    const doorwayY = this.scaleCoordY(1028);
    const doorwayWidth = 150 * bgScale;
    const doorwayHeight = 56 * bgScale;
    this.exitZone = this.add.zone(doorwayX, doorwayY, doorwayWidth, doorwayHeight);
    this.physics.add.existing(this.exitZone, true);

    this.player = this.physics.add.sprite(doorwayX, doorwayY - 34, `${this.heroKey}-idle`, 0);
    this.player.setScale(3.0);
    this.player.anims.play(`${this.heroKey}-topdown-idle-up`, true);
    this.player.setDepth(10);
    this.player.setCollideWorldBounds(true);
    this.player.body.setSize(20, 24);
    this.player.body.setOffset(22, 38);
    this.player.body.setMaxVelocity(230, 230);
    this.player.body.setDrag(1600, 1600);

    this.physics.add.collider(this.player, this.blockers);

    this.cursors = this.input.keyboard.createCursorKeys();
    this.enterKey = this.input.keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.ENTER);
    this.spaceKey = this.input.keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.SPACE);
    this.escapeKey = this.input.keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.ESC);

    this.exitHint = this.add.container(0, 0).setDepth(20).setVisible(false);
    const hintBg = this.add.rectangle(0, 0, 174, 32, 0x1c1209, 0.82).setStrokeStyle(2, 0xdab56a, 0.95);
    const hintText = this.add.text(0, 0, 'Exit', {
      fontFamily: 'Roboto Mono',
      fontSize: '16px',
      color: '#f7edd6',
    }).setOrigin(0.5);
    this.exitHint.add([hintBg, hintText]);
  }

  scaleCoordX(sourceX) {
    return this.interiorBounds.left + sourceX * this.interiorBounds.scale;
  }

  scaleCoordY(sourceY) {
    return this.interiorBounds.top + sourceY * this.interiorBounds.scale;
  }

  addBlocker(sourceX, sourceY, sourceW, sourceH) {
    const blocker = this.add.zone(
      this.scaleCoordX(sourceX),
      this.scaleCoordY(sourceY),
      sourceW * this.interiorBounds.scale,
      sourceH * this.interiorBounds.scale
    );
    this.physics.add.existing(blocker, true);
    this.blockers.add(blocker);
    return blocker;
  }

  exitToForest() {
    const returnScene = this.scene.get(this.returnSceneKey);
    this.scene.stop();
    returnScene.returnFromHut(this.returnPosition);
  }

  update() {
    const moveX = (this.cursors.left.isDown ? -1 : 0) + (this.cursors.right.isDown ? 1 : 0);
    const moveY = (this.cursors.up.isDown ? -1 : 0) + (this.cursors.down.isDown ? 1 : 0);
    const movement = new Phaser.Math.Vector2(moveX, moveY);
    const speed = 180;

    if (movement.lengthSq() > 0) {
      movement.normalize().scale(speed);
    }

    this.player.setVelocity(movement.x, movement.y);

    if (Math.abs(movement.x) > Math.abs(movement.y)) {
      this.topDownFacing = movement.x < 0 ? 'left' : 'right';
    } else if (Math.abs(movement.y) > 0) {
      this.topDownFacing = movement.y < 0 ? 'up' : 'down';
    }

    if (movement.lengthSq() > 0) {
      this.player.anims.play(`${this.heroKey}-topdown-walk-${this.topDownFacing}`, true);
    } else {
      this.player.anims.play(`${this.heroKey}-topdown-idle-${this.topDownFacing}`, true);
    }

    this.player.setDepth(this.player.y + 20);

    const atDoorway = this.physics.overlap(this.player, this.exitZone);
    this.exitHint.setVisible(atDoorway);
    if (atDoorway) {
      this.exitHint.setPosition(this.player.x, this.player.y - 84);
      if (this.player.body.velocity.y > 0 || this.player.y >= this.exitZone.y - 8) {
        this.exitToForest();
        return;
      }
    }

    if (Phaser.Input.Keyboard.JustDown(this.escapeKey) || Phaser.Input.Keyboard.JustDown(this.enterKey) || Phaser.Input.Keyboard.JustDown(this.spaceKey)) {
      if (atDoorway) {
        this.exitToForest();
      }
    }
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
  scene: [StartScene, HeroSelectScene, PrototypeScene, CityScene, HutInteriorScene],
  scale: {
    mode: Phaser.Scale.FIT,
    autoCenter: Phaser.Scale.CENTER_BOTH,
  },
};

new Phaser.Game(config);
