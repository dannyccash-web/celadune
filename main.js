const GAME_WIDTH = 1920;
const GAME_HEIGHT = 1080;
const GROUND_TILE = 160;
const WORLD_WIDTH = 5120;
const CITY_WORLD_WIDTH = Math.round(WORLD_WIDTH * 1.76);
const GROUND_Y = 888;
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
    frameW: 100,
    frameH: 64,
    usesFlipX: true,
    initFrame: 0,
    // Core animations (also used by current game logic)
    idle:             'assets/characters/caelan/idle.png',
    walk:             'assets/characters/caelan/walk.png',
    jump:             'assets/characters/caelan/jump.png',
    // Extended animations (available for future use)
    run:              'assets/characters/caelan/run.png',
    walk_heavy:       'assets/characters/caelan/walk_heavy.png',
    attack:           'assets/characters/caelan/attack.png',
    death:            'assets/characters/caelan/death.png',
    idle_sword:       'assets/characters/caelan/idle_sword.png',
    walk_sword:       'assets/characters/caelan/walk_sword.png',
    run_sword:        'assets/characters/caelan/run_sword.png',
    walk_sword_heavy: 'assets/characters/caelan/walk_sword_heavy.png',
    jump_sword:       'assets/characters/caelan/jump_sword.png',
    attack_sword:     'assets/characters/caelan/attack_sword.png',
    death_sword:      'assets/characters/caelan/death_sword.png',
    special_attack:   'assets/characters/caelan/special_attack.png',
    special_slash:    'assets/characters/caelan/special_slash.png',
    combo_attack:     'assets/characters/caelan/combo_attack.png',
  },
  nerisse: {
    key: 'nerisse',
    name: 'Nerisse',
    frameW: FRAME_W,
    frameH: FRAME_H,
    usesFlipX: false,
    initFrame: 39,
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

const HUT_WANDERER = {
  key: 'hutWanderer',
  name: 'Aldric',
  walk: 'assets/npcs/hut_wanderer/walk.png',
  idle: 'assets/npcs/hut_wanderer/idle.png',
  frameW: 64,
  frameH: 64,
  walkFrames: 8,
  idleFrames: 5,
};

const CITY_NPCS = {
  city1: { id: 'city1', key: 'npcCity1', name: 'Bram Alder', idle: 'assets/npcs/npc_city_1/idle.png', walk: 'assets/npcs/npc_city_1/walk.png' },
  city2: { id: 'city2', key: 'npcCity2', name: 'Ysra Thorn', idle: 'assets/npcs/npc_city_2/idle.png', walk: 'assets/npcs/npc_city_2/walk.png' },
  city3: { id: 'city3', key: 'npcCity3', name: 'Teren Vale', idle: 'assets/npcs/npc_city_3/idle.png', walk: 'assets/npcs/npc_city_3/walk.png' },
  tavernChef: { id: 'tavernChef', key: 'npcTavernChef', name: 'Padrig', idle: 'assets/npcs/npc_tavern_chef/idle.png', walk: 'assets/npcs/npc_tavern_chef/walk.png' },
};

const WAYFARERS_SALVE_ITEM = {
  name: "Wayfarer's Salve",
  texture: 'wayfarersSalve',
  actions: ['Use'],
};

const DEFAULT_STORY_FLAGS = {
  onionsReplacementGiven: false,
  chefOnionsDelivered: false,
  mirellePaymentResolved: false,
  mirellePaidInFull: false,
  mirellePaymentAmount: 0,
  nextOnionDeliveryUnlocked: false,
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

// Helper for single-row warrior-style spritesheets (one row, N frames)
function warriorFrameList(sheet, count) {
  const out = [];
  for (let i = 0; i < count; i += 1) {
    out.push({ key: sheet, frame: i });
  }
  return out;
}

function createCaelanAnimations(scene) {
  const hero = 'caelan';
  // Each entry: [sheetSuffix, frameCount, frameRate, repeat]
  // repeat -1 = loop, 0 = play once
  const defs = [
    ['idle',             1,  1,  -1],  // only frame 0 is a neutral stance; other frames are a swing
    ['walk',             6,  10, -1],  // 7th frame was nearly empty; remaining 6 re-anchored to head pos
    ['run',              6,  12, -1],
    ['walk_heavy',       6,  8,  -1],
    ['jump',             3,  10,  0],  // frames re-anchored to head pos
    ['attack',           3,  8,   0],
    ['death',            3,  5,   0],
    ['idle_sword',       1,  1,  -1],  // same — only frame 0 is a neutral stance
    ['walk_sword',       6,  10, -1],
    ['run_sword',        6,  12, -1],
    ['walk_sword_heavy', 6,  8,  -1],
    ['jump_sword',       3,  10,  0],
    ['attack_sword',     3,  8,   0],
    ['death_sword',      3,  5,   0],
    ['special_attack',   4,  8,   0],
    ['special_slash',    6,  8,   0],
    ['combo_attack',     8,  10,  0],
  ];

  defs.forEach(([suffix, count, rate, repeat]) => {
    const sheet = `${hero}-${suffix}`;
    ['right', 'left'].forEach((dir) => {
      const key = `${hero}-${suffix}-${dir}`;
      if (!scene.anims.exists(key)) {
        scene.anims.create({
          key,
          frames: warriorFrameList(sheet, count),
          frameRate: rate,
          repeat,
        });
      }
    });
  });
}

function createForestLadyAnimations(scene) {
  // GandalfHardcore single-row format; use setFlipX(true) for right, false for left
  if (!scene.anims.exists('forestLady-walk')) {
    scene.anims.create({
      key: 'forestLady-walk',
      frames: warriorFrameList('forestLady-walk', 8),
      frameRate: 10,
      repeat: -1,
    });
  }
  if (!scene.anims.exists('forestLady-idle')) {
    scene.anims.create({
      key: 'forestLady-idle',
      frames: warriorFrameList('forestLady-idle', 5),
      frameRate: 4,
      repeat: -1,
    });
  }
}

// Animations for GandalfHardcore-style single-row spritesheets (flipX for direction)
function createGandalfNpcAnimations(scene, npcConfig) {
  const { key, walkFrames, idleFrames } = npcConfig;
  if (!scene.anims.exists(`${key}-walk`)) {
    scene.anims.create({
      key: `${key}-walk`,
      frames: warriorFrameList(`${key}-walk`, walkFrames),
      frameRate: 10,
      repeat: -1,
    });
  }
  if (!scene.anims.exists(`${key}-idle`)) {
    scene.anims.create({
      key: `${key}-idle`,
      frames: warriorFrameList(`${key}-idle`, idleFrames),
      frameRate: 4,
      repeat: -1,
    });
  }
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

    this.logo = this.add.image(GAME_WIDTH / 2, 420, 'celadune-logo');
    const logoTexture = this.textures.get('celadune-logo').getSourceImage();
    const maxLogoWidth = 1860;
    const maxLogoHeight = 780;
    const logoScale = Math.min(maxLogoWidth / logoTexture.width, maxLogoHeight / logoTexture.height);
    this.logo.setScale(logoScale);

    this.add.rectangle(GAME_WIDTH / 2, 922, 384, 106, 0x1e140a, 0.72).setStrokeStyle(4, 0xdab56a, 0.9);
    this.add.rectangle(GAME_WIDTH / 2, 922, 360, 82, 0x41250d, 0.94).setStrokeStyle(2, 0xf3dfae, 0.9);
    this.add.text(GAME_WIDTH / 2, 922, 'Start', {
      fontFamily: 'Macondo Swash Caps',
      fontSize: '50px',
      color: '#fff3d0',
      stroke: '#4f280a',
      strokeThickness: 7,
      shadow: {
        offsetX: 0,
        offsetY: 2,
        color: '#000000',
        blur: 6,
        fill: true,
      },
    }).setOrigin(0.5);

    this.add.text(GAME_WIDTH / 2, 1006, 'Press Enter to begin', {
      fontFamily: 'Roboto Mono',
      fontSize: '26px',
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

    const sheen = this.add.rectangle(this.logo.x - 1080, this.logo.y, 252, 1176, 0xffffff, 0.2)
      .setAngle(-18)
      .setBlendMode(Phaser.BlendModes.SCREEN)
      .setVisible(false)
      .setDepth(this.logo.depth + 1);
    sheen.setMask(mask);

    const runSheen = () => {
      sheen.x = this.logo.x - 1080;
      sheen.y = this.logo.y;
      sheen.setVisible(true);
      this.tweens.add({
        targets: sheen,
        x: this.logo.x + 1080,
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
        frameWidth: hero.frameW,
        frameHeight: hero.frameH,
      });
    });
  }

  create() {
    this.cameras.main.setBackgroundColor('#08111a');

    const bg = this.add.image(GAME_WIDTH / 2, GAME_HEIGHT / 2, 'hero-select-bg');
    const bgTexture = this.textures.get('hero-select-bg').getSourceImage();
    const bgScale = Math.max(GAME_WIDTH / bgTexture.width, GAME_HEIGHT / bgTexture.height);
    bg.setScale(bgScale);

    const panelX = 318;
    const panelY = 182;
    const panelW = 1284;
    const panelH = 716;

    const parchment = this.add.tileSprite(panelX + panelW / 2, panelY + panelH / 2, panelW, panelH, 'parchment');
    const parchmentSource = this.textures.get('parchment').getSourceImage();
    parchment.setTileScale(160 / parchmentSource.width, 160 / parchmentSource.height);
    parchment.setAlpha(0.98);

    this.add.rectangle(panelX + panelW / 2, panelY + panelH / 2, panelW, panelH, 0x000000, 0)
      .setStrokeStyle(6, 0x5b3717, 1);
    this.add.rectangle(panelX + panelW / 2, panelY + panelH / 2, panelW - 18, panelH - 18, 0x000000, 0)
      .setStrokeStyle(2, 0xdab56a, 0.95);

    this.add.text(GAME_WIDTH / 2, panelY + 74, 'Select Your Hero', {
      fontFamily: 'Macondo Swash Caps',
      fontSize: '56px',
      color: '#4a2411',
      stroke: '#f5e2b6',
      strokeThickness: 3,
    }).setOrigin(0.5);

    this.add.text(GAME_WIDTH / 2, panelY + panelH - 65, 'Left / Right to choose  •  Enter to confirm', {
      fontFamily: 'Roboto Mono',
      fontSize: '24px',
      color: '#4e3720',
    }).setOrigin(0.5);

    this.heroCards = this.heroOrder.map((heroKey, index) => {
      const x = index === 0 ? 768 : 1152;
      const y = 538;

      const outer = this.add.rectangle(x, y, 300, 398, 0x000000, 0).setStrokeStyle(4, 0xdab56a, 0.98);
      const inner = this.add.rectangle(x, y, 278, 377, 0x000000, 0).setStrokeStyle(2, 0xe9cf96, 0.92);
      const portraitGlow = this.add.rectangle(x, y - 41, 199, 235, 0xa37a3f, 0.08).setStrokeStyle(1, 0xb88945, 0.22);
      const sprite = this.add.sprite(x, y - 43, `${heroKey}-idle`, HEROES[heroKey]?.initFrame ?? 0).setScale(3.8);
      const name = this.add.text(x, y + 125, HEROES[heroKey].name, {
        fontFamily: 'Macondo Swash Caps',
        fontSize: '40px',
        color: '#4a2411',
      }).setOrigin(0.5);
      const role = this.add.text(x, y + 166, heroKey === 'caelan' ? 'Fighter' : 'Mage', {
        fontFamily: 'Roboto Mono',
        fontSize: '22px',
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
      const hero = HEROES[heroKey];
      const key = `${heroKey}-preview`;
      if (!this.anims.exists(key)) {
        const f0 = hero?.initFrame ?? 0;
        const f1 = f0 + 1;
        this.anims.create({
          key,
          frames: [
            { key: `${heroKey}-idle`, frame: f0 },
            { key: `${heroKey}-idle`, frame: f1 },
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
    this.playerGold = 0;
    this.storyFlags = { ...DEFAULT_STORY_FLAGS };
    this.scriptedNpcTargetX = null;
    this.scriptedNpcCallback = null;
    this.isTransitioningToInterior = false;
  }

  init(data) {
    this.heroKey = data?.heroKey || 'caelan';
    this.startX = data?.startX ?? 300;
    this.startY = data?.startY ?? 768;
    this.inventoryItems = Array.isArray(data?.inventoryItems) ? data.inventoryItems.map((item) => ({ ...item })) : [];
    this.equipmentItems = Array.isArray(data?.equipmentItems) ? data.equipmentItems.map((item) => ({ ...item })) : [];
    this.playerGold = Number.isFinite(data?.playerGold) ? data.playerGold : 0;
    this.questState = data?.questState || 'notOffered';
    this.storyFlags = { ...DEFAULT_STORY_FLAGS, ...(data?.storyFlags || {}) };
    this.isSceneTransitioning = false;
    this.isTransitioningToInterior = false;
    if (this.input?.keyboard) {
      this.input.keyboard.enabled = true;
      this.input.keyboard.resetKeys();
    }
    if (this.physics?.world?.isPaused) {
      this.physics.world.resume();
    }
  }

  preload() {
    this.load.image('forestSky',      'assets/bg/forest_sky.png');
    this.load.image('forestMountain', 'assets/bg/forest_mountain.png');
    this.load.image('forestBack',     'assets/bg/forest_back.png');
    this.load.image('forestMid',      'assets/bg/forest_mid.png');
    this.load.image('forestShort',    'assets/bg/forest_short.png');
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
    this.load.image('cityWall1', 'assets/props/city_wall_1.png');
    this.load.image('cityWall2', 'assets/props/city_wall_2.png');
    this.load.image('cityWall3', 'assets/props/city_wall_3.png');
    this.load.image('cityArchway', 'assets/buildings/city_archway/building.png');
    this.load.image('cityHouse1', 'assets/buildings/city_house_1/building.png');
    this.load.image('cityHouse2', 'assets/buildings/city_house_2/building.png');
    this.load.image('cityHouse3', 'assets/buildings/city_house_3/building.png');
    this.load.image('cityMagicShop', 'assets/buildings/city_magic_shop/building.png');
    this.load.image('cityTavern', 'assets/buildings/city_tavern/building.png');
    this.load.image('cityBlacksmithShop', 'assets/buildings/city_blacksmith/building.png');
    this.load.image('forestHut', 'assets/buildings/forest_hut/building.png');
    this.load.image('forestHutInterior', 'assets/bg/forest_hut_interior.jpeg');
    this.load.image('brokenWagon', 'assets/props/broken_wagon.png');
    this.load.image('onionPatch', 'assets/props/onion_patch.png');
    this.load.image('largeTent', 'assets/props/large_tent.png');
    this.load.spritesheet('furnace', 'assets/props/furnace_animated.png', { frameWidth: 64, frameHeight: 64 });
    this.load.image('menuOnions', 'assets/ui/onions.png');
    this.load.image('wayfarersSalve', 'assets/ui/wayfarers_salve.png');
    this.load.audio('forestTheme', 'assets/audio/celadune_forest.mp3');
    this.load.audio('cityTheme', 'assets/audio/celadune_city.mp3');
    this.load.audio('writingSfx', 'assets/sfx/writing.mp3');
    this.load.audio('attackSfx', 'assets/sfx/freesound_community-sword-sound-2-36274.mp3');
    this.load.audio('jumpSfx',   'assets/sfx/ribhavagrawal-woosh-230554.mp3');
    this.load.spritesheet('forestLady-idle', FOREST_LADY.idle, { frameWidth: 64, frameHeight: 64 });
    this.load.spritesheet('forestLady-walk', FOREST_LADY.walk, { frameWidth: 64, frameHeight: 64 });
    this.load.spritesheet(`${HUT_WANDERER.key}-walk`, HUT_WANDERER.walk, { frameWidth: HUT_WANDERER.frameW, frameHeight: HUT_WANDERER.frameH });
    this.load.spritesheet(`${HUT_WANDERER.key}-idle`, HUT_WANDERER.idle, { frameWidth: HUT_WANDERER.frameW, frameHeight: HUT_WANDERER.frameH });

    Object.values(CITY_NPCS).forEach((npc) => {
      this.load.spritesheet(`${npc.key}-idle`, npc.idle, { frameWidth: 64, frameHeight: 64 });
      this.load.spritesheet(`${npc.key}-walk`, npc.walk, { frameWidth: 64, frameHeight: 64 });
    });

    Object.values(HEROES).forEach((hero) => {
      const fw = hero.frameW;
      const fh = hero.frameH;
      // Always load the three core sheets
      this.load.spritesheet(`${hero.key}-walk`, hero.walk, { frameWidth: fw, frameHeight: fh });
      this.load.spritesheet(`${hero.key}-idle`, hero.idle, { frameWidth: fw, frameHeight: fh });
      this.load.spritesheet(`${hero.key}-jump`, hero.jump, { frameWidth: fw, frameHeight: fh });
      // Load extended sheets for heroes that use them
      if (hero.usesFlipX) {
        const extended = [
          'run', 'walk_heavy', 'attack', 'death',
          'idle_sword', 'walk_sword', 'run_sword', 'walk_sword_heavy',
          'jump_sword', 'attack_sword', 'death_sword',
          'special_attack', 'special_slash', 'combo_attack',
        ];
        extended.forEach((anim) => {
          if (hero[anim]) {
            this.load.spritesheet(`${hero.key}-${anim}`, hero[anim], { frameWidth: fw, frameHeight: fh });
          }
        });
      }
    });
  }

  create() {
    this.physics.world.gravity.y = 1800;

    this.applyTextureFiltering();
    this.createParallaxBackground();
    this.createGround();
    this.createAnimations();
    this.createPlayer();
    this.createNPC();
    this.createHutWanderer();
    this.createProps();
    if (this.shouldUseSceneAtmosphere()) this.createAtmosphere();
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
    this.eKey = this.input.keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.E);
  }

  createParallaxBackground() {
    // Shift non-sky layers up so their bases land just below the ground line.
    const groundOffset = -(GAME_HEIGHT - (GROUND_Y + 20)); // ≈ -172

    // Make sprites wide enough that every layer covers the screen at every scroll position.
    // With scrollFactor, the sprite drifts left as the camera scrolls right;
    // maxDrift = WORLD_WIDTH * maxFactor = 5120 * 0.90 ≈ 4608, so width = WORLD_WIDTH + GAME_WIDTH covers it.
    const spriteWidth = WORLD_WIDTH + GAME_WIDTH;

    // Sky shifts up independently so clouds sit higher in the visible area.
    const skyOffset = -100;

    // Layers ordered back→front. scrollFactor drives the parallax automatically.
    const layerDefs = [
      { key: 'forestSky',      factor: 0.10, depth: -26, yOff: skyOffset },
      { key: 'forestMountain', factor: 0.26, depth: -25, yOff: groundOffset },
      { key: 'forestBack',     factor: 0.42, depth: -24, yOff: groundOffset },
      { key: 'forestMid',      factor: 0.58, depth: -23, yOff: groundOffset },
      { key: 'forestShort',    factor: 0.90, depth: -21, yOff: groundOffset },
    ];

    this.parallaxLayers = layerDefs.map(({ key, factor, depth, yOff }) => {
      const tex = this.textures.get(key).getSourceImage();
      const scale = GAME_HEIGHT / tex.height;
      const scaleX = scale;
      const sprite = this.add.tileSprite(0, yOff, spriteWidth, GAME_HEIGHT, key)
        .setOrigin(0, 0)
        .setScrollFactor(factor, 0)
        .setDepth(depth);
      sprite.setTileScale(scaleX, scale);
      return sprite;
    });

    // Keep this.bg pointing to the forestBack layer for portrait compat
    this.bg = this.parallaxLayers[2];
    const backTex = this.textures.get('forestBack').getSourceImage();
    this.bgScale = GAME_HEIGHT / backTex.height;
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

  setTextureFilter(keys, filterMode) {
    keys.forEach((key) => {
      if (this.textures.exists(key)) {
        this.textures.get(key).setFilter(filterMode);
      }
    });
  }

  applyTextureFiltering() {
    this.setTextureFilter(['forestSky', 'forestMountain', 'forestBack', 'forestMid', 'forestShort', 'cityBg', 'forestHutInterior'], Phaser.Textures.FilterMode.LINEAR);
    this.setTextureFilter([
      'blackTile', 'ground0', 'ground1', 'ground2', 'ground3',
      'cityGround1', 'cityGround2', 'cityGround3', 'parchment', 'forestHut',
      'brokenWagon', 'onionPatch', 'largeTent', 'furnace', 'menuOnions', 'wayfarersSalve',
      'cityHouse1', 'cityHouse2', 'cityHouse3', 'cityBlacksmithShop', 'cityTavern',
      'cityMagicShop', 'cityArchway', 'cityWall1', 'cityWall2', 'cityWall3',
      'forestLady-idle', 'forestLady-walk',
      `${HUT_WANDERER.key}-walk`, `${HUT_WANDERER.key}-idle`,
      ...Object.keys(CITY_NPCS).flatMap((npcKey) => [`${CITY_NPCS[npcKey].key}-walk`, `${CITY_NPCS[npcKey].key}-idle`]),
      ...Object.values(HEROES).flatMap((hero) => {
        const base = [`${hero.key}-walk`, `${hero.key}-idle`, `${hero.key}-jump`];
        if (hero.usesFlipX) {
          return base.concat([
            'run', 'walk_heavy', 'attack', 'death',
            'idle_sword', 'walk_sword', 'run_sword', 'walk_sword_heavy',
            'jump_sword', 'attack_sword', 'death_sword',
            'special_attack', 'special_slash', 'combo_attack',
          ].map((a) => `${hero.key}-${a}`));
        }
        return base;
      }),
    ], Phaser.Textures.FilterMode.NEAREST);
  }

  shouldUseSceneAtmosphere() {
    return false;
  }

  createAnimations() {
    Object.keys(HEROES).forEach((heroKey) => {
      if (HEROES[heroKey].usesFlipX) {
        createCaelanAnimations(this);
      } else {
        createHeroAnimations(this, heroKey);
        createHeroTopDownAnimations(this, heroKey);
      }
    });
    createForestLadyAnimations(this);
    Object.values(CITY_NPCS).forEach((npc) => createGandalfNpcAnimations(this, { key: npc.key, walkFrames: 8, idleFrames: 5 }));
    createGandalfNpcAnimations(this, HUT_WANDERER);
    if (!this.anims.exists('furnace-anim')) {
      this.anims.create({
        key: 'furnace-anim',
        frames: this.anims.generateFrameNumbers('furnace', { start: 0, end: 5 }),
        frameRate: 8,
        repeat: -1,
      });
    }
  }

  createPlayer() {
    const hero = HEROES[this.heroKey];
    this.player = this.physics.add.sprite(300, 768, `${this.heroKey}-idle`, hero?.initFrame ?? 39);
    this.playerBaseScaleX = 3.1;
    this.playerBaseScaleY = 3.1;
    this.player.setScale(this.playerBaseScaleX, this.playerBaseScaleY);
    this.player.setCollideWorldBounds(true);
    this.player.setDepth(10);
    const heroConfig = HEROES[this.heroKey];
    const bodyOffsetX = heroConfig?.usesFlipX ? 41 : 22;
    this.player.body.setSize(20, 34);
    this.player.body.setOffset(bodyOffsetX, 28);
    this.isAttacking = false;
    this.player.body.setMaxVelocity(350, 1200);
    this.player.body.setDragX(1800);
    this.player.body.setBounce(0);

    this.physics.add.collider(this.player, this.ground);
  }

  startAttack() {
    if (this.isAttacking) return;
    const hero = HEROES[this.heroKey];
    if (!hero?.usesFlipX) return; // only heroes with the warrior sprite set have attack animations
    this.isAttacking = true;
    this.attackSfx?.play();
    const dir = this.facing === 'right' ? 'right' : 'left';
    this.player.anims.play(`${this.heroKey}-special_attack-${dir}`, true);
    this.player.once(Phaser.Animations.Events.ANIMATION_COMPLETE, () => {
      this.isAttacking = false;
    });
  }

  createNPC() {
    this.npc = this.physics.add.sprite(2420, 768, 'forestLady-idle', 0);
    this.npc.setScale(3.0);
    this.npc.setDepth(8);
    this.npc.body.setSize(18, 34);
    this.npc.body.setOffset(23, 28);
    this.npc.body.setCollideWorldBounds(true);
    this.npc.setImmovable(false);
    this.npcMinX = 2420;
    this.npcMaxX = 2660;
    this.physics.add.collider(this.npc, this.ground);
    this.npc.anims.play('forestLady-idle', true);
    this.npc.setFlipX(true); // sprites face left by default; flip to face right

    this.npcTooltip = this.add.container(0, 0).setDepth(30).setVisible(false);
    const tooltipBg = this.add.rectangle(0, 0, 110, 30, 0x1c1209, 0.82).setStrokeStyle(2, 0xdab56a, 0.95);
    const tooltipText = this.add.text(0, 0, FOREST_LADY.name, {
      fontFamily: 'Roboto Mono',
      fontSize: '16px',
      color: '#f7edd6',
    }).setOrigin(0.5);
    this.npcTooltip.add([tooltipBg, tooltipText]);

    this.npc.patrolStartX = this.npcMinX;
    this.npc.patrolEndX = this.npcMaxX;
    this.npc.patrolDirection = 'right';
    this.npc.patrolPauseMs = 5000;
    this.npc.pauseUntil = this.time.now + this.npc.patrolPauseMs;
  }

  createHutWanderer() {
    // Aldric wanders in front of the hut (hut is at x=2240)
    const wanderMinX = 1860;
    const wanderMaxX = 2170;
    const startX = wanderMinX + (wanderMaxX - wanderMinX) / 2;

    this.wanderer = this.physics.add.sprite(startX, 768, `${HUT_WANDERER.key}-idle`, 0);
    this.wanderer.setScale(3.0);
    this.wanderer.setDepth(8);
    this.wanderer.body.setSize(18, 34);
    this.wanderer.body.setOffset(23, 28);
    this.wanderer.setCollideWorldBounds(true);
    this.wanderer.setImmovable(false);
    this.physics.add.collider(this.wanderer, this.ground);

    this.wanderer.wanderMinX = wanderMinX;
    this.wanderer.wanderMaxX = wanderMaxX;
    this.wanderer.wanderDirection = 'right';
    this.wanderer.wanderSpeed = 48;
    this.wanderer.wanderPauseMs = 3500;
    this.wanderer.pauseUntil = this.time.now + 1200; // brief delay before first move
    this.wanderer.wanderFacing = 'right';

    this.wanderer.anims.play(`${HUT_WANDERER.key}-idle`, true);
    this.wanderer.setFlipX(true); // sprite faces left by default; flip to face right on spawn
  }

  updateHutWanderer() {
    const w = this.wanderer;
    if (!w || this.isMenuOpen || this.isDialogueOpen) return;

    if (this.time.now < w.pauseUntil) {
      w.setVelocityX(0);
      if (w.anims.currentAnim?.key !== `${HUT_WANDERER.key}-idle`) {
        w.anims.play(`${HUT_WANDERER.key}-idle`, true);
      }
      return;
    }

    const dir = w.wanderDirection === 'right' ? 1 : -1;
    w.setVelocityX(dir * w.wanderSpeed);
    w.setFlipX(w.wanderDirection === 'right'); // sprite faces left natively; flip when going right
    if (w.anims.currentAnim?.key !== `${HUT_WANDERER.key}-walk`) {
      w.anims.play(`${HUT_WANDERER.key}-walk`, true);
    }

    const reachedEnd = w.wanderDirection === 'right'
      ? w.x >= w.wanderMaxX - 4
      : w.x <= w.wanderMinX + 4;

    if (reachedEnd) {
      w.wanderDirection = w.wanderDirection === 'right' ? 'left' : 'right';
      w.pauseUntil = this.time.now + w.wanderPauseMs;
      w.setVelocityX(0);
      w.anims.play(`${HUT_WANDERER.key}-idle`, true);
    }
  }

  scheduleNpcBehavior(delay = 5000) {
    if (!this.npc) return;
    this.npc.pauseUntil = this.time.now + delay;
    this.npc.setVelocityX(0);
    this.npc.anims.play('forestLady-idle', true);
    this.npcState = 'pause';
  }

  createProps() {
    this.propDepth = 7;

    this.wagon = this.add.image(360, WAGON_BASELINE_Y, 'brokenWagon')
      .setOrigin(0.5, 1)
      .setScale(0.44)
      .setDepth(this.propDepth);

    this.tent = this.add.image(610, WAGON_BASELINE_Y, 'largeTent')
      .setOrigin(0.5, 1)
      .setScale(2.5)
      .setDepth(this.propDepth);

    this.hut = this.add.image(2240, HUT_BASELINE_Y, 'forestHut')
      .setOrigin(0.5, 1)
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
      { x: 132, y: -108, scaleX: 0.72, scaleY: 1.45, alpha: 0.10, angle: -10 },
      { x: 348, y: -84, scaleX: 1.35, scaleY: 1.25, alpha: 0.15, angle: -6 },
      { x: 624, y: -120, scaleX: 0.58, scaleY: 1.55, alpha: 0.08, angle: 2 },
      { x: 912, y: -96, scaleX: 1.05, scaleY: 1.30, alpha: 0.12, angle: 5 },
      { x: 1236, y: -90, scaleX: 1.55, scaleY: 1.18, alpha: 0.10, angle: 8 },
      { x: 1590, y: -114, scaleX: 0.82, scaleY: 1.48, alpha: 0.09, angle: 12 },
      { x: 1788, y: -102, scaleX: 1.18, scaleY: 1.22, alpha: 0.11, angle: 6 },
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
    this.attackSfx = this.sound.add('attackSfx', { volume: 0.55 });
    this.jumpSfx   = this.sound.add('jumpSfx',   { volume: 0.45 });

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
    this.cameras.main.setDeadzone(264, 144);
  }

  createUI() {
    this.hud = this.add.text(26, 22, 'Press M for Menu', {
      fontFamily: 'Roboto Mono',
      fontSize: '28px',
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

    const panelX = 216;
    const panelY = 132;
    const panelW = 1488;
    const panelH = 816;
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

    this.menuTitle = this.add.text(panelX + 492, panelY + 67, 'Inventory', {
      fontFamily: 'Macondo Swash Caps',
      fontSize: '54px',
      color: '#4a2411',
      stroke: '#f5e2b6',
      strokeThickness: 3,
    }).setOrigin(0.5, 0.5);
    this.menuOverlay.add(this.menuTitle);

    this.goldCounterText = this.add.text(panelX + panelW - 204, panelY + panelH - 77, 'Gold: 0', {
      fontFamily: 'Roboto Mono',
      fontSize: '28px',
      color: '#4a2411',
      stroke: '#f5e2b6',
      strokeThickness: 2,
    }).setOrigin(0.5, 0.5);
    this.menuOverlay.add(this.goldCounterText);

    this.menuHint = this.add.text(panelX + panelW - 48, panelY + 46, 'M / Esc / Backspace to close', {
      fontFamily: 'Roboto Mono',
      fontSize: '19px',
      color: '#4e3720',
    }).setOrigin(1, 0);
    this.menuOverlay.add(this.menuHint);

    this.categoryButtons = [];
    const tabStartY = panelY + 182;
    this.menuPages.forEach((page, index) => {
      const tabBox = this.add.rectangle(panelX + 162, tabStartY + index * 106, 264, 70, 0x000000, 0)
        .setStrokeStyle(3, 0xdab56a, 0.95);
      const tabText = this.add.text(panelX + 162, tabStartY + index * 106, page, {
        fontFamily: 'Macondo Swash Caps',
        fontSize: '34px',
        color: '#5b3417',
      }).setOrigin(0.5);
      this.categoryButtons.push({ box: tabBox, text: tabText });
      this.menuOverlay.add(tabBox);
      this.menuOverlay.add(tabText);
    });

    this.contentDivider = this.add.rectangle(panelX + 318, panelY + panelH / 2, 2, panelH - 144, 0x6b4016, 0.8)
      .setOrigin(0.5, 0.5);
    this.menuOverlay.add(this.contentDivider);

    this.gridContainer = this.add.container(panelX + 386, panelY + 122);
    this.menuOverlay.add(this.gridContainer);

    this.controlsContainer = this.add.container(panelX + 386, panelY + 151);
    this.menuOverlay.add(this.controlsContainer);

    this.emptyStateText = this.add.text(panelX + 386, panelY + 180, '', {
      fontFamily: 'Roboto Mono',
      fontSize: '28px',
      color: '#5d4322',
    }).setVisible(false);
    this.menuOverlay.add(this.emptyStateText);

    this.actionMenuContainer = this.add.container(panelX + 1054, panelY + 218).setVisible(false);
    this.actionMenuBg = this.add.rectangle(0, 0, 276, 0, 0xf0e0b8, 0.96)
      .setOrigin(0, 0)
      .setStrokeStyle(3, 0x5b3717, 0.95);
    this.actionMenuTitle = this.add.text(22, 17, 'Actions', {
      fontFamily: 'Macondo Swash Caps',
      fontSize: '34px',
      color: '#4a2411',
    });
    this.actionMenuList = this.add.container(0, 0);
    this.actionMenuContainer.add([this.actionMenuBg, this.actionMenuTitle, this.actionMenuList]);
    this.menuOverlay.add(this.actionMenuContainer);

    this.controlsHeadingKeyboard = this.add.text(0, 0, 'KEYBOARD', {
      fontFamily: 'Roboto Mono',
      fontSize: '28px',
      fontStyle: 'bold',
      color: '#3f2411',
    });
    this.controlsKeyboardBody = this.add.text(0, 46, '', {
      fontFamily: 'Roboto Mono',
      fontSize: '25px',
      color: '#2b1b0f',
      lineSpacing: 12,
    });
    this.controlsHeadingController = this.add.text(0, 338, 'CONTROLLER (PLANNED)', {
      fontFamily: 'Roboto Mono',
      fontSize: '28px',
      fontStyle: 'bold',
      color: '#3f2411',
    });
    this.controlsControllerBody = this.add.text(0, 384, '', {
      fontFamily: 'Roboto Mono',
      fontSize: '25px',
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

  addGold(amount) {
    if (!Number.isFinite(amount)) return;
    this.playerGold = Math.max(0, this.playerGold + amount);
    this.refreshGoldDisplay();
  }

  spendGold(amount) {
    if (!Number.isFinite(amount) || amount <= 0) return false;
    if (this.playerGold < amount) return false;
    this.playerGold -= amount;
    this.refreshGoldDisplay();
    return true;
  }

  refreshGoldDisplay() {
    if (!this.goldCounterText) return;
    this.goldCounterText.setText(`Gold: ${this.playerGold}`);
    const showGold = this.menuPages[this.menuSectionIndex] === 'Inventory';
    this.goldCounterText.setVisible(showGold);
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
      if (this.questState === 'accepted') this.questState = 'onionsEaten';
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
    this.refreshGoldDisplay();

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
        'Space               Attack\n' +
        'E                   Interact\n' +
        'Enter               Confirm\n' +
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
    const slotSize = 144;
    const gapX = 29;
    const gapY = 36;
    const labelGap = 10;
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
        const icon = this.add.image(x + slotSize / 2, y + slotSize / 2 - 7, item.texture)
          .setDisplaySize(103, 103)
          .setOrigin(0.5);
        children.push(icon);
      }

      const label = this.add.text(x + slotSize / 2, y + slotSize + labelGap, item.name, {
        fontFamily: 'Roboto Mono',
        fontSize: '17px',
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
      const menuWidth = 276;
      const rowHeight = 50;
      const menuHeight = 65 + item.actions.length * rowHeight + 17;
      this.actionMenuBg.setSize(menuWidth, menuHeight);
      item.actions.forEach((action, index) => {
        const optionBg = this.add.rectangle(17, 65 + index * rowHeight, menuWidth - 34, rowHeight - 2, 0x000000, 0)
          .setOrigin(0, 0)
          .setStrokeStyle(index === this.menuActionIndex ? 3 : 2, index === this.menuActionIndex ? 0x6b4016 : 0xdab56a, 0.95)
          .setFillStyle(index === this.menuActionIndex ? 0x9b7740 : 0x000000, index === this.menuActionIndex ? 0.08 : 0);
        const optionText = this.add.text(36, 73 + index * rowHeight, action, {
          fontFamily: 'Roboto Mono',
          fontSize: '24px',
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

    const panelW = 1320;
    const panelH = 528;
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

    const contentLeft = panelX + 43;
    const contentTop = panelY + 36;
    const contentRight = panelX + panelW - 43;
    const portraitSize = 226;
    const portraitInner = portraitSize - 4;
    const portraitX = contentLeft + portraitSize / 2;
    const portraitY = contentTop + portraitSize / 2;
    const textX = panelX + 348;
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

    this.portraitSceneBg = this.add.tileSprite(portraitX, portraitY, portraitInner, portraitInner, 'forestBack').setOrigin(0.5);
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

    this.npcPortrait = this.add.sprite(portraitX, this.dialoguePortraitRect.bottom + 98, 'forestLady-idle', 0)
      .setOrigin(0.5, 1)
      .setScale(6.1)
      .setMask(this.portraitMask)
      .setVisible(true);
    this.dialogueOverlay.add(this.npcPortrait);

    this.dialogueSpeakerText = this.add.text(textX, contentTop + 12, FOREST_LADY.name, {
      fontFamily: 'Macondo Swash Caps',
      fontSize: '40px',
      color: '#4a2411',
    });
    this.dialogueOverlay.add(this.dialogueSpeakerText);

    this.dialogueText = this.add.text(textX, contentTop + 79, '', {
      fontFamily: 'Roboto Mono',
      fontSize: '24px',
      color: '#2b1b0f',
      lineSpacing: 12,
      wordWrap: { width: textRight - textX },
      maxLines: 5,
    });
    this.dialogueOverlay.add(this.dialogueText);

    this.dialogueOptionWidth = panelW - 86;
    this.dialogueOptions = this.add.container(contentLeft, panelY + panelH - 170);
    this.dialogueOverlay.add(this.dialogueOptions);

    this.dialogueHint = this.add.text(panelX + panelW - 41, panelY + 22, 'Enter to choose', {
      fontFamily: 'Roboto Mono',
      fontSize: '19px',
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

  removeInventoryItem(name) {
    const itemIndex = this.inventoryItems.findIndex((item) => item.name === name);
    if (itemIndex === -1) return false;
    this.inventoryItems.splice(itemIndex, 1);
    if (this.isMenuOpen && this.menuPages[this.selectedMenuIndex] === 'Inventory') {
      this.refreshMenuPage();
    }
    return true;
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
      this.npc.anims.play('forestLady-idle', true);
      this.npc.setFlipX(this.npcFacing === 'right');
      const callback = this.scriptedNpcCallback;
      this.scriptedNpcTargetX = null;
      this.scriptedNpcCallback = null;
      callback?.();
      return true;
    }

    if (delta < 0) {
      this.npcFacing = 'left';
      this.npc.setVelocityX(-95);
      this.npc.anims.play('forestLady-walk', true);
      this.npc.setFlipX(false);
    } else {
      this.npcFacing = 'right';
      this.npc.setVelocityX(95);
      this.npc.anims.play('forestLady-walk', true);
      this.npc.setFlipX(true);
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
    const safeStartX = Phaser.Math.Clamp(startX, 48, WORLD_WIDTH - 48);
    const safeStartY = Phaser.Math.Clamp(startY, 0, GROUND_Y - 4);
    this.player.setVelocity(0, 0);
    if (this.npc) this.npc.setVelocity(0, 0);
    this.physics.world.pause();
    if (this.input?.keyboard) {
      this.input.keyboard.resetKeys();
      this.input.keyboard.enabled = false;
    }
    this.fadeOutMusic(220);
    this.cameras.main.once(Phaser.Cameras.Scene2D.Events.FADE_OUT_COMPLETE, () => {
      this.scene.start(targetSceneKey, {
        heroKey: this.heroKey,
        startX: safeStartX,
        startY: safeStartY,
        inventoryItems: this.inventoryItems,
        equipmentItems: this.equipmentItems,
        playerGold: this.playerGold,
        questState: this.questState,
        storyFlags: this.storyFlags,
      });
    });
    this.cameras.main.fadeOut(220, 0, 0, 0);
  }

  handleSceneBoundaries(velocityX, onGround) {
    if (this.isMenuOpen || this.isDialogueOpen || this.isTransitioningToInterior || this.isSceneTransitioning) return;
    if (!onGround) return;
    if (velocityX > 0 && this.player.body.blocked.right) {
      this.transitionToScene('CityScene', 72, this.player.y);
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
    this.wanderer?.anims.pause();
  }

  closeMenu() {
    if (!this.isMenuOpen) return;
    this.isMenuOpen = false;
    this.menuMode = 'categories';
    this.menuOverlay.setVisible(false);
    this.physics.world.resume();
    this.player.anims.resume();
    this.npc.anims.resume();
    this.wanderer?.anims.resume();
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
    if (this.wanderer) { this.wanderer.setVelocityX(0); this.wanderer.anims.pause(); }
    this.player.anims.play(`${this.heroKey}-idle-${this.facing}`, true);
    this.npc.anims.play('forestLady-idle', true);
    this.npc.setFlipX(this.npcFacing === 'right');
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
    if (this.wanderer) {
      this.wanderer.anims.resume();
      this.wanderer.pauseUntil = this.time.now + 600;
    }
    this.scheduleNpcBehavior(900);
    this.flushQueuedItemReceivePopups();
  }

  startDialogueSequence(sequence = 'intro') {
    this.dialogueChoiceIndex = 0;

    if (sequence === 'onionQuest') {
      if (this.questState === 'accepted' && this.hasInventoryItem('Onions')) {
        this.dialogueState = 'questAcceptedReminder';
        this.showDialogueLine({
          speaker: FOREST_LADY.name,
          speakerType: 'npc',
          text: 'Those onions should still be fresh enough, dear heart. Padrig at the tavern will be delighted to have them if you are still bound for the city.',
          choices: ['I will deliver them.', 'Not today.'],
        });
        return;
      }

      if (this.questState === 'nextDeliveryAccepted' && this.hasInventoryItem('Onions')) {
        this.dialogueState = 'mirelleNextDeliveryReminder';
        this.showDialogueLine({
          speaker: FOREST_LADY.name,
          speakerType: 'npc',
          text: 'That fresh bundle is for Elira Fen, dear heart. When her door is built and her table is waiting, I know you will carry it kindly.',
          choices: ['I still have the onions for Elira Fen.'],
        });
        return;
      }

      if (this.questState === 'paymentPending' && !this.storyFlags.mirellePaymentResolved) {
        this.dialogueState = 'mirellePaymentChoice';
        this.showDialogueLine({
          speaker: FOREST_LADY.name,
          speakerType: 'npc',
          text: 'Oh, you came back. Did Padrig send the onion money along with his thanks?',
          choices: ['Give Mirelle the full 5 gold.', 'Say Padrig only paid 1 gold.'],
        });
        return;
      }

      if (this.questState === 'paidInFull') {
        this.dialogueState = 'mirelleNextDelivery';
        this.showDialogueLine({
          speaker: FOREST_LADY.name,
          speakerType: 'npc',
          text: 'You are an honest soul, and I will remember it. When next I have a good bundle ready, would you carry one to Elira Fen by the east road? She always saves a place for my onions at her table.',
          choices: ['I would be glad to help when the time comes.'],
        });
        return;
      }

      if (this.questState === 'paymentResolved') {
        this.dialogueState = 'mirelleAfterPayment';
        this.showDialogueLine({
          speaker: FOREST_LADY.name,
          speakerType: 'npc',
          text: 'Thank you again for helping an old woman mind her little patch. The road feels friendlier when there is kindness on it.',
          choices: ['Take care, Mirelle.'],
        });
        return;
      }

      if (this.questState === 'delivered') {
        this.dialogueState = 'mirelleAwaitingPayment';
        this.showDialogueLine({
          speaker: FOREST_LADY.name,
          speakerType: 'npc',
          text: 'Back already? If Padrig has not paid you yet, do not fret. He is warm-hearted, but the man lives with half his thoughts in a stewpot.',
          choices: ['I will see him again soon.'],
        });
        return;
      }

      if (this.questState === 'onionsEaten') {
        if (!this.storyFlags.onionsReplacementGiven) {
          this.dialogueState = 'questReplacementOffer';
          this.showDialogueLine({
            speaker: FOREST_LADY.name,
            speakerType: 'npc',
            text: 'Oh... you ate them? Well, I cannot pretend that does not sting a little, but no good comes from sending you off empty-handed. I can spare one more bundle, if you truly mean to deliver it this time.',
            choices: ['Could I have another bunch of onions?', 'No, I should not ask that of you.'],
          });
        } else {
          this.dialogueState = 'questNoMoreOnions';
          this.showDialogueLine({
            speaker: FOREST_LADY.name,
            speakerType: 'npc',
            text: 'I have already trusted you with all I can spare, dear. I must keep the rest for market and for my own table.',
            choices: ['I understand.'],
          });
        }
        return;
      }

      if (this.questState === 'declined') {
        this.dialogueState = 'questReoffer';
        this.showDialogueLine({
          speaker: FOREST_LADY.name,
          speakerType: 'npc',
          text: 'It is no great trouble if you cannot, but I would enjoy the company of knowing someone kind is carrying my onions into town. Have you changed your mind?',
          choices: ['I can take the onions.', 'I still cannot help.'],
        });
        return;
      }

      this.dialogueState = 'onionOffer';
      this.showDialogueLine({
        speaker: FOREST_LADY.name,
        speakerType: 'npc',
        text: 'These are my onions, sweet and strong and just the thing for a proper tavern pot. I sell them to Padrig in the city, but I am running behind today. Would you carry a bundle to him for me?',
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
      this.npcPortrait.setTexture('forestLady-idle').setFrame(0);
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
      this.npcPortrait.setTexture('forestLady-idle').setFrame(0);
      return;
    }
    if (!this.writingSound.isPlaying) this.writingSound.play();
    const talkFrames = [
      { texture: 'forestLady-idle', frame: 0 },
      { texture: 'forestLady-idle', frame: 1 },
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
    this.npcPortrait.setTexture('forestLady-idle').setFrame(0);
    if (this.writingSound?.isPlaying) this.writingSound.stop();
  }

  renderDialogueOptions(options) {
    this.clearDialogueOptions();
    this.dialogueOptionEntries = options.map((option, index) => {
      const y = index * 67;
      const box = this.add.rectangle(0, y, this.dialogueOptionWidth, 50, 0x000000, 0)
        .setOrigin(0, 0)
        .setStrokeStyle(2, 0xdab56a, 0.92);
      const text = this.add.text(17, y + 10, option, {
        fontFamily: 'Roboto Mono',
        fontSize: '19px',
        color: '#3e2514',
        wordWrap: { width: this.dialogueOptionWidth - 34 },
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
        if (!this.hasInventoryItem('Onions')) this.addInventoryItem({ name: 'Onions', texture: 'menuOnions', actions: ['Eat'] });
        this.dialogueState = 'questAccepted';
        this.showDialogueLine({
          speaker: FOREST_LADY.name,
          speakerType: 'npc',
          text: 'Bless you, dear. Take this bundle to Padrig at the tavern in the city. He will know they are mine the moment he smells them.',
          choices: ['I will deliver the onions.'],
        });
      } else {
        this.questState = 'declined';
        this.dialogueState = 'questDeclined';
        this.showDialogueLine({
          speaker: FOREST_LADY.name,
          speakerType: 'npc',
          text: 'Very well, then. If your road bends this way again and you have a little time to spare, come speak with me.',
          choices: ['Understood.'],
        });
      }
    } else if (this.dialogueState === 'questReplacementOffer') {
      if (selectedText === 'Could I have another bunch of onions?') {
        this.storyFlags.onionsReplacementGiven = true;
        this.questState = 'accepted';
        if (!this.hasInventoryItem('Onions')) this.addInventoryItem({ name: 'Onions', texture: 'menuOnions', actions: ['Eat'] });
        this.dialogueState = 'questReplacementGiven';
        this.showDialogueLine({
          speaker: FOREST_LADY.name,
          speakerType: 'npc',
          text: 'Here you are. Please take better care of this bunch than you did the last, hmm? My old heart would rather not be disappointed twice in one afternoon.',
          choices: ['I will take them straight to Padrig.'],
        });
      } else {
        this.dialogueState = 'questReplacementDeclined';
        this.showDialogueLine({
          speaker: FOREST_LADY.name,
          speakerType: 'npc',
          text: 'That is probably for the best. No harm in honesty, dear.',
          choices: ['Take care, Mirelle.'],
        });
      }
    } else if (this.dialogueState === 'mirellePaymentChoice') {
      if (selectedText === 'Give Mirelle the full 5 gold.') {
        if (this.spendGold(5)) {
          this.storyFlags.mirellePaymentResolved = true;
          this.storyFlags.mirellePaidInFull = true;
          this.storyFlags.mirellePaymentAmount = 5;
          this.storyFlags.nextOnionDeliveryUnlocked = true;
          if (!this.hasInventoryItem('Onions')) this.addInventoryItem({ name: 'Onions', texture: 'menuOnions', actions: ['Eat'] });
          this.questState = 'nextDeliveryAccepted';
          this.dialogueState = 'mirellePaidInFull';
          this.showDialogueLine({
            speaker: FOREST_LADY.name,
            speakerType: 'npc',
            text: 'Five gold? Oh, that is more than fair. Thank you, truly. And thank you for bringing me every coin of it. Here now, I have another fresh bundle ready. When the time comes, would you carry these onions to Elira Fen for me? She has a fondness for onion tarts and a gentleness that reminds me of spring rain.',
            choices: ['I would be glad to help.'],
          });
        } else {
          this.dialogueState = 'mirelleNoGold';
          this.showDialogueLine({
            speaker: FOREST_LADY.name,
            speakerType: 'npc',
            text: 'Oh? It sounds as though the road has already parted you from the payment. Never mind. These things happen.',
            choices: ['I am sorry.'],
          });
        }
      } else {
        this.spendGold(1);
        this.storyFlags.mirellePaymentResolved = true;
        this.storyFlags.mirellePaidInFull = false;
        this.storyFlags.mirellePaymentAmount = 1;
        this.questState = 'paymentResolved';
        this.dialogueState = 'mirellePaidOne';
        this.showDialogueLine({
          speaker: FOREST_LADY.name,
          speakerType: 'npc',
          text: 'Only one? Oh... well, if that is what Padrig could spare, then I suppose I must make peace with it. That is disappointing to hear. I had thought better of him.',
          choices: ['I am sorry to be the bearer of it.'],
        });
      }
    } else if ([
      'questAccepted',
      'questDeclined',
      'questAcceptedReminder',
      'questReplacementGiven',
      'questReplacementDeclined',
      'questNoMoreOnions',
      'mirelleAwaitingPayment',
      'mirellePaidInFull',
      'mirellePaidOne',
      'mirelleNoGold',
      'mirelleAfterPayment',
      'mirelleNextDelivery',
      'mirelleNextDeliveryReminder'
    ].includes(this.dialogueState)) {
      if (this.dialogueState === 'mirellePaidOne') {
        this.questState = 'paymentResolved';
      }
      this.closeDialogue();
    }
  }

  updateNPCBehavior() {
    if (!this.npc) return;

    if (this.scriptedNpcTargetX !== null) {
      this.npcTooltip.setVisible(false);
      return;
    }

    if (!this.isMenuOpen && !this.isDialogueOpen) {
      if (this.time.now < (this.npc.pauseUntil || 0)) {
        this.npc.setVelocityX(0);
        if (this.npc.anims.currentAnim?.key !== 'forestLady-idle') {
          this.npc.anims.play('forestLady-idle', true);
        }
        this.npcState = 'pause';
      } else {
        const direction = this.npc.patrolDirection === 'left' ? -1 : 1;
        this.npc.setVelocityX(direction * 55);
        this.npc.setFlipX(this.npc.patrolDirection === 'right');
        if (this.npc.anims.currentAnim?.key !== 'forestLady-walk') {
          this.npc.anims.play('forestLady-walk', true);
        }
        this.npcState = 'walk';

        const reachedEnd = this.npc.patrolDirection === 'right'
          ? this.npc.x >= this.npc.patrolEndX - 4
          : this.npc.x <= this.npc.patrolStartX + 4;
        if (reachedEnd) {
          this.npc.patrolDirection = this.npc.patrolDirection === 'right' ? 'left' : 'right';
          this.npc.pauseUntil = this.time.now + this.npc.patrolPauseMs;
          this.npc.setVelocityX(0);
          this.npc.anims.play('forestLady-idle', true);
          this.npcState = 'pause';
        }
      }
    }

    const distance = Phaser.Math.Distance.Between(this.player.x, this.player.y, this.npc.x, this.npc.y);
    const canInteract = distance < 150;
    this.npcTooltip.setVisible(canInteract);
    if (canInteract) {
      this.npcTooltip.setPosition(this.npc.x, this.npc.y - 96);
    }
  }

  update() {
    this.updateNPCBehavior();
    this.updateHutWanderer();

    const onionDistance = this.onionPatch ? Phaser.Math.Distance.Between(this.player.x, this.player.y, this.onionPatch.x, this.onionPatch.y - 40) : 9999;
    const nearOnionPatch = onionDistance < 180;
    this.onionPatchTooltip?.setVisible(nearOnionPatch && !this.isDialogueOpen && !this.isMenuOpen && this.scriptedNpcTargetX === null);
    if (nearOnionPatch) {
      this.onionPatchTooltip.setPosition(this.onionPatch.x, this.onionPatch.y - 80);
    }

    const nearHutDoor = this.hutDoorZone ? this.physics.overlap(this.player, this.hutDoorZone) : false;
    this.hutTooltip?.setVisible(nearHutDoor && !this.isDialogueOpen && !this.isMenuOpen && this.scriptedNpcTargetX === null);
    if (nearHutDoor) {
      this.hutTooltip.setPosition(this.hut.x, this.hut.y - this.hut.displayHeight - 10);
    }

    if (this.itemReceiveContainer?.visible) {
      this.itemReceiveContainer.setPosition(this.player.x, this.player.y - 116);
    }

    if (this.updateScriptedNpcMovement()) {
      return; // scrollFactor handles forest parallax; city bg updated below if needed
    }

    if (Phaser.Input.Keyboard.JustDown(this.menuKey)) {
      if (this.isMenuOpen) {
        this.closeMenu();
      } else if (!this.isDialogueOpen) {
        this.openMenu();
      }
    }

    if (this.isDialogueOpen) {
      if (this.isTyping && Phaser.Input.Keyboard.JustDown(this.enterKey)) {
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
        if (Phaser.Input.Keyboard.JustDown(this.enterKey)) {
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
    const interactPressed = Phaser.Input.Keyboard.JustDown(this.eKey);
    const nearNpc = Phaser.Math.Distance.Between(this.player.x, this.player.y, this.npc.x, this.npc.y) < 150;
    if (nearHutDoor && interactPressed) {
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
      this.jumpSfx?.play();
    }

    if (Phaser.Input.Keyboard.JustDown(this.spaceKey)) {
      this.startAttack();
    }

    const animPrefix = this.facing === 'left' ? 'left' : 'right';
    const heroConfigUpdate = HEROES[this.heroKey];
    if (heroConfigUpdate?.usesFlipX) {
      this.player.setFlipX(this.facing === 'right');
    }
    if (this.isAttacking) {
      // hold attack animation — no override until it completes
    } else if (!onGround) {
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

    this.player.setDepth(10);
    this.npc.setDepth(8);
    if (this.wanderer) this.wanderer.setDepth(8);
    this.handleSceneBoundaries(velocityX, onGround);
    // Both scenes now use scrollFactor parallax — no manual tilePositionX update needed.
    // Drift the sky/cloud layer slowly rightward even when the player is stationary.
    if (this.parallaxLayers?.[0]) {
      this.parallaxLayers[0].tilePositionX -= 0.1;
    }
  }
}

class CityScene extends PrototypeScene {
  constructor() {
    super('CityScene');
  }

  init(data) {
    super.init(data);
    this.startX = data?.startX ?? 120;
    this.startY = data?.startY ?? 768;
    this.cityNpcStates = {
      city2GiftGiven: this.hasInventoryItem(WAYFARERS_SALVE_ITEM.name),
      chefOnionsDelivered: !!this.storyFlags.chefOnionsDelivered,
    };
    this.activeCityNpc = null;
  }

  create() {
    this.physics.world.gravity.y = 1800;

    this.applyTextureFiltering();
    this.createParallaxBackground();
    this.createGround();
    this.createCityWall();
    this.createCityBuildings();
    this.createAnimations();
    this.createProps();
    this.createPlayer();
    this.createCityNPCs();
    if (this.shouldUseSceneAtmosphere()) this.createAtmosphere();
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
    this.eKey = this.input.keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.E);
  }

  createParallaxBackground() {
    const cityTexture = this.textures.get('cityBg').getSourceImage();
    const scale = GAME_HEIGHT / cityTexture.height;
    this.bgScale = scale;
    this.bgDisplayWidth = cityTexture.width * scale;
    this.bgMaxOffset = Math.max(0, this.bgDisplayWidth - GAME_WIDTH);
    this.cameraScrollRange = Math.max(1, CITY_WORLD_WIDTH - GAME_WIDTH);

    this.bg = this.add.tileSprite(0, 0, GAME_WIDTH, GAME_HEIGHT, 'cityBg')
      .setOrigin(0, 0)
      .setScrollFactor(0)
      .setDepth(-20);

    this.bg.setTileScale(scale, scale);
    this.bg.tilePositionX = 0;
  }

  createCityWall() {
    this.cityWallGroup = this.add.group();

    const wallKeys = ['cityWall1', 'cityWall2', 'cityWall3'];
    const rng = this.createSeededRandom(0xC17A11);
    let previousKey = null;
    const wallHeight = GROUND_TILE + 24;
    const wallY = GROUND_Y - GROUND_TILE + 22 - 24;
    const wallGapCenterX = CITY_WORLD_WIDTH / 2;
    const wallGapWidth = 190;
    const gapLeft = wallGapCenterX - (wallGapWidth / 2);
    const gapRight = wallGapCenterX + (wallGapWidth / 2);

    for (let i = 0; i < Math.ceil(CITY_WORLD_WIDTH / GROUND_TILE); i += 1) {
      const wallX = i * GROUND_TILE + GROUND_TILE / 2;
      if (wallX > gapLeft && wallX < gapRight) {
        continue;
      }

      let wallKey = wallKeys[Math.floor(rng() * wallKeys.length)];
      if (wallKeys.length > 1 && wallKey === previousKey) {
        wallKey = wallKeys[(wallKeys.indexOf(wallKey) + 1 + Math.floor(rng() * (wallKeys.length - 1))) % wallKeys.length];
      }
      previousKey = wallKey;

      const wallTile = this.add.image(wallX, wallY, wallKey)
        .setOrigin(0.5, 0)
        .setDisplaySize(GROUND_TILE, wallHeight)
        .setDepth(6);
      this.cityWallGroup.add(wallTile);
    }
  }

  createCityBuildings() {
    this.cityBuildings = this.add.group();

    const baseY = BLACK_TILE_GROUND_Y - 12;
    const centerX = CITY_WORLD_WIDTH / 2;
    const placements = [
      { key: 'cityHouse3',        x: centerX - 3500 },
      { key: 'cityBlacksmithShop', x: centerX - 2350 },
      { key: 'cityTavern',        x: centerX - 1280 },
      { key: 'cityArchway',       x: centerX        },
      { key: 'cityHouse1',        x: centerX + 1080 },
      { key: 'cityMagicShop',     x: centerX + 2380 },
      { key: 'cityHouse2',        x: centerX + 3740 },
    ];

    this.cityBuildingMap = {};
    placements.forEach(({ key, x }) => {
      const building = this.add.image(x, baseY, key)
        .setOrigin(0.5, 1)
        .setDepth(8);
      this.cityBuildings.add(building);
      this.cityBuildingMap[key] = building;
    });
  }

  createCityNPCs() {
    this.cityNpcGroup = this.physics.add.group();
    this.cityNpcConfigs = [
      {
        id: 'city3',
        npcKey: CITY_NPCS.city3.key,
        x: CITY_WORLD_WIDTH / 2 - 260,
        minX: 420,
        maxX: CITY_WORLD_WIDTH - 420,
        speed: 52,
        pauseDuration: 5000,
        tooltip: CITY_NPCS.city3.name,
      },
      {
        id: 'city1',
        npcKey: CITY_NPCS.city1.key,
        x: CITY_WORLD_WIDTH / 2 - 1900,
        minX: 620,
        maxX: (CITY_WORLD_WIDTH / 2) - 380,
        speed: 48,
        pauseDuration: 5000,
        tooltip: CITY_NPCS.city1.name,
      },
      {
        id: 'city2',
        npcKey: CITY_NPCS.city2.key,
        x: CITY_WORLD_WIDTH / 2 + 1750,
        minX: (CITY_WORLD_WIDTH / 2) + 380,
        maxX: CITY_WORLD_WIDTH - 620,
        speed: 48,
        pauseDuration: 5000,
        tooltip: CITY_NPCS.city2.name,
      },
      {
        id: 'tavernChef',
        npcKey: CITY_NPCS.tavernChef.key,
        x: this.cityBuildingMap.cityTavern.x + 100,
        minX: this.cityBuildingMap.cityTavern.x - 180,
        maxX: this.cityBuildingMap.cityTavern.x + 180,
        speed: 42,
        pauseDuration: 5000,
        tooltip: `${CITY_NPCS.tavernChef.name} (Chef)`,
      },
    ];

    this.cityNpcs = this.cityNpcConfigs.map((config) => {
      const isTavernChef = config.id === 'tavernChef';
      const npc = this.physics.add.sprite(config.x, isTavernChef ? 770 : 766, `${config.npcKey}-idle`, 0);
      npc.setScale(isTavernChef ? 2.75 : 3.0);
      npc.setCollideWorldBounds(true);
      npc.setDragX(1400);
      npc.setMaxVelocity(140, 1200);
      npc.setSize(18, 34);
      npc.setOffset(23, 28);
      npc.setDepth(8);
      npc.npcId = config.id;
      npc.npcKey = config.npcKey;
      npc.facing = 'right';
      npc.minX = config.minX;
      npc.maxX = config.maxX;
      npc.x = config.minX;
      npc.speed = config.speed;
      npc.pauseDuration = config.pauseDuration;
      npc.pauseUntil = this.time.now + npc.pauseDuration;
      npc.tooltipLabel = config.tooltip;
      npc.setVelocityX(0);
      npc.setFlipX(true); // sprites face left by default; flip to face right
      npc.anims.play(`${config.npcKey}-idle`, true);
      this.cityNpcGroup.add(npc);
      return npc;
    });

    this.physics.add.collider(this.cityNpcGroup, this.ground);
    this.cityNpcTooltips = new Map();

    this.cityNpcs.forEach((npc) => {
      const tooltip = this.add.container(0, 0).setDepth(30).setVisible(false);
      const tooltipBg = this.add.rectangle(0, 0, Math.max(132, npc.tooltipLabel.length * 8), 30, 0x1c1209, 0.82)
        .setStrokeStyle(2, 0xdab56a, 0.95);
      const tooltipText = this.add.text(0, 0, npc.tooltipLabel, {
        fontFamily: 'Roboto Mono',
        fontSize: '16px',
        color: '#f7edd6',
      }).setOrigin(0.5);
      tooltip.add([tooltipBg, tooltipText]);
      this.cityNpcTooltips.set(npc.npcId, tooltip);
    });
  }

  createDialogueUI() {
    this.dialogueOverlay = this.add.container(0, 0).setScrollFactor(0).setDepth(230).setVisible(false);
    const dim = this.add.rectangle(0, 0, GAME_WIDTH, GAME_HEIGHT, 0x05070a, 0.54).setOrigin(0, 0);
    this.dialogueOverlay.add(dim);

    const panelW = 1320;
    const panelH = 528;
    const panelX = Math.round((GAME_WIDTH - panelW) / 2);
    const panelY = Math.round((GAME_HEIGHT - panelH) / 2);

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

    const contentLeft = panelX + 43;
    const contentTop = panelY + 36;
    const contentRight = panelX + panelW - 43;
    const portraitSize = 226;
    const portraitInner = portraitSize - 4;
    const portraitX = contentLeft + portraitSize / 2;
    const portraitY = contentTop + portraitSize / 2;
    const textX = panelX + 348;
    const textRight = contentRight;

    this.dialoguePortraitRect = {
      left: portraitX - portraitInner / 2,
      top: portraitY - portraitInner / 2,
      width: portraitInner,
      height: portraitInner,
      bottom: portraitY + portraitInner / 2,
    };

    this.portraitFrame = this.add.rectangle(portraitX, portraitY, portraitSize, portraitSize, 0x000000, 0)
      .setStrokeStyle(2, 0xdab56a, 0.95);
    this.dialogueOverlay.add(this.portraitFrame);

    this.portraitSceneBg = this.add.tileSprite(portraitX, portraitY, portraitInner, portraitInner, 'cityBg').setOrigin(0.5);
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

    this.npcPortrait = this.add.sprite(portraitX, this.dialoguePortraitRect.bottom + 103, `${CITY_NPCS.city1.key}-idle`, 26)
      .setOrigin(0.5, 1)
      .setScale(6.1)
      .setMask(this.portraitMask)
      .setVisible(true);
    this.dialogueOverlay.add(this.npcPortrait);

    this.dialogueSpeakerText = this.add.text(textX, contentTop + 12, '', {
      fontFamily: 'Macondo Swash Caps',
      fontSize: '40px',
      color: '#4a2411',
    });
    this.dialogueOverlay.add(this.dialogueSpeakerText);

    this.dialogueText = this.add.text(textX, contentTop + 79, '', {
      fontFamily: 'Roboto Mono',
      fontSize: '24px',
      color: '#2b1b0f',
      lineSpacing: 12,
      wordWrap: { width: textRight - textX },
      maxLines: 5,
    });
    this.dialogueOverlay.add(this.dialogueText);

    this.dialogueOptionWidth = panelW - 86;
    this.dialogueOptions = this.add.container(contentLeft, panelY + panelH - 170);
    this.dialogueOverlay.add(this.dialogueOptions);

    this.dialogueHint = this.add.text(panelX + panelW - 41, panelY + 22, 'Enter to choose', {
      fontFamily: 'Roboto Mono',
      fontSize: '19px',
      color: '#4e3720',
    }).setOrigin(1, 0);
    this.dialogueOverlay.add(this.dialogueHint);
  }

  syncDialoguePortraitBackground() {
    if (!this.portraitSceneBg || !this.dialoguePortraitRect) return;
    this.portraitSceneBg.tilePositionX = (this.bg?.tilePositionX || 0) + this.dialoguePortraitRect.left;
    this.portraitSceneBg.tilePositionY = this.dialoguePortraitRect.top;
  }

  getMusicConfig() {
    return { key: 'cityTheme', volume: 0.42 };
  }

  createGround() {
    this.ground = this.physics.add.staticGroup();
    this.groundBack = this.add.group();
    this.groundFront = this.add.group();

    const tilesAcross = Math.ceil(CITY_WORLD_WIDTH / GROUND_TILE);
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

    this.groundShadow = this.add.rectangle(CITY_WORLD_WIDTH / 2, GROUND_Y + 10, CITY_WORLD_WIDTH, 18, 0x13210f, 0.12)
      .setDepth(3);
  }

  createNPC() {}

  createProps() {
    const centerX = CITY_WORLD_WIDTH / 2;
    const baseY = BLACK_TILE_GROUND_Y + PROP_BASELINE_OFFSET_Y;
    // Animated furnace in front of blacksmith shop (offset to its right side)
    this.furnaceSprite = this.add.sprite(centerX - 2350 + 340, baseY, 'furnace', 0)
      .setOrigin(0.5, 1)
      .setScale(3.0)
      .setDepth(9);
    this.furnaceSprite.play('furnace-anim');
  }

  beginOnionPatchInteraction() {}
  updateScriptedNpcMovement() { return false; }

  getCityNpcById(id) {
    return this.cityNpcs.find((npc) => npc.npcId === id);
  }

  getClosestCityNpc() {
    let closest = null;
    let bestDistance = 9999;
    this.cityNpcs.forEach((npc) => {
      const distance = Phaser.Math.Distance.Between(this.player.x, this.player.y, npc.x, npc.y);
      if (distance < 150 && distance < bestDistance) {
        bestDistance = distance;
        closest = npc;
      }
    });
    return closest;
  }

  openDialogue(npcId) {
    if (this.isDialogueOpen || this.isMenuOpen) return;
    this.activeCityNpc = this.getCityNpcById(npcId);
    if (!this.activeCityNpc) return;

    this.isDialogueOpen = true;
    this.dialogueOverlay.setVisible(true);
    this.physics.world.pause();
    this.player.setVelocity(0, 0);
    this.cityNpcs.forEach((npc) => npc.setVelocityX(0));
    this.player.anims.play(`${this.heroKey}-idle-${this.facing}`, true);
    this.activeCityNpc.anims.play(`${this.activeCityNpc.npcKey}-idle`, true);
    this.activeCityNpc.setVelocityX(0);
    this.portraitSceneBg?.setVisible(true);
    this.npcPortrait?.setVisible(true);
    this.npcPortrait.setTexture(`${this.activeCityNpc.npcKey}-idle`).setFrame(0);
    this.syncDialoguePortraitBackground();
    this.startDialogueSequence(npcId);
  }

  closeDialogue() {
    this.isDialogueOpen = false;
    this.dialogueOverlay.setVisible(false);
    this.clearDialogueOptions();
    this.stopTypewriter();
    this.physics.world.resume();
    this.activeCityNpc = null;
    this.flushQueuedItemReceivePopups();
  }

  startDialogueSequence(npcId) {
    this.dialogueChoiceIndex = 0;

    if (npcId === 'city1') {
      this.dialogueState = 'city1Intro';
      this.showDialogueLine({
        speaker: CITY_NPCS.city1.name,
        text: 'A fine morning for it, is it not? Everyone in the city has been summoned to the castle square. The king is meant to speak before long.',
        choices: ['What is happening at the castle?', 'Thanks. I should keep moving.'],
      });
      return;
    }

    if (npcId === 'city2') {
      if (this.cityNpcStates.city2GiftGiven || this.hasInventoryItem(WAYFARERS_SALVE_ITEM.name)) {
        this.dialogueState = 'city2AfterGift';
        this.showDialogueLine({
          speaker: CITY_NPCS.city2.name,
          text: 'You are still set on going east? Then keep your wits sharp and your eyes sharper. The road past the city does not forgive the careless.',
          choices: ['I will be careful.'],
        });
        return;
      }

      this.dialogueState = 'city2Warning';
      this.showDialogueLine({
        speaker: CITY_NPCS.city2.name,
        text: 'East of the city the roads turn mean. Beasts prowl the scrubland, and worse things watch from ruined places. Turn back while the walls are still behind you.',
        choices: ['I have to go east anyway.', 'You may be right.'],
      });
      return;
    }

    if (npcId === 'city3') {
      this.dialogueState = 'city3Worried';
      this.showDialogueLine({
        speaker: CITY_NPCS.city3.name,
        text: 'Have you seen anyone come through here carrying a little brass birdcage? No... of course not. It vanished this morning, and what was inside it matters more than I can say. Will you help me look?',
        choices: ['I will keep an eye out.', 'Not just now.'],
      });
      return;
    }

    if (npcId === 'tavernChef') {
      const choices = ['Maybe in a little while.'];
      if (this.hasInventoryItem('Onions')) {
        choices.unshift("I have Mirelle's onions for you.");
      }
      this.dialogueState = 'chefGreeting';
      const text = this.storyFlags.chefOnionsDelivered
        ? "There you are again! The kitchen still smells better for Mirelle's onions. If you see her, tell her I have not forgotten her kindness."
        : 'You there! Come warm yourself inside. I have stew on the fire, bread in the oven, and enough cheer for half the city.';
      this.showDialogueLine({
        speaker: CITY_NPCS.tavernChef.name,
        text,
        choices,
      });
    }
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
    this.talkPortrait(true);

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
    if (!this.activeCityNpc) return;
    const idleTexture = `${this.activeCityNpc.npcKey}-idle`;
    if (!active) {
      this.npcPortrait.setTexture(idleTexture).setFrame(0);
      return;
    }
    if (!this.writingSound.isPlaying) this.writingSound.play();
    const talkFrames = [0, 1];
    let talkIndex = 0;
    this.portraitTalkEvent = this.time.addEvent({
      delay: 120,
      loop: true,
      callback: () => {
        this.npcPortrait.setTexture(idleTexture).setFrame(talkFrames[talkIndex % talkFrames.length]);
        talkIndex += 1;
      },
    });
  }

  stopTalkingPortrait() {
    this.portraitTalkEvent?.remove(false);
    this.portraitTalkEvent = null;
    if (this.activeCityNpc) {
      this.npcPortrait.setTexture(`${this.activeCityNpc.npcKey}-idle`).setFrame(0);
    }
    if (this.writingSound?.isPlaying) this.writingSound.stop();
  }

  renderDialogueOptions(options) {
    this.clearDialogueOptions();
    this.dialogueOptionEntries = options.map((option, index) => {
      const y = index * 67;
      const box = this.add.rectangle(0, y, this.dialogueOptionWidth, 50, 0x000000, 0)
        .setOrigin(0, 0)
        .setStrokeStyle(2, 0xdab56a, 0.92);
      const text = this.add.text(17, y + 10, option, {
        fontFamily: 'Roboto Mono',
        fontSize: '19px',
        color: '#3e2514',
        wordWrap: { width: this.dialogueOptionWidth - 34 },
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
    this.dialogueOptions?.removeAll(true);
    this.dialogueOptionEntries = [];
  }

  chooseDialogueOption() {
    if (!this.dialogueAwaitingChoice) return;
    const selectedText = this.currentDialogueLine.choices[this.dialogueChoiceIndex];
    this.clearDialogueOptions();
    this.dialogueAwaitingChoice = false;

    if (this.dialogueState === 'city1Intro') {
      if (selectedText === 'What is happening at the castle?') {
        this.dialogueState = 'city1Castle';
        this.showDialogueLine({
          speaker: CITY_NPCS.city1.name,
          text: 'No one seems to know for certain, but the bells were rung before dawn and every household heard the call. It must be important.',
          choices: ['I should head that way.'],
        });
      } else {
        this.closeDialogue();
      }
      return;
    }

    if (this.dialogueState === 'city1Castle') {
      this.closeDialogue();
      return;
    }

    if (this.dialogueState === 'city2Warning') {
      if (selectedText === 'I have to go east anyway.') {
        this.cityNpcStates.city2GiftGiven = true;
        this.addInventoryItem({ ...WAYFARERS_SALVE_ITEM });
        this.dialogueState = 'city2Gift';
        this.showDialogueLine({
          speaker: CITY_NPCS.city2.name,
          text: 'Stubborn, then. Fine. Take this and keep it close. It is only a simple salve, but it may buy you a little time if the road turns against you.',
          choices: ['Thank you. I will take it.'],
        });
      } else {
        this.dialogueState = 'city2Stay';
        this.showDialogueLine({
          speaker: CITY_NPCS.city2.name,
          text: 'For once, a traveler with sense. Stay within the city walls until you truly know what waits beyond them.',
          choices: ['Understood.'],
        });
      }
      return;
    }

    if (['city2Gift', 'city2Stay', 'city2AfterGift'].includes(this.dialogueState)) {
      this.closeDialogue();
      return;
    }

    if (this.dialogueState === 'city3Worried') {
      this.dialogueState = 'city3End';
      const response = selectedText === 'I will keep an eye out.'
        ? 'Thank you. If you find any trace of it, please come back and tell me at once.'
        : 'I understand. Still, if anything unusual catches your eye, remember what I asked.';
      this.showDialogueLine({
        speaker: CITY_NPCS.city3.name,
        text: response,
        choices: ['All right.'],
      });
      return;
    }

    if (this.dialogueState === 'city3End') {
      this.closeDialogue();
      return;
    }

    if (this.dialogueState === 'chefGreeting') {
      if (selectedText === "I have Mirelle's onions for you.") {
        this.removeInventoryItem('Onions');
        this.cityNpcStates.chefOnionsDelivered = true;
        this.storyFlags.chefOnionsDelivered = true;
        this.questState = 'paymentPending';
        this.addGold(5);
        this.dialogueState = 'chefThanks';
        this.showDialogueLine({
          speaker: CITY_NPCS.tavernChef.name,
          text: "Mirelle's onions? Bless the pan and the cutting board. These are my favorite in all the valley. You have done me a grand kindness. Here are 5 gold for Mirelle, exactly as promised.",
          choices: ['I will take the payment to Mirelle.'],
        });
      } else {
        this.dialogueState = 'chefInvite';
        this.showDialogueLine({
          speaker: CITY_NPCS.tavernChef.name,
          text: 'Then come by when your boots are tired. I will have a hot plate ready and a mug to match it.',
          choices: ['I will remember that.'],
        });
      }
      return;
    }

    if (['chefThanks', 'chefInvite'].includes(this.dialogueState)) {
      this.closeDialogue();
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
    this.cityNpcs?.forEach((npc) => npc.anims.pause());
  }

  closeMenu() {
    if (!this.isMenuOpen) return;
    this.isMenuOpen = false;
    this.menuMode = 'categories';
    this.menuOverlay.setVisible(false);
    this.physics.world.resume();
    this.player.anims.resume();
    this.cityNpcs?.forEach((npc) => npc.anims.resume());
  }

  updateNPCBehavior() {
    if (!this.cityNpcs?.length) return;
    this.activeNearbyNpc = null;
    let nearestDistance = 9999;

    this.cityNpcs.forEach((npc) => {
      const tooltip = this.cityNpcTooltips.get(npc.npcId);
      const distance = Phaser.Math.Distance.Between(this.player.x, this.player.y, npc.x, npc.y);
      const canInteract = distance < 150 && !this.isDialogueOpen && !this.isMenuOpen;
      tooltip?.setVisible(canInteract);
      if (canInteract) {
        tooltip.setPosition(npc.x, npc.y - 96);
        if (distance < nearestDistance) {
          nearestDistance = distance;
          this.activeNearbyNpc = npc;
        }
      }

      if (this.isDialogueOpen || this.isMenuOpen) return;

      if (this.time.now < npc.pauseUntil) {
        npc.setVelocityX(0);
        if (npc.anims.currentAnim?.key !== `${npc.npcKey}-idle`) {
          npc.anims.play(`${npc.npcKey}-idle`, true);
        }
        return;
      }

      if (npc.x <= npc.minX + 4) npc.facing = 'right';
      if (npc.x >= npc.maxX - 4) npc.facing = 'left';

      const direction = npc.facing === 'left' ? -1 : 1;
      npc.setVelocityX(direction * npc.speed);
      npc.setFlipX(npc.facing === 'right');
      if (npc.anims.currentAnim?.key !== `${npc.npcKey}-walk`) {
        npc.anims.play(`${npc.npcKey}-walk`, true);
      }
      npc.setDepth(8);

      const reachedEnd = (npc.facing === 'left' && npc.x <= npc.minX + 4) || (npc.facing === 'right' && npc.x >= npc.maxX - 4);
      if (reachedEnd) {
        npc.pauseUntil = this.time.now + npc.pauseDuration;
        npc.setVelocityX(0);
        npc.anims.play(`${npc.npcKey}-idle`, true);
        npc.facing = npc.facing === 'left' ? 'right' : 'left';
      }
    });
  }

  handleSceneBoundaries(velocityX, onGround) {
    if (this.isMenuOpen || this.isDialogueOpen || this.isSceneTransitioning) return;
    if (!onGround) return;
    if (velocityX < 0 && this.player.body.blocked.left) {
      this.transitionToScene('PrototypeScene', WORLD_WIDTH - 72, this.player.y);
    }
  }

  createCamera() {
    this.physics.world.setBounds(0, 0, CITY_WORLD_WIDTH, GAME_HEIGHT);
    this.cameras.main.setBounds(0, 0, CITY_WORLD_WIDTH, GAME_HEIGHT);
    this.cameras.main.startFollow(this.player, true, 0.08, 0.08);
    this.cameras.main.setDeadzone(264, 144);
  }

  update() {
    this.updateNPCBehavior();

    if (this.itemReceiveContainer?.visible) {
      this.itemReceiveContainer.setPosition(this.player.x, this.player.y - 116);
    }

    if (Phaser.Input.Keyboard.JustDown(this.menuKey)) {
      if (this.isMenuOpen) {
        this.closeMenu();
      } else if (!this.isDialogueOpen) {
        this.openMenu();
      }
    }

    if (this.isDialogueOpen) {
      if (this.isTyping && Phaser.Input.Keyboard.JustDown(this.enterKey)) {
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
        if (Phaser.Input.Keyboard.JustDown(this.enterKey)) {
          this.chooseDialogueOption();
        }
      }
      if (Phaser.Input.Keyboard.JustDown(this.escapeKey) || Phaser.Input.Keyboard.JustDown(this.backspaceKey)) {
        this.closeDialogue();
      }
      this.syncDialoguePortraitBackground();
      return;
    }

    if (this.isMenuOpen) {
      this.handleMenuNavigation();
      return;
    }

    const upJustPressed = Phaser.Input.Keyboard.JustDown(this.cursors.up);
    const interactPressed = Phaser.Input.Keyboard.JustDown(this.eKey);
    const nearNpc = this.getClosestCityNpc();
    if (nearNpc && interactPressed) {
      this.openDialogue(nearNpc.npcId);
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
      this.jumpSfx?.play();
    }

    if (Phaser.Input.Keyboard.JustDown(this.spaceKey)) {
      this.startAttack();
    }

    const animPrefix = this.facing === 'left' ? 'left' : 'right';
    const heroConfigUpdate = HEROES[this.heroKey];
    if (heroConfigUpdate?.usesFlipX) {
      this.player.setFlipX(this.facing === 'right');
    }
    if (this.isAttacking) {
      // hold attack animation — no override until it completes
    } else if (!onGround) {
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

    this.player.setDepth(10);
    this.handleSceneBoundaries(velocityX, onGround);

    const scrollRatio = Phaser.Math.Clamp(this.cameras.main.scrollX / this.cameraScrollRange, 0, 1);
    const backgroundOffset = this.bgMaxOffset * scrollRatio;
    this.bg.tilePositionX = backgroundOffset / this.bgScale;
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
    this.returnPosition = data?.returnPosition || { x: 2240, y: 768 };
  }

  preload() {
    this.load.image('forestHutInterior', 'assets/bg/forest_hut_interior.jpeg');

    Object.values(HEROES).forEach((hero) => {
      if (!this.textures.exists(`${hero.key}-walk`)) {
        this.load.spritesheet(`${hero.key}-walk`, hero.walk, { frameWidth: hero.frameW, frameHeight: hero.frameH });
      }
      if (!this.textures.exists(`${hero.key}-idle`)) {
        this.load.spritesheet(`${hero.key}-idle`, hero.idle, { frameWidth: hero.frameW, frameHeight: hero.frameH });
      }
    });
  }

  create() {
    Object.keys(HEROES).forEach((heroKey) => {
      const hero = HEROES[heroKey];
      if (hero.usesFlipX) {
        // Provide simple left/right walk/idle fallbacks for non-LPC heroes in top-down scenes
        [['idle', 1], ['walk', 7]].forEach(([anim, count]) => {
          ['up', 'down', 'left', 'right'].forEach((dir) => {
            const key = `${heroKey}-topdown-${anim}-${dir}`;
            if (!this.anims.exists(key)) {
              this.anims.create({
                key,
                frames: warriorFrameList(`${heroKey}-${anim}`, count),
                frameRate: anim === 'walk' ? 10 : 4,
                repeat: -1,
              });
            }
          });
        });
      } else {
        createHeroTopDownAnimations(this, heroKey);
      }
    });

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

    this.player = this.physics.add.sprite(doorwayX, doorwayY - 34, `${this.heroKey}-idle`, HEROES[this.heroKey]?.initFrame ?? 0);
    this.player.setScale(3.0);
    this.player.anims.play(`${this.heroKey}-topdown-idle-up`, true);
    this.player.setDepth(10);
    this.player.setCollideWorldBounds(true);
    const hutBodyOffsetX = HEROES[this.heroKey]?.usesFlipX ? 41 : 22;
    this.player.body.setSize(20, 24);
    this.player.body.setOffset(hutBodyOffsetX, 38);
    this.player.body.setMaxVelocity(230, 230);
    this.player.body.setDrag(1600, 1600);

    this.physics.add.collider(this.player, this.blockers);

    this.cursors = this.input.keyboard.createCursorKeys();
    this.enterKey = this.input.keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.ENTER);
    this.spaceKey = this.input.keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.SPACE);
    this.escapeKey = this.input.keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.ESC);
    this.eKey = this.input.keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.E);

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

    const hutHeroConfig = HEROES[this.heroKey];
    if (hutHeroConfig?.usesFlipX) {
      if (this.topDownFacing === 'right') this.player.setFlipX(true);
      else if (this.topDownFacing === 'left') this.player.setFlipX(false);
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

    if (Phaser.Input.Keyboard.JustDown(this.escapeKey) || Phaser.Input.Keyboard.JustDown(this.enterKey) || Phaser.Input.Keyboard.JustDown(this.eKey)) {
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
  pixelArt: false,
  antialias: true,
  antialiasGL: true,
  roundPixels: false,
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
