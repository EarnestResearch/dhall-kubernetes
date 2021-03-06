let Prelude = ../Prelude.dhall

let map = Prelude.List.map

let kv = Prelude.JSON.keyText

let kubernetes =
      ../package.dhall sha256:3ea8628b704704de295261dfc7626c15247c589c10a266f970cade262543fdda

let Service = { name : Text, host : Text, version : Text }

let services = [ { name = "foo", host = "foo.example.com", version = "2.3" } ]

let makeTLS
    : Service → kubernetes.IngressTLS.Type
    =   λ(service : Service)
      → { hosts = [ service.host ]
        , secretName = Some "${service.name}-certificate"
        }

let makeRule
    : Service → kubernetes.IngressRule.Type
    =   λ(service : Service)
      → { host = Some service.host
        , http =
            Some
              { paths =
                  [ { backend =
                        { serviceName = service.name
                        , servicePort = kubernetes.IntOrString.Int 80
                        }
                    , path = None Text
                    }
                  ]
              }
        }

let mkIngress
    : List Service → kubernetes.Ingress.Type
    =   λ(inputServices : List Service)
      → let annotations =
              [ kv "kubernetes.io/ingress.class" "nginx"
              , kv "kubernetes.io/ingress.allow-http" "false"
              ]
        
        let defaultService =
              { name = "default"
              , host = "default.example.com"
              , version = " 1.0"
              }
        
        let ingressServices = inputServices # [ defaultService ]
        
        let spec =
              kubernetes.IngressSpec::{
              , tls =
                  map Service kubernetes.IngressTLS.Type makeTLS ingressServices
              , rules =
                  map
                    Service
                    kubernetes.IngressRule.Type
                    makeRule
                    ingressServices
              }
        
        in  kubernetes.Ingress::{
            , metadata =
                kubernetes.ObjectMeta::{
                , name = "nginx"
                , annotations = annotations
                }
            , spec = Some spec
            }

in  mkIngress services
