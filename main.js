const GAME_WIDTH = 1600;
const GAME_HEIGHT = 900;
const GROUND_TILE = 160;
const WORLD_WIDTH = 5120;
const GROUND_Y = 740;
const FRAME_W = 64;
const FRAME_H = 64;

class PrototypeScene extends Phaser.Scene {
  constructor() {
    super('PrototypeScene');
    this.facing = 'right';
  }

  preload() {
    this.load.image('forest', 'assets/bg/forest.png');
    this.load.image('ground1', 'assets/tiles/ground_tile_1.png');
    this.load.image('ground2', 'assets/tiles/ground_tile_2.png');
    this.load.image('ground3', 'assets/tiles/ground_tile_3.png');
    this.load.audio('fantasyScore', 'assets/Fantasy_Score_2.mp3');
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

    this.cursors = this.input.keyboard.createCursorKeys();
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
    if (this.textures.exists('light-beam')) {
      return;
    }

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
    if (this.textures.exists('vignette')) {
      return;
    }

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
    this.music = this.sound.add('fantasyScore', {
      loop: true,
      volume: 0.42,
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
      if (this.music) {
        this.music.stop();
      }
    });

    this.events.once(Phaser.Scenes.Events.DESTROY, () => {
      if (this.music) {
        this.music.destroy();
      }
    });
  }

  createCamera() {
    this.physics.world.setBounds(0, 0, WORLD_WIDTH, GAME_HEIGHT);
    this.cameras.main.setBounds(0, 0, WORLD_WIDTH, GAME_HEIGHT);
    this.cameras.main.startFollow(this.player, true, 0.08, 0.08);
    this.cameras.main.setDeadzone(220, 120);
  }

  createUI() {
    this.hud = this.add.text(22, 18, '← → Move   ↑ Jump', {
      fontFamily: 'Arial',
      fontSize: '26px',
      color: '#eef7ff',
      stroke: '#0a1218',
      strokeThickness: 5,
    }).setScrollFactor(0).setDepth(60);
  }

  update() {
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
  scene: [PrototypeScene],
  scale: {
    mode: Phaser.Scale.FIT,
    autoCenter: Phaser.Scale.CENTER_BOTH,
  },
};

new Phaser.Game(config);
