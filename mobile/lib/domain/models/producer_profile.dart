class ProducerProfile {
  const ProducerProfile({
    required this.name,
    required this.publicKey,
    required this.registeredAt,
  });

  final String name;

  /// Base58 public key.
  final String publicKey;
  final DateTime registeredAt;
}
