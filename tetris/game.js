// 游戏配置
const CONFIG = {
    COLS: 10,
    ROWS: 20,
    BLOCK_SIZE: 30,
    COLORS: [
        '#000000', // 空
        '#FF0D72', // I
        '#0DC2FF', // O
        '#0DFF72', // T
        '#F538FF', // S
        '#FF8E0D', // Z
        '#FFE138', // J
        '#3877FF'  // L
    ]
};

// 方块形状定义 (使用SRS旋转系统)
const SHAPES = [
    [], // 空
    [[1,1,1,1]], // I
    [[2,2],[2,2]], // O
    [[0,3,0],[3,3,3]], // T
    [[0,4,4],[4,4,0]], // S
    [[5,5,0],[0,5,5]], // Z
    [[6,0,0],[6,6,6]], // J
    [[0,0,7],[7,7,7]]  // L
];

// 游戏状态
class Game {
    constructor() {
        this.canvas = document.getElementById('gameCanvas');
        this.ctx = this.canvas.getContext('2d');
        this.canvas.width = CONFIG.COLS * CONFIG.BLOCK_SIZE;
        this.canvas.height = CONFIG.ROWS * CONFIG.BLOCK_SIZE;

        this.board = this.createBoard();
        this.score = 0;
        this.lines = 0;
        this.level = 1;
        this.highScore = this.loadHighScore();
        this.gameOver = false;
        this.isPaused = false;
        this.gameStarted = false;

        this.currentPiece = null;
        this.currentX = 0;
        this.currentY = 0;

        this.dropCounter = 0;
        this.dropInterval = 1000; // 初始速度
        this.lastTime = 0;

        this.difficulty = 2; // 默认普通难度

        this.initUI();
        this.setupEventListeners();
        this.updateDisplay();
    }

    createBoard() {
        return Array.from({ length: CONFIG.ROWS }, () =>
            Array(CONFIG.COLS).fill(0)
        );
    }

    loadHighScore() {
        const saved = localStorage.getItem('tetrisHighScore');
        return saved ? parseInt(saved, 10) : 0;
    }

    saveHighScore() {
        if (this.score > this.highScore) {
            this.highScore = this.score;
            localStorage.setItem('tetrisHighScore', this.highScore);
        }
    }

    initUI() {
        this.scoreEl = document.getElementById('score');
        this.highScoreEl = document.getElementById('highScore');
        this.levelEl = document.getElementById('level');
        this.linesEl = document.getElementById('lines');
        this.gameOverEl = document.getElementById('gameOver');
        this.finalScoreEl = document.getElementById('finalScore');

        this.startBtn = document.getElementById('startBtn');
        this.pauseBtn = document.getElementById('pauseBtn');
        this.restartBtn = document.getElementById('restartBtn');
        this.difficultySelect = document.getElementById('difficulty');
    }

    setupEventListeners() {
        // 按钮事件
        this.startBtn.addEventListener('click', () => this.start());
        this.pauseBtn.addEventListener('click', () => this.togglePause());
        this.restartBtn.addEventListener('click', () => this.restart());

        // 难度选择
        this.difficultySelect.addEventListener('change', (e) => {
            this.difficulty = parseInt(e.target.value, 10);
            this.updateSpeed();
        });

        // 键盘控制
        document.addEventListener('keydown', (e) => this.handleKeyPress(e));

        // 触控按钮
        document.getElementById('leftBtn').addEventListener('touchstart', (e) => {
            e.preventDefault();
            this.move(-1);
        });

        document.getElementById('rightBtn').addEventListener('touchstart', (e) => {
            e.preventDefault();
            this.move(1);
        });

        document.getElementById('downBtn').addEventListener('touchstart', (e) => {
            e.preventDefault();
            this.moveDown();
        });

        document.getElementById('rotateBtn').addEventListener('touchstart', (e) => {
            e.preventDefault();
            this.rotate();
        });

        document.getElementById('dropBtn').addEventListener('touchstart', (e) => {
            e.preventDefault();
            this.hardDrop();
        });

        // 同时支持click事件(桌面端)
        document.getElementById('leftBtn').addEventListener('click', () => this.move(-1));
        document.getElementById('rightBtn').addEventListener('click', () => this.move(1));
        document.getElementById('downBtn').addEventListener('click', () => this.moveDown());
        document.getElementById('rotateBtn').addEventListener('click', () => this.rotate());
        document.getElementById('dropBtn').addEventListener('click', () => this.hardDrop());
    }

    handleKeyPress(e) {
        if (!this.gameStarted || this.gameOver || this.isPaused) return;

        switch(e.key) {
            case 'ArrowLeft':
                e.preventDefault();
                this.move(-1);
                break;
            case 'ArrowRight':
                e.preventDefault();
                this.move(1);
                break;
            case 'ArrowDown':
                e.preventDefault();
                this.moveDown();
                break;
            case 'ArrowUp':
                e.preventDefault();
                this.rotate();
                break;
            case ' ':
                e.preventDefault();
                this.hardDrop();
                break;
        }
    }

