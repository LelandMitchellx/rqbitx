/// 1:1 Rust mapping for librqbit DhtStats.
class DhtStats {
  final String id;
  final int outstandingRequests;
  final int routingTableSize;
  final int routingTableSizeV6;

  const DhtStats({
    required this.id,
    required this.outstandingRequests,
    required this.routingTableSize,
    required this.routingTableSizeV6,
  });

  factory DhtStats.fromJson(Map<String, dynamic> json) {
    return DhtStats(
      id: json['id'] as String? ?? '',
      outstandingRequests:
          (json['outstanding_requests'] as num?)?.toInt() ?? 0,
      routingTableSize:
          (json['routing_table_size'] as num?)?.toInt() ?? 0,
      routingTableSizeV6:
          (json['routing_table_size_v6'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'outstanding_requests': outstandingRequests,
        'routing_table_size': routingTableSize,
        'routing_table_size_v6': routingTableSizeV6,
      };
}

/// 1:1 Rust mapping for RoutingTable.
class DhtRoutingTable {
  final String id;
  final int size;
  final Map<String, dynamic> buckets;

  const DhtRoutingTable({
    required this.id,
    required this.size,
    required this.buckets,
  });

  factory DhtRoutingTable.fromJson(Map<String, dynamic> json) {
    return DhtRoutingTable(
      id: json['id'] as String? ?? '',
      size: (json['size'] as num?)?.toInt() ?? 0,
      buckets: (json['buckets'] as Map<String, dynamic>?) ?? {},
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'size': size,
        'buckets': buckets,
      };
}

/// Container for both IPv4 and IPv6 DHT routing tables.
class DhtRoutingTableResponse {
  final DhtRoutingTable v4;
  final DhtRoutingTable v6;

  const DhtRoutingTableResponse({
    required this.v4,
    required this.v6,
  });

  factory DhtRoutingTableResponse.fromJson(Map<String, dynamic> json) {
    return DhtRoutingTableResponse(
      v4: DhtRoutingTable.fromJson(
        (json['v4'] as Map<String, dynamic>?) ?? {},
      ),
      v6: DhtRoutingTable.fromJson(
        (json['v6'] as Map<String, dynamic>?) ?? {},
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'v4': v4.toJson(),
        'v6': v6.toJson(),
      };
}
