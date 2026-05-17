import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:atelier7/presentation/controllers/user.controller.dart';
import 'package:atelier7/utils/cloudinary_upload_helper.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthController _authController = Get.find<AuthController>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _avatarCtrl;
  final ImagePicker _imagePicker = ImagePicker();
  Uint8List? _selectedImageBytes;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _emailCtrl = TextEditingController();
    _avatarCtrl = TextEditingController();
    _syncFields();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _authController.fetchProfile();
      if (mounted) {
        _syncFields();
      }
    });
  }

  void _syncFields() {
    _nameCtrl.text = _authController.userName.value;
    _emailCtrl.text = _authController.userEmail.value;
    _avatarCtrl.text = _authController.userAvatar.value;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _avatarCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 512,
      );
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      setState(() {
        _selectedImageBytes = bytes;
        _isUploadingImage = true;
      });

      final url = await CloudinaryUploadHelper.uploadImage(
        picked,
        bytes: bytes,
      );
      setState(() {
        _avatarCtrl.text = url;
        _isUploadingImage = false;
      });
    } catch (e) {
      setState(() => _isUploadingImage = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'image_upload_error'.tr}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final ok = await _authController.updateProfile(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      avatar: _avatarCtrl.text.trim(),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'profile_updated_success'.tr : 'profile_update_error'.tr,
        ),
        backgroundColor: ok ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'my_profile'.tr,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: colorScheme.onPrimary,
          ),
        ),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      body: Obx(() {
        final isLoading = _authController.isProfileLoading.value;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: CircleAvatar(
                            radius: 46,
                            backgroundColor: colorScheme.primary.withValues(
                              alpha: 0.12,
                            ),
                            backgroundImage: _selectedImageBytes != null
                                ? MemoryImage(_selectedImageBytes!)
                                : (_avatarCtrl.text.trim().isNotEmpty
                                      ? NetworkImage(_avatarCtrl.text.trim())
                                            as ImageProvider
                                      : null),
                            child:
                                (_selectedImageBytes == null &&
                                    _avatarCtrl.text.trim().isEmpty)
                                  ? Icon(
                                      Icons.person,
                                      size: 46,
                                      color: colorScheme.primary,
                                    )
                                  : null,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (_isUploadingImage)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 6),
                            child: LinearProgressIndicator(),
                          ),
                        if (!_isUploadingImage)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () =>
                                    _pickImage(ImageSource.gallery),
                                icon: const Icon(Icons.photo_library, size: 18),
                                label: Text(
                                  'gallery'.tr,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              if (!kIsWeb)
                                  OutlinedButton.icon(
                                    onPressed: () =>
                                        _pickImage(ImageSource.camera),
                                    icon: const Icon(Icons.camera_alt, size: 18),
                                    label: Text(
                                      'camera'.tr,
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                            ],
                          ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _nameCtrl,
                          decoration: InputDecoration(
                            labelText: 'full_name'.tr,
                            prefixIcon: const Icon(Icons.person_outline),
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? 'name_required_validation'.tr
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'email'.tr,
                            prefixIcon: const Icon(Icons.email_outlined),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'email_required_validation'.tr;
                            }
                            if (!GetUtils.isEmail(value.trim())) {
                              return 'email_invalid_validation'.tr;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _avatarCtrl,
                          decoration: InputDecoration(
                            labelText: 'avatar_url'.tr,
                            prefixIcon: const Icon(Icons.image_outlined),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colorScheme.secondaryContainer.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${'role'.tr}: ${_authController.userRole.value}',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${'id'.tr}: ${_authController.userId.value}',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: isLoading ? null : _submit,
                          icon: isLoading
                              ? SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: colorScheme.onPrimary,
                                  ),
                                )
                              : const Icon(Icons.save_outlined),
                          label: Text(
                            'enregistrer'.tr,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
