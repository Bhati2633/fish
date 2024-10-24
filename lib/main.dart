import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(VirtualAquariumApp());
}

class VirtualAquariumApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Virtual Aquarium',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: AquariumScreen(),
    );
  }
}

class AquariumScreen extends StatefulWidget {
  @override
  _AquariumScreenState createState() => _AquariumScreenState();
}

class _AquariumScreenState extends State<AquariumScreen>
    with SingleTickerProviderStateMixin {
  List<Fish> fishList = [];
  double speed = 1.0;
  Color selectedColor = Colors.blue;
  late AnimationController _controller;
  bool enableCollision = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat();

    _controller.addListener(() {
      setState(() {
        for (var fish in fishList) {
          fish.updatePosition(speed);
          fish.reverseDirectionIfNeeded(300.0, 300.0); // Container is 300x300
          if (enableCollision) _checkForCollision();
        }
      });
    });

    loadSettings().then((settings) {
      setState(() {
        speed = settings['speed'];
        selectedColor = _colorFromString(settings['color']);
        for (int i = 0; i < settings['fishCount']; i++) {
          fishList.add(Fish(color: selectedColor, speed: speed));
        }
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addFish() {
    if (fishList.length < 10) {
      setState(() {
        fishList.add(Fish(color: selectedColor, speed: speed));
      });
    }
  }

  Widget _buildFish(Fish fish) {
    return AnimatedPositioned(
      duration: Duration(milliseconds: (2000 / fish.speed).toInt()),
      left: fish.position.dx,
      top: fish.position.dy,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: fish.color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('fishCount', fishList.length);
    await prefs.setDouble('speed', speed);
    await prefs.setString('color', _stringFromColor(selectedColor));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Settings saved!")));
  }

  Future<Map<String, dynamic>> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'fishCount': prefs.getInt('fishCount') ?? 0,
      'speed': prefs.getDouble('speed') ?? 1.0,
      'color': prefs.getString('color') ?? 'blue',
    };
  }

  void _checkForCollision() {
    for (int i = 0; i < fishList.length; i++) {
      for (int j = i + 1; j < fishList.length; j++) {
        Fish fish1 = fishList[i];
        Fish fish2 = fishList[j];

        if ((fish1.position.dx - fish2.position.dx).abs() < 20 &&
            (fish1.position.dy - fish2.position.dy).abs() < 20) {
          fish1.changeDirection();
          fish2.changeDirection();
          setState(() {
            fish1.color = _getRandomColor();
            fish2.color = _getRandomColor();
          });
        }
      }
    }
  }

  Color _getRandomColor() {
    List<Color> colors = [selectedColor, Colors.blue, Colors.red, Colors.green];
    return colors[Random().nextInt(colors.length)];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Virtual Aquarium'),
      ),
      body: Column(
        children: [
          Container(
            height: 300,
            width: 300,
            color: Colors.blue[100],
            child: Stack(
              children: fishList.map((fish) => _buildFish(fish)).toList(),
            ),
          ),
          SizedBox(height: 10),
          Slider(
            value: speed,
            min: 0.5,
            max: 5.0,
            divisions: 10,
            label: 'Speed: $speed',
            onChanged: (double value) {
              setState(() {
                speed = value;
              });
            },
          ),
          DropdownButton<Color>(
            value: selectedColor,
            items: [
              DropdownMenuItem(
                value: Colors.blue,
                child: Text('Blue'),
              ),
              DropdownMenuItem(
                value: Colors.red,
                child: Text('Red'),
              ),
              DropdownMenuItem(
                value: Colors.green,
                child: Text('Green'),
              ),
            ],
            onChanged: (Color? color) {
              setState(() {
                selectedColor = color!;
              });
            },
          ),
          ElevatedButton(
            onPressed: _addFish,
            child: Text('Add Fish'),
          ),
          ElevatedButton(
            onPressed: _saveSettings,
            child: Text('Save Settings'),
          ),
          SwitchListTile(
            title: Text("Enable Collision Detection"),
            value: enableCollision,
            onChanged: (bool value) {
              setState(() {
                enableCollision = value;
              });
            },
          ),
        ],
      ),
    );
  }

  String _stringFromColor(Color color) {
    if (color == Colors.blue) return 'blue';
    if (color == Colors.red) return 'red';
    if (color == Colors.green) return 'green';
    return 'blue';
  }

  Color _colorFromString(String color) {
    if (color == 'blue') return Colors.blue;
    if (color == 'red') return Colors.red;
    if (color == 'green') return Colors.green;
    return Colors.blue;
  }
}

class Fish {
  Color color;
  double speed;
  Offset position;
  bool isGrowing;
  late double direction; // Angle in radians

  Fish({required this.color, required this.speed})
      : position = Offset(Random().nextDouble() * 280, Random().nextDouble() * 280),
        isGrowing = true {
    direction = Random().nextDouble() * 2 * pi; // Random direction
  }

  void updatePosition(double speed) {
    position = Offset(
      position.dx + cos(direction) * speed,
      position.dy + sin(direction) * speed,
    );
  }

  void reverseDirectionIfNeeded(double width, double height) {
    if (position.dx < 0 || position.dx > width) {
      direction = pi - direction; // Reverse horizontal direction
    }
    if (position.dy < 0 || position.dy > height) {
      direction = -direction; // Reverse vertical direction
    }
  }

  void changeDirection() {
    direction = Random().nextDouble() * 2 * pi; // Random new direction
  }
}
