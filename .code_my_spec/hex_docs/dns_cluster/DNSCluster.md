# DNSCluster

Simple DNS based cluster discovery.

A DNS query is made every `:interval` milliseconds to discover new ips.

## Default node discovery
Nodes will only be joined if their node basename matches the basename of the current node.
For example, if `node()` is `myapp-123@fdaa:1:36c9:a7b:198:c4b1:73c6:1`, it will try to connect
to every IP from the DNS query with `Node.connect/1`. But this will only work if the remote node
has the same basename, like `myapp-123@fdaa:1:36c9:a7b:198:c4b1:73c6:2`. If the remote node's
basename is different, the nodes will not connect.

## Specifying remote basenames
If you want to connect to nodes with different basenames, use a tuple with the basename and query.
For example, to connect to a node named `remote`, use `{"remote", "remote-app.internal"}`.

## Multiple queries
Sometimes you might want to cluster apps with different domain names. Just pass a list of queries
for this. For instance: `["app-one.internal", "app-two.internal", {"other-basename", "other.internal"}]`.
Remember, all nodes need to share the same secret cookie to connect successfully.

## Examples

To start in your supervision tree, add the child:

    children = [
      ...,
      {DNSCluster, query: "myapp.internal"}
    ]

See the `start_link/1` docs for all available options.

If you require more advanced clustering options and strategies, see the
[libcluster](https://hexdocs.pm/libcluster) library.