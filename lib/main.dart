
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]).then((_) {
    runApp(const MyApp());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Maze Runner',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        fontFamily: 'Roboto',
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
            elevation: 5,
          ),
        ),
      ),
      home: const MazeGameScreen(),
    );
  }
}

class MazeGameScreen extends StatefulWidget {
  const MazeGameScreen({Key? key}) : super(key: key);

  @override
  State<MazeGameScreen> createState() => _MazeGameScreenState();
}

class _MazeGameScreenState extends State<MazeGameScreen> with SingleTickerProviderStateMixin {
  // Maze settings - Increased size
  static const int rows = 31;  // Increased from 21
  static const int cols = 23;  // Increased from 15
  
  // Player position
  int playerRow = 1;
  int playerCol = 1;
  
  // Goal position
  late int goalRow;
  late int goalCol;
  
  // Game state
  bool gameWon = false;
  
  // Score
  int score = 0;
  
  // Animation controller for win animation
  late AnimationController _animationController;
  late Animation<double> _animation;
  
  // Maze representation: 0 = path, 1 = wall
  late List<List<int>> maze;
  
  // Random generator
  final random = Random();
  
  @override
  void initState() {
    super.initState();
    
    // Initialize animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );
    
    generateMaze();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  void generateMaze() {
    // Initialize maze with all walls
    maze = List.generate(rows, (_) => List.filled(cols, 1));
    
    // Create a DFS function to carve paths
    void dfs(int r, int c) {
      // Mark this cell as a path
      maze[r][c] = 0;
      
      // Define possible directions (up, right, down, left)
      final directions = [
        [-2, 0], [0, 2], [2, 0], [0, -2]
      ];
      
      // Shuffle directions for randomness
      directions.shuffle();
      
      // Check each direction
      for (final dir in directions) {
        final newR = r + dir[0];
        final newC = c + dir[1];
        
        // Check if the new position is valid
        if (newR > 0 && newR < rows - 1 && 
            newC > 0 && newC < cols - 1 && 
            maze[newR][newC] == 1) {
          // Carve a path by making the wall between current and new position a path
          maze[r + dir[0] ~/ 2][c + dir[1] ~/ 2] = 0;
          dfs(newR, newC);
        }
      }
    }
    
    // Start DFS from a random position
    int startR = random.nextInt(rows ~/ 2) * 2 + 1;
    int startC = random.nextInt(cols ~/ 2) * 2 + 1;
    
    dfs(startR, startC);
    
    // Set player starting position
    playerRow = 1;
    playerCol = 1;
    maze[playerRow][playerCol] = 0;
    
    // Generate random goal position
    generateNewGoal();
    
    // Ensure there's a path to the goal by connecting some walls
    for (int i = 1; i < rows - 1; i += 2) {
      for (int j = 1; j < cols - 1; j += 2) {
        if (random.nextDouble() < 0.30) { // Adjusted probability for larger maze
          final dirs = [[0, 1], [1, 0], [0, -1], [-1, 0]];
          dirs.shuffle();
          for (final dir in dirs) {
            final nr = i + dir[0];
            final nc = j + dir[1];
            if (nr > 0 && nr < rows - 1 && nc > 0 && nc < cols - 1) {
              maze[nr][nc] = 0;
              break;
            }
          }
        }
      }
    }
    
    gameWon = false;
  }
  
  void generateNewGoal() {
    // Generate random goal position that's far from the player
    do {
      goalRow = random.nextInt((rows - 3) ~/ 2) * 2 + 1;
      goalCol = random.nextInt((cols - 3) ~/ 2) * 2 + 1;
      
      // Ensure goal is far from player (at least half the maze away)
      final distance = (goalRow - playerRow).abs() + (goalCol - playerCol).abs();
      if (distance >= (rows + cols) ~/ 3) {
        break;
      }
    } while (true);
    
    maze[goalRow][goalCol] = 0;
  }
  
  void winGame() {
    setState(() {
      gameWon = true;
      score += 1;
      
      // Play animation
      _animationController.reset();
      _animationController.forward();
      
      // Delay for 1.5 seconds, then generate a new goal without resetting the maze
      Future.delayed(const Duration(milliseconds: 1500), () {
        setState(() {
          gameWon = false;
          generateNewGoal();
        });
      });
    });
  }
  
  void movePlayer(Direction direction) {
    if (gameWon) return;
    
    int newRow = playerRow;
    int newCol = playerCol;
    
    switch (direction) {
      case Direction.up:
        newRow--;
        break;
      case Direction.right:
        newCol++;
        break;
      case Direction.down:
        newRow++;
        break;
      case Direction.left:
        newCol--;
        break;
    }
    
    // Check if the new position is valid (within bounds and not a wall)
    if (newRow >= 0 && newRow < rows && 
        newCol >= 0 && newCol < cols && 
        maze[newRow][newCol] == 0) {
      setState(() {
        playerRow = newRow;
        playerCol = newCol;
        
        // Check if player reached the goal
        if (playerRow == goalRow && playerCol == goalCol) {
          winGame();
        }
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final mazeRatio = cols / rows;
    
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.indigo.shade900, Colors.indigo.shade400],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'MAZE RUNNER',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          score = 0;
                          generateMaze();
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: const Text('NEW GAME'),
                    ),
                  ],
                ),
              ),
              
