import 'dart:ffi';

String runtimeArchitecture(String platform) {
  if (platform == 'android') return 'universal';
  final abi = Abi.current().toString().toLowerCase();
  if (abi.contains('arm64')) return 'arm64';
  if (abi.contains('x64')) return 'x64';
  if (abi.contains('ia32')) return 'x86';
  if (abi.contains('riscv64')) return 'riscv64';
  return 'unknown';
}
