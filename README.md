# cep_7_e-commerce
Advanced Scalable E-commerce Web Application with Real-Time Streaming, Security, Autoscaling, and Helm on AWS

## TerraForm setup
The TerraForm setup will include to basic principles:
1. a tailored IAM role for TerraForm actions &rarr will limit potential actions that terraform can do and help with observability
2. state-lock for team collaboration


## ElasticSearch (ES)
ElasticSearch (ES) is a read-optimized cache for search.

Important characteristics:
- distributed (for horizontal scalability)
- does not pull data but needs to be fed (on change)
- stores both, the actual data to be queried, and the indices to optimize the query
- auto-infers indices &rarr needs careful configuration to avoid index explosion (!)


### Architectural considerations:
ES is resource hungry (need to ensure the processing nodes have enough CPU and RAM for the given data format) and duplicates data. I looked at a few comparable technologies to benchmark the case for ElasticSearch:

| Tool | Pros | Cons | Ideal When |
| :-- | :-- | :-- | :-- |
| Apache Lucene	| ✅ Same engine ES is built on<br>✅ Full control | ❌ Java-only<br>❌ No built-in distribution | 🟢 You're running Java apps<br>🟡 Want fine-grained local indexing |
| Typesense	| ✅ Simpler, developer-friendly<br>✅ Fast full-text search<br>✅ JSON API<br>✅ Light-weight | ❌ Less mature<br>❌ Limited scale | 🟢 Simpler product catalogs<br>🟡 1-node or lightweight distributed use |
| MeiliSearch | ✅ Super fast<br>✅ Easy to host<br>✅ Beautiful relevance out of the box | ❌ Still maturing<br>❌ Not built for huge data volumes | 🟢 Startup or mid-scale SaaS search<br>🟢 Local search-as-a-service |
| SQLite + FTS5 | ✅ Local, zero-infra<br>✅ Good for mobile / edge | ❌ No scale-out<br>❌ Minimal control	| 🟢 Mobile or single-user apps only |

ES especially shines with scale (~>10M entries). There are no safety issues per-se with duplicating the data (product catalogue).

> [!INFO]
> ElasticSearch is appropriate to provide the full-text search functionality at scale for this application.


### Deployment considerations:
ES comes in many different flavors to deploy it for use.

For the MVP of this project, we will start with EC2-managed nodes for ES. This uses systemd + Terraform + EBS volumes for persistent storage and keeps it stable and observable.

Later, we will consider to migrate to ECK (Elastic Cloud on Kubernetes) for tighter GitOps integration, auto-scaling, or dynamic environment setup.

> [!IMPORTANT] Running ES on EKS is operationally non-trivial: it involves StatefulSets, persistent volumes, readiness probes, node affinities, etc. It’s easy to break cluster consistency if misconfigured.


### ES Node updates:
ElasticSearch does not natively connect to its underlying data source but rather data needs to be fed into it by some external update mechanism. There are a few different options to do that:
1. CDC (Change Data Capture) &rarr real-time update of incremental changes over time
2. schedules sync / batch job
3. event-driven sync from application layer &rarr can hook directly into the API that creates/updates/deletes entries to do the same for ES

Since we are talking about a product catalogue, time for updates is not critical, i.e., no need for the complex real-time CDC pipeline setup. It is enough to have regular batch jobs (run at no-peak times) to update the ES nodes.


### Right-sizing (FinOps):
For ES we need to consider factors that can influence both, CPU and EBS (elastic block storage) of each node.


## Data Ingestion (Kinesis)
...


## Data Layer
...
