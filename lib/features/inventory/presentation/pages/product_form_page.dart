/// Product add/edit form with dynamic metadata fields and image selector.
library;

import 'dart:developer';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:stock_pilot/core/constants/app_constants.dart';
import 'package:stock_pilot/features/inventory/domain/entities/product.dart';
import 'package:stock_pilot/features/inventory/presentation/bloc/inventory_bloc.dart';
import 'package:stock_pilot/features/inventory/presentation/bloc/inventory_event.dart';

class ProductFormPage extends StatefulWidget {
  const ProductFormPage({super.key, this.product});
  final Product? product;

  bool get isEditing => product != null;

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _itemCodeCtrl;
  late final TextEditingController _barcodeCtrl;
  late final TextEditingController _itemNameCtrl;
  late final TextEditingController _brandCtrl;
  late final TextEditingController _productGroupCtrl;
  late final TextEditingController _detailedDescriptionCtrl;
  late final TextEditingController _descriptionCtrl;
  late final TextEditingController _salesRateCtrl;
  late final TextEditingController _purchaseRateCtrl;
  late final TextEditingController _wholesalePriceCtrl;
  late final TextEditingController _mrpCtrl;
  late final TextEditingController _profitPercentageCtrl;
  late final TextEditingController _minimumSaleRateCtrl;
  late final TextEditingController _addinPartNumber1Ctrl;
  late final TextEditingController _addinPartNumber2Ctrl;
  late final TextEditingController _imageCtrl;
  late final TextEditingController _otherLanguageCtrl;
  late final TextEditingController _qtyCtrl;
  late final TextEditingController _thresholdCtrl;
  late final TextEditingController _aisleCtrl;
  late final TextEditingController _shelfCtrl;
  late final TextEditingController _binCtrl;
  late UnitOfMeasure _selectedUnit;
  late List<_MetaRow> _metaRows;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _itemCodeCtrl = TextEditingController(text: p?.itemCode ?? '');
    _barcodeCtrl = TextEditingController(text: p?.barcode ?? '');
    _itemNameCtrl = TextEditingController(text: p?.itemName ?? '');
    _brandCtrl = TextEditingController(text: p?.brand ?? '');
    _productGroupCtrl = TextEditingController(text: p?.productGroup ?? '');
    _detailedDescriptionCtrl = TextEditingController(
      text: p?.detailedDescription ?? '',
    );
    _descriptionCtrl = TextEditingController(text: p?.description ?? '');
    _salesRateCtrl = TextEditingController(
      text: p != null ? p.salesRate.toString() : '0.00',
    );
    _purchaseRateCtrl = TextEditingController(
      text: p != null ? p.purchaseRate.toString() : '0.00',
    );
    _wholesalePriceCtrl = TextEditingController(
      text: p != null ? p.wholesalePrice.toString() : '0.00',
    );
    _mrpCtrl = TextEditingController(
      text: p != null ? p.mrp.toString() : '0.00',
    );
    _profitPercentageCtrl = TextEditingController(
      text: p != null ? p.profitPercentage.toString() : '0.00',
    );
    _minimumSaleRateCtrl = TextEditingController(
      text: p != null ? p.minimumSaleRate.toString() : '0.00',
    );
    _addinPartNumber1Ctrl = TextEditingController(
      text: p?.addinPartNumber1 ?? '',
    );
    _addinPartNumber2Ctrl = TextEditingController(
      text: p?.addinPartNumber2 ?? '',
    );
    _imageCtrl = TextEditingController(text: p?.image ?? '');
    _otherLanguageCtrl = TextEditingController(text: p?.otherLanguage ?? '');
    _qtyCtrl = TextEditingController(
      text: p != null ? p.quantityOnHand.toString() : '0',
    );
    _thresholdCtrl = TextEditingController(
      text: p != null ? p.lowStockThreshold.toString() : '10',
    );
    _aisleCtrl = TextEditingController(text: p?.locationAisle ?? '');
    _shelfCtrl = TextEditingController(text: p?.locationShelf ?? '');
    _binCtrl = TextEditingController(text: p?.locationBin ?? '');
    _selectedUnit = p?.unitOfMeasure ?? UnitOfMeasure.pieces;
    _metaRows =
        p?.metadata
            .map(
              (m) => _MetaRow(
                keyCtrl: TextEditingController(text: m.key),
                valueCtrl: TextEditingController(text: m.value),
              ),
            )
            .toList() ??
        [];

