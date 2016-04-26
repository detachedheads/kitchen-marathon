# <a name="title"></a> Kitchen::Marathon

A Test Kitchen Driver for Mesos Marathon.

This driver uses the [Marathon REST API][marathon_api] to create and destroy Marathon applications, allowing you to leverage your Mesos infrastructure for infrastructure testing!

This plugin takes an opinionated approach to running applications within Marathon:
* It assumes you are running in a docker container
* You can SSH into that container with a username and private key.

## <a name="requirements"></a> Requirements

To use this driver you will need access to a Mesos Marathon cluster.  You will need to know the hostname and access credentials for this cluster for the plugin to access its REST api.

This driver requires a slightly opinionated approach to Marathon Application configuration to assist in identifying what host port to use to acccess SSH running inside of a container.  To achieve this the plugin looks at the docker port mappings for a label with the key of "SERVICE" and value of "ssh".

The following is a slice of json showing the label:

```json
{
  "container": {
    "docker": {
      "forcePullImage": true,
      "image": "docker.yb0t.cc/centos-7-kitchen:1.0.0",
      "network": "BRIDGE",
      "portMappings": [
        {
          "containerPort": 22,
          "hostPort": 0,
          "labels": {
            "SERVICE" : "ssh"
          },
          "protocol": "tcp"
        },
      ],
    },
    "type": "DOCKER",
  }
}

```

## Installation and Setup

Please read the [Driver usage][driver_usage] page for more details.

## <a name="config"></a> Configuration

### <a name="config-app-prefix"></a> app\_prefix

This is the prefix applied to Marathon App names.

The default value is `kitchen/`.

### <a name="config-app-template"></a> app\_template

This allows for a Marathon Job template that will be used as the base template when the job template is created.  If this value is not provided all configuration parameters need to be set via `app_config`.

The default value is `nil`.

### <a name="config-app-config"></a> app\_config

This allows for Marathon Job configuration to be configured at the platform/suite/etc level as necessary.

This configuration is merged on top of any configuration provided by `app_template`.

The default value is `{}`.

### <a name="config-app-launch-timeout"></a> app\_launch\_timeout

Determines the timeout, in seconds, that the driver will wait for a Marathon App to deploy.  If the timeout is reached, the driver will assume that the deployment will not succeed and will attempt to stop the deployment and delete the Marathon App.  (This cleanup is best effort.)

The default value is `30` seconds.

### <a name="config-marathon-host"></a> marathon\_host

The web address to the Marathon host.

The default value is `http://localhost:8080`.

### <a name="config-marathon-password"></a> marathon\_password

The password to use for an HTTP AUTH protected Marathon Host

The default value is `nil`.

### <a name="config-marathon-username"></a> marathon\_username

The username to use for an HTTP AUTH protected Marathon Host

The default value is `nil`.

### <a name="config-marathon-verify-ssl"></a> marathon\_verify\_ssl

Whether or not a certificate presented by the Marathon Host is verified.

The default value is `true`.

## Marathon Proxy Configuration

### <a name="config-marathon-proxy-address"></a> marathon\_proxy\_address

Provides the option to specify a proxy address if necessary when connecting to the Marathon host.

The default value is `nil`.

### <a name="config-marathon-proxy-password"></a> marathon\_proxy\_password

Provides the option to specify a proxy passowrd if necessary when connecting to the Marathon host.

The default value is `nil`.

### <a name="config-marathon-proxy-port"></a> marathon\_proxy\_port

Provides the option to specify a proxy port if necessary when connecting to the Marathon host.

The default value is `nil`.

### <a name="config-marathon-proxy-username"></a> marathon\_proxy\_username

Provides the option to specify a proxy username if necessary when connecting to the Marathon host.

The default value is `nil`.

## Development

* Source hosted at [GitHub][repo]
* Report issues/questions/feature requests on [GitHub Issues][issues]

Pull requests are very welcome! Make sure your patches are well tested.
Ideally create a topic branch for every separate change you make. For
example:

1. Fork the repo
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Authors

Created and maintained by [Anthony Spring][author] (<aspring@yieldbot.com>)

## License

Apache 2.0 (see [LICENSE][license])

[author]:           https://github.com/yieldbot
[driver_usage]:     https://github.com/yieldbot/kitchen-marathon
[issues]:           https://github.com/yieldbot/kitchen-marathon/issues
[license]:          https://github.com/yieldbot/kitchen-marathon/blob/master/LICENSE
[marathon]:         https://mesosphere.github.io/marathon/
[marathon_api]:     https://github.com/otto-de/marathon-api
[repo]:             https://github.com/yieldbot/kitchen-marathon

