import 'package:flutter/material.dart';
import 'dart:math';

void main() {
  runApp(const Game4096App());
}

class Game4096App extends StatelessWidget {
  const Game4096App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '4096 Game',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const GameScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  // Game state variables
  late List<List<int>> grid;
  int score = 0;
  bool gameOver = false;
  bool gameWon = false;
  final Random random = Random();

  // Mouse movement variables
  Offset? _startPosition;
  Offset? _currentPosition;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    initializeGame();
  }

  /// Initialize the game with empty grid and spawn initial tiles
  void initializeGame() {
    grid = List.generate(4, (_) => List.filled(4, 0));
    score = 0;
    gameOver = false;
    gameWon = false;
    
    // Spawn two initial tiles
    spawnRandomTile();
    spawnRandomTile();
  }

  /// Spawn a random tile (2 or 4) in an empty cell
  void spawnRandomTile() {
    List<List<int>> emptyCells = [];
    
    // Find all empty cells
    for (int i = 0; i < 4; i++) {
      for (int j = 0; j < 4; j++) {
        if (grid[i][j] == 0) {
          emptyCells.add([i, j]);
        }
      }
    }
    
    // If there are empty cells, spawn a tile
    if (emptyCells.isNotEmpty) {
      final randomCell = emptyCells[random.nextInt(emptyCells.length)];
      final value = random.nextDouble() < 0.9 ? 2 : 4; // 90% chance for 2, 10% for 4
      grid[randomCell[0]][randomCell[1]] = value;
    }
  }

  /// Handle swipe gestures and mouse movements
  void handleSwipe(Direction direction) {
    if (gameOver) return;
    
    List<List<int>> previousGrid = grid.map((row) => List<int>.from(row)).toList();
    
    switch (direction) {
      case Direction.up:
        moveUp();
        break;
      case Direction.down:
        moveDown();
        break;
      case Direction.left:
        moveLeft();
        break;
      case Direction.right:
        moveRight();
        break;
    }
    
    // Check if the grid changed (valid move)
    if (!_gridsEqual(previousGrid, grid)) {
      spawnRandomTile();
      checkGameState();
    }
  }

  /// Handle mouse pan start
  void _onPanStart(DragStartDetails details) {
    _startPosition = details.localPosition;
    _currentPosition = details.localPosition;
    _isDragging = true;
  }

  /// Handle mouse pan update
  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;
    
    _currentPosition = details.localPosition;
    
    // Calculate the direction based on mouse movement
    if (_startPosition != null && _currentPosition != null) {
      final delta = _currentPosition! - _startPosition!;
      const threshold = 30.0; // Minimum distance to trigger a move
      
      if (delta.distance > threshold) {
        // Determine the primary direction
        if (delta.dx.abs() > delta.dy.abs()) {
          // Horizontal movement
          if (delta.dx > 0) {
            handleSwipe(Direction.right);
          } else {
            handleSwipe(Direction.left);
          }
        } else {
          // Vertical movement
          if (delta.dy > 0) {
            handleSwipe(Direction.down);
          } else {
            handleSwipe(Direction.up);
          }
        }
        
        // Reset drag state after move
        _isDragging = false;
        _startPosition = null;
        _currentPosition = null;
      }
    }
  }

  /// Handle mouse pan end
  void _onPanEnd(DragEndDetails details) {
    _isDragging = false;
    _startPosition = null;
    _currentPosition = null;
  }

  /// Move tiles up
  void moveUp() {
    for (int j = 0; j < 4; j++) {
      List<int> column = [];
      
      // Extract non-zero values from the column
      for (int i = 0; i < 4; i++) {
        if (grid[i][j] != 0) {
          column.add(grid[i][j]);
        }
      }
      
      // Merge adjacent equal values
      column = _mergeTiles(column);
      
      // Pad with zeros to make it 4 elements
      while (column.length < 4) {
        column.add(0);
      }
      
      // Update the grid
      for (int i = 0; i < 4; i++) {
        grid[i][j] = column[i];
      }
    }
  }

  /// Move tiles down
  void moveDown() {
    for (int j = 0; j < 4; j++) {
      List<int> column = [];
      
      // Extract non-zero values from the column (bottom to top)
      for (int i = 3; i >= 0; i--) {
        if (grid[i][j] != 0) {
          column.add(grid[i][j]);
        }
      }
      
      // Merge adjacent equal values
      column = _mergeTiles(column);
      
      // Pad with zeros to make it 4 elements
      while (column.length < 4) {
        column.add(0);
      }
      
      // Update the grid (reverse order)
      for (int i = 0; i < 4; i++) {
        grid[3 - i][j] = column[i];
      }
    }
  }

  /// Move tiles left
  void moveLeft() {
    for (int i = 0; i < 4; i++) {
      List<int> row = [];
      
      // Extract non-zero values from the row
      for (int j = 0; j < 4; j++) {
        if (grid[i][j] != 0) {
          row.add(grid[i][j]);
        }
      }
      
      // Merge adjacent equal values
      row = _mergeTiles(row);
      
      // Pad with zeros to make it 4 elements
      while (row.length < 4) {
        row.add(0);
      }
      
      // Update the grid
      for (int j = 0; j < 4; j++) {
        grid[i][j] = row[j];
      }
    }
  }

  /// Move tiles right
  void moveRight() {
    for (int i = 0; i < 4; i++) {
      List<int> row = [];
      
      // Extract non-zero values from the row (right to left)
      for (int j = 3; j >= 0; j--) {
        if (grid[i][j] != 0) {
          row.add(grid[i][j]);
        }
      }
      
      // Merge adjacent equal values
      row = _mergeTiles(row);
      
      // Pad with zeros to make it 4 elements
      while (row.length < 4) {
        row.add(0);
      }
      
      // Update the grid (reverse order)
      for (int j = 0; j < 4; j++) {
        grid[i][3 - j] = row[j];
      }
    }
  }

  /// Merge adjacent tiles with the same value
  List<int> _mergeTiles(List<int> tiles) {
    List<int> merged = [];
    int i = 0;
    
    while (i < tiles.length) {
      if (i < tiles.length - 1 && tiles[i] == tiles[i + 1]) {
        // Merge two equal tiles
        int mergedValue = tiles[i] * 2;
        merged.add(mergedValue);
        score += mergedValue; // Add to score
        i += 2; // Skip the next tile
      } else {
        merged.add(tiles[i]);
        i++;
      }
    }
    
    return merged;
  }

  /// Check if two grids are equal
  bool _gridsEqual(List<List<int>> grid1, List<List<int>> grid2) {
    for (int i = 0; i < 4; i++) {
      for (int j = 0; j < 4; j++) {
        if (grid1[i][j] != grid2[i][j]) {
          return false;
        }
      }
    }
    return true;
  }

  /// Check game state (win/lose conditions)
  void checkGameState() {
    // Check for win condition (4096 tile)
    for (int i = 0; i < 4; i++) {
      for (int j = 0; j < 4; j++) {
        if (grid[i][j] == 4096 && !gameWon) {
          gameWon = true;
          _showGameDialog('You Win!', 'Congratulations! You reached 4096!');
          return;
        }
      }
    }
    
    // Check for game over (no empty cells and no possible merges)
    if (!_hasEmptyCells() && !_hasPossibleMerges()) {
      gameOver = true;
      _showGameDialog('Game Over', 'No more moves available!');
    }
  }

  /// Check if there are empty cells
  bool _hasEmptyCells() {
    for (int i = 0; i < 4; i++) {
      for (int j = 0; j < 4; j++) {
        if (grid[i][j] == 0) return true;
      }
    }
    return false;
  }

  /// Check if there are possible merges
  bool _hasPossibleMerges() {
    // Check horizontal merges
    for (int i = 0; i < 4; i++) {
      for (int j = 0; j < 3; j++) {
        if (grid[i][j] == grid[i][j + 1]) return true;
      }
    }
    
    // Check vertical merges
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 4; j++) {
        if (grid[i][j] == grid[i + 1][j]) return true;
      }
    }
    
    return false;
  }

  /// Show game dialog
  void _showGameDialog(String title, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (gameOver || gameWon) {
                  initializeGame();
                }
              },
              child: const Text('New Game'),
            ),
            if (gameWon)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Continue playing
                },
                child: const Text('Continue'),
              ),
          ],
        );
      },
    );
  }

  /// Get tile color based on value
  Color getTileColor(int value) {
    switch (value) {
      case 0:
        return Colors.grey[300]!;
      case 2:
        return Colors.grey[200]!;
      case 4:
        return Colors.yellow[200]!;
      case 8:
        return Colors.orange[200]!;
      case 16:
        return Colors.red[200]!;
      case 32:
        return Colors.pink[200]!;
      case 64:
        return Colors.purple[200]!;
      case 128:
        return Colors.blue[200]!;
      case 256:
        return Colors.cyan[200]!;
      case 512:
        return Colors.teal[200]!;
      case 1024:
        return Colors.green[200]!;
      case 2048:
        return Colors.amber[200]!;
      case 4096:
        return const Color.fromARGB(255, 255, 130, 161);
      default:
        return Colors.grey[400]!;
    }
  }

  /// Get text color based on tile value
  Color getTextColor(int value) {
    return value <= 4 ? Colors.grey[700]! : Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('4096 Game'),
        backgroundColor: Colors.orange[400],
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: initializeGame,
            icon: const Icon(Icons.refresh),
            tooltip: 'New Game',
          ),
        ],
      ),
      body: GestureDetector(
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        child: Column(
          children: [
            // Score display
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.orange[400],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Score: $score',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Game grid
            Expanded(
              child: Center(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: 16,
                      itemBuilder: (context, index) {
                        int row = index ~/ 4;
                        int col = index % 4;
                        int value = grid[row][col];
                        
                        return Container(
                          decoration: BoxDecoration(
                            color: getTileColor(value),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: value != 0 ? [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ] : null,
                          ),
                          child: Center(
                            child: Text(
                              value == 0 ? '' : value.toString(),
                              style: TextStyle(
                                fontSize: value > 1000 ? 20 : 24,
                                fontWeight: FontWeight.bold,
                                color: getTextColor(value),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            
            // Instructions
            Container(
              padding: const EdgeInsets.all(16),
              child: const Text(
                'Swipe or drag with mouse to move tiles. Merge tiles with the same number to reach 4096!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Direction enum for swipe gestures
enum Direction {
  up,
  down,
  left,
  right,
}