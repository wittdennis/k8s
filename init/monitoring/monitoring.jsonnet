local addMixin = (import 'kube-prometheus/lib/mixin.libsonnet');
local certManagerMixin = addMixin({
  name: 'cert-manager',
  mixin: (import 'cert-manager-mixin/mixin.libsonnet') + {
    _config+: {},
  },
});

local networkPolicyFromRulesNginxIngress(ports) = [{
  from: [{
    namespaceSelector: {
      matchLabels: {
        'kubernetes.io/metadata.name': 'ingress-nginx',
      },
    },
    podSelector: {
      matchLabels: {
        'app.kubernetes.io/name': 'ingress-nginx',
      },
    },
  }],
  ports: ports,
}];
local secureIngress(name, namespace, tls, rules) = {
  apiVersion: 'networking.k8s.io/v1',
  kind: 'Ingress',
  metadata: {
    name: name,
    namespace: namespace,
    annotations: {
      'kubernetes.io/ingress.class': 'nginx',
      'cert-manager.io/cluster-issuer': 'letsencrypt',
      'nginx.ingress.kubernetes.io/auth-url': 'https://login.$DOMAIN/oauth2/auth',
      'nginx.ingress.kubernetes.io/auth-signin': 'https://login.$DOMAIN/oauth2/start?rd=https://alerts.$DOMAIN$escaped_request_uri',
    },
  },
  spec: { tls: tls, rules: rules },
};
local ingress(name, namespace, tls, rules) = {
  apiVersion: 'networking.k8s.io/v1',
  kind: 'Ingress',
  metadata: {
    name: name,
    namespace: namespace,
    annotations: {
      'kubernetes.io/ingress.class': 'nginx',
      'cert-manager.io/cluster-issuer': 'letsencrypt',

    },
  },
  spec: { tls: tls, rules: rules },
};

local kp =
  (import 'kube-prometheus/main.libsonnet') +
  (import 'kube-prometheus/addons/all-namespaces.libsonnet') +
  // Uncomment the following imports to enable its patches
  // (import 'kube-prometheus/addons/anti-affinity.libsonnet') +
  // (import 'kube-prometheus/addons/managed-cluster.libsonnet') +
  // (import 'kube-prometheus/addons/node-ports.libsonnet') +
  // (import 'kube-prometheus/addons/static-etcd.libsonnet') +
  // (import 'kube-prometheus/addons/custom-metrics.libsonnet') +
  // (import 'kube-prometheus/addons/external-metrics.libsonnet') +
  // (import 'kube-prometheus/addons/pyrra.libsonnet') +
  {
    values+:: {
      common+: {
        namespace: 'monitoring',
        platform: 'kubeadm',
      },
      prometheus+: {
        namespaces: [],
      },
      alertmanager+: {
        config: importstr 'alertmanager-config.yaml',
      },
      grafana+: {
        dashboards+: certManagerMixin.grafanaDashboards,
        config+: {
          sections+: {
            server+: {
              root_url: 'https://grafana.$DOMAIN',
            },
            security: {
              admin_password: '$GRAFANA_ADMIN_PASSWORD',
            },
            'auth.github': {
              enabled: true,
              allow_sign_up: true,
              auto_login: false,
              client_id: '$GITHUB_APP_CLIENT_ID',
              client_secret: '$GITHUB_APP_CLIENT_SECRET',
              scopes: 'user:email,read:org',
              auth_url: 'https://github.com/login/oauth/authorize',
              token_url: 'https://github.com/login/oauth/access_token',
              api_url: 'https://api.github.com/user',
              allowed_organizations: '$GITHUB_ORG',
              allow_assign_grafana_admin: true,
              role_attribute_path: "contains(groups[*], '@$GITHUB_ORG/admins') &&  'GrafanaAdmin' || 'Viewer'",
            },
          },
        },
      },
    },

    prometheus+:: {
      prometheus+: {
        spec+: {
          externalUrl: 'https://prometheus.$DOMAIN',
        },
      },
      networkPolicy+: {
        spec+: {
          ingress+: networkPolicyFromRulesNginxIngress([{ port: 'web', protocol: 'TCP' }]),
        },
      },
    },
    alertmanager+:: {
      alertmanager+: {
        spec+: {
          externalUrl: 'https://alerts.$DOMAIN',
        },
      },
      networkPolicy+: {
        spec+: {
          ingress+: networkPolicyFromRulesNginxIngress([{ port: 'web', protocol: 'TCP' }]),
        },
      },
    },
    grafana+:: {
      networkPolicy+: {
        spec+: {
          ingress+: networkPolicyFromRulesNginxIngress([{ port: 'http', protocol: 'TCP' }]),
        },
      },
    },
    ingress+:: {
      'alertmanager-main': secureIngress(
        'alertmanager-main',
        $.values.common.namespace,
        [{
          hosts: ['alerts.$DOMAIN'],
          secretName: 'alertmanager-ingress-tls',
        }],
        [{
          host: 'alerts.$DOMAIN',
          http: {
            paths: [{
              path: '/',
              pathType: 'Prefix',
              backend: {
                service: {
                  name: 'alertmanager-main',
                  port: {
                    name: 'web',
                  },
                },
              },
            }],
          },
        }]
      ),
      'prometheus-k8s': secureIngress(
        'prometheus-k8s',
        $.values.common.namespace,
        [{
          hosts: ['prometheus.$DOMAIN'],
          secretName: 'prometheus-ingress-tls',
        }],
        [{
          host: 'prometheus.$DOMAIN',
          http: {
            paths: [{
              path: '/',
              pathType: 'Prefix',
              backend: {
                service: {
                  name: 'prometheus-k8s',
                  port: {
                    name: 'web',
                  },
                },
              },
            }],
          },
        }]
      ),
      grafana: ingress(
        'grafana',
        $.values.common.namespace,
        [{
          hosts: ['grafana.$DOMAIN'],
          secretName: 'grafana-ingress-tls',
        }],
        [{
          host: 'grafana.$DOMAIN',
          http: {
            paths: [{
              path: '/',
              pathType: 'Prefix',
              backend: {
                service: {
                  name: 'grafana',
                  port: {
                    name: 'http',
                  },
                },
              },
            }],
          },
        }]
      ),
    },
  };

