import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buyer Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _createNewBuyer,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue,
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
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: _filterBuyers,
              decoration: InputDecoration(
                hintText: 'Search Buyer by Name',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          Expanded(
            child: _filteredBuyers.isEmpty
                ? const Center(child: Text('No buyers found'))
                : ListView.separated(
              itemCount: _filteredBuyers.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final buyer = _filteredBuyers[index];
                return ListTile(
                  title: Text(buyer['customerName'] ?? 'Unknown'),
                  subtitle: Text(buyer['mobileNumber'] ?? ''),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          widget.onBuyerSelected(buyer);
                          Navigator.pop(context);
                        },
                        child: const Text('ADD'),
                      ),
                      PopupMenuButton(
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text('Edit'),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Delete'),
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
                                title:  Text('Delete Buyer', style: TextStyle(color: isDarkMode ? AppColors.darkText : AppColors.lightText)),
                                content: Text('Are you sure you want to delete ${buyer['customerName']}?', style: TextStyle(color: isDarkMode ? AppColors.darkText : AppColors.lightText)),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Cancel'),
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
                                    child: const Text('Delete'),
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