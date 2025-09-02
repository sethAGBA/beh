import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String _selectedRole = 'user';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    // Animation setup
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameController.dispose();
    _firstNameController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  String? _validateName(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'Veuillez saisir votre $fieldName';
    }
    if (value.trim().length < 2) {
      return '$fieldName doit contenir au moins 2 caractères';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez saisir votre email';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Veuillez saisir un email valide';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez saisir un mot de passe';
    }
    if (value.length < 8) {
      return 'Le mot de passe doit contenir au moins 8 caractères';
    }
    if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(value)) {
      return 'Le mot de passe doit contenir au moins une majuscule, une minuscule et un chiffre';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez confirmer votre mot de passe';
    }
    if (value != _passwordController.text) {
      return 'Les mots de passe ne correspondent pas';
    }
    return null;
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_amber_outlined, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text('Veuillez accepter les conditions d\'utilisation')),
            ],
          ),
          backgroundColor: Colors.orange[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Store user data in Cloud Firestore
      if (userCredential.user != null) {
        final uid = userCredential.user!.uid;
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .set({
          'fullName': _fullNameController.text.trim(),
          'firstName': _firstNameController.text.trim(),
          'email': _emailController.text.trim(),
          'role': _selectedRole,
          'createdAt': Timestamp.now(),
        });

        // If role is admin, keep admins collection in sync
        if (_selectedRole == 'admin') {
          await FirebaseFirestore.instance.collection('admins').doc(uid).set({
            'email': _emailController.text.trim(),
            'createdAt': Timestamp.now(),
            'createdBy': uid,
          });
        }

        // Update user profile
        await userCredential.user!.updateDisplayName(
          '${_firstNameController.text.trim()} ${_fullNameController.text.trim()}',
        );
      }

      // Sign out the user immediately after registration
      await FirebaseAuth.instance.signOut();

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.white),
                SizedBox(width: 8),
                Expanded(child: Text('Compte créé avec succès ! Veuillez vous connecter.')),
              ],
            ),
            backgroundColor: Colors.green[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
          ),
        );

        // Navigate to sign-in page with pre-filled info
        context.go(
          '/signin',
          extra: {
            'email': _emailController.text.trim(),
            'password': _passwordController.text.trim(),
          },
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String errorMessage;
        switch (e.code) {
          case 'weak-password':
            errorMessage = 'Le mot de passe est trop faible';
            break;
          case 'email-already-in-use':
            errorMessage = 'Un compte existe déjà avec cet email';
            break;
          case 'invalid-email':
            errorMessage = 'Adresse email invalide';
            break;
          case 'operation-not-allowed':
            errorMessage = 'Opération non autorisée';
            break;
          default:
            errorMessage = e.message ?? 'Une erreur est survenue';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text(errorMessage)),
              ],
            ),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } on FirebaseException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text(e.message ?? 'Une erreur Firestore est survenue')),
              ],
            ),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required String? Function(String?) validator,
    bool obscureText = false,
    bool hasVisibilityToggle = false,
    VoidCallback? onVisibilityToggle,
    bool? obscureValue,
    TextInputType? keyboardType,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        validator: validator,
        obscureText: obscureText,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: colorScheme.primary),
          ),
          suffixIcon: hasVisibilityToggle
              ? IconButton(
                  onPressed: onVisibilityToggle,
                  icon: Icon(
                    obscureValue == true
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: Colors.grey[600],
                  ),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary.withOpacity(0.1),
              colorScheme.secondary.withOpacity(0.05),
              Colors.white,
            ],
            stops: const [0.0, 0.3, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 20),
                        
                        // Logo/Icon avec animation
                        Hero(
                          tag: 'app_logo',
                          child: Container(
                            height: 100,
                            width: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: colorScheme.primary.withOpacity(0.2),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                              image: const DecorationImage(
                                image: AssetImage('assets/icon/icon.png'),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Titre et sous-titre
                        Text(
                          'Créer un compte',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Rejoignez-nous pour commencer',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Champs de saisie
                        _buildInputField(
                          controller: _firstNameController,
                          label: 'Prénom',
                          hint: 'Jean',
                          icon: Icons.person_outline,
                          validator: (value) => _validateName(value, 'prénom'),
                        ),
                        const SizedBox(height: 16),

                        // Role selection
                        DropdownButtonFormField<String>(
                          value: _selectedRole,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'user', child: Text('Utilisateur')), 
                            DropdownMenuItem(value: 'vendor', child: Text('Prestataire')),
                            DropdownMenuItem(value: 'admin', child: Text('Administrateur')),
                          ],
                          onChanged: (v) => setState(() => _selectedRole = v ?? 'user'),
                        ),
                        const SizedBox(height: 16),

                        _buildInputField(
                          controller: _fullNameController,
                          label: 'Nom de famille',
                          hint: 'doe',
                          icon: Icons.person_outline,
                          validator: (value) => _validateName(value, 'nom de famille'),
                        ),
                        const SizedBox(height: 16),

                        _buildInputField(
                          controller: _emailController,
                          label: 'Email',
                          hint: 'jean.doe@email.com',
                          icon: Icons.email_outlined,
                          validator: _validateEmail,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),

                        _buildInputField(
                          controller: _passwordController,
                          label: 'Mot de passe',
                          hint: '••••••••',
                          icon: Icons.lock_outline,
                          validator: _validatePassword,
                          obscureText: _obscurePassword,
                          hasVisibilityToggle: true,
                          obscureValue: _obscurePassword,
                          onVisibilityToggle: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        const SizedBox(height: 16),

                        _buildInputField(
                          controller: _confirmPasswordController,
                          label: 'Confirmer le mot de passe',
                          hint: '••••••••',
                          icon: Icons.lock_outline,
                          validator: _validateConfirmPassword,
                          obscureText: _obscureConfirmPassword,
                          hasVisibilityToggle: true,
                          obscureValue: _obscureConfirmPassword,
                          onVisibilityToggle: () {
                            setState(() {
                              _obscureConfirmPassword = !_obscureConfirmPassword;
                            });
                          },
                        ),
                        const SizedBox(height: 24),

                        // Conditions d'utilisation
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey[200]!,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Checkbox(
                                value: _acceptTerms,
                                onChanged: (value) {
                                  setState(() {
                                    _acceptTerms = value ?? false;
                                  });
                                },
                                activeColor: colorScheme.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: RichText(
                                    text: TextSpan(
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: Colors.grey[700],
                                      ),
                                      children: [
                                        const TextSpan(text: 'J\'accepte les '),
                                        TextSpan(
                                          text: 'conditions d\'utilisation',
                                          style: TextStyle(
                                            color: colorScheme.primary,
                                            fontWeight: FontWeight.w600,
                                            decoration: TextDecoration.underline,
                                          ),
                                        ),
                                        const TextSpan(text: ' et la '),
                                        TextSpan(
                                          text: 'politique de confidentialité',
                                          style: TextStyle(
                                            color: colorScheme.primary,
                                            fontWeight: FontWeight.w600,
                                            decoration: TextDecoration.underline,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Bouton d'inscription
                        Container(
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                colorScheme.primary,
                                colorScheme.secondary,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: colorScheme.primary.withOpacity(0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _signUp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Créer mon compte',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Divider avec "OU"
                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: Colors.grey[300],
                                thickness: 1,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'OU',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: Colors.grey[300],
                                thickness: 1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Lien de connexion
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.grey[200]!,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Vous avez déjà un compte ? ",
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                              GestureDetector(
                                onTap: () => context.go('/signin'),
                                child: Text(
                                  'Se connecter',
                                  style: TextStyle(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}