import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../../../../utils/app_colors.dart';
import '../../../../../utils/theme_provider.dart';
import '../invoice_model.dart';

class ProductDetailScreen extends StatefulWidget {
  final ProductModel? product; // Can be null for a new product
  final Function(ProductModel)? onSave; // Optional callback for manual handling

  const ProductDetailScreen({
    Key? key,
    this.product,
    this.onSave,
  }) : super(key: key);

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _hsnController = TextEditingController();
  final TextEditingController _salePriceController = TextEditingController();
  final TextEditingController _unitController = TextEditingController();
  final TextEditingController _gstRateController = TextEditingController();
  final TextEditingController _cessRateController = TextEditingController();
  final TextEditingController _purchasePriceController =
      TextEditingController();
  final TextEditingController _wholesalePriceController =
      TextEditingController();
  final TextEditingController _minWholesaleQtyController =
      TextEditingController();
  final TextEditingController _openingStockController = TextEditingController();
  final TextEditingController _openingStockUnitController =
      TextEditingController();
  final TextEditingController _openingStockDateController =
      TextEditingController();
  final TextEditingController _lowStockAlertController =
      TextEditingController();
  final TextEditingController _barcodeController = TextEditingController();

  String _itemType = 'Goods';
  bool _isTaxInclusive = false;
  String _gstType = 'GST @ 0';
  String _cessType = '% Percent Wise';
  String _gstTreatment = 'Exclusive GST';
  bool _maintainStock = false;
  DateTime _openingStockDate = DateTime.now();

  final FirebaseService _firebaseService = FirebaseService();
  bool _isLoading = false;

