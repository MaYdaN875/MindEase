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

  static List<Psychologist> get list => [
        Psychologist(
          id: 'sarah-jenkins',
          name: 'Dr. Sarah Jenkins, PhD',
          title: 'Clinical Psychologist',
          imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuBafJfrd0z5ODpsKMvlKnSCkGZJcW0rgqnOSAn0zxu_FQkpsPPgrZnSaXzG9qSQHY3GkdAJsZVqRX6Ltg69kb6Gag7c7HcsPPCNjmW2ocuO2S6H-qoPs4oRtY6ygu2Q2NxNFFu2VZ7N3VdURJeVwXtljbFsk3vii0Jz3qHkxrQIZ44Wpvd1azYqFE77lb55agIyhuAITCxaPAHVe1zgo_7h4l4GXhH0docC12vmdEihtftUDWx00DzakmwI7A_2k1k8lKJKeR2_xmye',
          profileImageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuCuLQiChMGWWZeWUMAXeKsstyn9b_FBQ1E9pbVaV6JqjaSoc2R6ZkeNmmKWUpfN9iTklzNO0Bt9aUzoxCASP23dxV93wjKHZkK4BXoRS5m5-TLRQ_uwNbvqKYDGtsiYHtGWnWgUU-KJ7XhKaxs8l-ssXAzrqS99ZLmu5RaQhXE5QRH6G3z0i_5DXoLfNogUJnJr2m4yfZqoNYHTgjR5dxvLqjs6T6wEdQGUyNOw5aevqQiCWdVA0ZqkwG-xQTd2fezEeo655utRUQnB',
          rating: 4.9,
          reviewsCount: 120,
          durationMinutes: 50,
          pricePerSession: 120,
          patients: '500+',
          experience: '12 yrs',
          languages: 'EN, ES',
          about: 'Specializing in cognitive behavioral therapy (CBT) and mindfulness-based stress reduction. Dedicated to helping individuals navigate anxiety, depression, and trauma through evidence-based practices and a compassionate, person-centered approach.',
          specialties: [
            'Cognitive Behavioral Therapy',
            'Anxiety Disorders',
            'Depression',
            'Mindfulness',
            'Stress Management'
          ],
          reviews: [
            PsychologistReview(
              name: 'John D.',
              initials: 'JD',
              rating: 5.0,
              timeAgo: '2 days ago',
              comment: 'Dr. Jenkins was incredibly empathetic and helped me through a very difficult transition in my career. Highly recommend her for anyone dealing with stress.',
            ),
            PsychologistReview(
              name: 'Anna M.',
              initials: 'AM',
              rating: 4.5,
              timeAgo: '1 week ago',
              comment: 'Great listener and provides practical tools for anxiety management. The sessions are always productive.',
            ),
          ],
        ),
        Psychologist(
          id: 'michael-chen',
          name: 'Dr. Michael Chen',
          title: 'Child & Adolescent Specialist',
          imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuBwu-bMkhU4qRENJ26XeQQ_W_AzGeoQRs5LzKtLRKzq-ks6wS-_kjhbqq8apU0IZibtYaSP1y1tBouLr8-doA_936Qmo7o6tV2nJRKORKASc2GyeW_b7W_jUJWloXk-_HO1S2e3KbMeculPs_hdQkaDsyrtCAy8avXa3rKpgSG25B-rpdOTI0r69LfHvFdnEdE7obazAxDIiXXIRVRityzSXuOqYzPlRMsxJRQcN-BMUALvt7pYSlMdB8poIn_VQyosSs6BNs8ipcVQ',
          profileImageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuBwu-bMkhU4qRENJ26XeQQ_W_AzGeoQRs5LzKtLRKzq-ks6wS-_kjhbqq8apU0IZibtYaSP1y1tBouLr8-doA_936Qmo7o6tV2nJRKORKASc2GyeW_b7W_jUJWloXk-_HO1S2e3KbMeculPs_hdQkaDsyrtCAy8avXa3rKpgSG25B-rpdOTI0r69LfHvFdnEdE7obazAxDIiXXIRVRityzSXuOqYzPlRMsxJRQcN-BMUALvt7pYSlMdB8poIn_VQyosSs6BNs8ipcVQ',
          rating: 4.8,
          reviewsCount: 95,
          durationMinutes: 45,
          pricePerSession: 145,
          patients: '320+',
          experience: '8 yrs',
          languages: 'EN, ZH',
          about: 'Focusing on developmental support, childhood anxiety, behavioral adjustments, and family dynamic therapies. Dr. Chen provides a warm, engaging, and collaborative space for children and parents.',
          specialties: [
            'Child Therapy',
            'Adolescent Psychology',
            'ADHD Support',
            'Family Counseling',
            'Play Therapy'
          ],
          reviews: [
            PsychologistReview(
              name: 'Emily R.',
              initials: 'ER',
              rating: 5.0,
              timeAgo: '3 days ago',
              comment: 'Dr. Chen connected immediately with our son. We have seen tremendous improvement in his school focus and communication.',
            ),
          ],
        ),
        Psychologist(
          id: 'elena-rodriguez',
          name: 'Dr. Elena Rodriguez',
          title: 'Anxiety & Depression Therapy',
          imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuAfao2rDf6rjyiVZp0EF7lBksmohlM3JPUlaZUNPqFKeP2pttzdBQC2ZCZUKW_q87PLDb-zqvrIO3askiwG_DHLycl60WPZsFEZZLDlOcuM1hlh6hNJPwIs1q1uC3XVCLFT3eyi6RGQTDhrwSbM2qdTdJxCF3QwASmsSFcZOycPgj2c_Ad0SCg2clWHXv-xj_SaqZWSavFKzZxefFY4GFbANpQG1iVCsul8enL_kTdETiAECiSLLkYiO70kLCUxJ3aLacasz7qkAyaf',
          profileImageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuAfao2rDf6rjyiVZp0EF7lBksmohlM3JPUlaZUNPqFKeP2pttzdBQC2ZCZUKW_q87PLDb-zqvrIO3askiwG_DHLycl60WPZsFEZZLDlOcuM1hlh6hNJPwIs1q1uC3XVCLFT3eyi6RGQTDhrwSbM2qdTdJxCF3QwASmsSFcZOycPgj2c_Ad0SCg2clWHXv-xj_SaqZWSavFKzZxefFY4GFbANpQG1iVCsul8enL_kTdETiAECiSLLkYiO70kLCUxJ3aLacasz7qkAyaf',
          rating: 5.0,
          reviewsCount: 150,
          durationMinutes: 60,
          pricePerSession: 110,
          patients: '600+',
          experience: '15 yrs',
          languages: 'ES, EN, PT',
          about: 'Specialist in mood disorders, anxiety, self-esteem improvement, and relationship issues. Passionate about empowering clients through structured mindfulness tools and schema-based therapies.',
          specialties: [
            'Anxiety Disorders',
            'Depression Therapy',
            'Mindfulness Practice',
            'Self-Esteem Building',
            'Relationship Counseling'
          ],
          reviews: [
            PsychologistReview(
              name: 'Mateo S.',
              initials: 'MS',
              rating: 5.0,
              timeAgo: '4 days ago',
              comment: 'La doctora Elena es excepcional. Me ayudó a superar mis ataques de pánico de una manera práctica y sumamente comprensiva.',
            ),
          ],
        ),
        Psychologist(
          id: 'james-wilson',
          name: 'Dr. James Wilson',
          title: 'Trauma & PTSD Specialist',
          imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuDPvRV6PldFrCQFoq53DIUmzkx2W6lEbmNk6XmzHkbCel4iTHzy5f7TuHHF4C53v_bdARLjpeHYCAK4ZWVBPCV8nsg3HIrjEHZUZ5pJ1UB-uvEKI1AXSUBYI26K4RsH-w206D7kpm4JBlWbeydqwQiuf799SNOEYeI6z4t8DXzMXH5APYmjd5vVuaV1aa4mxkoQIwuKsX41tIW-2E6lM2qtC-OQOfyu7Zpx3abgRyoaH5bc5b_6q8JboG0KYg3GPFZjYTqaXfvzGPV7',
          profileImageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuDPvRV6PldFrCQFoq53DIUmzkx2W6lEbmNk6XmzHkbCel4iTHzy5f7TuHHF4C53v_bdARLjpeHYCAK4ZWVBPCV8nsg3HIrjEHZUZ5pJ1UB-uvEKI1AXSUBYI26K4RsH-w206D7kpm4JBlWbeydqwQiuf799SNOEYeI6z4t8DXzMXH5APYmjd5vVuaV1aa4mxkoQIwuKsX41tIW-2E6lM2qtC-OQOfyu7Zpx3abgRyoaH5bc5b_6q8JboG0KYg3GPFZjYTqaXfvzGPV7',
          rating: 4.7,
          reviewsCount: 88,
          durationMinutes: 50,
          pricePerSession: 135,
          patients: '450+',
          experience: '10 yrs',
          languages: 'EN',
          about: 'Specializing in trauma recovery, PTSD treatments using EMDR, grief, and long-term coping mechanisms. Dedicated to helping individuals heal from deep wounds and live resilient, meaningful lives.',
          specialties: [
            'Trauma Recovery',
            'PTSD Therapy',
            'EMDR Treatment',
            'Grief Counseling',
            'Resilience Training'
          ],
          reviews: [
            PsychologistReview(
              name: 'David L.',
              initials: 'DL',
              rating: 5.0,
              timeAgo: '2 weeks ago',
              comment: 'Dr. James helped me process veteran-related trauma in a way no other therapist could. I am forever grateful.',
            ),
          ],
        ),
      ];
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
