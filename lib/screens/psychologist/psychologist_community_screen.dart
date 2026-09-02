import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class PsychologistCommunityScreen extends StatefulWidget {
  final VoidCallback onOpenNotifications;
  final VoidCallback onToggleTheme;
  final bool isDarkMode;

  const PsychologistCommunityScreen({
    super.key,
    required this.onOpenNotifications,
    required this.onToggleTheme,
    required this.isDarkMode,
  });

  @override
  State<PsychologistCommunityScreen> createState() => _PsychologistCommunityScreenState();
}

class _PsychologistCommunityScreenState extends State<PsychologistCommunityScreen> {
  final List<Map<String, dynamic>> _channels = [
    {
      'title': 'Entendiendo la ansiedad',
      'followers': '1,240 seguidores',
      'posts': '18 publicaciones',
      'image':
          'https://lh3.googleusercontent.com/aida-public/AB6AXuCSxpOj5-tXLhR2Mkyk8YSQMAJrZQulzKY6rwS9sOUgyhaGezNM3Rme2VYASww_XWOrv8kMS1I-v7afPsmFwsmoRN21V8TNisNdUiRwwneB0ifU3Ym806QUAvic8yFS-BDkN8ydMHSWpsHVudUCAaht2wE8CMoKFTJG7cqShVK8ie5IUaioW3v5pFI0ZSYYxDbJKSoBwhmDsqOpuojXHkc2N-R99nnqN4TQScwQcsyAaE7Kmm-wgikN9Q',
      'status': 'Activo',
    },
    {
      'title': 'Mindfulness Diario',
      'followers': '850 seguidores',
      'posts': '12 publicaciones',
      'image':
          'https://lh3.googleusercontent.com/aida-public/AB6AXuByBQ104VbtAqPlalSJyR3RMirA7YJPr51takYQogIBOOKUNXxrBGKGFDBbi7mmBpxoihkPquHogrIcRdhaE03lQfbzxI26UPfcFoUlrrPzrUaSjbp9TV9KjQ67CMsNVi24RQ3vthej2LAWterB1-WiRuMa43aD0pHQNC-_TeArsfFLB-hMjjOVDXKxMwmEdOTMrXCxejyPpEPguxV42oSsCGSnn9PWMPdKy-UsNq3HCALxOBWn05ZOZA',
      'status': 'Activo',
    },
  ];