    _imageCtrl.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _itemCodeCtrl.dispose();
    _barcodeCtrl.dispose();
    _itemNameCtrl.dispose();
    _brandCtrl.dispose();
    _productGroupCtrl.dispose();
    _detailedDescriptionCtrl.dispose();
    _descriptionCtrl.dispose();
    _salesRateCtrl.dispose();
    _purchaseRateCtrl.dispose();
    _wholesalePriceCtrl.dispose();
    _mrpCtrl.dispose();
    _profitPercentageCtrl.dispose();
    _minimumSaleRateCtrl.dispose();
    _addinPartNumber1Ctrl.dispose();
    _addinPartNumber2Ctrl.dispose();
    _imageCtrl.dispose();
    _otherLanguageCtrl.dispose();
    _qtyCtrl.dispose();
    _thresholdCtrl.dispose();
    _aisleCtrl.dispose();
    _shelfCtrl.dispose();
    _binCtrl.dispose();
    for (final m in _metaRows) {
      m.keyCtrl.dispose();
      m.valueCtrl.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      final pickedFile = File(result.files.single.path!);
      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${appDir.path}/product_images');
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      final fileName = p.basename(pickedFile.path);
      final localFile = await pickedFile.copy('${imagesDir.path}/$fileName');

      setState(() {
        _imageCtrl.text = localFile.path;
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final metadata = _metaRows
        .where((m) => m.keyCtrl.text.trim().isNotEmpty)
        .map(
          (m) => ProductMetadata(
            key: m.keyCtrl.text.trim(),
            value: m.valueCtrl.text.trim(),
          ),
        )
        .toList();

    final product = Product(
      id: widget.product?.id,
      itemCode: _itemCodeCtrl.text.trim(),
      barcode: _barcodeCtrl.text.trim(),
      itemName: _itemNameCtrl.text.trim(),
      brand: _brandCtrl.text.trim(),
      productGroup: _productGroupCtrl.text.trim(),
      detailedDescription: _detailedDescriptionCtrl.text.trim(),
      description: _descriptionCtrl.text.trim(),
      salesRate: double.tryParse(_salesRateCtrl.text) ?? 0.0,
      purchaseRate: double.tryParse(_purchaseRateCtrl.text) ?? 0.0,
      wholesalePrice: double.tryParse(_wholesalePriceCtrl.text) ?? 0.0,
      mrp: double.tryParse(_mrpCtrl.text) ?? 0.0,
      profitPercentage: double.tryParse(_profitPercentageCtrl.text) ?? 0.0,
      minimumSaleRate: double.tryParse(_minimumSaleRateCtrl.text) ?? 0.0,
      addinPartNumber1: _addinPartNumber1Ctrl.text.trim(),
      addinPartNumber2: _addinPartNumber2Ctrl.text.trim(),
      image: _imageCtrl.text.trim(),
      otherLanguage: _otherLanguageCtrl.text.trim(),
      quantityOnHand: double.tryParse(_qtyCtrl.text) ?? 0.0,
      unitOfMeasure: _selectedUnit,
      lowStockThreshold: double.tryParse(_thresholdCtrl.text) ?? 10.0,
      locationAisle: _aisleCtrl.text.trim(),
      locationShelf: _shelfCtrl.text.trim(),
      locationBin: _binCtrl.text.trim(),
      metadata: metadata,
    );

    if (widget.isEditing) {
      context.read<InventoryBloc>().add(UpdateProduct(product));
    } else {
      context.read<InventoryBloc>().add(AddProduct(product));
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Product' : 'New Product'),
      ),
      body: Row(
        children: [
          _buildImageSelector(),

          Expanded(
            flex: 4,
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const SizedBox(height: 24),
                  _SectionHeader('Basic Information'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _itemCodeCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Item Code *',
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Required'
                              : null,
                          enabled: !widget.isEditing,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _barcodeCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Barcode',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _itemNameCtrl,
                    decoration: const InputDecoration(labelText: 'Item Name *'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _brandCtrl,
                          decoration: const InputDecoration(labelText: 'Brand'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _productGroupCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Product Group',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descriptionCtrl,
                    decoration: const InputDecoration(labelText: 'Description'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _detailedDescriptionCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Detailed Description',
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _addinPartNumber1Ctrl,
                          decoration: const InputDecoration(
                            labelText: 'Addin Part Number 1',
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _addinPartNumber2Ctrl,
                          decoration: const InputDecoration(
                            labelText: 'Addin Part Number 2',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _otherLanguageCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Other Language',
                    ),
                  ),
                  const SizedBox(height: 24),
                  _SectionHeader('Pricing'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _salesRateCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Sales Rate',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _purchaseRateCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Purchase Rate',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _wholesalePriceCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Wholesale Price',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _mrpCtrl,
                          decoration: const InputDecoration(labelText: 'MRP'),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _profitPercentageCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Profit %',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _minimumSaleRateCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Min Sale Rate',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _SectionHeader('Stock & Units'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _qtyCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Quantity on Hand',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<UnitOfMeasure>(
                          initialValue: _selectedUnit,
                          decoration: const InputDecoration(
                            labelText: 'Unit of Measure',
                          ),
                          items: UnitOfMeasure.values
                              .map(
                                (u) => DropdownMenuItem(
                                  value: u,
                                  child: Text(u.label),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setState(
                            () => _selectedUnit = v ?? UnitOfMeasure.pieces,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _thresholdCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Low Stock Threshold',
                    ),
                    keyboardType: TextInputType.number,
                  ),

                  const SizedBox(height: 24),
                  _SectionHeader('Physical Location'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _aisleCtrl,
                          decoration: const InputDecoration(labelText: 'Aisle'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _shelfCtrl,
                          decoration: const InputDecoration(labelText: 'Shelf'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _binCtrl,
                          decoration: const InputDecoration(labelText: 'Bin'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  _SectionHeader('Custom Attributes'),
                  const SizedBox(height: 12),
                  ..._metaRows.asMap().entries.map((entry) {
                    final i = entry.key;
                    final m = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: m.keyCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Key',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: m.valueCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Value',
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () =>
                                setState(() => _metaRows.removeAt(i)),
                          ),
                        ],
                      ),
                    );
                  }),
                  TextButton.icon(
                    onPressed: () => setState(
                      () => _metaRows.add(
                        _MetaRow(
                          keyCtrl: TextEditingController(),
                          valueCtrl: TextEditingController(),
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Attribute'),
                  ),

                  const SizedBox(height: 32),
                  FilledButton(
                    onPressed: _submit,
                    child: Text(
                      widget.isEditing ? 'Save Changes' : 'Create Product',
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

  Widget _buildImageSelector() {
    final imagePath = _imageCtrl.text.trim();
    final bool hasImage = imagePath.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader('Product Image'),
          const SizedBox(height: 12),
          Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: hasImage
                      ? _buildImageView(imagePath)
                      : const Center(
                          child: Icon(
                            Icons.image_outlined,
                            size: 64,
                            color: Colors.white24,
                          ),
                        ),
                ),
              ),
              if (hasImage)
                Positioned(
                  top: 8,
                  right: 8,
                  child: CircleAvatar(
                    backgroundColor: Colors.black54,
                    radius: 18,
                    child: IconButton(
                      icon: const Icon(
                        Icons.close,
                        size: 18,
                        color: Colors.white,
                      ),
                      onPressed: () => setState(() => _imageCtrl.clear()),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.photo_library_outlined),
                label: const SizedBox(),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _openWebBrowser,
                icon: const Icon(Icons.public),
                label: const SizedBox(),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _showUrlDialog(),
                icon: const Icon(Icons.link),
                label: const SizedBox(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImageView(String path) {
    if (path.startsWith('data:image')) {
      try {
        final base64String = path.split(',').last;
        return Image.memory(
          base64Decode(base64String),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              const Center(child: Icon(Icons.broken_image, size: 64)),
        );
      } catch (e) {
        return const Center(child: Icon(Icons.broken_image, size: 64));
      }
    } else if (path.startsWith('http')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            const Center(child: Icon(Icons.broken_image, size: 64)),
      );
    } else {
      return Image.file(
        File(path),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          log('$error');
          return const Center(child: Icon(Icons.broken_image, size: 64));
        },
      );
    }
  }

  Future<void> _openWebBrowser() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => const _WebBrowserDialog(),
    );
    if (result != null) {
      setState(() {
        _imageCtrl.text = result;
      });
    }
  }

  void _showUrlDialog() {
    final ctrl = TextEditingController(
      text: _imageCtrl.text.startsWith('http') ? _imageCtrl.text : '',
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Image URL'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            hintText: 'https://example.com/image.png',
            labelText: 'Enter network image URL',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _imageCtrl.text = ctrl.text.trim();
              });
              Navigator.pop(context);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }
}

class _WebBrowserDialog extends StatefulWidget {
  const _WebBrowserDialog();

  @override
  State<_WebBrowserDialog> createState() => _WebBrowserDialogState();
}

class _WebBrowserDialogState extends State<_WebBrowserDialog> {
  final _searchCtrl = TextEditingController();
  InAppWebViewController? webViewController;
  double progress = 0;
  String url = "https://www.google.com/imghp";

  void _performSearch() {
    final query = _searchCtrl.text.trim();
    if (query.isNotEmpty && webViewController != null) {
      final searchUrl =
          "https://www.google.com/search?q=${Uri.encodeComponent(query)}&tbm=isch";
      webViewController!.loadUrl(
        urlRequest: URLRequest(url: WebUri(searchUrl)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Browse for Image'),
      content: SizedBox(
        width: 800,
        height: 600,
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Search images...',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                    onSubmitted: (_) => _performSearch(),
                  ),
                ),
                IconButton(
                  onPressed: _performSearch,
                  icon: const Icon(Icons.search),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (progress < 1.0) LinearProgressIndicator(value: progress),
            Expanded(
              child: Container(
                color: Colors.white,
                child: InAppWebView(
                  initialUrlRequest: URLRequest(url: WebUri(url)),
                  initialSettings: InAppWebViewSettings(
                    useShouldOverrideUrlLoading: false,
                    mediaPlaybackRequiresUserGesture: false,
                    javaScriptEnabled: true,
                    supportZoom: true,
                    allowsInlineMediaPlayback: true,
                    disableContextMenu: false,
                    userAgent:
                        "Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Mobile/15E148 Safari/604.1",
                  ),
                  onWebViewCreated: (controller) {
                    webViewController = controller;
                    // Add JavaScript handler for click/double-click fallback
                    controller.addJavaScriptHandler(
                      handlerName: 'onImageClick',
                      callback: (args) {
                        final String imageUrl = args[0];
                        _showSelectionConfirm(imageUrl);
                      },
                    );
                  },
                  onLoadStop: (controller, url) async {
                    log('WebView loaded: $url');
                    // Inject JavaScript to listen for clicks on images
                    await controller.evaluateJavascript(
                      source: """
                      document.addEventListener('click', function(e) {
                        var target = e.target;
                        while (target && target.tagName !== 'IMG') {
                          target = target.parentNode;
                        }
                        if (target && target.tagName === 'IMG') {
                          window.flutter_inappwebview.callHandler('onImageClick', target.src);
                        }
                      }, true);
                    """,
                    );
                  },
                  onProgressChanged: (controller, progress) {
                    setState(() {
                      this.progress = progress / 100;
                    });
                  },
                  onLongPressHitTestResult: (controller, hitTestResult) async {
                    log(
                      'Long press hit test: ${hitTestResult.type} extra: ${hitTestResult.extra}',
                    );
                    if (hitTestResult.type ==
                            InAppWebViewHitTestResultType.IMAGE_TYPE ||
                        hitTestResult.type ==
                            InAppWebViewHitTestResultType
                                .SRC_IMAGE_ANCHOR_TYPE) {
                      final imageUrl = hitTestResult.extra;
                      if (imageUrl != null) {
                        _showSelectionConfirm(imageUrl);
                      }
                    }
                  },
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Text(
                'Click or Long press on an image to select it.',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  void _showSelectionConfirm(String imageUrl) {
    showDialog(
      context: context,
      builder: (innerContext) => AlertDialog(
        title: const Text('Select this image?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogImage(imageUrl),
            const SizedBox(height: 8),
            Text(
              imageUrl,
              style: const TextStyle(fontSize: 10),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(innerContext),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(innerContext); // Close confirm
              Navigator.pop(context, imageUrl); // Return URL to page
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogImage(String path) {
    if (path.startsWith('data:image')) {
      try {
        final base64String = path.split(',').last;
        return Image.memory(
          base64Decode(base64String),
          height: 150,
          fit: BoxFit.contain,
          errorBuilder: (c, e, s) => const Text('Image preview unavailable'),
        );
      } catch (e) {
        return const Text('Image preview unavailable');
      }
    }
    return Image.network(
      path,
      height: 150,
      fit: BoxFit.contain,
      errorBuilder: (c, e, s) => const Text('Image preview unavailable'),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

class _MetaRow {
  _MetaRow({required this.keyCtrl, required this.valueCtrl});
  final TextEditingController keyCtrl;
  final TextEditingController valueCtrl;
}
