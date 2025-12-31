import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart';
import '../../config/theme.dart';
import '../../models/subject.dart';
import '../../services/subject_service.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';

class AddSubjectDialog extends StatefulWidget {
  final Subject? subject; // For editing existing subject

  const AddSubjectDialog({super.key, this.subject});

  @override
  State<AddSubjectDialog> createState() => _AddSubjectDialogState();
}

class _AddSubjectDialogState extends State<AddSubjectDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();
  
  final List<String> _weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  final Set<String> _selectedDays = {};
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  String _fieldOfStudy = 'Minor Subject';
  final List<SubjectFile> _attachedFiles = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.subject != null) {
      _nameController.text = widget.subject!.name;
      _notesController.text = widget.subject!.notes ?? '';
      _selectedDays.addAll(widget.subject!.weekdays);
      _startTime = _parseTimeOfDay(widget.subject!.startTime);
      _endTime = _parseTimeOfDay(widget.subject!.endTime);
      _fieldOfStudy = widget.subject!.fieldOfStudy;
      _attachedFiles.addAll(widget.subject!.files);
    }
  }

  TimeOfDay _parseTimeOfDay(String time) {
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _formatTimeOfDay(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickTime(bool isStartTime) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppTheme.accentPrimary,
              onSurface: AppTheme.textPrimary,
              surface: AppTheme.surfaceAlt,
            ),
          ),
          child: child!,
        );
      },
    );

    if (time != null) {
      setState(() {
        if (isStartTime) {
          _startTime = time;
        } else {
          _endTime = time;
        }
      });
    }
  }

  Future<void> _showAttachFilesDialog() async {
    await showDialog(
      context: context,
      builder: (context) => _AttachFilesDialog(
        currentFiles: _attachedFiles,
        onFilesSelected: (files) {
          setState(() {
            _attachedFiles.clear();
            _attachedFiles.addAll(files);
          });
        },
      ),
    );
  }

  Future<void> _saveSubject() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one day')),
      );
      return;
    }
    if (_startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select start and end time')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = context.read<AuthService>().currentUser!.id;
      final subjectService = context.read<SubjectService>();

      final subject = Subject(
        id: widget.subject?.id ?? const Uuid().v4(),
        userId: userId,
        name: _nameController.text.trim(),
        weekdays: _selectedDays.toList()..sort((a, b) => _weekdays.indexOf(a).compareTo(_weekdays.indexOf(b))),
        startTime: _formatTimeOfDay(_startTime!),
        endTime: _formatTimeOfDay(_endTime!),
        fieldOfStudy: _fieldOfStudy,
        files: _attachedFiles,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        createdAt: widget.subject?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.subject == null) {
        await subjectService.addSubject(subject);
      } else {
        // Cancel old notifications if weekdays or time changed
        final notificationService = NotificationService();
        await notificationService.cancelSubjectNotifications(
          widget.subject!.id, 
          widget.subject!.weekdays,
        );
        await subjectService.updateSubject(subject);
      }

      // Schedule notifications for subject class reminders
      final notificationService = NotificationService();
      await notificationService.scheduleSubjectClassNotification(
        subjectId: subject.id,
        subjectName: subject.name,
        startTime: subject.startTime,
        weekdays: subject.weekdays,
        minutesBefore: 30,
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.subject == null ? 'Subject added!' : 'Subject updated!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surfaceAlt,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surfaceAlt,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Icon(Icons.book, color: AppTheme.accentPrimary),
                  const SizedBox(width: 12),
                  Text(
                    widget.subject == null ? 'Add Subject' : 'Edit Subject',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            
            // Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Subject Name
                      TextFormField(
                        controller: _nameController,
                        style: GoogleFonts.inter(color: AppTheme.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Enter subject name...',
                          hintStyle: GoogleFonts.inter(color: AppTheme.textSecondary.withOpacity(0.5)),
                          filled: true,
                          fillColor: AppTheme.surfaceAlt,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter subject name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Schedule
                      Text(
                        'Schedule:',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _weekdays.map((day) {
                          final isSelected = _selectedDays.contains(day);
                          return InkWell(
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  _selectedDays.remove(day);
                                } else {
                                  _selectedDays.add(day);
                                }
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected ? AppTheme.accentPrimary : AppTheme.surfaceAlt,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected ? AppTheme.accentPrimary : AppTheme.textSecondary.withOpacity(0.2),
                                ),
                              ),
                              child: Text(
                                day,
                                style: GoogleFonts.inter(
                                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      // Time Selection
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Start Time',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: () => _pickTime(true),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: AppTheme.surfaceAlt,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.access_time, size: 20, color: AppTheme.accentPrimary),
                                        const SizedBox(width: 12),
                                        Text(
                                          _startTime == null ? '--:--' : _formatTimeOfDay(_startTime!),
                                          style: GoogleFonts.inter(
                                            color: _startTime == null ? AppTheme.textSecondary : AppTheme.textPrimary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'End Time',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: () => _pickTime(false),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: AppTheme.surfaceAlt,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.access_time, size: 20, color: AppTheme.accentPrimary),
                                        const SizedBox(width: 12),
                                        Text(
                                          _endTime == null ? '--:--' : _formatTimeOfDay(_endTime!),
                                          style: GoogleFonts.inter(
                                            color: _endTime == null ? AppTheme.textSecondary : AppTheme.textPrimary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Field of Study
                      Text(
                        'Field of Study:',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => setState(() => _fieldOfStudy = 'Minor Subject'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(
                                  color: _fieldOfStudy == 'Minor Subject' ? AppTheme.accentPrimary : AppTheme.surfaceAlt,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _fieldOfStudy == 'Minor Subject' ? AppTheme.accentPrimary : AppTheme.textSecondary.withOpacity(0.2),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Radio<String>(
                                      value: 'Minor Subject',
                                      groupValue: _fieldOfStudy,
                                      onChanged: (value) => setState(() => _fieldOfStudy = value!),
                                      activeColor: Colors.white,
                                    ),
                                    Flexible(
                                      child: Text(
                                        'Minor Subject',
                                        style: GoogleFonts.inter(
                                          color: _fieldOfStudy == 'Minor Subject' ? Colors.white : AppTheme.textSecondary,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: () => setState(() => _fieldOfStudy = 'Major Subject'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(
                                  color: _fieldOfStudy == 'Major Subject' ? AppTheme.accentPrimary : AppTheme.surfaceAlt,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _fieldOfStudy == 'Major Subject' ? AppTheme.accentPrimary : AppTheme.textSecondary.withOpacity(0.2),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Radio<String>(
                                      value: 'Major Subject',
                                      groupValue: _fieldOfStudy,
                                      onChanged: (value) => setState(() => _fieldOfStudy = value!),
                                      activeColor: Colors.white,
                                    ),
                                    Flexible(
                                      child: Text(
                                        'Major Subject',
                                        style: GoogleFonts.inter(
                                          color: _fieldOfStudy == 'Major Subject' ? Colors.white : AppTheme.textSecondary,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Attach Files
                      InkWell(
                        onTap: _showAttachFilesDialog,
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceAlt,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.textSecondary.withOpacity(0.2),
                              style: BorderStyle.solid,
                              strokeAlign: BorderSide.strokeAlignInside,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.note_add, size: 32, color: AppTheme.accentPrimary),
                              const SizedBox(height: 8),
                              Text(
                                '+ Attach Files Here',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              if (_attachedFiles.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Text(
                                  '${_attachedFiles.length} file(s) attached',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: AppTheme.accentPrimary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Notes
                      TextFormField(
                        controller: _notesController,
                        style: GoogleFonts.inter(color: AppTheme.textPrimary),
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Enter additional notes...',
                          hintStyle: GoogleFonts.inter(color: AppTheme.textSecondary.withOpacity(0.5)),
                          filled: true,
                          fillColor: AppTheme.surfaceAlt,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Footer Buttons
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surfaceAlt,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'CANCEL',
                      style: GoogleFonts.inter(
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveSubject,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            'SAVE',
                            style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Attach Files Dialog
class _AttachFilesDialog extends StatefulWidget {
  final List<SubjectFile> currentFiles;
  final Function(List<SubjectFile>) onFilesSelected;

  const _AttachFilesDialog({
    required this.currentFiles,
    required this.onFilesSelected,
  });

  @override
  State<_AttachFilesDialog> createState() => _AttachFilesDialogState();
}

class _AttachFilesDialogState extends State<_AttachFilesDialog> {
  late List<SubjectFile> _files;

  @override
  void initState() {
    super.initState();
    _files = List.from(widget.currentFiles);
  }

  Future<void> _addFile() async {
    try {
      // Pick files
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'ppt', 'pptx', 'xls', 'xlsx', 'txt', 'jpg', 'jpeg', 'png'],
      );

      if (result != null && result.files.isNotEmpty) {
        // Size limit: 10 MB per file
        const maxSizeInBytes = 10 * 1024 * 1024; // 10 MB
        
        for (final file in result.files) {
          final fileSize = file.size;
          
          // Check file size
          if (fileSize > maxSizeInBytes) {
            final sizeInMB = (fileSize / (1024 * 1024)).toStringAsFixed(2);
            if (mounted) {
              // Show size limit warning
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: AppTheme.surfaceAlt,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  title: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
                      const SizedBox(width: 12),
                      Text(
                        'File Too Large',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  content: Text(
                    'The file "${file.name}" is $sizeInMB MB.\n\nMaximum file size allowed is 10 MB.\n\nPlease select a smaller file.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  actions: [
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'OK',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
            continue; // Skip this file
          }
          
          // Add valid file
          final newFile = SubjectFile(
            name: file.name,
            sizeInBytes: fileSize,
            uploadedAt: DateTime.now(),
            // In production, upload to Firebase Storage and store URL
            // url: await uploadToStorage(file),
          );
          
          setState(() => _files.add(newFile));
        }
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting files: $e'),
            backgroundColor: AppTheme.accentAlert,
          ),
        );
      }
    }
  }

  void _removeFile(int index) {
    setState(() => _files.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surfaceAlt,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Attach Files',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            Text(
              '(Subject Title)',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 20),

            // Attach Area
            InkWell(
              onTap: _addFile,
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceAlt,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.textSecondary.withOpacity(0.3),
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(Icons.note_add, size: 48, color: AppTheme.accentPrimary),
                    const SizedBox(height: 12),
                    Text(
                      '+ Attach Files Here',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // File List
            if (_files.isNotEmpty) ...[
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _files.length,
                  itemBuilder: (context, index) {
                    final file = _files[index];
                    final sizeInMB = (file.sizeInBytes ?? 0) / (1024 * 1024);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceAlt,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.insert_drive_file, color: AppTheme.accentPrimary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  file.name,
                                  style: GoogleFonts.inter(
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (file.sizeInBytes != null)
                                  Text(
                                    'File Size in ${sizeInMB.toStringAsFixed(1)} MB',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => _removeFile(index),
                            icon: const Icon(Icons.close, size: 20),
                            color: AppTheme.accentAlert,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Footer Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'CANCEL',
                    style: GoogleFonts.inter(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    widget.onFilesSelected(_files);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'SAVE',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