  // Tab state
  int _currentTab = 0; // 0 for Basic Details, 1 for Optional Details

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      // Fill in the controllers with existing product data
      _nameController.text = widget.product!.name;
      _descriptionController.text = widget.product!.description;
      _hsnController.text = widget.product!.hsn;
      _salePriceController.text = widget.product!.salePrice.toString();
      _unitController.text = widget.product!.unit;
      _itemType = widget.product!.itemType;
      _isTaxInclusive = widget.product!.isTaxInclusive;
      _gstRateController.text = widget.product!.gstRate.toString();
      _gstType = widget.product!.gstType;
      _cessRateController.text = widget.product!.cessRate.toString();
      _cessType = widget.product!.cessType;
      _purchasePriceController.text = widget.product!.purchasePrice.toString();
      _gstTreatment = widget.product!.gstTreatment;
      _wholesalePriceController.text =
          widget.product!.wholesalePrice.toString();
      _minWholesaleQtyController.text =
          widget.product!.minWholesaleQty.toString();
      _maintainStock = widget.product!.maintainStock;
      _openingStockController.text = widget.product!.openingStock.toString();
      _openingStockUnitController.text = widget.product!.openingStockUnit;
      _openingStockDate = widget.product!.openingStockDate;
      _openingStockDateController.text =
          DateFormat('dd/MM/yyyy').format(_openingStockDate);
      _lowStockAlertController.text = widget.product!.lowStockAlert.toString();
      _barcodeController.text = widget.product!.barcode;
    } else {
      // Default values for new product
      _openingStockDateController.text =
          DateFormat('dd/MM/yyyy').format(_openingStockDate);
      _cessRateController.text = '0';
      _gstRateController.text = '0';
      _openingStockController.text = '0';
      _lowStockAlertController.text = '0';
    }
  }

  Future<void> _saveProduct() async {
    // Validate required fields
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter product name')),
      );
      return;
    }

    if (_salePriceController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter sale price')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Create product model from form data
      final product = ProductModel(
        id: widget.product?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        itemType: _itemType,
        salePrice: double.tryParse(_salePriceController.text) ?? 0,
        unit: _unitController.text.trim(),
        isTaxInclusive: _isTaxInclusive,
        gstRate: double.tryParse(_gstRateController.text) ?? 0,
        gstType: _gstType,
        cessRate: double.tryParse(_cessRateController.text) ?? 0,
        cessType: _cessType,
        purchasePrice: double.tryParse(_purchasePriceController.text) ?? 0,
        gstTreatment: _gstTreatment,
        wholesalePrice: double.tryParse(_wholesalePriceController.text) ?? 0,
        minWholesaleQty: int.tryParse(_minWholesaleQtyController.text) ?? 0,
        maintainStock: _maintainStock,
        openingStock: int.tryParse(_openingStockController.text) ?? 0,
        openingStockUnit: _openingStockUnitController.text.trim(),
        openingStockDate: _openingStockDate,
        lowStockAlert: int.tryParse(_lowStockAlertController.text) ?? 0,
        barcode: _barcodeController.text.trim(),
        hsn: _hsnController.text.trim(),
      );

      // Save to Firebase
      await _firebaseService.saveProduct(product);

      // Call the onSave callback if provided
      if (widget.onSave != null) {
        widget.onSave!(product);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product saved successfully')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving product: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  double _getGstRateFromDropdown(String gstType) {
    switch (gstType) {
      case 'GST @ 5%':
        return 5.0;
      case 'GST @ 12%':
        return 12.0;
      case 'GST @ 18%':
        return 18.0;
      case 'GST @ 28%':
        return 28.0;
      default:
        return 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final secondaryTextColor = AppColors.getSecondaryTextColor(isDarkMode);
    final dividerColor = AppColors.getDividerColor(isDarkMode);
    final BackgroundColor = AppColors.getBackgroundColor(isDarkMode);

    return Scaffold(
      backgroundColor:
          isDarkMode ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(widget.product == null ? 'Add Product' : 'Edit Product'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Basic/Optional Tabs

          // Main content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product name input
                  TextField(
                    controller: _nameController,
                    style: TextStyle(
                      color:
                          isDarkMode ? AppColors.darkText : AppColors.lightText,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Item Name',
                      labelStyle: TextStyle(color: secondaryTextColor),
                      border: const OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: dividerColor),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: AppColors.primaryBlue),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Tab buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _currentTab = 0;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _currentTab == 0
                                ? AppColors.primaryBlue
                                : (BackgroundColor),
                            foregroundColor: _currentTab == 0
                                ? Colors.white
                                : secondaryTextColor,
                          ),
                          child: const Text('Basic Details'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _currentTab = 1;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _currentTab == 1
                                ? AppColors.primaryBlue
                                : (BackgroundColor),
                            foregroundColor: _currentTab == 1
                                ? Colors.white
                                : secondaryTextColor,
                          ),
                          child: const Text('Optional Details'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Tab content
                  Expanded(
                    child: _currentTab == 0
                        ? _buildBasicDetails(
                            isDarkMode, secondaryTextColor, dividerColor)
                        : _buildOptionalDetails(
                            isDarkMode, secondaryTextColor, dividerColor),
                  ),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveProduct,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        disabledBackgroundColor:
                            AppColors.primaryBlue.withOpacity(0.5),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Save',
                              style:
                                  TextStyle(fontSize: 16, color: Colors.white),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicDetails(
      bool isDarkMode, Color secondaryTextColor, Color dividerColor) {
    return SingleChildScrollView(
        padding: const EdgeInsets.all(8.0),
    child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Item Type
          Text(
            'Select Item Type',
            style: TextStyle(
              fontSize: 16,
              color: isDarkMode ? AppColors.darkText : AppColors.lightText,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Radio(
                value: 'Goods',
                groupValue: _itemType,
                onChanged: (value) {
                  setState(() {
                    _itemType = value.toString();
                  });
                },
                activeColor: AppColors.primaryBlue,
              ),
              Text(
                'Goods',
                style: TextStyle(
                  color: isDarkMode ? AppColors.darkText : AppColors.lightText,
                ),
              ),
              const SizedBox(width: 20),
              Radio(
                value: 'Services',
                groupValue: _itemType,
                onChanged: (value) {
                  setState(() {
                    _itemType = value.toString();
                  });
                },
                activeColor: AppColors.primaryBlue,
              ),
              Text(
                'Services',
                style: TextStyle(
                  color: isDarkMode ? AppColors.darkText : AppColors.lightText,
                ),
              ),
            ],
          ),
          Divider(color: dividerColor),

          // Item Description
          Text(
            'Item Description',
            style: TextStyle(
              fontSize: 16,
              color: isDarkMode ? AppColors.darkText : AppColors.lightText,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _descriptionController,
            style: TextStyle(
              color: isDarkMode ? AppColors.darkText : AppColors.lightText,
            ),
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              hintText: 'Enter description',
              hintStyle: TextStyle(color: secondaryTextColor),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: dividerColor),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: AppColors.primaryBlue),
              ),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),

          // HSN
          TextField(
            controller: _hsnController,
            style: TextStyle(
              color: isDarkMode ? AppColors.darkText : AppColors.lightText,
            ),
            decoration: InputDecoration(
              labelText: 'HSN',
              labelStyle: TextStyle(color: secondaryTextColor),
              border: const OutlineInputBorder(),
              suffixIcon: Icon(Icons.search, color: secondaryTextColor),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: dividerColor),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: AppColors.primaryBlue),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Sale Price and Unit
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _salePriceController,
                  style: TextStyle(
                    color:
                        isDarkMode ? AppColors.darkText : AppColors.lightText,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Sale Price',
                    labelStyle: TextStyle(color: secondaryTextColor),
                    border: const OutlineInputBorder(),
                    prefixText: '₹ ',
                    prefixStyle: TextStyle(
                      color:
                          isDarkMode ? AppColors.darkText : AppColors.lightText,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: dividerColor),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.primaryBlue),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _unitController,
                  style: TextStyle(
                    color:
                        isDarkMode ? AppColors.darkText : AppColors.lightText,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Unit',
                    labelStyle: TextStyle(color: secondaryTextColor),
                    border: const OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: dividerColor),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.primaryBlue),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Tax Inclusive
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tax Inclusive',
                style: TextStyle(
                  fontSize: 16,
                  color: isDarkMode ? AppColors.darkText : AppColors.lightText,
                ),
              ),
              Switch(
                value: _isTaxInclusive,
                onChanged: (value) {
                  setState(() {
                    _isTaxInclusive = value;
                  });
                },
                activeColor: AppColors.primaryBlue,
              ),
            ],
          ),

          // GST and CESS fields
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _gstRateController,
                  style: TextStyle(
                    color:
                        isDarkMode ? AppColors.darkText : AppColors.lightText,
                  ),
                  decoration: InputDecoration(
                    labelText: 'GST (%)',
                    labelStyle: TextStyle(color: secondaryTextColor),
                    border: const OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: dividerColor),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.primaryBlue),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  style: TextStyle(
                    color:
                        isDarkMode ? AppColors.darkText : AppColors.lightText,
                  ),
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: dividerColor),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.primaryBlue),
                    ),
                  ),
                  dropdownColor: Colors.white,
                  value: _gstType,
                  onChanged: (String? newValue) {
                    setState(() {
                      _gstType = newValue!;
                      // Automatically update the GST rate controller
                      _gstRateController.text = _getGstRateFromDropdown(newValue).toString();
                    });
                  },
                  items: <String>[
                    'GST @ 0',
                    'GST @ 5%',
                    'GST @ 12%',
                    'GST @ 18%',
                    'GST @ 28%',
                  ].map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(
                        value,
                        style: TextStyle(
                          color: isDarkMode
                              ? AppColors.darkText
                              : AppColors.lightText,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _cessRateController,
                  style: TextStyle(
                    color:
                        isDarkMode ? AppColors.darkText : AppColors.lightText,
                  ),
                  decoration: InputDecoration(
                    labelText: 'CESS',
                    labelStyle: TextStyle(color: secondaryTextColor),
                    border: const OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: dividerColor),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.primaryBlue),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  style: TextStyle(
                    color:
                        isDarkMode ? AppColors.darkText : AppColors.lightText,
                  ),
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: dividerColor),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.primaryBlue),
                    ),
                  ),
                  dropdownColor: Colors.white,
                  value: _cessType,
                  onChanged: (String? newValue) {
                    setState(() {
                      _cessType = newValue!;
                    });
                  },
                  items: <String>[
                    '% Percent Wise',
                    'Fixed',
                  ].map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(
                        value,
                        style: TextStyle(
                          color: isDarkMode
                              ? AppColors.darkText
                              : AppColors.lightText,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          SizedBox(height: 30),
        ],
      ));
  }

  Widget _buildOptionalDetails(
      bool isDarkMode, Color secondaryTextColor, Color dividerColor) {
    return SingleChildScrollView(
        padding: const EdgeInsets.all(8.0),
    child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Purchase Price
          Text(
            'Purchase Price',
            style: TextStyle(
              fontSize: 16,
              color: isDarkMode ? AppColors.darkText : AppColors.lightText,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _purchasePriceController,
            style: TextStyle(
              color: isDarkMode ? AppColors.darkText : AppColors.lightText,
            ),
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              prefixText: '₹ ',
              prefixStyle: TextStyle(
                color: isDarkMode ? AppColors.darkText : AppColors.lightText,
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: dividerColor),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: AppColors.primaryBlue),
              ),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
          ),
          const SizedBox(height: 16),

          // GST Treatment Dropdown
          DropdownButtonFormField<String>(
            style: TextStyle(
              color: isDarkMode ? AppColors.darkText : AppColors.lightText,
            ),
            decoration: InputDecoration(
              labelText: 'GST Treatment',
              labelStyle: TextStyle(color: secondaryTextColor),
              border: const OutlineInputBorder(),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: dividerColor),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: AppColors.primaryBlue),
              ),
            ),
            dropdownColor: Colors.white,
            value: _gstTreatment,
            onChanged: (String? newValue) {
              setState(() {
                _gstTreatment = newValue!;
              });
            },
            items: <String>[
              'Exclusive GST',
              'Inclusive GST',
              'Composite',
            ].map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(
                  value,
                  style: TextStyle(
                    color:
                        isDarkMode ? AppColors.darkText : AppColors.lightText,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Wholesale Price
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _wholesalePriceController,
                  style: TextStyle(
                    color:
                        isDarkMode ? AppColors.darkText : AppColors.lightText,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Wholesale Price',
                    labelStyle: TextStyle(color: secondaryTextColor),
                    border: const OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: dividerColor),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.primaryBlue),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _minWholesaleQtyController,
                  style: TextStyle(
                    color:
                        isDarkMode ? AppColors.darkText : AppColors.lightText,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Min. Wholesale Qty',
                    labelStyle: TextStyle(color: secondaryTextColor),
                    border: const OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: dividerColor),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.primaryBlue),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Maintain Stock
          Container(
            padding: const EdgeInsets.all(8),
            color: isDarkMode
                ? AppColors.darkBackground.withOpacity(0.3)
                : Colors.grey[200],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Maintain Stock',
                  style: TextStyle(
                    fontSize: 16,
                    color:
                        isDarkMode ? AppColors.darkText : AppColors.lightText,
                  ),
                ),
                Switch(
                  value: _maintainStock,
                  onChanged: (value) {
                    setState(() {
                      _maintainStock = value;
                    });
                  },
                  activeColor: AppColors.primaryBlue,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Opening Stock fields
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _openingStockController,
                  style: TextStyle(
                    color:
                        isDarkMode ? AppColors.darkText : AppColors.lightText,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Opening Stock',
                    labelStyle: TextStyle(color: secondaryTextColor),
                    border: const OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: dividerColor),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.primaryBlue),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _openingStockUnitController,
                  style: TextStyle(
                    color:
                        isDarkMode ? AppColors.darkText : AppColors.lightText,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Opening Stock Unit',
                    labelStyle: TextStyle(color: secondaryTextColor),
                    border: const OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: dividerColor),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.primaryBlue),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Opening Stock Date and Low Stock Alert
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _openingStockDateController,
                  style: TextStyle(
                    color:
                        isDarkMode ? AppColors.darkText : AppColors.lightText,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Opening Stock Date',
                    labelStyle: TextStyle(color: secondaryTextColor),
                    border: const OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: dividerColor),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.primaryBlue),
                    ),
                  ),
                  readOnly: true,
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _openingStockDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                      builder: (BuildContext context, Widget? child) {
                        return Theme(
                          data: isDarkMode
                              ? ThemeData.dark().copyWith(
                                  colorScheme: ColorScheme.dark(
                                    primary: AppColors.primaryBlue,
                                    onPrimary: Colors.white,
                                    surface: Colors.white,
                                    onSurface: AppColors.darkText,
                                  ),
                                )
                              : ThemeData.light().copyWith(
                                  colorScheme: const ColorScheme.light(
                                    primary: AppColors.primaryBlue,
                                    onPrimary: Colors.white,
                                    surface: Colors.white,
                                    onSurface: AppColors.lightText,
                                  ),
                                ),
                          child: child!,
                        );
                      },
                    );
                    if (date != null) {
                      setState(() {
                        _openingStockDate = date;
                        _openingStockDateController.text =
                            DateFormat('dd/MM/yyyy').format(date);
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _lowStockAlertController,
                  style: TextStyle(
                    color:
                        isDarkMode ? AppColors.darkText : AppColors.lightText,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Low Stock Alert',
                    labelStyle: TextStyle(color: secondaryTextColor),
                    border: const OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: dividerColor),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.primaryBlue),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Barcode
          Container(
            padding: const EdgeInsets.all(8),
            color: isDarkMode
                ? AppColors.darkBackground.withOpacity(0.3)
                : Colors.grey[200],
            child: Text(
              'Barcode',
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode ? AppColors.darkText : AppColors.lightText,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Barcode Input
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _barcodeController,
                  style: TextStyle(
                    color:
                        isDarkMode ? AppColors.darkText : AppColors.lightText,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Item Code Input',
                    labelStyle: TextStyle(color: secondaryTextColor),
                    border: const OutlineInputBorder(),
                    suffixIcon: Icon(Icons.qr_code, color: secondaryTextColor),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: dividerColor),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.primaryBlue),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: () {
                  // Generate barcode logic
                  // Set a random barcode for demo
                  setState(() {
                    _barcodeController.text =
                        DateTime.now().millisecondsSinceEpoch.toString();
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                ),
                child: const Text(
                  'Generate',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          SizedBox(height: 30,),
        ],
      ));
  }
}
