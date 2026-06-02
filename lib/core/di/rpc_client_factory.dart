import 'package:rpc_client/rpc_client.dart';

typedef RpcClientFactory =
    BitcoinRpcClient Function({
      required String url,
      required String user,
      required String password,
    });
