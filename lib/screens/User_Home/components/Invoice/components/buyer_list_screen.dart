import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_svg/svg.dart';
import '../../../../../utils/app_colors.dart';
import '../../../../../utils/theme_provider.dart';
import 'buyer_details_screen.dart';

class BuyerListScreen extends StatefulWidget {
  final Function(Map<String, dynamic>) onBuyerSelected;

  const BuyerListScreen({
    Key? key,
    required this.onBuyerSelected,
  }) : super(key: key);

  @override
  State<BuyerListScreen> createState() => _BuyerListScreenState();
}

class _BuyerListScreenState extends State<BuyerListScreen> {
  List<Map<String, dynamic>> _buyers = [];
  List<Map<String, dynamic>> _filteredBuyers = [];
  bool _isLoading = true;
  TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _loadBuyers();
  }

  // Get the current user's document ID (email with dots replaced by underscores)
  String get _userDocId {
    if (_auth.currentUser == null) {
      throw Exception('User not authenticated');
    }
    String userEmail = _auth.currentUser!.email!;
    return userEmail.replaceAll('.', '_');
  }

  Future<void> _loadBuyers() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_userDocId)
          .collection('invoice')
          .doc('buyers')
          .collection('items')
          .get();

      final buyers = snapshot.docs.map((doc) => doc.data()).toList();

      setState(() {
        _buyers = buyers;
        _filteredBuyers = buyers;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading buyers: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterBuyers(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredBuyers = _buyers;
      } else {
        _filteredBuyers = _buyers.where((buyer) =>
            buyer['customerName'].toString().toLowerCase().contains(query.toLowerCase())).toList();
      }
    });
  }

  void _createNewBuyer() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BuyerDetailsScreen(
          onSave: (buyer) async {
            // Save to Firebase
            try {
              final id = DateTime.now().millisecondsSinceEpoch.toString();
              final buyerWithId = {...buyer, 'id': id};

              await _firestore
                  .collection('users')
                  .doc(_userDocId)
                  .collection('invoice')
                  .doc('buyers')
                  .collection('items')
                  .doc(id)
                  .set(buyerWithId);

              setState(() {
                _buyers.add(buyerWithId);
                _filteredBuyers = _buyers;
              });

              widget.onBuyerSelected(buyerWithId);
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error saving buyer: $e')),
              );
            }
          },
        ),
      ),
    );
  }

  void _toggleListening() {
    // This function would implement voice recognition functionality
    // For now, just toggle the state for UI changes
    setState(() {
      _isListening = !_isListening;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    // Get theme-specific colors
    final backgroundColor = AppColors.getBackgroundColor(isDarkMode);
    final textColor = AppColors.getTextColor(isDarkMode);
    final secondaryTextColor = AppColors.getSecondaryTextColor(isDarkMode);
    final dividerColor = AppColors.getDividerColor(isDarkMode);
    final iconColor = AppColors.getIconColor(isDarkMode);
    final surfaceColor = AppColors.getSurfaceColor(isDarkMode);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Buyer Details',
          style: TextStyle(color: textColor),
        ),
        backgroundColor: backgroundColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: iconColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _createNewBuyer,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Create New',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.primaryBlue))
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                style: TextStyle(
                  color: AppColors.getTextColor(isDarkMode),
                ),
                decoration: InputDecoration(
                  hintText: 'Search Buyer by Name',
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[500],
                  ),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: SvgPicture.asset(
                      'assets/icons/search_button.svg',
                      width: 20,
                      height: 20,
                      colorFilter: ColorFilter.mode(
                        isDarkMode ? Colors.grey[400]! : Colors.grey[600]!,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_searchController.text.isNotEmpty)
                        IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _filteredBuyers = _buyers;
                            });
                          },
                        ),
                      IconButton(
                        icon: _isListening
                            ? SvgPicture.asset(
                          'assets/icons/microphone open.svg',
                          width: 20,
                          height: 34,
                          colorFilter: ColorFilter.mode(
                            AppColors.primaryBlue,
                            BlendMode.srcIn,
                          ),
                        )
                            : SvgPicture.asset(
                          'assets/icons/microphone close.svg',
                          width: 20,
                          height: 20,
                          colorFilter: ColorFilter.mode(
                            isDarkMode ? Colors.grey[400]! : Colors.grey[600]!,
                            BlendMode.srcIn,
                          ),
                        ),
                        onPressed: _toggleListening,
                      ),
                    ],
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
                onChanged: _filterBuyers,
              ),
            ),
          ),
          Expanded(
            child: _filteredBuyers.isEmpty
                ? Center(
              child: Text(
                'No buyers found',
                style: TextStyle(color: textColor),
              ),
            )
                : ListView.separated(
              itemCount: _filteredBuyers.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: dividerColor,
              ),
              itemBuilder: (context, index) {
                final buyer = _filteredBuyers[index];
                return ListTile(
                  title: Text(
                    buyer['customerName'] ?? 'Unknown',
                    style: TextStyle(color: textColor),
                  ),
                  subtitle: Text(
                    buyer['mobileNumber'] ?? '',
                    style: TextStyle(color: secondaryTextColor),
                  ),
                  tileColor: isDarkMode ? AppColors.darkSurface : AppColors.lightSurface,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          widget.onBuyerSelected(buyer);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('ADD'),
                      ),
                      PopupMenuButton(
                        icon: Icon(Icons.more_vert, color: iconColor),
                        color: isDarkMode ? AppColors.darkSurface : AppColors.lightSurface,
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: Text('Edit', style: TextStyle(color: textColor)),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text('Delete', style: TextStyle(color: textColor)),
                          ),
                        ],
                        onSelected: (value) async {
                          if (value == 'edit') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BuyerDetailsScreen(
                                  initialDetails: buyer,
                                  onSave: (updatedBuyer) async {
                                    try {
                                      final updatedBuyerWithId = {
                                        ...updatedBuyer,
                                        'id': buyer['id'],
                                      };

                                      await _firestore
                                          .collection('users')
                                          .doc(_userDocId)
                                          .collection('invoice')
                                          .doc('buyers')
                                          .collection('items')
                                          .doc(buyer['id'])
                                          .set(updatedBuyerWithId);

                                      setState(() {
                                        final index = _buyers.indexWhere(
                                                (b) => b['id'] == buyer['id']);
                                        if (index >= 0) {
                                          _buyers[index] = updatedBuyerWithId;
                                          _filteredBuyers = _buyers;
                                        }
                                      });

                                      Navigator.pop(context);
                                    } catch (e) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Error updating buyer: $e')),
                                      );
                                    }
                                  },
                                ),
                              ),
                            );
                          } else if (value == 'delete') {
                            // Show delete confirmation
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor: isDarkMode ? AppColors.darkSurface : AppColors.lightSurface,
                                title: Text(
                                  'Delete Buyer',
                                  style: TextStyle(color: textColor),
                                ),
                                content: Text(
                                  'Are you sure you want to delete ${buyer['customerName']}?',
                                  style: TextStyle(color: textColor),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text(
                                      'Cancel',
                                      style: TextStyle(color: AppColors.primaryBlue),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      try {
                                        await _firestore
                                            .collection('users')
                                            .doc(_userDocId)
                                            .collection('invoice')
                                            .doc('buyers')
                                            .collection('items')
                                            .doc(buyer['id'])
                                            .delete();

                                        setState(() {
                                          _buyers.removeWhere((b) => b['id'] == buyer['id']);
                                          _filteredBuyers = _buyers;
                                        });

                                        Navigator.pop(context);
                                      } catch (e) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Error deleting buyer: $e')),
                                        );
                                      }
                                    },
                                    child: Text(
                                      'Delete',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}