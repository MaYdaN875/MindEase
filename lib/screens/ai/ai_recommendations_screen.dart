import 'package:flutter/material.dart';
import '../../models/ai_orientation.dart';
import '../../models/psychologist.dart';
import '../../theme/app_theme.dart';
import '../profile_screen.dart';

class AIRecommendationsScreen extends StatelessWidget {
  final Map<String, dynamic> recommendationsData;
  final VoidCallback onFinish;

  const AIRecommendationsScreen({
    super.key,
    required this.recommendationsData,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final List<dynamic> rawSpecs =
        recommendationsData['suggestedSpecialties'] as List<dynamic>? ?? [];
    final specialties =
        rawSpecs.map((s) => SuggestedSpecialty.fromJson(s as Map<String, dynamic>)).toList();

    final List<dynamic> rawPsychs =
        recommendationsData['recommendedPsychologists'] as List<dynamic>? ?? [];
    final psychologists = rawPsychs
        .map((p) => RecommendedPsychologistItem.fromJson(p as Map<String, dynamic>))
        .toList();

    final summary = recommendationsData['summary']?.toString();

    return Scaffold(
      backgroundColor: isDark ? AppTheme.bgDark : AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('Resultados de Orientación'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: onFinish,
            child: const Text('Listo', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner No Diagnóstico (Obligatorio)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.25)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.verified_user_outlined, color: Colors.blue, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Esta orientación no constituye un diagnóstico clínico. Su propósito es sugerir áreas de especialidad y profesionales verificados para acompañar tu proceso.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white70 : Colors.black87,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Resumen de la orientación
            if (summary != null && summary.isNotEmpty) ...[
              Text(
                'Resumen de tu consulta',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppTheme.textLight : AppTheme.textDark,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                summary,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Especialidades recomendadas
            if (specialties.isNotEmpty) ...[
              Text(
                'Especialidades sugeridas para ti',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppTheme.textLight : AppTheme.textDark,
                    ),
              ),
              const SizedBox(height: 10),
              ...specialties.map(
                (spec) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.cardDark : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.psychology_outlined,
                              color: AppTheme.primary, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              spec.name,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppTheme.textLight : AppTheme.textDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        spec.reason,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? AppTheme.textSecondaryDark
                              : AppTheme.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Profesionales sugeridos (solo verificados y reales)
            Text(
              'Psicólogos verificados afines',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppTheme.textLight : AppTheme.textDark,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'Seleccionados con base en sus especialidades acreditadas y disponibilidad.',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 12),

            if (psychologists.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.cardDark : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text('No hay profesionales disponibles en este momento.'),
                ),
              )
            else
              ...psychologists.map((psychItem) {
                return _buildPsychologistCard(context, psychItem, isDark);
              }),

            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: onFinish,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: AppTheme.textDark,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Finalizar orientación',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPsychologistCard(
    BuildContext context,
    RecommendedPsychologistItem psychItem,
    bool isDark,
  ) {
    // Mapear a objeto Psychologist existente para poder navegar a ProfileScreen
    final psychObj = Psychologist(
      id: psychItem.id,
      name: psychItem.name,
      title: psychItem.academicBackground ?? 'Psicólogo Clínico Verificado',
      imageUrl: psychItem.photoUrl ??
          'https://lh3.googleusercontent.com/aida-public/AB6AXuBVs8tIfuOwuiiM-Jm-RNLgqdr8y0XfiRuGHeVo2ftxGEBO3ELLyb399uhfqzzNCY6cFQbCw6_XflUCBZQxmXV9XUuQuFlNJRv4G930tsKTwqHY9YhTaBxMCgjwlpZnX0vn3JxLr0W8eRACOBZZCnyM9qyHdeZ4hrKp38VF7ezCzcfqITwxmviFLDSnDMDfaXPu_cMZ7EQYa5r1TDfPPLjGUN8wcewpo7vnMM-EuiyfrvReGwfyR-AWmw',
      profileImageUrl: psychItem.photoUrl ??
          'https://lh3.googleusercontent.com/aida-public/AB6AXuBVs8tIfuOwuiiM-Jm-RNLgqdr8y0XfiRuGHeVo2ftxGEBO3ELLyb399uhfqzzNCY6cFQbCw6_XflUCBZQxmXV9XUuQuFlNJRv4G930tsKTwqHY9YhTaBxMCgjwlpZnX0vn3JxLr0W8eRACOBZZCnyM9qyHdeZ4hrKp38VF7ezCzcfqITwxmviFLDSnDMDfaXPu_cMZ7EQYa5r1TDfPPLjGUN8wcewpo7vnMM-EuiyfrvReGwfyR-AWmw',
      rating: 5.0,
      reviewsCount: 18,
      durationMinutes: 50,
      pricePerSession: psychItem.consultationPrice,
      patients: '100+',
      experience: '5+ años',
      languages: 'Español',
      about: 'Especialista verificado en MindEase enfocado en brindar acompañamiento profesional.',
      specialties: psychItem.specialties,
      reviews: [],
      isVerified: true,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundImage: NetworkImage(psychObj.imageUrl),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            psychItem.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppTheme.textLight : AppTheme.textDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.verified, color: AppTheme.primary, size: 16),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      psychObj.title,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? AppTheme.textSecondaryDark
                            : AppTheme.textSecondaryLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${psychItem.consultationPrice} MXN / sesión',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (psychItem.matchReasons.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: psychItem.matchReasons.map((reason) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    reason,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppTheme.primary : Colors.teal.shade800,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 38,
            child: OutlinedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ProfileScreen(
                      psychologist: psychObj,
                      onBack: () => Navigator.of(context).pop(),
                    ),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppTheme.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Ver perfil y agendar'),
            ),
          ),
        ],
      ),
    );
  }
}
