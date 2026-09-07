import 'package:flutter/material.dart';
import '../models/psychologist.dart';
import '../theme/app_theme.dart';
import 'appointment_booking_sheet.dart';

class ProfileScreen extends StatefulWidget {
  final Psychologist psychologist;
  final VoidCallback onBack;

  const ProfileScreen({
    super.key,
    required this.psychologist,
    required this.onBack,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _selectedDateIndex = 0;
  String _selectedTime = '09:00 AM';

  final List<Map<String, String>> _dates = [
    {'day': 'MON', 'num': '12'},
    {'day': 'TUE', 'num': '13'},
    {'day': 'WED', 'num': '14'},
    {'day': 'THU', 'num': '15'},
    {'day': 'FRI', 'num': '16'},
    {'day': 'SAT', 'num': '17'},
  ];

  final List<String> _times = [
    '09:00 AM',
    '10:30 AM',
    '02:00 PM',
  ];

  void _showBookingConfirmation() {
    AppointmentBookingSheet.show(context, widget.psychologist);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final doc = widget.psychologist;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
        title: const Text('Psychologist Profile'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Shared ${doc.name.split(',')[0]}\'s profile!'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // Scrollable Body
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 100), // Padded for sticky footer
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Profile Header
                Container(
                  color: isDark ? AppTheme.cardDark.withOpacity(0.3) : Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Column(
                    children: [
                      // Avatar with verified badge
                      Stack(
                        children: [
                          Container(
                            width: 128,
                            height: 128,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppTheme.primary.withOpacity(0.2),
                                width: 4,
                              ),
                              image: DecorationImage(
                                image: NetworkImage(doc.profileImageUrl),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 2,
                            right: 2,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppTheme.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDark ? AppTheme.bgDark : Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.verified,
                                color: AppTheme.bgDark,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Name & Title
                      Text(
                        doc.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${doc.title} • ${doc.experience} exp.',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppTheme.textSecondaryDark : AppTheme.textMediumLight,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Rating summary
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            doc.rating.toString(),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '(${doc.reviewsCount} reviews)',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      // Row buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _showBookingConfirmation,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                foregroundColor: AppTheme.bgDark,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Book a Session',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          InkWell(
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Chatting with ${doc.name.split(',')[0]}...'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              width: 56,
                              height: 48,
                              decoration: BoxDecoration(
                                color: isDark ? AppTheme.cardDark : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.chat_bubble_outline,
                                color: isDark ? AppTheme.textLight : AppTheme.textDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Quick Stats Row
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      _buildStatCard('Patients', doc.patients, isDark),
                      const SizedBox(width: 12),
                      _buildStatCard('Experience', doc.experience, isDark),
                      const SizedBox(width: 12),
                      _buildStatCard('Languages', doc.languages, isDark),
                    ],
                  ),
                ),
                
                // About Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'About Me',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        doc.about,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: isDark ? AppTheme.textSecondaryDark : AppTheme.textMediumLight,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Specialties Wrap
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Specialties',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: doc.specialties.map((spec) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppTheme.primary.withOpacity(0.2),
                              ),
                            ),
                            child: Text(
                              spec,
                              style: const TextStyle(
                                color: AppTheme.primary,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                
                // Availability Selector
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Availability',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontSize: 18,
                            ),
                          ),
                          TextButton(
                            onPressed: () {},
                            child: const Text(
                              'View Full Calendar',
                              style: TextStyle(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      // Horizontal Dates scroll
                      SizedBox(
                        height: 70,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: _dates.length,
                          itemBuilder: (context, index) {
                            final date = _dates[index];
                            final isSelected = _selectedDateIndex == index;
                            
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedDateIndex = index;
                                });
                              },
                              child: Container(
                                width: 68,
                                margin: const EdgeInsets.only(right: 10),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppTheme.primary
                                      : (isDark ? AppTheme.cardDark : Colors.white),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppTheme.primary
                                        : (isDark ? AppTheme.borderDark : AppTheme.borderLight),
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      date['day']!,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected
                                            ? AppTheme.bgDark
                                            : (isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      date['num']!,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected ? AppTheme.bgDark : null,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Times Grid
                      Row(
                        children: _times.map((time) {
                          final isSelected = _selectedTime == time;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4.0),
                              child: OutlinedButton(
                                onPressed: () {
                                  setState(() {
                                    _selectedTime = time;
                                  });
                                },
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: isSelected
                                      ? AppTheme.primary.withOpacity(0.15)
                                      : (isDark ? AppTheme.cardDark : const Color(0xFFF1F5F9)),
                                  foregroundColor: isSelected ? AppTheme.primary : null,
                                  side: BorderSide(
                                    color: isSelected ? AppTheme.primary : Colors.transparent,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: Text(
                                  time,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? AppTheme.primary
                                        : (isDark ? AppTheme.textMediumDark : AppTheme.textMediumLight),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                
                // Reviews Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Reviews',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontSize: 18,
                            ),
                          ),
                          TextButton(
                            onPressed: () {},
                            child: const Text(
                              'See All',
                              style: TextStyle(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      
                      // Reviews Lists
                      Column(
                        children: doc.reviews.map((review) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark ? AppTheme.cardDark : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark ? AppTheme.borderSubtleDark : AppTheme.borderSubtleLight,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        // Initials Circle
                                        Container(
                                          width: 36,
                                          height: 36,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: AppTheme.primary.withOpacity(0.2),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Text(
                                            review.initials,
                                            style: const TextStyle(
                                              color: AppTheme.primary,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              review.name,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Row(
                                              children: List.generate(5, (starIdx) {
                                                final floorRating = review.rating.floor();
                                                final isFull = starIdx < floorRating;
                                                final isHalf = !isFull && (starIdx == floorRating) && (review.rating % 1.0 > 0);
                                                
                                                return Icon(
                                                  isFull 
                                                      ? Icons.star 
                                                      : (isHalf ? Icons.star_half : Icons.star_border),
                                                  color: Colors.amber,
                                                  size: 12,
                                                );
                                              }),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    Text(
                                      review.timeAgo,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  review.comment,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark ? AppTheme.textSecondaryDark : AppTheme.textMediumLight,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Sticky Floating Bottom Action
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.bgDark.withOpacity(0.8) : Colors.white.withOpacity(0.85),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                border: Border(
                  top: BorderSide(
                    color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                    width: 0.5,
                  ),
                ),
              ),
              child: ElevatedButton(
                onPressed: _showBookingConfirmation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: AppTheme.bgDark,
                  shadowColor: AppTheme.primary.withOpacity(0.3),
                  elevation: 4,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Book Initial Consultation',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String val, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
          ),
        ),
        child: Column(
          children: [
            Text(
              title.toUpperCase(),
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              val,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
