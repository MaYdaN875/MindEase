import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class DocumentUploadWidget extends StatefulWidget {
  final String title;
  final String description;
  final String documentType;
  final List<dynamic> existingDocuments;
  final VoidCallback onStateChanged;

  const DocumentUploadWidget({
    super.key,
    required this.title,
    required this.description,
    required this.documentType,
    required this.existingDocuments,
    required this.onStateChanged,
  });

  @override
  State<DocumentUploadWidget> createState() => _DocumentUploadWidgetState();
}

class _DocumentUploadWidgetState extends State<DocumentUploadWidget> {
  bool _isUploading = false;
  bool _isDeleting = false;
  String? _errorMessage;

  // Find document of this type in existing list
  Map<String, dynamic>? get _currentDocument {
    try {
      return widget.existingDocuments.firstWhere(
        (doc) => doc['documentType'] == widget.documentType,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _pickAndUploadFile() async {
    setState(() {
      _errorMessage = null;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (result == null || result.files.single.path == null) {
        return; // Canceled by user
      }

      setState(() {
        _isUploading = true;
      });

      final filePath = result.files.single.path!;
      final response = await AuthService().uploadPsychologistDocument(
        filePath,
        widget.documentType,
      );

      setState(() {
        _isUploading = false;
      });

      if (response['success'] == true) {
        widget.onStateChanged();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Documento ${widget.title} subido correctamente'),
            backgroundColor: AppTheme.primary,
          ),
        );
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Error al subir archivo';
        });
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
        _errorMessage = 'Error al seleccionar archivo: ${e.toString()}';
      });
    }
  }

  Future<void> _deleteFile(String documentId) async {
    setState(() {
      _isDeleting = true;
      _errorMessage = null;
    });

    final response = await AuthService().deletePsychologistDocument(documentId);

    setState(() {
      _isDeleting = false;
    });

    if (response['success'] == true) {
      widget.onStateChanged();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Documento eliminado correctamente'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } else {
      setState(() {
        _errorMessage = response['message'] ?? 'Error al eliminar archivo';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final doc = _currentDocument;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildStatusIndicator(doc?['status']),
            ],
          ),
          const SizedBox(height: 16),

          if (_errorMessage != null) ...[
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.redAccent, fontSize: 12),
            ),
            const SizedBox(height: 12),
          ],

          if (doc != null) ...[
            // Document uploaded info view
            Row(
              children: [
                const Icon(Icons.description_outlined, color: AppTheme.primary, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    doc['originalFilename'] ?? 'archivo_cargado',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(width: 12),
                _isDeleting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.redAccent),
                      )
                    : IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        onPressed: () => _deleteFile(doc['id']),
                        tooltip: 'Eliminar documento',
                      ),
              ],
            ),
          ] else ...[
            // Actions to upload file
            _isUploading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Column(
                        children: [
                          CircularProgressIndicator(color: AppTheme.primary),
                          SizedBox(height: 8),
                          Text('Subiendo documento...', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  )
                : OutlinedButton.icon(
                    onPressed: _pickAndUploadFile,
                    icon: const Icon(Icons.upload_file_outlined),
                    label: const Text('Subir Documento (PDF o Imagen)'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                      side: const BorderSide(color: AppTheme.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    ),
                  ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(String? status) {
    if (status == null) return const SizedBox.shrink();

    Color color;
    String label;
    IconData icon;

    switch (status) {
      case 'APPROVED':
        color = Colors.green;
        label = 'Aprobado';
        icon = Icons.check_circle_outline;
        break;
      case 'REJECTED':
        color = Colors.redAccent;
        label = 'Rechazado';
        icon = Icons.error_outline;
        break;
      case 'PENDING':
      default:
        color = Colors.amber;
        label = 'En revisión';
        icon = Icons.hourglass_empty;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
