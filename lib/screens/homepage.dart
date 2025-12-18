import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const List<Map<String, String>> _breadClasses = [
    {
      'name': 'Binangkal',
      'description': 'Sesame-coated fried dough balls with a nutty crunch.',
      'image': 'Bread pictures/Binangkal_(sesame_seed_doughnuts).jpg',
    },
    {
      'name': 'Pan de coco',
      'description': 'Soft bread roll filled with sweet coconut jam.',
      'image': 'Bread pictures/Pan de coco.jpg',
    },
    {
      'name': 'Garlic Bread',
      'description': 'Toasted loaf brushed with garlic butter and herbs.',
      'image': 'Bread pictures/Garlic.jpg',
    },
    {
      'name': 'Spanish Bread',
      'description': 'Rolled pastry with buttery, sugary filling inside.',
      'image': 'Bread pictures/Spanish Bread.jpg',
    },
    {
      'name': 'Toasted Siopao',
      'description': 'Baked bun with savory asado-style meat filling.',
      'image': 'Bread pictures/Toasted Soipao.jpg',
    },
    {
      'name': 'Pan De Leche',
      'description': 'Milk-enriched rolls that are soft, light, and mildly sweet.',
      'image': 'Bread pictures/Pan de leche.jpg',
    },
    {
      'name': 'Ensaymada',
      'description': 'Brioche-like bun topped with butter, sugar, and cheese.',
      'image': 'Bread pictures/ensymada.jpg',
    },
    {
      'name': 'Star Bread',
      'description': 'Star-shaped bread with jam-like filling in each point.',
      'image': 'Bread pictures/Star.jpg',
    },
    {
      'name': 'Pandesal',
      'description': 'Classic breakfast roll with a lightly sweet crumb.',
      'image': 'Bread pictures/pandesal.webp',
    },
    {
      'name': 'Loaf Bread',
      'description': 'Standard sliced loaf great for sandwiches and toast.',
      'image': 'Bread pictures/Loafbird.jpg',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: const DecorationImage(
            image: AssetImage('Bread pictures/Background.jpg'),
            fit: BoxFit.cover,
          ),
          // Warm dark overlay so text and cards stay readable on top of the photo
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.65),
              Colors.black.withOpacity(0.45),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // App Icon/Logo
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.bakery_dining,
                    size: 60,
                    color: Colors.amber,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Title
                const Text(
                  'Bread Classifier',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Identify different types of bread',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 18),
                
                // Camera Button
                _buildFeatureCard(
                  context,
                  icon: Icons.camera_alt,
                  title: 'Camera',
                  description: 'Take a photo to identify bread',
                  color: Colors.orange,
                  onTap: () {
                    Navigator.pushNamed(context, '/camera');
                  },
                ),
                const SizedBox(height: 12),
                
                // Analytics Button
                _buildFeatureCard(
                  context,
                  icon: Icons.analytics,
                  title: 'Analytics',
                  description: 'View classification statistics',
                  color: Colors.brown,
                  onTap: () {
                    Navigator.pushNamed(context, '/analytics');
                  },
                ),
                const SizedBox(height: 12),
                
                // Records Button
                _buildFeatureCard(
                  context,
                  icon: Icons.history,
                  title: 'Records',
                  description: 'View classification history',
                  color: Colors.deepOrange,
                  onTap: () {
                    Navigator.pushNamed(context, '/records');
                  },
                ),
                const SizedBox(height: 20),

                // Bread Classes Header
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Bread Classes',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const SizedBox(height: 8),
                Expanded(
                  child: _buildBreadTypesCarousel(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.95),
                color.withOpacity(0.85),
              ],
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Horizontally sliding carousel of bread classes
  Widget _buildBreadTypesCarousel() {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: _breadClasses.length,
      separatorBuilder: (_, __) => const SizedBox(width: 16),
      itemBuilder: (context, index) {
        final bread = _breadClasses[index];

        return Container(
          width: 190,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if ((bread['image'] ?? '').isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.asset(
                    bread['image']!,
                    height: 90,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                )
              else
                Container(
                  height: 90,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.bakery_dining,
                    color: Colors.amber,
                    size: 32,
                  ),
                ),
              const SizedBox(height: 10),
              Text(
                bread['name'] ?? '',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4E342E), // deep brown
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                bread['description'] ?? '',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black87,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }
}

