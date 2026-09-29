class Psychologist {
  final String id;
  final String name;
  final String title;
  final String imageUrl;
  final String profileImageUrl;
  final double rating;
  final int reviewsCount;
  final int durationMinutes;
  final int pricePerSession;
  final String patients;
  final String experience;
  final String languages;
  final String about;
  final List<String> specialties;
  final List<PsychologistReview> reviews;
  final bool isVerified;

  Psychologist({
    required this.id,
    required this.name,
    required this.title,
    required this.imageUrl,
    required this.profileImageUrl,
    required this.rating,
    required this.reviewsCount,
    required this.durationMinutes,
    required this.pricePerSession,
    required this.patients,
    required this.experience,
    required this.languages,
    required this.about,
    required this.specialties,
    required this.reviews,
    this.isVerified = true,
  });


}

class PsychologistReview {
  final String name;
  final String initials;
  final double rating;
  final String timeAgo;
  final String comment;

  PsychologistReview({
    required this.name,
    required this.initials,
    required this.rating,
    required this.timeAgo,
    required this.comment,
  });
}
