// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:nutrinotion_app/providers/auth_provider.dart';
import 'package:nutrinotion_app/providers/mess_provider.dart';
import 'package:nutrinotion_app/providers/user_provider.dart';
import 'package:nutrinotion_app/core/custom_colors.dart';
import 'package:nutrinotion_app/core/page_transitions.dart';
import 'package:nutrinotion_app/views/auth/login_page.dart';
import '../../models/personalized_meal_item.dart';
import '../../providers/personalized_food_provider.dart';
import '../profile/profile_page_new.dart';
import '../analytics/analytics_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Current day of the week
  final currentDay = DateFormat('EEEE').format(DateTime.now());

  // Check if it's past meal time
  bool _isMealTimePassed(String mealType) {
    final now = DateTime.now().hour;
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return now >= 11; // After 11 AM
      case 'lunch':
        return now >= 15; // After 3 PM
      case 'snacks':
        return now >= 17; // After 5 PM
      case 'dinner':
        return now >= 22; // After 10 PM
      default:
        return false;
    }
  }

  // Check if it's a future meal (before its designated time)
  bool _isFutureMeal(String mealType) {
    final now = DateTime.now().hour;
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return now < 6; // Before 6 AM
      case 'lunch':
        return now < 12; // Before 12 PM
      case 'snacks':
        return now < 16; // Before 4 PM
      case 'dinner':
        return now < 18; // Before 6 PM
      default:
        return false;
    }
  }

  // Get appropriate icon for food items
  IconData _getFoodIcon(String foodName) {
    final name = foodName.toLowerCase();
    if (name.contains('rice') ||
        name.contains('biryani') ||
        name.contains('dal')) {
      return Icons.rice_bowl;
    } else if (name.contains('roti') ||
        name.contains('paratha') ||
        name.contains('bread')) {
      return Icons.bakery_dining;
    } else if (name.contains('curry') ||
        name.contains('sabzi') ||
        name.contains('sambar')) {
      return Icons.soup_kitchen;
    } else if (name.contains('chai') ||
        name.contains('tea') ||
        name.contains('coffee')) {
      return Icons.local_cafe;
    } else if (name.contains('samosa') ||
        name.contains('pakora') ||
        name.contains('puri')) {
      return Icons.fastfood;
    } else if (name.contains('idli') ||
        name.contains('upma') ||
        name.contains('poha')) {
      return Icons.breakfast_dining;
    } else if (name.contains('paneer') ||
        name.contains('chicken') ||
        name.contains('egg') ||
        name.contains('fish')) {
      return Icons.dinner_dining;
    } else {
      return Icons.restaurant;
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final mealProvider =
          Provider.of<PersonalizedMealProvider>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      // Load today's mess menu
      Provider.of<MessProvider>(context, listen: false).loadTodayMenu();

      // Load user data
      if (authProvider.userId != null) {
        await userProvider.loadFromFirestore(authProvider.userId!);
      }

      // Load today's personalized meals + calorie summary concurrently
      await mealProvider.loadTodayData(authProvider.userId ?? '');
    });
  }

  @override
  Widget build(BuildContext context) {
    final mealProvider = Provider.of<PersonalizedMealProvider>(context);
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color.fromARGB(255, 255, 251, 247),
      drawer: _buildSidebar(context),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Welcome Section
            _buildWelcomeSection(),
            SizedBox(height: 16),

            // Main Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Daily Progress (moved to top)
                  _buildTotalCaloriesSummary(),

                  const SizedBox(height: 20),

                  // Health Tip
                  _buildHealthTip(),

                  SizedBox(height: 20),

                  // Quick Analytics Access
                  _buildQuickAnalyticsCard(),

                  SizedBox(height: 20),

                  // View Full Menu Button (moved to top)
                  _buildViewFullMenuButton(),

                  const SizedBox(height: 24),

                  // Meal Plan Title
                  Text(
                    'Today\'s Personalized Meal Plan',
                    style: GoogleFonts.lato(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 24),

                  mealProvider.isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                          color: primaryColor,
                          strokeWidth: 2.5,
                        ))
                      : mealProvider.errorMessage != null
                          ? Center(child: Text(mealProvider.errorMessage!))
                          : mealProvider.mealsByType.isNotEmpty
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    for (final mealType
                                        in mealProvider.orderedMealTypes) ...[
                                      _buildMealSection(
                                        mealType,
                                        mealProvider.mealsByType[mealType]!,
                                      ),
                                      const SizedBox(height: 20),
                                    ],
                                  ],
                                )
                              : _buildPersonalizedMenuCookingMessage(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              primaryColor,
              primaryColor.withOpacity(0.8),
            ],
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Consumer2<AuthProvider, UserProvider>(
              builder: (context, authProvider, userProvider, child) {
                return DrawerHeader(
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white,
                        child: Text(
                          authProvider.userDisplayName?.substring(0, 1) ?? 'U',
                          style: GoogleFonts.lato(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        authProvider.userDisplayName ?? 'User',
                        style: GoogleFonts.lato(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        authProvider.userEmail ?? '',
                        style: GoogleFonts.lato(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            _buildDrawerItem(
              icon: Icons.home,
              title: 'Home',
              onTap: () => Navigator.pop(context),
            ),
            _buildDrawerItem(
              icon: Icons.person,
              title: 'Profile',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfilePage(),
                  ),
                );
              },
            ),
            _buildDrawerItem(
              icon: Icons.analytics,
              title: 'Analytics',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AnalyticsPage(),
                  ),
                );
              },
            ),
            const Divider(color: Colors.white30),
            _buildDrawerItem(
              icon: Icons.logout,
              title: 'Logout',
              onTap: () {
                Navigator.pop(context);
                _showLogoutDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(
        title,
        style: GoogleFonts.lato(
          color: Colors.white,
          fontSize: 16,
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 40, 0, 0),
      decoration: BoxDecoration(
        color: Colors.grey[50],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top header with menu and app title
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            spacing: 6,
            children: [
              IconButton(
                icon: const Icon(Icons.menu,
                    color: Color.fromARGB(255, 31, 31, 31)),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
              Text(
                'NutriNotion',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: const Color.fromARGB(255, 54, 54, 54),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMealSection(String mealType, List<PersonalizedMealItem> items) {
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.no_meals,
                color: Colors.grey[600],
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'No items available for $mealType',
              style: GoogleFonts.lato(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    int totalCalories = items.fold(0, (sum, item) => sum + item.calories);
    bool isTimePassed = _isMealTimePassed(mealType);
    bool isFutureMeal = _isFutureMeal(mealType);

    bool allItemsCompleted = items.every((item) => item.isChecked);
    int completedCount = items.where((item) => item.isChecked).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Meal type header with + icon
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  mealType.toUpperCase(),
                  style: GoogleFonts.lato(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: allItemsCompleted
                          ? Colors.grey
                          : const Color.fromARGB(255, 27, 27, 27),
                      letterSpacing: 1.2),
                ),
                if (completedCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: allItemsCompleted ? Colors.green : Colors.orange,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$completedCount/${items.length}',
                      style: GoogleFonts.lato(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            Row(
              children: [
                GestureDetector(
                  onTap: () => _showFullMenuDialog(),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.add,
                      color: primaryColor,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (allItemsCompleted)
                  Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 24,
                  )
                else if (isFutureMeal)
                  Icon(
                    Icons.schedule,
                    color: Colors.blue[400],
                    size: 20,
                  )
                else if (isTimePassed)
                  Icon(
                    Icons.access_time_filled,
                    color: Colors.grey,
                    size: 20,
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Meal items
        ...items.map((item) {
          final mealProvider =
              Provider.of<PersonalizedMealProvider>(context, listen: false);
          final isItemCompleted = item.isChecked;
          final isToggling = mealProvider.isToggling(item.id);
          final shouldBeGrayedOut = isItemCompleted || isTimePassed;
          // Toggle requires a backend item ID (PUT /item/{id}/check)
          final canToggle = !isFutureMeal && item.id != null;

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: shouldBeGrayedOut ? Colors.grey[100] : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: shouldBeGrayedOut
                      ? Colors.grey.shade300
                      : Colors.grey.shade200),
              boxShadow: shouldBeGrayedOut
                  ? []
                  : [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: shouldBeGrayedOut
                        ? Colors.grey.withOpacity(0.3)
                        : primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isFutureMeal ? Icons.schedule : Icons.restaurant,
                    color: shouldBeGrayedOut ? Colors.grey : primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.foodName,
                        style: GoogleFonts.lato(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: shouldBeGrayedOut
                              ? Colors.grey[600]
                              : Colors.black87,
                          decoration: isItemCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '${item.quantity.isNotEmpty ? '${item.quantity} \u2022 ' : ''}${item.calories} kcal',
                            style: GoogleFonts.lato(
                              fontSize: 12,
                              color: shouldBeGrayedOut
                                  ? Colors.grey[500]
                                  : Colors.grey[600],
                              decoration: isItemCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          if (isFutureMeal) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: Colors.blue.withOpacity(0.3),
                                  width: 0.5,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.schedule,
                                    size: 10,
                                    color: Colors.blue[600],
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    'Soon',
                                    style: GoogleFonts.lato(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blue[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                if (canToggle)
                  Tooltip(
                    message: isItemCompleted
                        ? 'Mark as incomplete'
                        : 'Mark as completed',
                    child: GestureDetector(
                      onTap:
                          isToggling ? null : () => _toggleItemCompletion(item),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isTimePassed
                              ? (isItemCompleted
                                  ? Colors.grey.withAlpha(40)
                                  : Colors.grey.withAlpha(20))
                              : (isItemCompleted
                                  ? Colors.orange.withOpacity(0.1)
                                  : Colors.green.withOpacity(0.1)),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isTimePassed
                                ? (isItemCompleted
                                    ? Colors.grey.withOpacity(0.4)
                                    : Colors.grey.withOpacity(0.3))
                                : (isItemCompleted
                                    ? Colors.orange.withOpacity(0.3)
                                    : Colors.green.withOpacity(0.3)),
                            width: 1,
                          ),
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: isToggling
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    key: ValueKey(
                                        'loading_${item.id ?? item.foodName}'),
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      isTimePassed
                                          ? Colors.grey[500]!
                                          : primaryColor,
                                    ),
                                  ),
                                )
                              : Icon(
                                  isItemCompleted ? Icons.close : Icons.check,
                                  key: ValueKey(isItemCompleted),
                                  color: isTimePassed
                                      ? (isItemCompleted
                                          ? Colors.grey[600]
                                          : Colors.grey[500])
                                      : (isItemCompleted
                                          ? Colors.orange
                                          : Colors.green),
                                  size: 20,
                                ),
                        ),
                      ),
                    ),
                  )
                else if (isFutureMeal)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.blue.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.schedule,
                      color: Colors.blue[400],
                      size: 20,
                    ),
                  ),
              ],
            ),
          );
        }),

        // Total calories for this meal
        Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: allItemsCompleted || isTimePassed
                ? LinearGradient(
                    colors: [
                      Colors.grey.withOpacity(0.2),
                      Colors.grey.withOpacity(0.1)
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : LinearGradient(
                    colors: [
                      primaryColor.withOpacity(0.1),
                      primaryColor.withOpacity(0.05)
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: allItemsCompleted || isTimePassed
                    ? Colors.grey.withOpacity(0.5)
                    : primaryColor.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$mealType Total:',
                style: GoogleFonts.lato(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: allItemsCompleted || isTimePassed
                      ? Colors.grey[600]
                      : primaryColor,
                  decoration:
                      allItemsCompleted ? TextDecoration.lineThrough : null,
                ),
              ),
              Text(
                '$totalCalories kcal',
                style: GoogleFonts.lato(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: allItemsCompleted || isTimePassed
                      ? Colors.grey[600]
                      : primaryColor,
                  decoration:
                      allItemsCompleted ? TextDecoration.lineThrough : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTotalCaloriesSummary() {
    final mealProvider = Provider.of<PersonalizedMealProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final summary = mealProvider.calorieSummary;
    final totalCalories = summary?.consumedCalories ?? 0;
    final targetCalories = summary?.targetCalories ??
        userProvider.user.calorieTargetPerDay ??
        1800;
    final remainingCalories = summary?.remainingCalories ??
        (targetCalories - totalCalories).clamp(0, targetCalories);
    final double progress =
        targetCalories > 0 ? totalCalories / targetCalories : 0.0;

    // Calculate status color
    Color statusColor;
    String statusText;
    if (progress >= 1.2) {
      statusColor = Colors.red;
      statusText = 'Exceeded Target';
    } else if (progress >= 1.0) {
      statusColor = Colors.orange;
      statusText = 'Target Reached';
    } else if (progress >= 0.8) {
      statusColor = Colors.green;
      statusText = 'Almost There';
    } else {
      statusColor = Colors.white;
      statusText = 'In Progress';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, primaryColor.withOpacity(0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daily Progress',
                    style: GoogleFonts.lato(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Today\'s Calorie Intake',
                    style: GoogleFonts.lato(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: statusColor.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Text(
                  statusText,
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$totalCalories',
                    style: GoogleFonts.lato(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'of $targetCalories kcal',
                    style: GoogleFonts.lato(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    remainingCalories > 0 ? '$remainingCalories' : '0',
                    style: GoogleFonts.lato(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'kcal remaining',
                    style: GoogleFonts.lato(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Stack(
            children: [
              // Background progress bar
              Container(
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 0.5,
                  ),
                ),
              ),
              // Foreground progress bar
              FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progress > 1.0 ? 1.0 : progress,
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        statusColor,
                        statusColor.withOpacity(0.8),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(5),
                    boxShadow: [
                      BoxShadow(
                        color: statusColor.withOpacity(0.4),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${(progress * 100).toInt()}% of daily target',
            style: GoogleFonts.lato(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewFullMenuButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryColor, width: 2),
      ),
      child: ElevatedButton(
        onPressed: () {
          _showFullMenuDialog();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: primaryColor,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_menu,
              color: primaryColor,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              'View Today\'s Full Mess Menu',
              style: GoogleFonts.lato(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleItemCompletion(PersonalizedMealItem item) async {
    if (!mounted) return;
    final mealProvider =
        Provider.of<PersonalizedMealProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.userId == null) return;

    final newChecked = !item.isChecked;
    await mealProvider.toggleItem(authProvider.userId!, item);

    if (!mounted) return;
    if (mealProvider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mealProvider.errorMessage!),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                newChecked ? Icons.check_circle : Icons.remove_circle,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  newChecked
                      ? '${item.foodName} marked as completed!'
                      : '${item.foodName} marked as incomplete!',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: newChecked ? Colors.green : Colors.orange,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Widget _buildHealthTip() {
    final mealProvider = Provider.of<PersonalizedMealProvider>(context);
    final tip = mealProvider.nutritionTip ??
        'Stay hydrated! Drink 8-10 glasses of water daily to boost metabolism and aid digestion.';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.lightbulb_outline,
              color: primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nutrition Tip',
                  style: GoogleFonts.lato(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  tip,
                  style: GoogleFonts.lato(
                    fontSize: 13,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAnalyticsCard() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AnalyticsPage(),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.analytics_outlined,
                color: primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'View Analytics',
                    style: GoogleFonts.lato(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Track your daily progress and streaks',
                    style: GoogleFonts.lato(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey[400],
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalizedMenuCookingMessage() {
    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryColor.withOpacity(0.05),
            primaryColor.withOpacity(0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: primaryColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Animated cooking icon
          Container(
            height: 80,
            width: 80,
            alignment: Alignment.center,
            decoration:
                BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: Text(
              '',
              style: TextStyle(fontSize: 50),
            ),
          ),

          const SizedBox(height: 24),

          // Main message
          Text(
            '🍳 Your Personalized Meal is Being Cooked!',
            style: GoogleFonts.lato(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 12),

          // Subtitle
          Text(
            'Our nutrition experts are preparing a customized meal plan just for you based on your preferences and goals.',
            style: GoogleFonts.lato(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          // Progress indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ...List.generate(3, (index) {
                return TweenAnimationBuilder(
                  duration: Duration(milliseconds: 600 + (index * 200)),
                  tween: Tween<double>(begin: 0.3, end: 1.0),
                  builder: (context, double value, child) {
                    return AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(value),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  },
                );
              }),
            ],
          ),

          const SizedBox(height: 20),

          // Action hint
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.blue.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Colors.blue[600],
                ),
                const SizedBox(width: 8),
                Text(
                  'This usually takes a few moments',
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    color: Colors.blue[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFullMenuDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Today\'s Full Mess Menu',
                      style: GoogleFonts.lato(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      color: Colors.grey[600],
                    ),
                  ],
                ),
              ),
              // Tab bar and content
              Expanded(
                child: DefaultTabController(
                  length: 4,
                  child: Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: TabBar(
                          labelColor: Colors.white,
                          unselectedLabelColor: Colors.grey[600],
                          indicator: BoxDecoration(
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          indicatorPadding: const EdgeInsets.all(2),
                          labelStyle: GoogleFonts.lato(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          unselectedLabelStyle: GoogleFonts.lato(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          indicatorSize: TabBarIndicatorSize.tab,
                          dividerColor: Colors.transparent,
                          tabs: const [
                            Tab(
                              height: 44,
                              text: 'Breakfast',
                            ),
                            Tab(
                              height: 44,
                              text: 'Lunch',
                            ),
                            Tab(
                              height: 44,
                              text: 'Snacks',
                            ),
                            Tab(
                              height: 44,
                              text: 'Dinner',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _buildMenuList('Breakfast', scrollController),
                            _buildMenuList('Lunch', scrollController),
                            _buildMenuList('Snacks', scrollController),
                            _buildMenuList('Dinner', scrollController),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuList(String mealType, [ScrollController? scrollController]) {
    return Consumer<MessProvider>(
      builder: (context, messProvider, _) {
        if (messProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (messProvider.errorMessage != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Failed to load menu',
                  style:
                      GoogleFonts.lato(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  messProvider.errorMessage!,
                  style:
                      GoogleFonts.lato(fontSize: 12, color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => messProvider.loadTodayMenu(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Retry', style: GoogleFonts.lato()),
                ),
              ],
            ),
          );
        }

        if (messProvider.menuData == null) {
          return Center(
            child: Text(
              'Menu not available',
              style: GoogleFonts.lato(fontSize: 16, color: Colors.grey[600]),
            ),
          );
        }

        final menuData = messProvider.menuData!;
        // Backend returns comma-separated strings, e.g. "Masala Dosa,Chutney"
        final raw = menuData[mealType.toLowerCase()];
        final List<String> itemNames = raw == null
            ? []
            : raw is List
                ? List<String>.from(raw)
                : raw
                    .toString()
                    .split(',')
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .toList();
        final itemsRaw = itemNames;

        if (itemsRaw.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.restaurant_outlined,
                    size: 48, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No items available for $mealType',
                  style:
                      GoogleFonts.lato(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        // Map each string item name into a display card model
        final List<Map<String, dynamic>> menuItems =
            itemsRaw.map<Map<String, dynamic>>((name) {
          final isVeg = !name.toLowerCase().contains('chicken') &&
              !name.toLowerCase().contains('fish') &&
              !name.toLowerCase().contains('egg') &&
              !name.toLowerCase().contains('mutton');
          return {
            'name': name,
            'description': 'Freshly prepared $name',
            'calories': 200,
            'isVegetarian': isVeg,
            'category': 'Indian',
          };
        }).toList();

        return ListView.builder(
          controller: scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: menuItems.length,
          itemBuilder: (context, index) {
            final item = menuItems[index];

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Food icon
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            primaryColor.withOpacity(0.1),
                            primaryColor.withOpacity(0.05)
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        _getFoodIcon(item['name'] as String? ?? ''),
                        color: primaryColor,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Food details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item['name'] as String? ?? 'Unknown Item',
                                  style: GoogleFonts.lato(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item['description'] as String? ??
                                'No description available',
                            style: GoogleFonts.lato(
                              fontSize: 13,
                              color: Colors.grey[600],
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),

                          // Calories and category badges
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${item['calories'] ?? 0} kcal',
                                  style: GoogleFonts.lato(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: primaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Add button
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.add,
                            color: Colors.white, size: 20),
                        onPressed: () {
                          final itemToAdd = {
                            'item': item['name'] as String? ?? 'Unknown Item',
                            'calories': item['calories'] as int? ?? 0,
                            'description': item['description'] as String? ??
                                'No description available',
                          };
                          Navigator.pop(context);
                          print(itemToAdd);
                          _addToNutritionTracker(itemToAdd);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _addToNutritionTracker(Map<String, dynamic> item) async {
    final mealProvider =
        Provider.of<PersonalizedMealProvider>(context, listen: false);

    // Show dialog to let user choose meal type
    final String? selectedMealType = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Add to Meal Plan',
            style: GoogleFonts.lato(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select which meal you want to add "${item['item']}" to:',
                style: GoogleFonts.lato(),
              ),
              const SizedBox(height: 16),
              ...['Breakfast', 'Lunch', 'Snacks', 'Dinner'].map((mealType) {
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(mealType),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: primaryColor,
                      side: BorderSide(color: primaryColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        mealType,
                        style: GoogleFonts.lato(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.lato(color: Colors.grey),
              ),
            ),
          ],
        );
      },
    );

    if (selectedMealType == null) return; // User cancelled

    try {
      mealProvider.addItemLocally(
        selectedMealType,
        PersonalizedMealItem(
          foodName: item['item'] as String? ?? '',
          quantity: '1 serving',
          calories: item['calories'] as int? ?? 0,
          mealType: selectedMealType,
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item['item']} added to your $selectedMealType!'),
          backgroundColor: primaryColor,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add item: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Logout',
          style: GoogleFonts.lato(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: GoogleFonts.lato(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.lato(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              final authProvider =
                  Provider.of<AuthProvider>(context, listen: false);
              authProvider.signOut().then((_) {
                context.pushReplacementFade(const LoginPage(), duration: 600);
              });
            },
            child: Text(
              'Logout',
              style: GoogleFonts.lato(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
