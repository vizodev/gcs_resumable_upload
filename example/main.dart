import 'dart:io';

import 'package:gcs_resumable_upload/gcs_resumable_upload.dart';
import 'package:test/test.dart';

void main() async {
  String url =
      'https://storage.googleapis.com/d-platform-vizo.appspot.com/xZNPFR6zNPmZ8u5K?X-Goog-Algorithm=GOOG4-RSA-SHA256&X-Goog-Credential=firebase-adminsdk-weusf%40d-platform-vizo.iam.gserviceaccount.com%2F20230124%2Fauto%2Fstorage%2Fgoog4_request&X-Goog-Date=20230124T105436Z&X-Goog-Expires=1801&X-Goog-SignedHeaders=host%3Bx-goog-meta-attributename%3Bx-goog-meta-collectionid%3Bx-goog-resumable&X-Goog-Signature=95cb6c05ae66d8615bc0fd65e99406997edaaf86d6b6cbbbd3243869a5e31dfdba5b9dc1229673757fdf607b4f768927d8763fb8d5d60e005868635d15f90941cb244990addb00e18f61d08622cdf525cba5daee45533f39f8ab3312c3bcb7b81ebe329b6293148d69670114b190c12b12317981b8b731d90570a2bf609fecb2e11248d110fb8a0157b383bd761b1a9058b414cd790902ee78d74b33e4173c6030e2a204ce90a1361ea2aa4b1bab5f84a49d1364421b378d8a2013fce5b839a678069b5e5f79f3562acc5d8d78426c14f717858bd04c66dc59da175cc3b435ccad8a9fa470bb8fb8d8912a31fc1a4d785d20235ceb2d1a7550148a762e5523d0';

  // Get test file
  final file = File('example/test_pdf.pdf');

  final Upload upload = Upload(
    'id',
    url,
    file,
    options: UploadOptions(
      metadata: {
        'collectionid': 'test',
        'attributename': 'test',
      },
      contentType: 'application/pdf',
    ),
  );

  try {
    await upload.start();
    print('Upload finished');
  } catch (e) {
    print(e);
  }
}
