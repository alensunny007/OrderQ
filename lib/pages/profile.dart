import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:math';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _universityIdController = TextEditingController();
  
  bool _isEditing = false;
  bool _isLoading = false;
  String? _errorMessage;
  File? _imageFile;
  String? _profileImageUrl;
  bool _isUploadingImage = false;
  double _uploadProgress = 0.0;

  final ImagePicker _picker = ImagePicker();
  
  // ImgBB API key from environment variables
  late String _imgbbApiKey;

  @override
  void initState() {
    super.initState();
    // Load API key from .env file
    _imgbbApiKey = dotenv.env['IMGBB_API_KEY'] ?? '';
    print("ImgBB API Key loaded: ${_imgbbApiKey.isNotEmpty ? 'Yes (${_imgbbApiKey.substring(0, min(3, _imgbbApiKey.length))}...)' : 'No'}");
    
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userData = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (userData.exists && mounted) {
          setState(() {
            _nameController.text = userData.data()?['name'] ?? '';
            _emailController.text = userData.data()?['email'] ?? user.email ?? '';
            _phoneController.text = userData.data()?['phone'] ?? '';
            _universityIdController.text = userData.data()?['universityId'] ?? '';
            _profileImageUrl = userData.data()?['profileImageUrl'];
          });
          
          // Debug log to verify URL is being loaded
          print("Loaded profile image URL from Firestore: $_profileImageUrl");
        } else {
          // If document doesn't exist, initialize with default values
          _nameController.text = user.displayName ?? '';
          _emailController.text = user.email ?? '';
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load user data: $e';
        });
        print("Error loading user data: $e");
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _getImageFromGallery() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (pickedFile != null && mounted) {
        print("Image picked: ${pickedFile.path}");
        
        // Compress image
        final tempDir = await getTemporaryDirectory();
        final targetPath = path.join(tempDir.path, 'compressed_${path.basename(pickedFile.path)}');
        
        try {
          final compressedFile = await FlutterImageCompress.compressAndGetFile(
            pickedFile.path,
            targetPath,
            quality: 85,
            minWidth: 600,
            minHeight: 600,
          );
          
          if (compressedFile != null) {
            setState(() {
              _imageFile = File(compressedFile.path);
            });
            print("Image compressed: ${compressedFile.path}");
          } else {
            setState(() {
              _imageFile = File(pickedFile.path);
            });
            print("Compression failed, using original image");
          }
        } catch (e) {
          // Fallback to non-compressed image
          setState(() {
            _imageFile = File(pickedFile.path);
          });
          print("Error compressing image: $e");
        }
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick image: ${e.toString()}');
    }
  }

  Future<String?> _uploadImageToImgBB() async {
    if (_imageFile == null) return _profileImageUrl;

    print("Starting image upload to ImgBB");
    setState(() {
      _isUploadingImage = true;
      _uploadProgress = 0.0;
    });

    try {
      // Read file as bytes
      final bytes = await _imageFile!.readAsBytes();
      final base64Image = base64Encode(bytes);
      
      print("Image converted to base64, sending to ImgBB...");
      print("API Key being used: ${_imgbbApiKey.substring(0, min(5, _imgbbApiKey.length))}...");
      
      // Create request
      final response = await http.post(
        Uri.parse('https://api.imgbb.com/1/upload'),
        body: {
          'key': _imgbbApiKey,
          'image': base64Image,
          'name': 'profile_${FirebaseAuth.instance.currentUser?.uid ?? DateTime.now().millisecondsSinceEpoch}',
        },
      );
      
      print("ImgBB response status code: ${response.statusCode}");
      print("ImgBB response body (first 100 chars): ${response.body.substring(0, min(100, response.body.length))}...");
      
      if (response.statusCode != 200) {
        print("Full ImgBB error response: ${response.body}");
        throw Exception('ImgBB returned status code ${response.statusCode}');
      }
      
      final jsonData = json.decode(response.body);
      
      // Check if upload was successful
      if (jsonData['success'] == true) {
        final String imageUrl = jsonData['data']['url'];
        print("✓ Image uploaded successfully to ImgBB. URL: $imageUrl");
        
        setState(() {
          _profileImageUrl = imageUrl;
          _isUploadingImage = false;
          _uploadProgress = 1.0;
        });
        
        return imageUrl;
      } else {
        print("✗ ImgBB upload failed: ${jsonData['error']?['message'] ?? 'Unknown error'}");
        throw Exception('Failed to upload image: ${jsonData['error']?['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      print("✗ Error uploading image: $e");
      setState(() {
        _isUploadingImage = false;
      });
      _showErrorSnackBar('Failed to upload profile image: ${e.toString()}');
      return null;
    }
  }

  Future<void> _saveUserData() async {
    // Validate inputs
    if (_nameController.text.isEmpty) {
      _showErrorSnackBar('Name cannot be empty');
      return;
    }

    if (_emailController.text.isEmpty || !_emailController.text.contains('@')) {
      _showErrorSnackBar('Please enter a valid email address');
      return;
    }

    if (_phoneController.text.isEmpty || _phoneController.text.length < 10) {
      _showErrorSnackBar('Please enter a valid phone number');
      return;
    }

    if (_universityIdController.text.isEmpty) {
      _showErrorSnackBar('University ID cannot be empty');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Upload image if selected
        String? imageUrl = _profileImageUrl;  // Default to current URL
        
        if (_imageFile != null) {
          print("Image file selected, uploading to ImgBB...");
          imageUrl = await _uploadImageToImgBB();
          print("After upload, imageUrl: $imageUrl");
        } else {
          print("No new image file selected, keeping existing URL: $imageUrl");
        }

        // Create a data map for Firestore update
        final Map<String, dynamic> userData = {
          'name': _nameController.text,
          'email': _emailController.text,
          'phone': _phoneController.text,
          'universityId': _universityIdController.text,
          'lastUpdated': FieldValue.serverTimestamp(),
        };
        
        // Only add profileImageUrl if we have one
        if (imageUrl != null && imageUrl.isNotEmpty) {
          userData['profileImageUrl'] = imageUrl;
          print("Adding imageUrl to userData for Firestore: $imageUrl");
        } else {
          print("No valid imageUrl to store in Firestore");
        }

        print("Updating Firestore document for user ${user.uid}");
        // Update Firestore document
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set(userData, SetOptions(merge: true));
        
        print("✓ Firestore document updated successfully");
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      print("✗ Error saving user data: $e");
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to update profile: $e';
        });
        _showErrorSnackBar('Failed to update profile: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isEditing = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  // Safe navigation method that handles possible navigation issues
  void _navigateBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      // If there's nothing to pop, navigate to the home route
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _navigateBack();
        return false; // Prevent default back behavior
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: _navigateBack,
          ),
          title: const Text(
            "Profile",
            style: TextStyle(color: Colors.white),
          ),
        ),
        extendBodyBehindAppBar: true,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF53E3C6), Color(0xFF00122D)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  )
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.white),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: _loadUserData,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF53E3C6),
                              ),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              const SizedBox(height: 20),
                              _buildProfileSection(),
                              const SizedBox(height: 20),
                              _buildDetailsCard(),
                            ],
                          ),
                        ),
                      ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.2),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: _isUploadingImage
                  ? Center(
                      child: CircularProgressIndicator(
                        value: _uploadProgress > 0 ? _uploadProgress : null,
                        color: Colors.white,
                      ),
                    )
                  : _imageFile != null
                      ? ClipOval(
                          child: Image.file(
                            _imageFile!,
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                          ),
                        )
                      : _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                          ? ClipOval(
                              child: Image.network(
                                _profileImageUrl!,
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                    child: CircularProgressIndicator(
                                      value: loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress.cumulativeBytesLoaded /
                                              loadingProgress.expectedTotalBytes!
                                          : null,
                                      color: Colors.white,
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  print("Error loading image from URL: $error");
                                  return const Icon(
                                    Icons.person,
                                    size: 60,
                                    color: Colors.white,
                                  );
                                },
                              ),
                            )
                          : const Icon(
                              Icons.person,
                              size: 60,
                              color: Colors.white,
                            ),
            ),
            if (_isEditing)
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _isUploadingImage ? null : _getImageFromGallery,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF53E3C6),
                    ),
                    child: _isUploadingImage
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),
        Column(
          children: [
            Text(
              _nameController.text.isNotEmpty ? _nameController.text : "Student Name",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _emailController.text.isNotEmpty ? _emailController.text : "student@example.com",
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          if (_isEditing) ...[
            _buildEditableDetailRow("Name", _nameController),
            const SizedBox(height: 16),
            _buildEditableDetailRow("Email", _emailController),
            const SizedBox(height: 16),
          ],
          _isEditing
              ? _buildEditableDetailRow("Phone", _phoneController)
              : _buildDetailRow("Phone", _phoneController.text.isNotEmpty ? _phoneController.text : "Not set"),
          const SizedBox(height: 16),
          _isEditing
              ? _buildEditableDetailRow("University ID", _universityIdController)
              : _buildDetailRow("University ID", _universityIdController.text.isNotEmpty ? _universityIdController.text : "Not set"),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _isLoading ? null : () {
              if (_isEditing) {
                _saveUserData();
              } else {
                setState(() {
                  _isEditing = true;
                });
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF53E3C6),
              minimumSize: const Size(double.infinity, 45),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    _isEditing ? "Save Changes" : "Edit Profile",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
          if (_isEditing)
            TextButton(
              onPressed: () {
                setState(() {
                  _isEditing = false;
                  _imageFile = null; // Clear selected image if canceled
                  // Restore original values
                  _loadUserData();
                });
              },
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.white70),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 16,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildEditableDetailRow(String label, TextEditingController controller) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 16,
          ),
        ),
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.5,
          child: TextField(
            controller: controller,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF53E3C6), width: 2),
              ),
              errorBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.red, width: 2),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _universityIdController.dispose();
    super.dispose();
  }
}