  void _showCreateChannelModal() {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    String category = 'Ansiedad';
    List<String> selectedChips = ['Psicología Clínica'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.cardDark : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Crear Canal',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Cover upload placeholder
                    Container(
                      height: 140,
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.bgDark : AppTheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.borderLight, style: BorderStyle.solid),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate, size: 36, color: AppTheme.primary),
                          SizedBox(height: 6),
                          Text('Toca para subir imagen de portada', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Inputs
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Nombre del canal',
                        hintText: 'Ej. Meditación Matutina',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Descripción',
                        hintText: 'Describe el propósito de este canal...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: category,
                      decoration: InputDecoration(
                        labelText: 'Categoría',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: ['Ansiedad', 'Depresión', 'Mindfulness', 'Productividad']
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (v) => setModalState(() => category = v!),
                    ),
                    const SizedBox(height: 16),

                    const Text('Especialidad relacionada', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: ['Psicología Clínica', 'Psiquiatría', 'Terapia Cognitiva'].map((chip) {
                        final isSelected = selectedChips.contains(chip);
                        return FilterChip(
                          label: Text(chip),
                          selected: isSelected,
                          selectedColor: AppTheme.primary.withValues(alpha: 0.2),
                          onSelected: (val) {
                            setModalState(() {
                              if (val) {
                                selectedChips.add(chip);
                              } else {
                                selectedChips.remove(chip);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    ElevatedButton.icon(
                      onPressed: () {
                        if (nameController.text.trim().isNotEmpty) {
                          setState(() {
                            _channels.add({
                              'title': nameController.text.trim(),
                              'followers': '0 seguidores',
                              'posts': '0 publicaciones',
                              'image':
                                  'https://lh3.googleusercontent.com/aida-public/AB6AXuCSxpOj5-tXLhR2Mkyk8YSQMAJrZQulzKY6rwS9sOUgyhaGezNM3Rme2VYASww_XWOrv8kMS1I-v7afPsmFwsmoRN21V8TNisNdUiRwwneB0ifU3Ym806QUAvic8yFS-BDkN8ydMHSWpsHVudUCAaht2wE8CMoKFTJG7cqShVK8ie5IUaioW3v5pFI0ZSYYxDbJKSoBwhmDsqOpuojXHkc2N-R99nnqN4TQScwQcsyAaE7Kmm-wgikN9Q',
                              'status': 'Activo',
                            });
                          });
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Canal creado exitosamente.'),
                              backgroundColor: AppTheme.primaryDark,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.add_circle),
                      label: const Text('Crear canal', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: AppTheme.textDark,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showCreatePostModal() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    String canal = 'Community';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.cardDark : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Crear Publicación Educativa', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: canal,
                  decoration: InputDecoration(
                    labelText: 'Canal',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: ['Community', 'Recursos para Pacientes', 'Blog Profesional']
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => canal = v!,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Título',
                    hintText: 'Ej. Técnicas de respiración para la ansiedad',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contentController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    labelText: 'Cuerpo de contenido',
                    hintText: 'Escribe tu contenido educativo aquí...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),

                // Attachments row
                Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.image, size: 16),
                      label: const Text('Imagen', style: TextStyle(fontSize: 11)),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.movie, size: 16),
                      label: const Text('Video', style: TextStyle(fontSize: 11)),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.picture_as_pdf, size: 16),
                      label: const Text('PDF', style: TextStyle(fontSize: 11)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.tertiaryContainer.withValues(alpha: 0.15),
                    border: const Border(left: BorderSide(color: AppTheme.tertiaryFixedDim, width: 4)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'El contenido publicado debe ser educativo y no sustituye una evaluación psicológica profesional.',
                    style: TextStyle(fontSize: 12, color: AppTheme.onTertiaryContainer),
                  ),
                ),
                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Publicación creada y enviada a la comunidad.'),
                        backgroundColor: AppTheme.primaryDark,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: AppTheme.textDark,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Publicar', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Profesional'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(widget.isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
            onPressed: widget.onToggleTheme,
            tooltip: 'Cambiar tema',
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none_outlined),
            onPressed: widget.onOpenNotifications,
            tooltip: 'Notificaciones',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header & Action Area
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mis Canales',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppTheme.textLight : AppTheme.textDark,
                        ),
                      ),
                      Text(
                        'Canales de difusión educativa para la comunidad.',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton.filled(
                        icon: const Icon(Icons.post_add),
                        onPressed: _showCreatePostModal,
                        style: IconButton.styleFrom(
                          backgroundColor: AppTheme.secondaryContainer,
                          foregroundColor: AppTheme.onSecondaryContainer,
                        ),
                        tooltip: 'Crear publicación',
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        icon: const Icon(Icons.add),
                        onPressed: _showCreateChannelModal,
                        style: IconButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: AppTheme.textDark,
                        ),
                        tooltip: 'Crear canal',
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Channels List
              ..._channels.map((channel) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.cardDark : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Banner Image with overlay
                      Container(
                        height: 120,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          image: DecorationImage(
                            image: NetworkImage(channel['image']),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.75)],
                                ),
                              ),
                            ),
                            Positioned(
                              top: 10,
                              right: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  channel['status'],
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 10,
                              left: 12,
                              right: 12,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    channel['title'],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      const Icon(Icons.group, color: Colors.white70, size: 12),
                                      const SizedBox(width: 4),
                                      Text(channel['followers'], style: const TextStyle(color: Colors.white70, fontSize: 11)),
                                      const SizedBox(width: 12),
                                      const Icon(Icons.article, color: Colors.white70, size: 12),
                                      const SizedBox(width: 4),
                                      Text(channel['posts'], style: const TextStyle(color: Colors.white70, fontSize: 11)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Card Actions
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Visualizando publicaciones de "${channel['title']}"'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                              icon: const Icon(Icons.visibility_outlined, size: 16, color: AppTheme.primary),
                              label: const Text('Ver publicaciones', style: TextStyle(color: AppTheme.primary, fontSize: 12)),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Editando "${channel['title']}"'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                              icon: const Icon(Icons.edit_outlined, size: 16, color: Colors.grey),
                              label: Text(
                                'Editar canal',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
