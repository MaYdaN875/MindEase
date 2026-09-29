import 'package:flutter/material.dart';
import '../widgets/person_avatar.dart';
import '../models/psychologist.dart';
import '../services/psychologist_service.dart';
import '../theme/app_theme.dart';

class DirectoryScreen extends StatefulWidget {
  final Function(Psychologist) onSelectPsychologist;

  const DirectoryScreen({
    super.key,
    required this.onSelectPsychologist,
  });

  @override
  State<DirectoryScreen> createState() => _DirectoryScreenState();
}

class _DirectoryScreenState extends State<DirectoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final PsychologistService _psychologistService = PsychologistService();

  String _selectedCategory = 'All';
  bool _loading = true;
  String? _loadError;
  List<Psychologist> _allPsychologists = [];
  List<Psychologist> _filteredPsychologists = [];

  final List<String> _categories = [
    'All',
    'Clinical',
    'Child',
    'Anxiety',
    'Depression',
  ];

  @override
  void initState() {
    super.initState();
    _allPsychologists = [];
    _filteredPsychologists = _allPsychologists;
    _searchController.addListener(_applyFilters);
    _loadBackendPsychologists();
  }

  Future<void> _loadBackendPsychologists() async {
    setState(() { _loading = true; _loadError = null; });
    final res = await _psychologistService.getVerifiedPsychologists();
    if (!mounted) return;
    setState(() { _loading = false; _loadError = res['success'] == true ? null : 'No se pudo cargar el directorio.'; });
    if (res['success'] == true && mounted) {
      final List<dynamic> list = res['data'];
      {
        final List<Psychologist> fetched = list.map((item) {
          final user = item['user'] ?? {};
          final specialtiesList = (item['specialties'] as List<dynamic>?)
                  ?.map((s) => s['specialty']?['name']?.toString() ?? '')
                  .where((s) => s.isNotEmpty)
                  .toList() ??
              ['Psicología Clínica'];

          return Psychologist(
            id: item['id'] ?? user['id'] ?? 'doc',
            name: user['name'] ?? 'Psicólogo Verificado',
            title: item['academicBackground'] ?? 'Psicólogo Clínico',
            imageUrl: item['photoUrl'] ?? '',
            profileImageUrl: item['photoUrl'] ?? '',
            rating: (item['rating'] as num?)?.toDouble() ?? 0,
            reviewsCount: (item['reviewsCount'] as num?)?.toInt() ?? 0,
            durationMinutes: 50,
            pricePerSession: (item['consultationPrice'] as num?)?.toInt() ?? 350,
            patients: '—',
            experience: item['experience'] ?? 'No especificada',
            languages: item['languages'] ?? 'Español',
            about: item['description'] ?? 'Especialista en apoyo psicológico personalizado.',
            specialties: specialtiesList,
            reviews: [],
            isVerified: true,
          );
        }).toList();

        setState(() {
          _allPsychologists = fetched;
          _applyFilters();
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _selectCategory(String category) {
    setState(() {
      _selectedCategory = category;
    });
    _applyFilters();
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredPsychologists = _allPsychologists.where((doc) {
        // Filter by category
        bool matchesCategory = true;
        if (_selectedCategory != 'All') {
          final categoryLower = _selectedCategory.toLowerCase();
          matchesCategory = doc.specialties.any((spec) => spec.toLowerCase().contains(categoryLower)) ||
              doc.title.toLowerCase().contains(categoryLower);
        }

        // Filter by search query
        bool matchesQuery = true;
        if (query.isNotEmpty) {
          matchesQuery = doc.name.toLowerCase().contains(query) ||
              doc.title.toLowerCase().contains(query) ||
              doc.specialties.any((spec) => spec.toLowerCase().contains(query));
        }

        return matchesCategory && matchesQuery;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header / Navigation
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.psychology,
                          color: AppTheme.bgDark,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'MindSpace',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_none),
                        onPressed: () {},
                        style: IconButton.styleFrom(
                          foregroundColor: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const AccountAvatar(size: 32),
                    ],
                  ),
                ],
              ),
            ),
            
            // Search & Category Tabs Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Find a Psychologist',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Search Bar
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.cardDark : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: Row(
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(left: 12.0),
                          child: Icon(
                            Icons.search,
                            color: Colors.grey,
                            size: 20,
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            style: const TextStyle(fontSize: 15),
                            decoration: const InputDecoration(
                              hintText: 'Search by name or specialty...',
                              hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.tune),
                          color: AppTheme.primary,
                          iconSize: 20,
                          onPressed: () {
                            // Reset filters
                            setState(() {
                              _searchController.clear();
                              _selectedCategory = 'All';
                              _filteredPsychologists = _allPsychologists;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Category Tabs List
                  SizedBox(
                    height: 38,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final cat = _categories[index];
                        final isSelected = _selectedCategory == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(
                              cat,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? AppTheme.bgDark
                                    : (isDark ? AppTheme.textLight : AppTheme.textMediumLight),
                              ),
                            ),
                            selected: isSelected,
                            onSelected: (_) => _selectCategory(cat),
                            backgroundColor: isDark ? AppTheme.cardDark : Colors.white,
                            selectedColor: AppTheme.primary,
                            elevation: 0,
                            pressElevation: 0,
                            side: BorderSide(
                              color: isSelected
                                  ? AppTheme.primary
                                  : (isDark ? AppTheme.borderDark : AppTheme.borderLight),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            showCheckmark: false,
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Directory list
            Expanded(
              child: _loading ? const Center(child: CircularProgressIndicator())
                  : _loadError != null ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(_loadError!), TextButton(onPressed: _loadBackendPsychologists, child: const Text('Reintentar')),
                  ])) : _filteredPsychologists.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 48,
                            color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No se encontraron profesionales',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppTheme.textLight : AppTheme.textDark,
                            ),
                          ),
                          Text(
                            'Prueba otra búsqueda o categoría.',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      physics: const BouncingScrollPhysics(),
                      itemCount: _filteredPsychologists.length,
                      itemBuilder: (context, index) {
                        final psychologist = _filteredPsychologists[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16.0),
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.cardDark : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark ? AppTheme.borderSubtleDark : AppTheme.borderSubtleLight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.01),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: InkWell(
                            onTap: () => widget.onSelectPsychologist(psychologist),
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Image
                                  PersonAvatar(name: psychologist.name, photoUrl: psychologist.imageUrl, size: 90),
                                  const SizedBox(width: 14),
                                  
                                  // Details Column
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Header row (Name & Rating)
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    psychologist.name.split(',')[0], // Base name
                                                    style: TextStyle(
                                                      fontSize: 15,
                                                      fontWeight: FontWeight.bold,
                                                      color: isDark ? AppTheme.textLight : AppTheme.textDark,
                                                    ),
                                                  ),
                                                  Text(
                                                    psychologist.title,
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: AppTheme.primary,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: AppTheme.primary.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(
                                                    Icons.star,
                                                    color: AppTheme.primary,
                                                    size: 12,
                                                  ),
                                                  const SizedBox(width: 2),
                                                  Text(
                                                    psychologist.reviewsCount == 0 ? 'Sin calificaciones' : psychologist.rating.toStringAsFixed(1),
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.bold,
                                                      color: AppTheme.primary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        
                                        // Metadata Row (Duration, payments)
                                        Row(
                                          children: [
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.access_time,
                                                  size: 13,
                                                  color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                                                ),
                                                const SizedBox(width: 3),
                                                Text(
                                                  '${psychologist.durationMinutes} min',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(width: 16),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.payments_outlined,
                                                  size: 13,
                                                  color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                                                ),
                                                const SizedBox(width: 3),
                                                Text(
                                                  '\$${psychologist.pricePerSession}/session',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        
                                        // Actions Row
                                        Row(
                                          children: [
                                            Expanded(
                                              child: InkWell(
                                                onTap: () => widget.onSelectPsychologist(psychologist),
                                                child: Container(
                                                  alignment: Alignment.center,
                                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                                  decoration: BoxDecoration(
                                                    color: AppTheme.primary,
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: const Text(
                                                    'Book Now',
                                                    style: TextStyle(
                                                      color: AppTheme.bgDark,
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              width: 34,
                                              height: 32,
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                                                ),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: IconButton(
                                                padding: EdgeInsets.zero,
                                                icon: const Icon(Icons.chat_outlined, size: 16),
                                                color: Colors.grey,
                                                onPressed: () {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text('Starting chat with ${psychologist.name.split(',')[0]}...'),
                                                      behavior: SnackBarBehavior.floating,
                                                    ),
                                                  );
                                                },
                                              ),
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
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
