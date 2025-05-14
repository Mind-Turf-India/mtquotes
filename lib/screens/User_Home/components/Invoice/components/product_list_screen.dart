import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import '../../../../../utils/app_colors.dart';
import '../../../../../utils/theme_provider.dart';
import 'product_details_screen.dart';
import '../invoice_model.dart';

class ProductListScreen extends StatefulWidget {
  final Function(ProductModel) onProductSelected;

  const ProductListScreen({
    Key? key,
    required this.onProductSelected,
  }) : super(key: key);

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  List<ProductModel> _products = [];
  bool _isLoading = true;
  TextEditingController _searchController = TextEditingController();
  List<ProductModel> _filteredProducts = [];
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final products = await _firebaseService.getAllProducts();
      setState(() {
        _products = products;
        _filteredProducts = products;
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading products: $e')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterProducts(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredProducts = _products;
      } else {
        _filteredProducts = _products.where((product) =>
            product.name.toLowerCase().contains(query.toLowerCase())).toList();
      }
    });
  }

  void _createNewProduct() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailScreen(
          onSave: (product) {
            // Add to list and select it
            setState(() {
              _products.add(product);
              _filteredProducts = _products;
            });
            widget.onProductSelected(product);
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
          'Product Details',
          style: TextStyle(color: textColor),
        ),
        backgroundColor: backgroundColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: iconColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _createNewProduct,
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
                  hintText: 'Search Product by Name',
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
                              _filteredProducts = _products;
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
                onChanged: _filterProducts,
              ),
            ),
          ),
          Expanded(
            child: _filteredProducts.isEmpty
                ? Center(
              child: Text(
                'No products found',
                style: TextStyle(color: textColor),
              ),
            )
                : ListView.separated(
              itemCount: _filteredProducts.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: dividerColor,
              ),
              itemBuilder: (context, index) {
                final product = _filteredProducts[index];
                return ListTile(
                  title: Text(
                    product.name,
                    style: TextStyle(color: textColor),
                  ),
                  subtitle: Text(
                    '₹${product.salePrice}/${product.unit}',
                    style: TextStyle(color: secondaryTextColor),
                  ),
                  tileColor: surfaceColor,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          widget.onProductSelected(product);
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
                        color: surfaceColor,
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
                        onSelected: (value) {
                          if (value == 'edit') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProductDetailScreen(
                                  product: product,
                                  onSave: (updatedProduct) {
                                    setState(() {
                                      final index = _products.indexWhere(
                                              (p) => p.id == updatedProduct.id);
                                      if (index >= 0) {
                                        _products[index] = updatedProduct;
                                        _filteredProducts = _products;
                                      }
                                    });
                                    Navigator.pop(context);
                                  },
                                ),
                              ),
                            );
                          } else if (value == 'delete') {
                            // Show delete confirmation
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor: surfaceColor,
                                title: Text(
                                  'Delete Product',
                                  style: TextStyle(color: textColor),
                                ),
                                content: Text(
                                  'Are you sure you want to delete ${product.name}?',
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
                                        await _firebaseService.deleteProduct(product.id);
                                        setState(() {
                                          _products.removeWhere((p) => p.id == product.id);
                                          _filteredProducts = _products;
                                        });
                                        Navigator.pop(context);
                                      } catch (e) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Error deleting product: $e')),
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