{ 'setup/0namespace-namespace': kp.kubePrometheus.namespace } +
{
  ['setup/prometheus-operator-' + name]: kp.prometheusOperator[name]
  for name in std.filter((function(name) name != 'serviceMonitor' && name != 'prometheusRule'), std.objectFields(kp.prometheusOperator))
} +
// { 'setup/pyrra-slo-CustomResourceDefinition': kp.pyrra.crd } +
// serviceMonitor and prometheusRule are separated so that they can be created after the CRDs are ready
{ 'prometheus-operator-serviceMonitor': kp.prometheusOperator.serviceMonitor } +
{ 'prometheus-operator-prometheusRule': kp.prometheusOperator.prometheusRule } +
{ 'kube-prometheus-prometheusRule': kp.kubePrometheus.prometheusRule } +
{ ['alertmanager-' + name]: kp.alertmanager[name] for name in std.objectFields(kp.alertmanager) } +
{ ['blackbox-exporter-' + name]: kp.blackboxExporter[name] for name in std.objectFields(kp.blackboxExporter) } +
{ ['grafana-' + name]: kp.grafana[name] for name in std.objectFields(kp.grafana) } +
// { ['pyrra-' + name]: kp.pyrra[name] for name in std.objectFields(kp.pyrra) if name != 'crd' } +
{ ['kube-state-metrics-' + name]: kp.kubeStateMetrics[name] for name in std.objectFields(kp.kubeStateMetrics) } +
{ ['kubernetes-' + name]: kp.kubernetesControlPlane[name] for name in std.objectFields(kp.kubernetesControlPlane) }
{ ['node-exporter-' + name]: kp.nodeExporter[name] for name in std.objectFields(kp.nodeExporter) } +
{ ['prometheus-' + name]: kp.prometheus[name] for name in std.objectFields(kp.prometheus) } +
{ ['prometheus-adapter-' + name]: kp.prometheusAdapter[name] for name in std.objectFields(kp.prometheusAdapter) } +
{ 'cert-manager-prometheus-rules': certManagerMixin.prometheusRules } +
{ [name + '-ingress']: kp.ingress[name] for name in std.objectFields(kp.ingress) }
