import 'dart:math' as math;

/// US Navy body fat estimation. Returns null if inputs are insufficient.
double? calculateBodyFat({
  required String gender,
  required double height,
  required double waist,
  double? hip,
  double? neck,
}) {
  if (height <= 0 || waist <= 0) return null;
  final genderLower = gender.toLowerCase();

  if (genderLower == 'male') {
    if (neck == null || neck <= 0 || waist <= neck) return null;
    final bodyFat = 495 /
            (1.0324 - 0.19077 * _log10(waist - neck) + 0.15456 * _log10(height)) -
        450;
    return _round(bodyFat);
  }

  if (genderLower == 'female') {
    if (neck == null || neck <= 0 || hip == null || hip <= 0 || waist + hip <= neck) {
      return null;
    }
    final bodyFat = 495 /
            (1.29579 -
                0.35004 * _log10(waist + hip - neck) +
                0.22100 * _log10(height)) -
        450;
    return _round(bodyFat);
  }
  return null;
}

double _log10(num x) => math.log(x) / math.ln10;

double _round(double value) => double.parse(value.toStringAsFixed(1));
