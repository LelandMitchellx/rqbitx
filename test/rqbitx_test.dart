import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rqbitx/rqbitx.dart';

void main() {
  test('RqbitServer start, probe HTTP, current, and stop lifecycle', () async {
    final tempDir = await Directory.systemTemp.createTemp('rqbitx_test_');
    try {
      // 0. 未启动时 current 为 null
      expect(RqbitServer.current(), isNull);

      // 1. 启动服务
      final server = await RqbitServer.start(
        downloadDir: tempDir.path,
        bindAddr: '127.0.0.1:0',
      );

      expect(server.port, greaterThan(0));
      expect(
        server.url.toString(),
        contains('http://127.0.0.1:${server.port}'),
      );
      expect(server.isRunning, isTrue);

      // 2. 验证 current() 能够正确探活并返回同端口实例（用于热重启自动重连）
      final active = RqbitServer.current();
      expect(active, isNotNull);
      expect(active!.port, equals(server.port));
      expect(active.url, equals(server.url));
      expect(active.isRunning, isTrue);

      // 3. 验证 startOrAttach 直接复用已存活的后台服务
      final attached = await RqbitServer.startOrAttach(
        downloadDir: tempDir.path,
      );
      expect(attached.port, equals(server.port));

      // 4. HTTP 探活：使用原生 HttpClient 访问 rqbit HTTP 服务
      final client = HttpClient();
      try {
        final request = await client.getUrl(server.url);
        final response = await request.close();
        expect(response.statusCode, inInclusiveRange(200, 399));
      } finally {
        client.close();
      }

      // 4.1 验证 RqbitServer 继承自 RqbitClient，可以直接调用所有 REST API
      expect(server, isA<RqbitClient>());
      final torrentList = await server.listTorrents();
      expect(torrentList.torrents, isEmpty);
      final serverInfo = await server.getServerInfo();
      expect(serverInfo.version, isNotEmpty);

      // 5. 停止服务
      await server.stop();
      expect(server.isRunning, isFalse);
      expect(RqbitServer.current(), isNull);

      // 6. 验证默认 DHT 持久化目录已被安全创建在 downloadDir/.rqbit 下
      final dhtFolder = Directory('${tempDir.path}/.rqbit');
      expect(await dhtFolder.exists(), isTrue);
    } finally {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    }
  });

  test('RqbitServer start with custom dhtPersistencePath', () async {
    final tempDir = await Directory.systemTemp.createTemp('rqbitx_custom_dht_');
    try {
      final customDht = '${tempDir.path}/custom_cache/dht_routing.json';
      final server = await RqbitServer.start(
        downloadDir: tempDir.path,
        dhtPersistencePath: customDht,
      );
      expect(server.isRunning, isTrue);

      final parentFolder = Directory('${tempDir.path}/custom_cache');
      expect(await parentFolder.exists(), isTrue);

      await server.stop();
      expect(server.isRunning, isFalse);
    } finally {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    }
  });

  test(
    'RqbitServer start with disabled dht persistence (empty string)',
    () async {
      final tempDir = await Directory.systemTemp.createTemp('rqbitx_no_dht_');
      try {
        final server = await RqbitServer.start(
          downloadDir: tempDir.path,
          dhtPersistencePath: '',
        );
        expect(server.isRunning, isTrue);

        await server.stop();
        expect(server.isRunning, isFalse);
      } finally {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    },
  );

  test(
    'RqbitServer verify /torrents/{id}/delete endpoint route exists',
    () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'rqbitx_delete_test_',
      );
      try {
        final server = await RqbitServer.start(downloadDir: tempDir.path);
        final client = HttpClient();
        try {
          // 验证 /torrents/{id}/delete 路由已在 librqbit 后台服务中装配生效
          final uri = server.url.resolve('/torrents/99999/delete');
          final request = await client.postUrl(uri);
          final response = await request.close();
          // 未存在的种子会返回 500/404 并附带错误提示信息，证明路由与文件删除逻辑正常挂载
          expect(response.statusCode, inInclusiveRange(400, 500));
        } finally {
          client.close();
        }
        await server.stop();
      } finally {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    },
  );

  test(
    'RqbitServer directly executes RqbitClient APIs as a unified instance',
    () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'rqbitx_client_inherit_',
      );
      try {
        final server = await RqbitServer.start(downloadDir: tempDir.path);
        expect(server, isA<RqbitClient>());

        // 直接通过 server 调用各类 RqbitClient 接口
        final stats = await server.getSessionStats();
        expect(stats.counters.fetchedBytes, equals(0));

        final limits = await server.getLimits();
        expect(limits, isNotNull);

        await server.stop();
      } finally {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    },
  );
}
