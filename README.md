# hackney_disp

Load-balanced Pool dispatcher based on
[dispcount](https://github.com/ferd/dispcount) for
[hackney](https://github.com/benoitc/hackney).

Like the default pool handler hackney_pool, but with the difference that
for each endpoint (domain/ip + port + ssl) of requests, a load balancer
is started allowing as many connections as mentioned in the
configuration.

Each load balancer has N workers that will connect on-demand to each
client.

The load balancer/pools/dispatcher mechanism is based on
[dispcount](https://github.com/ferd/dispcount), which will randomly
contact workers. This means that even though few connections might be
required, the nondeterministic dispatching may make all connections open
at some point. As such, it should be used in cases where the load is
somewhat predictable in terms of base levels.

## When to use it?

Whenever the HTTP client you're currently using happens to block trying
to access resources that are too scarce for the load required, you may
experience something similar to bufferbloat, where the queuing up of
requests ends up ruining latency for everyone, making the overall
response time terribly slow.

In the case of Erlang, this may happen over pools (like the default)
that dispatch resources through message passing. Then the process'
mailbox ends up as a bottleneck that makes the application too slow.
Dispcount was developed to solve similar issues by avoiding all message
passing on busy workers.

WARNING: use with caution, this pool handler is considered as
experimental. It's for now nased on the code from the dlhttpc project
and adapted to hackney.  How to use it?

In your application config set the pool_handler property to hackney_disp:

    {hackney, [
        {pool_handler, hackney_disp},
        {restart, permanent},
        {shutdown, 10000},
        {maxr, 10},
        {maxt, 1}
        ...
    ]}

and hackney will automatically use this pool.

The restart, shutdown, maxr, and maxt values allow to configure the supervisor that will take care of that dispatcher. You can set the maximum number of connections with the options passed to the client: [{max_connections, 200}] .

Note: for now you can't force the pool handler / client.
