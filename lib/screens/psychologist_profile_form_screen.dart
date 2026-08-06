import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'document_upload_widget.dart';

class PsychologistProfileFormScreen extends StatefulWidget {
  final VoidCallback onFormSubmitted;

  const PsychologistProfileFormScreen({super.key, required this.onFormSubmitted});

  @override
  State<PsychologistProfileFormScreen> createState() => _PsychologistProfileFormScreenState();
}

class _PsychologistProfileFormScreenState extends State<PsychologistProfileFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _backgroundController = TextEditingController();
  final _experienceController = TextEditingController();
  final _priceController = TextEditingController();
  final _licenseController = TextEditingController();
  final _locationController = TextEditingController();
  final _languagesController = TextEditingController();

  final List<String> _availableSpecialties = [
    'Ansiedad',
    'Depresión',
    'Estrés Laboral',
    'Terapia Familiar',
    'Problemas de Pareja',
    'Autoestima',
    'Duelo y Pérdida',
    'Trastornos del Sueño',
  ];
  final List<String> _selectedSpecialties = [];

  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  Map<String, dynamic>? _profileData;
  List<dynamic> _existingDocuments = [];

  int _currentStep = 0; // 0 = Profile Info, 1 = Upload Credentials

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _backgroundController.dispose();
    _experienceController.dispose();
    _priceController.dispose();
    _licenseController.dispose();
    _locationController.dispose();
    _languagesController.dispose();
    super.dispose();
  }

  Future<void> _fetchProfileData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await AuthService().getPsychologistProfile();

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      if (result['success'] == true) {
        final profile = result['data'];
        setState(() {
          _profileData = profile;
          _existingDocuments = profile['documents'] ?? [];

          // Pre-populate controllers
          _descriptionController.text = profile['description'] ?? '';
          _backgroundController.text = profile['academicBackground'] ?? '';
          _experienceController.text = profile['experience'] ?? '';
          _priceController.text = profile['consultationPrice']?.toString() ?? '';
          _licenseController.text = profile['licenseNumber'] ?? '';
          _locationController.text = profile['location'] ?? '';
          _languagesController.text = profile['languages'] ?? '';

          // Pre-populate specialties
          final List<dynamic> specs = profile['specialties'] ?? [];
          _selectedSpecialties.clear();
          for (var s in specs) {
            final name = s['specialty']?['name'];
            if (name != null) {
              _selectedSpecialties.add(name);
            }
          }
        });
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Error al cargar perfil';
        });
      }
    }
  }

  Future<void> _saveProfileInfo() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final fields = {
      'description': _descriptionController.text.trim(),
      'academicBackground': _backgroundController.text.trim(),
      'experience': _experienceController.text.trim(),
      'consultationPrice': double.tryParse(_priceController.text.trim()) ?? 0.0,
      'licenseNumber': _licenseController.text.trim(),
      'location': _locationController.text.trim(),
      'languages': _languagesController.text.trim(),
      'specialties': _selectedSpecialties,
    };

    final result = await AuthService().updatePsychologistProfile(fields);

    if (mounted) {
      setState(() {
        _isSaving = false;
      });

      if (result['success'] == true) {
        setState(() {
          _profileData = result['data'];
          _existingDocuments = _profileData?['documents'] ?? [];
          _currentStep = 1; // Transition to upload screen
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Datos guardados. Continúa subiendo tus documentos.'),
            backgroundColor: AppTheme.primary,
          ),
        );
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Error al guardar datos';
        });
      }
    }
  }

  Future<void> _submitRequest() async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final result = await AuthService().submitPsychologistReview();

    if (mounted) {
      setState(() {
        _isSaving = false;
      });

      if (result['success'] == true) {
        widget.onFormSubmitted(); // Reload app state
        Navigator.of(context).pop(); // Go back to ApplicationStatusScreen
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Error al enviar revisión';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro Profesional'),
        centerTitle: true,
        actions: [
          if (_currentStep == 1)
            TextButton(
              onPressed: () {
                setState(() {
                  _currentStep = 0;
                });
              },
              child: const Text('Editar Datos', style: TextStyle(color: AppTheme.primary)),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Step Indicators
              _buildStepIndicator(isDark),
              const SizedBox(height: 28),

              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 20),
              ],

              _currentStep == 0 ? _buildFormSection(isDark) : _buildUploadSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _currentStep == 0 ? AppTheme.primary : AppTheme.primary.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '1',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _currentStep == 0 ? AppTheme.bgDark : AppTheme.textLight,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Text('Perfil', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        Container(
          width: 40,
          height: 2,
          color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
        ),
        Expanded(
          child: Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _currentStep == 1 ? AppTheme.primary : (isDark ? AppTheme.cardDark : Colors.white),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _currentStep == 1 ? AppTheme.primary : (isDark ? AppTheme.borderDark : AppTheme.borderLight),
                  ),
                ),
                child: Center(
                  child: Text(
                    '2',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _currentStep == 1 ? AppTheme.bgDark : Colors.grey,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Text('Documentos', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFormSection(bool isDark) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section 1: Professional Details
          _buildInputLabel('Semblanza Profesional'),
          TextFormField(
            controller: _descriptionController,
            maxLines: 4,
            style: TextStyle(color: isDark ? AppTheme.textLight : AppTheme.textDark),
            decoration: _buildInputDecoration(
              'Cuéntanos sobre ti y tu enfoque terapéutico...',
              isDark,
              prefixIcon: Icons.edit_note,
            ),
            validator: (val) => val == null || val.isEmpty ? 'Este campo es obligatorio' : null,
          ),
          const SizedBox(height: 20),

          _buildInputLabel('Número de Cédula Profesional'),
          TextFormField(
            controller: _licenseController,
            style: TextStyle(color: isDark ? AppTheme.textLight : AppTheme.textDark),
            decoration: _buildInputDecoration('Cédula oficial emitida por la SEP', isDark, prefixIcon: Icons.badge_outlined),
            validator: (val) => val == null || val.isEmpty ? 'La cédula es requerida' : null,
          ),
          const SizedBox(height: 20),

          // Academic & Experience
          _buildInputLabel('Formación Académica'),
          TextFormField(
            controller: _backgroundController,
            maxLines: 2,
            style: TextStyle(color: isDark ? AppTheme.textLight : AppTheme.textDark),
            decoration: _buildInputDecoration('Universidad, Posgrados, Certificados...', isDark, prefixIcon: Icons.school_outlined),
            validator: (val) => val == null || val.isEmpty ? 'Escribe tu formación académica' : null,
          ),
          const SizedBox(height: 20),

          _buildInputLabel('Experiencia Laboral'),
          TextFormField(
            controller: _experienceController,
            maxLines: 2,
            style: TextStyle(color: isDark ? AppTheme.textLight : AppTheme.textDark),
            decoration: _buildInputDecoration('Años de experiencia en consulta...', isDark, prefixIcon: Icons.work_history_outlined),
            validator: (val) => val == null || val.isEmpty ? 'Detalla tu experiencia' : null,
          ),
          const SizedBox(height: 20),

          // Price & Location
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInputLabel('Precio Consulta (MXN)'),
                    TextFormField(
                      controller: _priceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: TextStyle(color: isDark ? AppTheme.textLight : AppTheme.textDark),
                      decoration: _buildInputDecoration('Precio por hora', isDark, prefixIcon: Icons.attach_money),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Requerido';
                        if (double.tryParse(val) == null) return 'Monto inválido';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInputLabel('Ubicación General'),
                    TextFormField(
                      controller: _locationController,
                      style: TextStyle(color: isDark ? AppTheme.textLight : AppTheme.textDark),
                      decoration: _buildInputDecoration('Ciudad y Estado', isDark, prefixIcon: Icons.location_on_outlined),
                      validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          _buildInputLabel('Idiomas que atiende'),
          TextFormField(
            controller: _languagesController,
            style: TextStyle(color: isDark ? AppTheme.textLight : AppTheme.textDark),
            decoration: _buildInputDecoration('Ej: Español, Inglés...', isDark, prefixIcon: Icons.language),
          ),
          const SizedBox(height: 24),

          // Specialties Selection
          _buildInputLabel('Especialidades Clínicas (Selecciona las que apliquen)'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableSpecialties.map((spec) {
              final isSelected = _selectedSpecialties.contains(spec);
              return FilterChip(
                label: Text(spec),
                selected: isSelected,
                selectedColor: AppTheme.primary.withOpacity(0.2),
                checkmarkColor: AppTheme.primary,
                labelStyle: TextStyle(
                  color: isSelected ? AppTheme.primary : (isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight),
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                backgroundColor: isDark ? AppTheme.cardDark : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: isSelected ? AppTheme.primary : (isDark ? AppTheme.borderDark : AppTheme.borderLight),
                  ),
                ),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedSpecialties.add(spec);
                    } else {
                      _selectedSpecialties.remove(spec);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 36),

          ElevatedButton(
            onPressed: _isSaving ? null : _saveProfileInfo,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: AppTheme.bgDark,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.bgDark),
                  )
                : const Text('Continuar a Documentos', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Validación de Identidad y Credenciales',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Sube la documentación oficial requerida. Estos archivos se guardarán en almacenamiento cifrado privado de consulta restringida.',
          style: TextStyle(fontSize: 13, color: Colors.grey),
        ),
        const SizedBox(height: 24),

        DocumentUploadWidget(
          title: 'Identificación Oficial',
          description: 'Carga una copia legible de tu INE o pasaporte oficial.',
          documentType: 'ID',
          existingDocuments: _existingDocuments,
          onStateChanged: _fetchProfileData,
        ),
        DocumentUploadWidget(
          title: 'Título Profesional',
          description: 'Carga tu título o comprobante de estudios académicos en Psicología.',
          documentType: 'DEGREE',
          existingDocuments: _existingDocuments,
          onStateChanged: _fetchProfileData,
        ),
        DocumentUploadWidget(
          title: 'Cédula Profesional',
          description: 'Carga tu cédula oficial para validación ante la SEP.',
          documentType: 'LICENSE',
          existingDocuments: _existingDocuments,
          onStateChanged: _fetchProfileData,
        ),

        const SizedBox(height: 36),

        ElevatedButton(
          onPressed: _isSaving ? null : _submitRequest,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: AppTheme.bgDark,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.bgDark),
                )
              : const Text('Enviar Solicitud a Revisión', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 4.0),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint, bool isDark, {required IconData prefixIcon}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(prefixIcon, color: AppTheme.primary, size: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppTheme.primary, width: 2),
      ),
      filled: true,
      fillColor: isDark ? AppTheme.cardDark.withOpacity(0.5) : Colors.white,
    );
  }
}
