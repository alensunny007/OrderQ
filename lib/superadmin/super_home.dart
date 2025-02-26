import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';

// User model with safe Firestore integration
class User {
  final String id;
  final String name;
  final String email;
  String role;
  final String dateJoined;
  final String? studentId;
  final String? mobileNumber;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.dateJoined,
    this.studentId,
    this.mobileNumber,
  });

  // Type-safe factory constructor
  factory User.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    // Handle date joined format
    String formattedDate = '';
    if (data['dateJoined'] != null) {
      formattedDate = data['dateJoined'].toString();
    } else if (data['createdAt'] != null) {
      if (data['createdAt'] is Timestamp) {
        formattedDate = (data['createdAt'] as Timestamp).toDate().toString().split(' ')[0];
      } else {
        formattedDate = data['createdAt'].toString();
      }
    } else {
      formattedDate = DateTime.now().toString().split(' ')[0];
    }

    // Safe getters for fields that might have type mismatches
    String getName() {
      try {
        return data['name']?.toString() ?? 'Unknown';
      } catch (e) {
        return 'Unknown';
      }
    }
    
    String getEmail() {
      try {
        return data['email']?.toString() ?? '';
      } catch (e) {
        return '';
      }
    }
    
    String getRole() {
      try {
        return data['role']?.toString() ?? 'student';
      } catch (e) {
        return 'student';
      }
    }
    
    String? getStudentId() {
      try {
        if (data['studentId'] != null) {
          return data['studentId'].toString();
        } else if (data['universityId'] != null) {
          return data['universityId'].toString();
        }
        return null;
      } catch (e) {
        return null;
      }
    }
    
    String? getMobileNumber() {
      try {
        if (data['mobileNumber'] != null) {
          return data['mobileNumber'].toString();
        }
        return null;
      } catch (e) {
        return null;
      }
    }

    return User(
      id: doc.id,
      name: getName(),
      email: getEmail(),
      role: getRole(),
      dateJoined: formattedDate,
      studentId: getStudentId(),
      mobileNumber: getMobileNumber(),
    );
  }
}