              // Game status and score
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Status message
                    ScaleTransition(
                      scale: gameWon ? _animation : const AlwaysStoppedAnimation(1.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: gameWon ? Colors.green.shade700 : Colors.blue.shade700,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 5,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Text(
                          gameWon ? 'LEVEL COMPLETE! 🎉' : 'FIND THE EXIT!',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    
                    // Score display
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade800,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.emoji_events, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            'SCORE: $score',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Maze display - take max available space
              Expanded(
                child: Center(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Calculate the best size to fit the maze while maintaining aspect ratio
                      double mazeWidth, mazeHeight;
                      if (constraints.maxWidth / constraints.maxHeight > mazeRatio) {
                        // Width is the limiting factor
                        mazeHeight = constraints.maxHeight * 1;
                        mazeWidth = mazeHeight * mazeRatio;
                      } else {
                        // Height is the limiting factor
                        mazeWidth = constraints.maxWidth * 1;
                        mazeHeight = mazeWidth / mazeRatio;
                      }
                      
                      return Container(
                        width: mazeWidth,
                        height: mazeHeight,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white, width: 4),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CustomPaint(
                            painter: MazePainter(
                              maze: maze,
                              playerRow: playerRow,
                              playerCol: playerCol,
                              goalRow: goalRow,
                              goalCol: goalCol,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              
              // Controls with improved styling
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        directionButton(
                          icon: Icons.arrow_upward,
                          onPressed: () => movePlayer(Direction.up),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        directionButton(
                          icon: Icons.arrow_back,
                          onPressed: () => movePlayer(Direction.left),
                        ),
                        const SizedBox(width: 50),
                        directionButton(
                          icon: Icons.arrow_forward,
                          onPressed: () => movePlayer(Direction.right),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        directionButton(
                          icon: Icons.arrow_downward,
                          onPressed: () => movePlayer(Direction.down),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget directionButton({required IconData icon, required VoidCallback onPressed}) {
    return Container(
      margin: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.cyan.shade700,
          foregroundColor: Colors.white,
          shape: const CircleBorder(),
          padding: const EdgeInsets.all(20),
          elevation: 0,
        ),
        child: Icon(icon, size: 30),
      ),
    );
  }
}

class MazePainter extends CustomPainter {
  final List<List<int>> maze;
  final int playerRow;
  final int playerCol;
  final int goalRow;
  final int goalCol;
  
  MazePainter({
    required this.maze,
    required this.playerRow,
    required this.playerCol,
    required this.goalRow,
    required this.goalCol,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final rows = maze.length;
    final cols = maze[0].length;
    final cellWidth = size.width / cols;
    final cellHeight = size.height / rows;
    
    // Draw maze with enhanced visuals
    Paint wallPaint = Paint()..color = const Color(0xFF1A237E); // Dark indigo walls
    Paint wallDetailPaint = Paint()
      ..color = const Color(0xFF3949AB) // Lighter indigo for wall details
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    Paint pathPaint = Paint()..color = const Color(0xFFE8EAF6); // Light indigo paths
    
    // Add a subtle background texture
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFFE8EAF6)
    );
    
    // Draw maze cells
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final cellRect = Rect.fromLTWH(
          c * cellWidth,
          r * cellHeight,
          cellWidth,
          cellHeight,
        );
        
        if (maze[r][c] == 1) {
          // Draw wall with enhanced visuals
          canvas.drawRect(cellRect, wallPaint);
          
          // Add brick pattern with a more subtle look
          // For larger mazes, simplify the wall details to improve performance
          if (cellWidth > 10 && cellHeight > 10) {
            for (int i = 1; i < 3; i++) {
              canvas.drawLine(
                Offset(c * cellWidth, r * cellHeight + i * cellHeight / 3),
                Offset((c + 1) * cellWidth, r * cellHeight + i * cellHeight / 3),
                wallDetailPaint,
              );
            }
            
            for (int i = 1; i < 3; i++) {
              canvas.drawLine(
                Offset(c * cellWidth + i * cellWidth / 3, r * cellHeight),
                Offset(c * cellWidth + i * cellWidth / 3, (r + 1) * cellHeight),
                wallDetailPaint,
              );
            }
          }
        } else {
          // Draw path
          canvas.drawRect(cellRect, pathPaint);
          
          // Add subtle grid lines to the path
          Paint gridPaint = Paint()
            ..color = const Color(0xFFD1D9FF)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.5;
          
          canvas.drawRect(cellRect, gridPaint);
        }
        
        // Draw goal with enhanced visuals
        if (r == goalRow && c == goalCol) {
          final goalPaint = Paint()..color = Colors.green.shade600;
          canvas.drawRect(cellRect, goalPaint);
          
          // Draw star pattern for goal
          final centerX = c * cellWidth + cellWidth / 2;
          final centerY = r * cellHeight + cellHeight / 2;
          final radius = min(cellWidth, cellHeight) * 0.35;
          
          final starPaint = Paint()
            ..color = Colors.yellow
            ..style = PaintingStyle.fill;
          
          final path = Path();
          final points = 5;
          final innerRadius = radius * 0.4;
          
          for (int i = 0; i < points * 2; i++) {
            final currentRadius = i.isEven ? radius : innerRadius;
            final angle = i * pi / points;
            final x = centerX + cos(angle) * currentRadius;
            final y = centerY + sin(angle) * currentRadius;
            
            if (i == 0) {
              path.moveTo(x, y);
            } else {
              path.lineTo(x, y);
            }
          }
          path.close();
          canvas.drawPath(path, starPaint);
        }
        
        // Draw player with enhanced visuals
        if (r == playerRow && c == playerCol) {
          final centerX = c * cellWidth + cellWidth / 2;
          final centerY = r * cellHeight + cellHeight / 2;
          final radius = min(cellWidth, cellHeight) * 0.6;
          
          // Draw player body
          final playerPaint = Paint()..color = Colors.blue.shade600;
          canvas.drawCircle(Offset(centerX, centerY), radius, playerPaint);
          
          // For smaller cells, simplify the player details
          if (cellWidth > 8 && cellHeight > 8) {
            // Draw player face details
            final eyePaint = Paint()..color = Colors.white;
            canvas.drawCircle(
              Offset(centerX - radius * 0.3, centerY - radius * 0.1),
              radius * 0.15,
              eyePaint,
            );
            canvas.drawCircle(
              Offset(centerX + radius * 0.3, centerY - radius * 0.1),
              radius * 0.15,
              eyePaint,
            );
            
            // Draw pupil
            final pupilPaint = Paint()..color = Colors.black;
            canvas.drawCircle(
              Offset(centerX - radius * 0.3, centerY - radius * 0.1),
              radius * 0.07,
              pupilPaint,
            );
            canvas.drawCircle(
              Offset(centerX + radius * 0.3, centerY - radius * 0.1),
              radius * 0.07,
              pupilPaint,
            );
            
            // Draw smile
            final smilePaint = Paint()
              ..color = Colors.white
              ..style = PaintingStyle.stroke
              ..strokeWidth = radius * 0.1;
            
            final smilePath = Path();
            smilePath.moveTo(centerX - radius * 0.3, centerY + radius * 0.2);
            smilePath.quadraticBezierTo(
              centerX, centerY + radius * 0.5,
              centerX + radius * 0.3, centerY + radius * 0.2
            );
            canvas.drawPath(smilePath, smilePaint);
          }
        }
      }
    }
  }
  
  @override
  bool shouldRepaint(MazePainter oldDelegate) {
    return oldDelegate.playerRow != playerRow ||
           oldDelegate.playerCol != playerCol ||
           oldDelegate.maze != maze;
  }
}

enum Direction {
  up,
  right,
  down,
  left,
}