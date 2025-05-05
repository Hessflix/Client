import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:hessflix/screens/shared/hessflix_snackbar.dart';
import 'package:hessflix/util/localization_helper.dart';

extension ClipboardHelper on BuildContext {
  Future<void> copyToClipboard(String value, {String? customMessage}) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (mounted) {
      hessflixSnackbar(
        this,
        title: customMessage ?? localized.copiedToClipboard,
      );
    }
  }
}