class SuperHome extends StatefulWidget {
  final String userId;
  const SuperHome({Key? key, required this.userId}) : super(key: key);

  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<SuperHome> {
  bool isLoading = true;
  String roleFilter = 'all';
  String searchQuery = '';
  int _selectedIndex = 0;

  // Firebase references
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Custom theme colors
  final mainGradient = const LinearGradient(
    colors: [
      Color(0xFF00122D), // Dark blue
      Color(0xFF53E3C6), // Teal
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  final cardGradient = const LinearGradient(
    colors: [
      Color(0xFF001736),
      Color(0xFF002147),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  final Color tealColor = Color(0xFF53E3C6);

  // Get stream of users from Firestore
  Stream<List<User>> getUsersStream() {
    return _firestore
        .collection('users')
        .snapshots()
        .map((snapshot) => 
            snapshot.docs.map((doc) => User.fromFirestore(doc)).toList());
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _selectedIndex == 0 ? _buildHomeContent() : _buildAddUserContent(),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add),
              label: 'Add',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Color(0xFF53E3C6),
          unselectedItemColor: Colors.white,
          backgroundColor:  const Color(0xFF00122D),
          elevation: 0,
          onTap: _onItemTapped,
        ),
      ),
    );
  }

  // Home content (user list)
  Widget _buildHomeContent() {
    return Container(
      decoration: BoxDecoration(gradient: mainGradient),
      child: SafeArea(
        child: Column(
          children: [
            // Custom AppBar
            Container(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Text(
                    'Admin Dashboard',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Spacer(),
                  IconButton(
                    icon: Icon(Icons.refresh, color: Colors.white),
                    onPressed: () {
                      setState(() {});
                    },
                    tooltip: 'Refresh Users',
                  ),
                  IconButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            backgroundColor: Color(0xFF00122D),
                            title: Text('Logout', 
                              style: TextStyle(color: Colors.white)
                            ),
                            content: Text(
                              'Are you sure you want to logout?',
                              style: TextStyle(color: Colors.white70)
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: Text('Cancel', 
                                  style: TextStyle(color: Colors.white70)
                                ),
                              ),
                              TextButton(
                                onPressed: () async {
                                  try {
                                    await FirebaseAuth.instance.signOut();
                                    if (context.mounted) {
                                      Navigator.of(context).pop(); // Close dialog
                                      Navigator.pushReplacementNamed(context, '/loginPage');
                                    }
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Error logging out. Please try again.'),
                                        backgroundColor: Colors.redAccent,
                                      ),
                                    );
                                  }
                                },
                                child: Text('Logout',
                                  style: TextStyle(color: Colors.redAccent)
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    icon: Icon(
                      Icons.logout,
                      color: Colors.white,
                      size: 24,
                    ),
                    tooltip: 'Logout',
                  ),
                ],
              ),
            ),

            // Search and filter section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextField(
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Search by name, email, or student ID...',
                          hintStyle: TextStyle(color: Colors.white70),
                          prefixIcon: Icon(Icons.search, color: Colors.white70),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            searchQuery = value;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: DropdownButton<String>(
                      value: roleFilter,
                      dropdownColor: Color(0xFF00122D),
                      style: TextStyle(color: Colors.white),
                      icon: Icon(Icons.arrow_drop_down, color: Colors.white),
                      underline: SizedBox(),
                      items: [
                        DropdownMenuItem(value: 'all', child: Text('All Roles')),
                        DropdownMenuItem(value: 'student', child: Text('Students')),
                        DropdownMenuItem(value: 'admin', child: Text('Admins')),
                        DropdownMenuItem(value: 'canteen_manager', child: Text('Canteen Managers')),
                        DropdownMenuItem(value: 'cafeteria_manager', child: Text('Cafeteria Managers')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          roleFilter = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Users list with StreamBuilder
            Expanded(
              child: StreamBuilder<List<User>>(
                stream: getUsersStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(tealColor),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.error_outline, color: Colors.white, size: 48),
                          SizedBox(height: 16),
                          Text(
                            'Error loading users',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                          SizedBox(height: 8),
                          Text(
                            snapshot.error.toString(),
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  final users = snapshot.data ?? [];
                  
                  // Apply filters
                  final filteredUsers = users.where((user) {
                    bool matchesSearch = 
                        user.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
                        user.email.toLowerCase().contains(searchQuery.toLowerCase()) ||
                        (user.studentId?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false) ||
                        (user.mobileNumber?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false);
                    
                    bool matchesRole = roleFilter == 'all' || user.role.toLowerCase() == roleFilter.toLowerCase();
                    
                    return matchesSearch && matchesRole;
                  }).toList();

                  if (filteredUsers.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_off, color: Colors.white70, size: 48),
                          SizedBox(height: 16),
                          Text(
                            'No users found',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                          if (roleFilter != 'all' || searchQuery.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                'Try adjusting your search or filter',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: filteredUsers.length,
                    padding: EdgeInsets.all(16),
                    itemBuilder: (context, index) {
                      final user = filteredUsers[index];
                      return Container(
                        margin: EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          gradient: cardGradient,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.all(16),
                          leading: CircleAvatar(
                            backgroundColor: Color(0xFF53E3C6),
                            child: Text(
                              user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                              style: TextStyle(
                                color: Color(0xFF00122D),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            user.name,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.email,
                                style: TextStyle(color: Colors.white70),
                              ),
                              if (user.studentId != null && user.studentId!.isNotEmpty && user.role.toLowerCase() == 'student')
                                Text(
                                  'Student ID: ${user.studentId}',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              if (user.mobileNumber != null && user.mobileNumber!.isNotEmpty)
                                Text(
                                  'Phone: ${user.mobileNumber}',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              Text(
                                'Role: ${_getRoleDisplayName(user.role)}',
                                style: TextStyle(
                                  color: _getRoleColor(user.role),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Joined: ${user.dateJoined}',
                                style: TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit),
                                color: Color(0xFF53E3C6),
                                onPressed: () => _changeUserRole(user),
                                tooltip: 'Change Role',
                              ),
                              IconButton(
                                icon: Icon(Icons.person_remove),
                                color: Colors.redAccent,
                                onPressed: () => _ejectUser(user),
                                tooltip: 'Eject User',
                              ),
                            ],
                          ),
                          isThreeLine: true,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Add user content (signup form)
  Widget _buildAddUserContent() {
    // Controllers for the form fields
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final fullNameController = TextEditingController();
    final phoneController = TextEditingController();

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(gradient: mainGradient),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20.0),
                  child: Text(
                    'Add New Admin',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                
                // Form fields
                const SizedBox(height: 20),
                
                TextField(
                  controller: fullNameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    labelStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  keyboardType: TextInputType.name,
                  style: const TextStyle(color: Colors.white),
                ),
                
                const SizedBox(height: 16),
                
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.white),
                ),
                
                const SizedBox(height: 16),
                
                TextField(
                  controller: passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                ),
                
                const SizedBox(height: 16),
                
                TextField(
                  controller: phoneController,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    labelStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white),
                ),
                
                const SizedBox(height: 30),
                
                // Add user button
                Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      final email = emailController.text.trim();
                      final password = passwordController.text.trim();
                      final name = fullNameController.text.trim();
                      final mobileNumber = phoneController.text.trim();
                
                      // Validate all fields
                      if (email.isEmpty ||
                          password.isEmpty ||
                          name.isEmpty ||
                          mobileNumber.isEmpty) {
                        Fluttertoast.showToast(
                          msg: 'Please fill in all fields.',
                          toastLength: Toast.LENGTH_SHORT,
                          gravity: ToastGravity.BOTTOM,
                          backgroundColor: Colors.redAccent,
                          textColor: Colors.white,
                          fontSize: 14.0,
                        );
                        return;
                      }
                
                      // Validate password length
                      if (password.length < 6) {
                        Fluttertoast.showToast(
                          msg: 'Password must be at least 6 characters long.',
                          toastLength: Toast.LENGTH_SHORT,
                          gravity: ToastGravity.BOTTOM,
                          backgroundColor: Colors.redAccent,
                          textColor: Colors.white,
                        );
                        return;
                      }
                
                      try {
                        // Show loading indicator
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (BuildContext context) {
                            return Dialog(
                              backgroundColor: Colors.transparent,
                              elevation: 0,
                              child: Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(tealColor),
                                ),
                              ),
                            );
                          },
                        );
                
                        // Create user in Firebase Auth
                        final userCredential = await auth.FirebaseAuth.instance.createUserWithEmailAndPassword(
                          email: email,
                          password: password,
                        );
                
                        // If signup is successful, add user details to Firestore with admin role
                        if (userCredential.user != null) {
                          final user = userCredential.user!;
                          final today = DateTime.now().toString().split(' ')[0];
                          
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(user.uid)
                              .set({
                            'name': name,
                            'email': email,
                            'mobileNumber': mobileNumber,
                            'role': 'admin', // Set role to admin
                            'dateJoined': today,
                            'createdAt': FieldValue.serverTimestamp(),
                            'lastUpdated': FieldValue.serverTimestamp(),
                          });
                          
                          // Close loading dialog
                          if (context.mounted) {
                            Navigator.of(context).pop();
                          }
                
                          // Show success message
                          Fluttertoast.showToast(
                            msg: 'Admin user created successfully!',
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.BOTTOM,
                            backgroundColor: Colors.green,
                            textColor: Colors.white,
                          );
                
                          // Clear form fields
                          emailController.clear();
                          passwordController.clear();
                          fullNameController.clear();
                          phoneController.clear();
                
                          // Go back to home tab
                          setState(() {
                            _selectedIndex = 0;
                          });
                        }
                      } catch (e) {
                        // Close loading dialog if it's open
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                        
                        String errorMessage = e.toString();
                        if (errorMessage.contains('email-already-in-use')) {
                          errorMessage = 'This email is already registered';
                        } else if (errorMessage.contains('invalid-email')) {
                          errorMessage = 'Please enter a valid email address';
                        } else if (errorMessage.contains('weak-password')) {
                          errorMessage = 'Password is too weak';
                        }
                        
                        Fluttertoast.showToast(
                          msg: 'Failed to create user: $errorMessage',
                          toastLength: Toast.LENGTH_LONG,
                          gravity: ToastGravity.BOTTOM,
                          backgroundColor: Colors.redAccent,
                          textColor: Colors.white,
                          fontSize: 14.0,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF53E3C6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      'Add Admin User',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Color(0xFFFF5555);
      case 'canteen_manager':
        return Color(0xFF53E3C6);
      case 'cafeteria_manager':
        return Color(0xFF64B5F6);
      case 'student':
        return Color(0xFFE040FB);
      default:
        return Colors.grey;
    }
  }

  String _getRoleDisplayName(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return 'Admin';
      case 'canteen_manager':
        return 'Canteen Manager';
      case 'cafeteria_manager':
        return 'Cafeteria Manager';
      case 'student':
        return 'Student';
      default:
        return role;
    }
  }

  // Ejection dialog with Firestore integration
  Future<void> _ejectUser(User user) async {
    bool confirm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF00122D),
          title: Text('Confirm Ejection', style: TextStyle(color: Colors.white)),
          content: Text(
            'Are you sure you want to eject ${user.name}?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Eject', style: TextStyle(color: Colors.redAccent)),
            ),
          ],
        );
      },
    ) ?? false;

    if (confirm) {
      try {
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(tealColor),
                ),
              ),
            );
          },
        );
        
        // Delete user from Firestore
        await _firestore.collection('users').doc(user.id).delete();
        
        // Close loading dialog
        if (context.mounted) {
          Navigator.of(context).pop();
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${user.name} has been ejected'),
              backgroundColor: Color(0xFF00122D),
            ),
          );
        }
      } catch (e) {
        // Close loading dialog if it's open
        if (context.mounted) {
          Navigator.of(context).pop();
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to eject user: ${e.toString()}'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  // Role change dialog with Firestore integration
  Future<void> _changeUserRole(User user) async {
    String? newRole = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF00122D),
          title: Text('Change Role', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select new role for ${user.name}',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text('Admin', style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.of(context).pop('admin'),
                tileColor: Colors.white.withOpacity(0.1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              SizedBox(height: 8),
              ListTile(
                title: Text('Canteen Manager', style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.of(context).pop('canteen_manager'),
                tileColor: Colors.white.withOpacity(0.1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              SizedBox(height: 8),
              ListTile(
                title: Text('Cafeteria Manager', style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.of(context).pop('cafeteria_manager'),
                tileColor: Colors.white.withOpacity(0.1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              SizedBox(height: 8),
              ListTile(
                title: Text('Student', style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.of(context).pop('student'),
                tileColor: Colors.white.withOpacity(0.1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),],
          ),
        );
      },
    );

    if (newRole != null && newRole.toLowerCase() != user.role.toLowerCase()) {
      try {
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(tealColor),
                ),
              ),
            );
          },
        );
        
        // Update role in Firestore
        await _firestore.collection('users').doc(user.id).update({
          'role': newRole,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
        
        // Close loading dialog
        if (context.mounted) {
          Navigator.of(context).pop();
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${user.name}\'s role has been updated to ${_getRoleDisplayName(newRole)}'),
              backgroundColor: Color(0xFF00122D),
            ),
          );
        }
      } catch (e) {
        // Close loading dialog if it's open
        if (context.mounted) {
          Navigator.of(context).pop();
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update role: ${e.toString()}'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }
}