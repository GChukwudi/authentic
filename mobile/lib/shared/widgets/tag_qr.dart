import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:mobile/app/theme/app_colors.dart';

class TagQr extends StatelessWidget {
  const TagQr({super.key, required this.data, this.size});

  final String data;
  final double? size;

  @override
  Widget build(BuildContext context) {
    return QrImageView(
      data: data,
      size: size,
      padding: EdgeInsets.zero,
      backgroundColor: Colors.white,
      errorCorrectionLevel: QrErrorCorrectLevel.M,
      eyeStyle: const QrEyeStyle(
        eyeShape: QrEyeShape.square,
        color: AppColors.ink,
      ),
      dataModuleStyle: const QrDataModuleStyle(
        dataModuleShape: QrDataModuleShape.square,
        color: AppColors.ink,
      ),
    );
  }
}
