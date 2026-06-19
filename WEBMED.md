# WebMed: publishing `dotnet-pg-repack` to harbor

This repo is a WebMed fork of [cherts/pg_repack_docker](https://github.com/CHERTS/pg_repack_docker). Upstream CI (`.github/workflows/release.yml`) publishes to Docker Hub (`cherts/pg-repack`). **WebMed does not use that pipeline for its internal image.**

The image consumed by **WALL-E** (`harbor.k8s.webmed.no:443/webmed/dotnet-pg-repack`) is **built and pushed manually from a local machine** — there is no CI that pushes to harbor. If you change a Dockerfile here, you must rebuild and push by hand or WALL-E will keep running the old image.

## Why the base is `dotnet/aspnet` (not `dotnet/runtime`)

WALL-E is an ASP.NET Core service (`Microsoft.NET.Sdk.Web`, health-check endpoint), so its published app needs the **`Microsoft.AspNetCore.App`** shared framework — which only `mcr.microsoft.com/dotnet/aspnet` ships, not `dotnet/runtime`. The `17/Dockerfile` `FROM` must stay on `aspnet`.

LLVM/JIT is **not** built in (`--with-llvm` removed): JIT is a server-side feature and this is a client-side `pg_repack` image, so it's dead weight (and Alpine 3.22 no longer ships `clang15`).

## Build & push (PostgreSQL 17 image)

```bash
# 1. Build (context is the PG-major dir, e.g. 17)
docker build -t dotnet-pg-repack:<version> -f 17/Dockerfile 17

# 2. Sanity-check the runtimes and pg_repack
docker run --rm --entrypoint dotnet     dotnet-pg-repack:<version> --list-runtimes
docker run --rm --entrypoint pg_repack  dotnet-pg-repack:<version> --version

# 3. Tag for harbor and push
docker login harbor.k8s.webmed.no:443
docker tag  dotnet-pg-repack:<version> harbor.k8s.webmed.no:443/webmed/dotnet-pg-repack:<version>
docker push harbor.k8s.webmed.no:443/webmed/dotnet-pg-repack:<version>
```

## Tag convention

The harbor tag tracks the **pg_repack version** (e.g. `1.5.3`). Historically a `.N` revision suffix was used for rebuilds at the same pg_repack version (e.g. `1.5.2.1`). Keep WALL-E's `Dockerfile` base `FROM` in sync with whatever tag you push.

| pushed tag | base image | pg_repack | notes |
|------------|-----------|-----------|-------|
| `1.5.2.1`  | `dotnet/aspnet:9.0-alpine3.20` | 1.5.2 | previous (.NET 9) |
| `1.5.3`    | `dotnet/aspnet:10.0-alpine3.22` | 1.5.3 | .NET 10 (WM-16100) |

## Consumer

`WALL-E/Dockerfile` → `FROM harbor.k8s.webmed.no:443/webmed/dotnet-pg-repack:<version>`.