    start() {
        if (this.gameStarted) return;

        this.gameStarted = true;
        this.gameOver = false;
        this.isPaused = false;
        this.board = this.createBoard();
        this.score = 0;
        this.lines = 0;
        this.level = 1;

        this.updateSpeed();
        this.spawnPiece();
        this.updateDisplay();

        this.startBtn.disabled = true;
        this.pauseBtn.disabled = false;
        this.difficultySelect.disabled = true;
        this.gameOverEl.classList.add('hidden');

        this.lastTime = performance.now();
        this.update();
    }

    restart() {
        this.gameStarted = false;
        this.startBtn.disabled = false;
        this.pauseBtn.disabled = true;
        this.difficultySelect.disabled = false;
        this.start();
    }

    togglePause() {
        if (!this.gameStarted || this.gameOver) return;

        this.isPaused = !this.isPaused;
        this.pauseBtn.textContent = this.isPaused ? '继续' : '暂停';

        if (!this.isPaused) {
            this.lastTime = performance.now();
            this.update();
        }
    }

    updateSpeed() {
        // 基础速度根据难度和等级调整
        const baseSpeed = 1000;
        const difficultyMultiplier = [1, 0.8, 0.6, 0.4][this.difficulty - 1];
        const levelMultiplier = Math.max(0.1, 1 - (this.level - 1) * 0.1);

        this.dropInterval = baseSpeed * difficultyMultiplier * levelMultiplier;
    }

    spawnPiece() {
        const shapeIndex = Math.floor(Math.random() * (SHAPES.length - 1)) + 1;
        this.currentPiece = SHAPES[shapeIndex];
        this.currentX = Math.floor((CONFIG.COLS - this.currentPiece[0].length) / 2);
        this.currentY = 0;

        if (this.collision()) {
            this.endGame();
        }
    }

    collision(piece = this.currentPiece, x = this.currentX, y = this.currentY) {
        for (let row = 0; row < piece.length; row++) {
            for (let col = 0; col < piece[row].length; col++) {
                if (piece[row][col]) {
                    const newX = x + col;
                    const newY = y + row;

                    if (newX < 0 || newX >= CONFIG.COLS ||
                        newY >= CONFIG.ROWS ||
                        (newY >= 0 && this.board[newY][newX])) {
                        return true;
                    }
                }
            }
        }
        return false;
    }

    merge() {
        for (let row = 0; row < this.currentPiece.length; row++) {
            for (let col = 0; col < this.currentPiece[row].length; col++) {
                if (this.currentPiece[row][col]) {
                    const y = this.currentY + row;
                    const x = this.currentX + col;
                    if (y >= 0) {
                        this.board[y][x] = this.currentPiece[row][col];
                    }
                }
            }
        }

        this.clearLines();
        this.spawnPiece();
    }

    clearLines() {
        let linesCleared = 0;

        for (let row = CONFIG.ROWS - 1; row >= 0; row--) {
            if (this.board[row].every(cell => cell !== 0)) {
                this.board.splice(row, 1);
                this.board.unshift(Array(CONFIG.COLS).fill(0));
                linesCleared++;
                row++; // 检查同一行
            }
        }

        if (linesCleared > 0) {
            this.lines += linesCleared;

            // 计分：1行=100, 2行=300, 3行=500, 4行=800
            const points = [0, 100, 300, 500, 800][linesCleared] || 0;
            this.score += points * this.level;

            // 升级：每10行提升1级
            const newLevel = Math.floor(this.lines / 10) + 1;
            if (newLevel > this.level) {
                this.level = newLevel;
                this.updateSpeed();
            }

            this.updateDisplay();
        }
    }

    move(dir) {
        if (!this.gameStarted || this.gameOver || this.isPaused) return;

        this.currentX += dir;
        if (this.collision()) {
            this.currentX -= dir;
        }
        this.draw();
    }

    moveDown() {
        if (!this.gameStarted || this.gameOver || this.isPaused) return;

        this.currentY++;
        if (this.collision()) {
            this.currentY--;
            this.merge();
        } else {
            this.score += 1; // 软降加分
        }
        this.dropCounter = 0;
        this.draw();
        this.updateDisplay();
    }

    hardDrop() {
        if (!this.gameStarted || this.gameOver || this.isPaused) return;

        let dropDistance = 0;
        while (!this.collision()) {
            this.currentY++;
            dropDistance++;
        }
        this.currentY--;
        dropDistance--;

        this.score += dropDistance * 2; // 硬降加分更多
        this.merge();
        this.draw();
        this.updateDisplay();
    }

    rotate() {
        if (!this.gameStarted || this.gameOver || this.isPaused) return;

        const rotated = this.rotatePiece(this.currentPiece);
        const originalX = this.currentX;

        // 尝试基本旋转
        if (!this.collision(rotated, this.currentX, this.currentY)) {
            this.currentPiece = rotated;
        }
        // 尝试墙壁踢(wall kick)
        else {
            const kicks = [-1, 1, -2, 2];
            for (let kick of kicks) {
                this.currentX = originalX + kick;
                if (!this.collision(rotated, this.currentX, this.currentY)) {
                    this.currentPiece = rotated;
                    this.draw();
                    return;
                }
            }
            this.currentX = originalX;
        }

        this.draw();
    }

