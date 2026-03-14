const GAME_WIDTH = 1600;
const GAME_HEIGHT = 900;
const GROUND_TILE = 160;
const WORLD_WIDTH = 5120;
const GROUND_Y = 740;
const FRAME_W = 64;
const FRAME_H = 64;

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
    bg.setDisplaySize(GAME_WIDTH, GAME_HEIGHT);

    this.logo = this.add.image(GAME_WIDTH / 2, 290, 'celadune-logo');
    const logoTexture = this.textures.get('celadune-logo').getSourceImage();
    const maxLogoWidth = 1080;
    const maxLogoHeight = 360;
    const logoScale = Math.min(maxLogoWidth / logoTexture.width, maxLogoHeight / logoTexture.height);
    this.logo.setScale(logoScale);

    this.add.rectangle(GAME_WIDTH / 2, 748, 320, 88, 0x1e140a, 0.72).setStrokeStyle(4, 0xdab56a, 0.9);
    this.add.rectangle(GAME_WIDTH / 2, 748, 300, 68, 0x41250d, 0.94).setStrokeStyle(2, 0xf3dfae, 0.9);
    this.startButton = this.add.text(GAME_WIDTH / 2, 748, 'Start', {
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

    this.promptText = this.add.text(GAME_WIDTH / 2, 820, 'Press Enter to begin', {
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
    const sheenWidth = 180;
    const sheenHeight = 440;
    const sheen = this.add.rectangle(this.logo.x - 700, this.logo.y, sheenWidth, sheenHeight, 0xffffff, 0.18)
      .setAngle(-18)
      .setBlendMode(Phaser.BlendModes.SCREEN)
      .setVisible(false);

    const maskShape = this.make.graphics({ x: 0, y: 0, add: false });
    const bounds = this.logo.getBounds();
    maskShape.fillRect(bounds.x, bounds.y, bounds.width, bounds.height);
    const mask = maskShape.createGeometryMask();
    sheen.setMask(mask);

    const runSheen = () => {
      sheen.setVisible(true);
      sheen.x = bounds.x - 140;
      this.tweens.add({
        targets: sheen,
        x: bounds.right + 140,
        duration: 1100,
        ease: 'Sine.easeInOut',
        onComplete: () => {
          sheen.setVisible(false);
          this.time.delayedCall(4200, runSheen);
        },
      });
    };

    this.time.delayedCall(1500, runSheen);
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
    this.time.delayedCall(520, () => this.scene.start('PrototypeScene'));
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

  preload() {
    this.load.image('forest', 'assets/bg/forest.png');
    this.load.image('ground1', 'assets/tiles/ground_tile_1.png');
    this.load.image('ground2', 'assets/tiles/ground_tile_2.png');
    this.load.image('ground3', 'assets/tiles/ground_tile_3.png');
    this.load.image('parchment', 'assets/ui/parchment.png');
    this.load.audio('forestTheme', 'assets/audio/celadune_forest.mp3');
    this.load.spritesheet('walk', 'assets/characters/walk.png', {
      frameWidth: FRAME_W,
      frameHeight: FRAME_H,
    });
    this.load.spritesheet('idle', 'assets/characters/idle.png', {
      frameWidth: FRAME_W,
      frameHeight: FRAME_H,
    });
    this.load.spritesheet('jump', 'assets/characters/jump.png', {
      frameWidth: FRAME_W,
      frameHeight: FRAME_H,
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
    const rowStart = (row) => row * 13;
    const frameList = (sheet, row, start, end) => {
      const out = [];
      for (let i = start; i <= end; i += 1) {
        out.push({ key: sheet, frame: rowStart(row) + i });
      }
      return out;
    };

    const animations = [
      { key: 'walk-left', sheet: 'walk', row: 1, start: 0, end: 8, rate: 10, repeat: -1 },
      { key: 'walk-right', sheet: 'walk', row: 3, start: 0, end: 8, rate: 10, repeat: -1 },
      { key: 'idle-left', sheet: 'idle', row: 1, start: 0, end: 1, rate: 3, repeat: -1 },
      { key: 'idle-right', sheet: 'idle', row: 3, start: 0, end: 1, rate: 3, repeat: -1 },
      { key: 'jump-left', sheet: 'jump', row: 1, start: 0, end: 3, rate: 12, repeat: 0 },
      { key: 'jump-right', sheet: 'jump', row: 3, start: 0, end: 3, rate: 12, repeat: 0 },
    ];

    animations.forEach((anim) => {
      if (!this.anims.exists(anim.key)) {
        this.anims.create({
          key: anim.key,
          frames: frameList(anim.sheet, anim.row, anim.start, anim.end),
          frameRate: anim.rate,
          repeat: anim.repeat,
        });
      }
    });
  }

  createPlayer() {
    this.player = this.physics.add.sprite(300, 634, 'idle', 39);
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

    const dim = this.add.rectangle(0, 0, GAME_WIDTH, GAME_HEIGHT, 0x05070a, 0.62)
      .setOrigin(0, 0);
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
      const tabBox = this.add.rectangle(panelX + 135, tabStartY + index * 88, 220, 58, 0x8d6a3b, 0.18)
        .setStrokeStyle(3, 0x6b4016, 0.7);
      const tabText = this.add.text(panelX + 135, tabStartY + index * 88, page, {
        fontFamily: 'Macondo Swash Caps',
        fontSize: '28px',
        color: '#5b3417',
      }).setOrigin(0.5);
      this.tabTexts.push({ box: tabBox, text: tabText });
      this.menuOverlay.add(tabBox);
      this.menuOverlay.add(tabText);
    });

    this.contentDivider = this.add.line(0, 0, panelX + 265, panelY + 118, panelX + 265, panelY + panelH - 50, 0x6b4016, 0.8)
      .setLineWidth(2, 2);
    this.menuOverlay.add(this.contentDivider);

    this.contentHeader = this.add.text(panelX + 320, panelY + 150, '', {
      fontFamily: 'Macondo Swash Caps',
      fontSize: '34px',
      color: '#4a2411',
    });
    this.contentBody = this.add.text(panelX + 320, panelY + 215, '', {
      fontFamily: 'Roboto Mono',
      fontSize: '22px',
      color: '#2b1b0f',
      lineSpacing: 12,
      wordWrap: { width: 800 },
    });
    this.menuOverlay.add(this.contentHeader);
    this.menuOverlay.add(this.contentBody);

    this.inventoryList = this.add.container(panelX + 320, panelY + 215);
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
    this.tabTexts.forEach((tab, index) => {
      const active = index === this.selectedMenuIndex;
      tab.box.setFillStyle(active ? 0xb58c51 : 0x8d6a3b, active ? 0.38 : 0.18);
      tab.box.setStrokeStyle(active ? 4 : 3, active ? 0xe3c78d : 0x6b4016, 0.95);
      tab.text.setColor(active ? '#3c1d0d' : '#5b3417');
    });

    const currentPage = this.menuPages[this.selectedMenuIndex];
    this.menuTitle.setText(currentPage);
    this.contentHeader.setText(currentPage);

    this.inventoryList.removeAll(true);
    this.contentBody.setVisible(false);
    this.contentHeader.setVisible(true);

    if (currentPage === 'Inventory') {
      let y = 0;
      this.inventoryItems.forEach((item) => {
        const row = this.add.rectangle(420, y + 18, 840, 46, 0x9b7740, 0.10)
          .setOrigin(0, 0);
        const icon = this.add.text(18, y + 6, item.icon, {
          fontFamily: 'Macondo Swash Caps',
          fontSize: '28px',
          color: '#6b4016',
        });
        const label = this.add.text(66, y + 8, item.name, {
          fontFamily: 'Roboto Mono',
          fontSize: '22px',
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
      this.player.anims.play(`jump-${animPrefix}`, true);
      if (this.player.body.velocity.y > -20) {
        this.player.anims.pause(this.player.anims.currentFrame);
      }
      this.player.setDepth(10);
    } else if (Math.abs(velocityX) > 5) {
      this.player.anims.play(`walk-${animPrefix}`, true);
      this.player.setDepth(10);
    } else {
      this.player.anims.play(`idle-${animPrefix}`, true);
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
  scene: [StartScene, PrototypeScene],
  scale: {
    mode: Phaser.Scale.FIT,
    autoCenter: Phaser.Scale.CENTER_BOTH,
  },
};

new Phaser.Game(config);
