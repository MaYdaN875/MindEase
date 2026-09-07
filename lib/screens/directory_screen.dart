import 'package:flutter/material.dart';
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
    _allPsychologists = Psychologist.list;
    _filteredPsychologists = _allPsychologists;
    _searchController.addListener(_applyFilters);
    _loadBackendPsychologists();
  }

  Future<void> _loadBackendPsychologists() async {
    final res = await _psychologistService.getVerifiedPsychologists();
    if (res['success'] == true && mounted) {
      final List<dynamic> list = res['data'];
      if (list.isNotEmpty) {
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
            imageUrl: item['photoUrl'] ??
                'https://lh3.googleusercontent.com/aida-public/AB6AXuBVs8tIfuOwuiiM-Jm-RNLgqdr8y0XfiRuGHeVo2ftxGEBO3ELLyb399uhfqzzNCY6cFQbCw6_XflUCBZQxmXV9XUuQuFlNJRv4G930tsKTwqHY9YhTaBxMCgjwlpZnX0vn3JxLr0W8eRACOBZZCnyM9qyHdeZ4hrKp38VF7ezCzcfqITwxmviFLDSnDMDfaXPu_cMZ7EQYa5r1TDfPPLjGUN8wcewpo7vnMM-EuiyfrvReGwfyR-AWmw',
            profileImageUrl: item['photoUrl'] ??
                'https://lh3.googleusercontent.com/aida-public/AB6AXuBVs8tIfuOwuiiM-Jm-RNLgqdr8y0XfiRuGHeVo2ftxGEBO3ELLyb399uhfqzzNCY6cFQbCw6_XflUCBZQxmXV9XUuQuFlNJRv4G930tsKTwqHY9YhTaBxMCgjwlpZnX0vn3JxLr0W8eRACOBZZCnyM9qyHdeZ4hrKp38VF7ezCzcfqITwxmviFLDSnDMDfaXPu_cMZ7EQYa5r1TDfPPLjGUN8wcewpo7vnMM-EuiyfrvReGwfyR-AWmw',
            rating: 5.0,
            reviewsCount: 24,
            durationMinutes: 50,
            pricePerSession: (item['consultationPrice'] as num?)?.toInt() ?? 350,
            patients: '150+',
            experience: item['experience'] ?? '5 años',
            languages: item['languages'] ?? 'Español',
            about: item['description'] ?? 'Especialista en apoyo psicológico personalizado.',
            specialties: specialtiesList,
            reviews: [],
            isVerified: true,
          );
        }).toList();

        setState(() {
          // Merge backend psychologists at top
          _allPsychologists = [...fetched, ...Psychologist.list];
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
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
                          image: const DecorationImage(
                            image: NetworkImage(
                              'https://lh3.googleusercontent.com/aida-public/AB6AXuCX79pv4KMKWyo9hVfl29b87SbikPmbrNFq9g5Or7dhvrwwOa9PAeYmdNu_XM7qT_byEDcwpi2dphfdZAXlLKT3cw5w5Zgek7Jp6JOG_FnFmO4HvYpfd2CM4_U2K9jn4EB7a0sDUwiOcCtLiHmNJlU2OU88QZgRSPv6BgT52GFQekokXI_gT8fBymh1k8F8da6HQ4bU3zGzR9sGrsxjeisg3lHLq2lGODbnCXNmnno_eKH-1vBlqVth65x2BJNcfj-Ej84CrEqx1nYy',
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
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
              child: _filteredPsychologists.isEmpty
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
                            'No specialists found',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppTheme.textLight : AppTheme.textDark,
                            ),
                          ),
                          Text(
                            'Try modifying your search or filters.',
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
                                  Container(
                                    width: 90,
                                    height: 90,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      image: DecorationImage(
                                        image: NetworkImage(psychologist.imageUrl),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
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
                                                    psychologist.rating.toString(),
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
