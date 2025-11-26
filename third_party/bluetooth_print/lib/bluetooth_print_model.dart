class BluetoothDevice {
  String? address;
  String? name;
  BluetoothDevice({this.address, this.name});
}

class LineText {
  static const TYPE_TEXT = 'text';
  static const TYPE_QRCODE = 'qrcode';

  static const ALIGN_LEFT = 0;
  static const ALIGN_CENTER = 1;
  static const ALIGN_RIGHT = 2;

  final String type;
  final String content;
  final int? align;
  final int? weight;
  final int? linefeed;

  LineText({required this.type, required this.content, this.align, this.weight, this.linefeed});
}