    rotatePiece(piece) {
        const rotated = [];
        const rows = piece.length;
        const cols = piece[0].length;

        for (let col = 0; col < cols; col++) {
            const newRow = [];
            for (let row = rows - 1; row >= 0; row--) {
                newRow.push(piece[row][col]);
            }
            rotated.push(newRow);
        }

        return rotated;
    }

    update(time = 0) {
        if (this.gameOver || this.isPaused) return;

        const deltaTime = time - this.lastTime;
        this.lastTime = time;
        this.dropCounter += deltaTime;

        if (this.dropCounter > this.dropInterval) {
            this.moveDown();
        }

        this.draw();
        requestAnimationFrame((t) => this.update(t));
    }

    draw() {
        // 清空画布
        this.ctx.fillStyle = '#000';
        this.ctx.fillRect(0, 0, this.canvas.width, this.canvas.height);

        // 绘制网格
        this.drawGrid();

        // 绘制已固定的方块
        this.drawBoard();

        // 绘制当前方块
        this.drawPiece();

        // 绘制幽灵方块(预览落点)
        this.drawGhost();
    }

    drawGrid() {
        this.ctx.strokeStyle = '#1a1a1a';
        this.ctx.lineWidth = 1;

        for (let row = 0; row <= CONFIG.ROWS; row++) {
            this.ctx.beginPath();
            this.ctx.moveTo(0, row * CONFIG.BLOCK_SIZE);
            this.ctx.lineTo(CONFIG.COLS * CONFIG.BLOCK_SIZE, row * CONFIG.BLOCK_SIZE);
            this.ctx.stroke();
        }

        for (let col = 0; col <= CONFIG.COLS; col++) {
            this.ctx.beginPath();
            this.ctx.moveTo(col * CONFIG.BLOCK_SIZE, 0);
            this.ctx.lineTo(col * CONFIG.BLOCK_SIZE, CONFIG.ROWS * CONFIG.BLOCK_SIZE);
            this.ctx.stroke();
        }
    }

    drawBoard() {
        for (let row = 0; row < CONFIG.ROWS; row++) {
            for (let col = 0; col < CONFIG.COLS; col++) {
                if (this.board[row][col]) {
                    this.drawBlock(col, row, this.board[row][col]);
                }
            }
        }
    }

    drawPiece() {
        if (!this.currentPiece) return;

        for (let row = 0; row < this.currentPiece.length; row++) {
            for (let col = 0; col < this.currentPiece[row].length; col++) {
                if (this.currentPiece[row][col]) {
                    this.drawBlock(
                        this.currentX + col,
                        this.currentY + row,
                        this.currentPiece[row][col]
                    );
                }
            }
        }
    }

    drawGhost() {
        if (!this.currentPiece) return;

        let ghostY = this.currentY;
        while (!this.collision(this.currentPiece, this.currentX, ghostY + 1)) {
            ghostY++;
        }

        this.ctx.globalAlpha = 0.3;
        for (let row = 0; row < this.currentPiece.length; row++) {
            for (let col = 0; col < this.currentPiece[row].length; col++) {
                if (this.currentPiece[row][col]) {
                    this.drawBlock(
                        this.currentX + col,
                        ghostY + row,
                        this.currentPiece[row][col]
                    );
                }
            }
        }
        this.ctx.globalAlpha = 1;
    }

    drawBlock(x, y, colorIndex) {
        const px = x * CONFIG.BLOCK_SIZE;
        const py = y * CONFIG.BLOCK_SIZE;

        // 主色块
        this.ctx.fillStyle = CONFIG.COLORS[colorIndex];
        this.ctx.fillRect(px + 1, py + 1, CONFIG.BLOCK_SIZE - 2, CONFIG.BLOCK_SIZE - 2);

        // 高光效果
        this.ctx.fillStyle = 'rgba(255, 255, 255, 0.3)';
        this.ctx.fillRect(px + 2, py + 2, CONFIG.BLOCK_SIZE - 8, CONFIG.BLOCK_SIZE - 8);
    }

    updateDisplay() {
        this.scoreEl.textContent = this.score;
        this.highScoreEl.textContent = this.highScore;
        this.levelEl.textContent = this.level;
        this.linesEl.textContent = this.lines;
    }

    endGame() {
        this.gameOver = true;
        this.gameStarted = false;
        this.saveHighScore();

        this.finalScoreEl.textContent = this.score;
        this.gameOverEl.classList.remove('hidden');

        this.startBtn.disabled = false;
        this.pauseBtn.disabled = true;
        this.difficultySelect.disabled = false;

        this.updateDisplay();
    }
}

// 初始化游戏
let game;
window.addEventListener('load', () => {
    game = new Game();
});
