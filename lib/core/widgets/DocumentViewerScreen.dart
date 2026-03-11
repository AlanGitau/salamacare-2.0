import 'package:flutter/material.dart';
import 'package:signup/core/constants/colors.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:photo_view/photo_view.dart';
import 'package:url_launcher/url_launcher.dart';

/// Universal document viewer screen that handles PDFs, images, and other file types
class DocumentViewerScreen extends StatefulWidget {
  final String fileUrl;
  final String fileName;
  final String mimeType;

  const DocumentViewerScreen({
    super.key,
    required this.fileUrl,
    required this.fileName,
    required this.mimeType,
  });

  @override
  State<DocumentViewerScreen> createState() => _DocumentViewerScreenState();
}

class _DocumentViewerScreenState extends State<DocumentViewerScreen> {
  final PdfViewerController _pdfViewerController = PdfViewerController();
  bool _isLoading = true;
  String? _error;

  @override
  void dispose() {
    _pdfViewerController.dispose();
    super.dispose();
  }

  bool get _isPdf => widget.mimeType.toLowerCase() == 'application/pdf' ||
                     widget.fileName.toLowerCase().endsWith('.pdf');

  bool get _isImage => widget.mimeType.toLowerCase().startsWith('image/') ||
                       widget.fileName.toLowerCase().endsWith('.jpg') ||
                       widget.fileName.toLowerCase().endsWith('.jpeg') ||
                       widget.fileName.toLowerCase().endsWith('.png') ||
                       widget.fileName.toLowerCase().endsWith('.gif') ||
                       widget.fileName.toLowerCase().endsWith('.webp');

  Future<void> _openExternal() async {
    final uri = Uri.parse(widget.fileUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open document'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isPdf ? Colors.grey[300] : Colors.black,
      appBar: AppBar(
        title: Text(
          widget.fileName,
          style: const TextStyle(color: Colors.white),
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          if (_isPdf) ...[
            IconButton(
              icon: const Icon(Icons.zoom_in),
              onPressed: () {
                _pdfViewerController.zoomLevel = _pdfViewerController.zoomLevel + 0.25;
              },
              tooltip: 'Zoom In',
            ),
            IconButton(
              icon: const Icon(Icons.zoom_out),
              onPressed: () {
                _pdfViewerController.zoomLevel = _pdfViewerController.zoomLevel - 0.25;
              },
              tooltip: 'Zoom Out',
            ),
          ],
          IconButton(
            icon: const Icon(Icons.open_in_new),
            onPressed: _openExternal,
            tooltip: 'Open Externally',
          ),
        ],
      ),
      body: _buildViewer(),
      floatingActionButton: _isPdf
          ? FloatingActionButton(
              onPressed: () {
                _pdfViewerController.jumpToPage(1);
              },
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.first_page, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildViewer() {
    if (_isPdf) {
      return _buildPdfViewer();
    } else if (_isImage) {
      return _buildImageViewer();
    } else {
      return _buildUnsupportedView();
    }
  }

  Widget _buildPdfViewer() {
    return Stack(
      children: [
        SfPdfViewer.network(
          widget.fileUrl,
          controller: _pdfViewerController,
          onDocumentLoaded: (PdfDocumentLoadedDetails details) {
            setState(() {
              _isLoading = false;
            });
          },
          onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
            setState(() {
              _isLoading = false;
              _error = details.error;
            });
          },
          enableDoubleTapZooming: true,
          enableTextSelection: true,
          canShowScrollHead: true,
          canShowScrollStatus: true,
          canShowPaginationDialog: true,
        ),
        if (_isLoading)
          Container(
            color: Colors.white,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 16),
                  Text('Loading PDF...', style: TextStyle(color: Colors.black87)),
                ],
              ),
            ),
          ),
        if (_error != null)
          Container(
            color: Colors.white,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  const Text(
                    'Failed to load PDF',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _openExternal,
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Open Externally'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildImageViewer() {
    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          PhotoView(
            imageProvider: NetworkImage(widget.fileUrl),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 3,
            initialScale: PhotoViewComputedScale.contained,
            backgroundDecoration: const BoxDecoration(color: Colors.black),
            loadingBuilder: (context, event) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    SizedBox(height: 16),
                    Text(
                      'Loading image...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    const Text(
                      'Failed to load image',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _openExternal,
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Open Externally'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.pinch, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'Pinch to zoom',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnsupportedView() {
    return Container(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.description, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 24),
            Text(
              widget.fileName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Preview not available for this file type',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _openExternal,
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open in External App'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
