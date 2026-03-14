const GAME_WIDTH = 1600;
const GAME_HEIGHT = 900;
const GROUND_TILE = 160;
const WORLD_WIDTH = 5120;
const GROUND_Y = 740;
const FRAME_W = 64;
const FRAME_H = 64;

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
    this.npcState = 'idle';
    this.npcFacing = 'right';
    this.dialogueChoiceIndex = 0;
  }

  init(data) {
    this.heroKey = data?.heroKey || 'caelan';
  }

  preload() {
    this.load.image('forest', 'assets/bg/forest.png');
    this.load.image('blackTile', 'assets/tiles/black_tile.png');
    this.load.image('ground0', 'assets/tiles/ground_tile.png');
    this.load.image('ground1', 'assets/tiles/ground_tile_1.png');
    this.load.image('ground2', 'assets/tiles/ground_tile_2.png');
    this.load.image('ground3', 'assets/tiles/ground_tile_3.png');
    this.load.image('parchment', 'assets/ui/parchment.png');
    this.load.audio('forestTheme', 'assets/audio/celadune_forest.mp3');
    this.load.audio('writingSfx', 'assets/sfx/writing.wav');
    this.load.spritesheet('forestLady-idle', FOREST_LADY.idle, { frameWidth: FRAME_W, frameHeight: FRAME_H });
    this.load.spritesheet('forestLady-walk', FOREST_LADY.walk, { frameWidth: FRAME_W, frameHeight: FRAME_H });
    this.load.spritesheet('forestLady-emote', FOREST_LADY.emote, { frameWidth: FRAME_W, frameHeight: FRAME_H });

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
    this.createAtmosphere();
    this.createCamera();
    this.createUI();
    this.createAudio();
    this.createMenu();
    this.createDialogueUI();

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
    Object.keys(HEROES).forEach((heroKey) => createHeroAnimations(this, heroKey));
    createForestLadyAnimations(this);
  }

  createPlayer() {
    this.player = this.physics.add.sprite(300, 620, `${this.heroKey}-idle`, 39);
    this.playerBaseScaleX = 3.1;
    this.playerBaseScaleY = 3.1;
    this.player.setScale(this.playerBaseScaleX, this.playerBaseScaleY);
    this.player.setCollideWorldBounds(true);
    this.player.setDepth(9);
    this.player.body.setSize(20, 34);
    this.player.body.setOffset(22, 28);
    this.player.body.setMaxVelocity(350, 1200);
    this.player.body.setDragX(1800);
    this.player.body.setBounce(0);

    this.physics.add.collider(this.player, this.ground);

    this.playerIdleTween = this.tweens.add({
      targets: this.player,
      scaleX: this.playerBaseScaleX * 0.985,
      scaleY: this.playerBaseScaleY * 1.02,
      duration: 950,
      ease: 'Sine.inOut',
      yoyo: true,
      repeat: -1,
      paused: true,
    });
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
    this.music = this.sound.add('forestTheme', { loop: true, volume: 0.42 });
    this.writingSound = this.sound.add('writingSfx', { loop: true, volume: 0.18 });

    if (!this.sound.locked) {
      this.music.play();
    } else {
      this.sound.once(Phaser.Sound.Events.UNLOCKED, () => {
        if (!this.music.isPlaying) this.music.play();
      });
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

  createMenu() {
    this.menuOverlay = this.add.container(0, 0).setScrollFactor(0).setDepth(200).setVisible(false);

    const dim = this.add.rectangle(0, 0, GAME_WIDTH, GAME_HEIGHT, 0x05070a, 0.62).setOrigin(0, 0);
    this.menuOverlay.add(dim);

    const panelX = 180;
    const panelY = 110;
    const panelW = 1240;
    const panelH = 680;

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

    this.tabTexts = [];
    const tabStartY = panelY + 152;
    this.menuPages.forEach((page, index) => {
      const tabBox = this.add.rectangle(panelX + 135, tabStartY + index * 88, 220, 58, 0x000000, 0)
        .setStrokeStyle(3, 0xdab56a, 0.95);
      const tabText = this.add.text(panelX + 135, tabStartY + index * 88, page, {
        fontFamily: 'Macondo Swash Caps',
        fontSize: '28px',
        color: '#5b3417',
      }).setOrigin(0.5);
      this.tabTexts.push({ box: tabBox, text: tabText });
      this.menuOverlay.add(tabBox);
      this.menuOverlay.add(tabText);
    });

    const dividerTop = panelY + 60;
    const dividerBottom = panelY + panelH - 60;
    this.contentDivider = this.add.line(0, 0, panelX + 265, dividerTop, panelX + 265, dividerBottom, 0x6b4016, 0.8)
      .setLineWidth(2, 2);
    this.menuOverlay.add(this.contentDivider);

    this.contentBody = this.add.text(panelX + 320, panelY + 132, '', {
      fontFamily: 'Roboto Mono',
      fontSize: '22px',
      color: '#2b1b0f',
      lineSpacing: 12,
      wordWrap: { width: 720 },
    });
    this.menuOverlay.add(this.contentBody);

    this.inventoryList = this.add.container(panelX + 320, panelY + 132);
    this.menuOverlay.add(this.inventoryList);

    this.refreshMenuPage();
  }

  createDialogueUI() {
    this.dialogueOverlay = this.add.container(0, 0).setScrollFactor(0).setDepth(230).setVisible(false);
    const dim = this.add.rectangle(0, 0, GAME_WIDTH, GAME_HEIGHT, 0x05070a, 0.54).setOrigin(0, 0);
    this.dialogueOverlay.add(dim);

    const panelX = 120;
    const panelY = 494;
    const panelW = 1360;
    const panelH = 320;

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

    const portraitX = panelX + 118;
    const portraitY = panelY + 126;
    this.portraitFrame = this.add.rectangle(portraitX, portraitY, 176, 176, 0x000000, 0)
      .setStrokeStyle(2, 0xdab56a, 0.95);
    this.dialogueOverlay.add(this.portraitFrame);

    this.portraitInnerFrame = this.add.rectangle(portraitX, portraitY, 148, 148, 0x000000, 0)
      .setStrokeStyle(1, 0xdab56a, 0.55);
    this.dialogueOverlay.add(this.portraitInnerFrame);

    this.portraitMaskGraphics = this.add.graphics();
    this.portraitMaskGraphics.fillStyle(0xffffff, 1);
    this.portraitMaskGraphics.fillRect(portraitX - 74, portraitY - 74, 148, 148);
    this.portraitMaskGraphics.setVisible(false);
    this.dialogueOverlay.add(this.portraitMaskGraphics);

    this.npcPortrait = this.add.sprite(portraitX, portraitY + 74, 'forestLady-idle', 26)
      .setOrigin(0.5, 1)
      .setScale(2.2);
    this.npcPortrait.setMask(this.portraitMaskGraphics.createGeometryMask());
    this.dialogueOverlay.add(this.npcPortrait);

    const textX = panelX + 226;
    this.dialogueSpeakerText = this.add.text(textX, panelY + 24, FOREST_LADY.name, {
      fontFamily: 'Macondo Swash Caps',
      fontSize: '34px',
      color: '#4a2411',
    });
    this.dialogueOverlay.add(this.dialogueSpeakerText);

    this.dialogueText = this.add.text(textX, panelY + 72, '', {
      fontFamily: 'Roboto Mono',
      fontSize: '20px',
      color: '#2b1b0f',
      lineSpacing: 10,
      wordWrap: { width: 960 },
    });
    this.dialogueOverlay.add(this.dialogueText);

    this.dialogueOptions = this.add.container(textX, panelY + 182);
    this.dialogueOverlay.add(this.dialogueOptions);

    this.dialogueHint = this.add.text(panelX + panelW - 34, panelY + panelH - 26, 'Enter to choose', {
      fontFamily: 'Roboto Mono',
      fontSize: '16px',
      color: '#4e3720',
    }).setOrigin(1, 1);
    this.dialogueOverlay.add(this.dialogueHint);
  }

  openMenu() {
    if (this.isMenuOpen || this.isDialogueOpen) return;
    this.isMenuOpen = true;
    this.menuOverlay.setVisible(true);
    this.physics.world.pause();
    this.player.anims.pause();
    this.npc.anims.pause();
  }

  closeMenu() {
    if (!this.isMenuOpen) return;
    this.isMenuOpen = false;
    this.menuOverlay.setVisible(false);
    this.physics.world.resume();
    this.player.anims.resume();
    this.npc.anims.resume();
  }

  changeMenuPage(direction) {
    this.selectedMenuIndex = Phaser.Math.Wrap(this.selectedMenuIndex + direction, 0, this.menuPages.length);
    this.refreshMenuPage();
  }

  refreshMenuPage() {
    this.tabTexts.forEach((tab, index) => {
      const active = index === this.selectedMenuIndex;
      tab.box.setFillStyle(0x000000, 0);
      tab.box.setStrokeStyle(active ? 4 : 3, active ? 0x6b4016 : 0xdab56a, 0.98);
      tab.text.setColor(active ? '#3c1d0d' : '#7f6131');
    });

    const currentPage = this.menuPages[this.selectedMenuIndex];
    this.menuTitle.setText(currentPage);

    this.inventoryList.removeAll(true);
    this.contentBody.setVisible(false);

    if (currentPage === 'Inventory') {
      let y = 0;
      this.inventoryItems.forEach((item) => {
        const row = this.add.rectangle(0, y + 18, 690, 46, 0x9b7740, 0.08).setOrigin(0, 0);
        const icon = this.add.text(18, y + 6, item.icon, {
          fontFamily: 'Macondo Swash Caps',
          fontSize: '28px',
          color: '#6b4016',
        });
        const label = this.add.text(66, y + 8, item.name, {
          fontFamily: 'Roboto Mono',
          fontSize: '20px',
          color: '#2b1b0f',
        });
        this.inventoryList.add([row, icon, label]);
        y += 62;
      });
      this.inventoryList.setVisible(true);
    } else {
      this.inventoryList.setVisible(false);
      this.contentBody.setVisible(true);
      this.contentBody.setText(
        'Keyboard\n' +
        'Arrow Left / Right  Move\n' +
        'Arrow Up            Jump\n' +
        'Enter               Confirm / Interact\n' +
        'Space               Action\n' +
        'M                   Open Menu\n' +
        'Esc / Backspace     Cancel / Close\n\n' +
        'Controller (planned)\n' +
        'D-pad / Left Stick  Move / Navigate\n' +
        'South Button        Confirm / Interact\n' +
        'East Button         Cancel / Back\n' +
        'Menu / Start        Open Menu'
      );
    }
  }

  openDialogue() {
    if (this.isDialogueOpen || this.isMenuOpen) return;
    this.isDialogueOpen = true;
    this.dialogueOverlay.setVisible(true);
    this.physics.world.pause();
    this.player.setVelocity(0, 0);
    this.npc.setVelocityX(0);
    this.player.anims.play(`${this.heroKey}-idle-${this.facing}`, true);
    this.npc.anims.play(this.npcFacing === 'left' ? 'forestLady-idle-left' : 'forestLady-idle-right', true);
    this.startDialogueSequence();
  }

  closeDialogue() {
    this.isDialogueOpen = false;
    this.dialogueOverlay.setVisible(false);
    this.clearDialogueOptions();
    this.stopTypewriter();
    this.physics.world.resume();
    this.scheduleNpcBehavior(900);
  }

  startDialogueSequence() {
    this.dialogueChoiceIndex = 0;
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
      const y = index * 54;
      const box = this.add.rectangle(0, y, 940, 42, 0x000000, 0).setOrigin(0, 0).setStrokeStyle(2, 0xdab56a, 0.92);
      const text = this.add.text(14, y + 8, option, {
        fontFamily: 'Roboto Mono',
        fontSize: '16px',
        color: '#3e2514',
        wordWrap: { width: 910 },
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
      if (selectedText) {
        this.closeDialogue();
      }
    }
  }

  updateNPCBehavior() {
    if (!this.npc || this.isMenuOpen || this.isDialogueOpen) return;

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
      this.npcTooltip.setPosition(this.npc.x, this.npc.y - 96);
    }
  }

  update() {
    this.updateNPCBehavior();

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
      if (Phaser.Input.Keyboard.JustDown(this.cursors.up)) this.changeMenuPage(-1);
      if (Phaser.Input.Keyboard.JustDown(this.cursors.down)) this.changeMenuPage(1);
      if (Phaser.Input.Keyboard.JustDown(this.escapeKey) || Phaser.Input.Keyboard.JustDown(this.backspaceKey)) {
        this.closeMenu();
      }
      return;
    }

    const nearNpc = Phaser.Math.Distance.Between(this.player.x, this.player.y, this.npc.x, this.npc.y) < 150;
    if (nearNpc && (Phaser.Input.Keyboard.JustDown(this.enterKey) || Phaser.Input.Keyboard.JustDown(this.spaceKey))) {
      this.openDialogue();
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
      if (this.playerIdleTween) {
        this.playerIdleTween.pause();
        this.player.setScale(this.playerBaseScaleX, this.playerBaseScaleY);
      }
      this.player.anims.play(`${this.heroKey}-jump-${animPrefix}`, true);
      if (this.player.body.velocity.y > -20) {
        this.player.anims.pause(this.player.anims.currentFrame);
      }
    } else if (Math.abs(velocityX) > 5) {
      if (this.playerIdleTween) {
        this.playerIdleTween.pause();
        this.player.setScale(this.playerBaseScaleX, this.playerBaseScaleY);
      }
      this.player.anims.play(`${this.heroKey}-walk-${animPrefix}`, true);
    } else {
      this.player.anims.play(`${this.heroKey}-idle-${animPrefix}`, true);
      if (this.playerIdleTween && (this.playerIdleTween.isPaused() || !this.playerIdleTween.isPlaying())) {
        this.playerIdleTween.play();
      }
    }

    this.player.setDepth(9);
    this.npc.setDepth(9);
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
