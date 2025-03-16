import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';

void showImageViewer(BuildContext context, String imageUrl, {String? heroTag}) {
  if (!imageUrl.startsWith('http')) {
    print('Invalid image URL: $imageUrl');
    return;
  }

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Center(
              child: Hero(
                tag: heroTag ?? imageUrl,
                child: PhotoView(
                  imageProvider: CachedNetworkImageProvider(imageUrl),
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 2,
                ),
              ),
            ),
            Positioned(
              top: 40,
              left: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget buildImageWidget(String? imageUrl, {double? height, double? width, BoxFit fit = BoxFit.cover}) {
  if (imageUrl == null || imageUrl.isEmpty || !imageUrl.startsWith('http')) {
    return const SizedBox();
  }

  return CachedNetworkImage(
    imageUrl: imageUrl,
    height: height,
    width: width,
    fit: fit,
    placeholder: (context, url) => Container(
      height: height,
      width: width,
      color: Colors.grey[200],
      child: const Center(child: CircularProgressIndicator()),
    ),
    errorWidget: (context, url, error) {
      print('Error loading network image: $error for URL: $url');
      return Container(
        height: height,
        width: width,
        color: Colors.grey[200],
        child: const Icon(Icons.error),
      );
    },
  );
}
