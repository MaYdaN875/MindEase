import 'package:flutter/material.dart';
import 'chat/private_chat_screen.dart';
import '../widgets/person_avatar.dart';
import '../models/psychologist.dart';
import '../services/psychologist_service.dart';
import '../theme/app_theme.dart';

class DirectoryScreen extends StatefulWidget {
  final Function(Psychologist) onSelectPsychologist;

  const DirectoryScreen({super.key, required this.onSelectPsychologist});

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
    setState(() {
      _loading = true;
      _loadError = null;
    });
    final res = await _psychologistService.getVerifiedPsychologists();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _loadError = res['success'] == true
          ? null
          : 'No se pudo cargar el directorio.';
    });
    if (res['success'] == true && mounted) {
      final List<dynamic> list = res['data'];
      {
        final List<Psychologist> fetched = list.map((item) {
          final user = item['user'] ?? {};
          final specialtiesList =
              (item['specialties'] as List<dynamic>?)
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
            pricePerSession:
                (item['consultationPrice'] as num?)?.toInt() ?? 350,
            patients: '—',
            experience: item['experience'] ?? 'No especificada',
            languages: item['languages'] ?? 'Español',
            about:
                item['description'] ??
                'Especialista en apoyo psicológico personalizado.',
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
          matchesCategory =
              doc.specialties.any(
                (spec) => spec.toLowerCase().contains(categoryLower),
              ) ||
              doc.title.toLowerCase().contains(categoryLower);
        }

        // Filter by search query
        bool matchesQuery = true;
        if (query.isNotEmpty) {
          matchesQuery =
              doc.name.toLowerCase().contains(query) ||
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth < 380 ? 12.0 : 24.0;
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1360),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.9, end: 1),
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.easeOutBack,
                            builder: (context, scale, child) =>
                                Transform.scale(scale: scale, child: child),
                            child: Image.asset(
                              'logoT.png',
                              width: 112,
                              height: 75,
                              fit: BoxFit.contain,
                              semanticLabel: 'MindEase',
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.forum_outlined),
                                tooltip: 'Mensajes',
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const PrivateChatInbox(),
                                  ),
                                ),
                                style: IconButton.styleFrom(
                                  foregroundColor: isDark
                                      ? AppTheme.textSecondaryDark
                                      : AppTheme.textSecondaryLight,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const AccountAvatar(size: 32),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        8,
                        horizontalPadding,
                        12,
                      ),
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
                          Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: isDark ? AppTheme.cardDark : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark
                                    ? AppTheme.borderDark
                                    : AppTheme.borderLight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.02),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(left: 12),
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
                                      hintText:
                                          'Search by name or specialty...',
                                      hintStyle: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 14,
                                      ),
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.tune),
                                  color: AppTheme.primary,
                                  iconSize: 20,
                                  tooltip: 'Restablecer filtros',
                                  onPressed: () {
                                    _searchController.clear();
                                    _selectCategory('All');
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            height: 38,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              itemCount: _categories.length,
                              itemBuilder: (context, index) {
                                final category = _categories[index];
                                final isSelected =
                                    _selectedCategory == category;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ChoiceChip(
                                    label: Text(
                                      category,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected
                                            ? AppTheme.bgDark
                                            : (isDark
                                                  ? AppTheme.textLight
                                                  : AppTheme.textMediumLight),
                                      ),
                                    ),
                                    selected: isSelected,
                                    onSelected: (_) =>
                                        _selectCategory(category),
                                    backgroundColor: isDark
                                        ? AppTheme.cardDark
                                        : Colors.white,
                                    selectedColor: AppTheme.primary,
                                    elevation: 0,
                                    pressElevation: 0,
                                    side: BorderSide(
                                      color: isSelected
                                          ? AppTheme.primary
                                          : (isDark
                                                ? AppTheme.borderDark
                                                : AppTheme.borderLight),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    showCheckmark: false,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _buildResults(
                        isDark: isDark,
                        availableWidth: constraints.maxWidth > 1360
                            ? 1360
                            : constraints.maxWidth,
                        horizontalPadding: horizontalPadding,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildResults({
    required bool isDark,
    required double availableWidth,
    required double horizontalPadding,
  }) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_loadError!),
            TextButton(
              onPressed: _loadBackendPsychologists,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_filteredPsychologists.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off,
              size: 48,
              color: isDark
                  ? AppTheme.textSecondaryDark
                  : AppTheme.textSecondaryLight,
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
                color: isDark
                    ? AppTheme.textSecondaryDark
                    : AppTheme.textSecondaryLight,
              ),
            ),
          ],
        ),
      );
    }

    final columns = availableWidth >= 1000
        ? 3
        : availableWidth >= 700
        ? 2
        : 1;
    final listPadding = EdgeInsets.fromLTRB(
      horizontalPadding,
      12,
      horizontalPadding,
      20,
    );

    if (columns == 1) {
      return ListView.builder(
        padding: listPadding,
        physics: const BouncingScrollPhysics(),
        itemCount: _filteredPsychologists.length,
        itemBuilder: (context, index) => _buildPsychologistCard(
          _filteredPsychologists[index],
          isDark: isDark,
        ),
      );
    }

    return GridView.builder(
      padding: listPadding,
      physics: const BouncingScrollPhysics(),
      itemCount: _filteredPsychologists.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 18,
        mainAxisSpacing: 18,
        mainAxisExtent: 270,
      ),
      itemBuilder: (context, index) =>
          _buildPsychologistCard(_filteredPsychologists[index], isDark: isDark),
    );
  }

  Widget _buildPsychologistCard(
    Psychologist psychologist, {
    required bool isDark,
  }) {
    final secondaryColor = isDark
        ? AppTheme.textSecondaryDark
        : AppTheme.textSecondaryLight;
    final specialties = psychologist.specialties.take(2).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? AppTheme.borderSubtleDark
              : AppTheme.borderSubtleLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => widget.onSelectPsychologist(psychologist),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  PersonAvatar(
                    name: psychologist.name,
                    photoUrl: psychologist.imageUrl,
                    size: 64,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          psychologist.name.split(',')[0],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppTheme.textLight
                                : AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          psychologist.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: AppTheme.primary,
                              size: 13,
                            ),
                            const SizedBox(width: 3),
                            Flexible(
                              child: Text(
                                psychologist.reviewsCount == 0
                                    ? 'Sin calificaciones'
                                    : '${psychologist.rating.toStringAsFixed(1)} (${psychologist.reviewsCount})',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (specialties.isNotEmpty)
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: specialties
                      .map(
                        (specialty) => Container(
                          constraints: const BoxConstraints(maxWidth: 180),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            specialty,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 16,
                runSpacing: 6,
                children: [
                  _buildMetadata(
                    Icons.access_time,
                    '${psychologist.durationMinutes} min',
                    secondaryColor,
                  ),
                  _buildMetadata(
                    Icons.payments_outlined,
                    '\$${psychologist.pricePerSession} / sesión',
                    secondaryColor,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: ElevatedButton(
                        onPressed: () =>
                            widget.onSelectPsychologist(psychologist),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: AppTheme.bgDark,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Agendar consulta',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: IconButton(
                      tooltip: 'Enviar mensaje',
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.chat_outlined, size: 18),
                      color: secondaryColor,
                      onPressed: () => openPreBookingChat(
                        context,
                        psychologistId: psychologist.id,
                        name: psychologist.name,
                      ),
                      style: IconButton.styleFrom(
                        side: BorderSide(
                          color: isDark
                              ? AppTheme.borderDark
                              : AppTheme.borderLight,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetadata(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(fontSize: 12, color: color)),
      ],
    );
  }
}
