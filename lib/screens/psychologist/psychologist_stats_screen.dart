import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class PsychologistStatsScreen extends StatefulWidget {
  const PsychologistStatsScreen({super.key});

  @override
  State<PsychologistStatsScreen> createState() => _PsychologistStatsScreenState();
}

class _PsychologistStatsScreenState extends State<PsychologistStatsScreen> {
  String _filter = 'Mes';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Estadísticas de Impacto'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header and Filter
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Estadísticas',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppTheme.textLight : AppTheme.textDark,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.cardDark : AppTheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: ['Semana', 'Mes', 'Año'].map((f) {
                        final isSel = _filter == f;
                        return GestureDetector(
                          onTap: () => setState(() => _filter = f),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isSel ? (isDark ? AppTheme.borderDark : Colors.white) : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              f,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                color: isSel ? AppTheme.primary : Colors.grey,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Main Followers KPI (Hero Card)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.cardDark : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: const Border(left: BorderSide(color: AppTheme.primary, width: 4)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Seguidores Totales', style: TextStyle(fontSize: 13, color: Colors.grey)),
                        Icon(Icons.group, color: AppTheme.primary, size: 20),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Text(
                          '12,450',
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.arrow_upward, size: 12, color: AppTheme.onSecondaryContainer),
                              SizedBox(width: 2),
                              Text('+128 este mes', style: TextStyle(fontSize: 10, color: AppTheme.onSecondaryContainer, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Sparkline Bars
                    SizedBox(
                      height: 40,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [0.3, 0.45, 0.4, 0.6, 0.55, 0.8, 1.0].map((val) {
                          return Expanded(
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              height: 40 * val,
                              decoration: BoxDecoration(
                                color: val == 1.0 ? AppTheme.primary : AppTheme.primary.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // KPI Row
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.cardDark : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.visibility, size: 16, color: AppTheme.primary),
                              SizedBox(width: 6),
                              Text('Visualizaciones', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                          SizedBox(height: 6),
                          Text('4,821', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          Text('vs 4,200 (Mes ant.)', style: TextStyle(fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.cardDark : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.post_add, size: 16, color: AppTheme.secondary),
                              SizedBox(width: 6),
                              Text('Publicaciones', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                          SizedBox(height: 6),
                          Text('8', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          Text('Objetivo cumplido', style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Top Content
              const Text('Contenido con mayor impacto', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildTopContentItem(
                rank: '#1',
                title: '5 Tips para la Ansiedad Diaria',
                views: '1.2k',
                likes: '345',
                shares: '42',
                imageUrl:
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuBgPu0v2wu-QsvdfcmcPt0o06ZJmAgodbhI1wweeP8S5Br0RilccnN1sfclNVZmV6OApu_ljUAgqICITvXJNsQItQIs5Mqki5kZ7Zh1BMSGpAvmbPho_dNIpjw4kni-QZntvQlcZ0x08kh5cuFWSnWanRKWIz69j-VDIeKfawLsZS3-k8ouBhYvUJFt61jlXPk2YsOYQ5lq5H8wnlovbnS02hSTsVKM9csoevdnuCwL4GHnbFEaHzZvrw',
                isDark: isDark,
              ),
              const SizedBox(height: 10),
              _buildTopContentItem(
                rank: '#2',
                title: 'Beneficios de la Meditación Matutina',
                views: '980',
                likes: '210',
                shares: '18',
                imageUrl:
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuDyQVvetbteP6Y1tWXb3MrnwJe6l_of5v_BFC9M8Bk5B_qVIGmx_uI1G7LSMsHuXaUqNzq4ByX4yLJyOENLicsvPyHkBpC5YBnpfN84dDmJwT1CBIK6CunMgYxLsFZegZN2o6pwS968aQ4xBTDPpr1SepsKBnQY_cYkAbOAczWV01HJ_pZMsC0V-DFH6jNmTPukxfVd0sfoTK9atzYx09uCub4c6V2g3HbAc6AtGMaxoNy_7DEMbgRHTg',
                isDark: isDark,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopContentItem({
    required String rank,
    required String title,
    required String views,
    required String likes,
    required String shares,
    required String imageUrl,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              image: DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover),
            ),
            child: Stack(
              children: [
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4)),
                    child: Text(rank, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.visibility, size: 12, color: Colors.grey),
                    const SizedBox(width: 2),
                    Text(views, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    const SizedBox(width: 10),
                    const Icon(Icons.favorite, size: 12, color: Colors.grey),
                    const SizedBox(width: 2),
                    Text(likes, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    const SizedBox(width: 10),
                    const Icon(Icons.share, size: 12, color: Colors.grey),
                    const SizedBox(width: 2),
                    Text(shares, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
