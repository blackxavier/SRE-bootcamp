# Engineering Philosophy & Core Principles

This repository follows strict minimalist, maintainable, and pragmatic software engineering standards.

---

## 🎯 Core Principles

1. **Minimalism First**
   - Build clean, single-purpose, Unix-style components.
   - Implement only what is explicitly requested. Never add speculative features, unused helper methods, or boilerplate abstractions.
   - Keep pull requests and changesets focused and easy to review.

2. **Simplicity Over Complexity**
   - Prefer Python standard library utilities and native Django capabilities over heavy third-party packages.
   - Avoid prematurely introducing microservices, message queues, or distributed caches unless system scale or explicit project requirements demand them.
   - Avoid redundant layers of abstraction (e.g., custom repository patterns or service wrappers when Django's native ORM and DRF generic views/viewsets suffice).

3. **Explicit Over Implicit**
   - Configuration must be declarative and environment-driven (via `python-decouple`).
   - Fail early and visibly when critical environment variables or runtime dependencies are missing.
   - Explicit database dependencies: services dependent on PostgreSQL must verify health (e.g., `pg_isready`) before executing migrations or serving traffic.

4. **Reliability & Idempotency**
   - Startup scripts (`entrypoint.sh`), migrations, and deployment tasks must be idempotent and safe to retry automatically.
   - Static asset collection (`collectstatic --noinput`) and database migrations (`migrate --noinput`) must execute reliably during container bootstrap or CI validation.

5. **Security by Design**
   - Never commit sensitive secrets, credentials, or production `.env` files into source control.
   - Always run production containers with `DEBUG=False` and strict `ALLOWED_HOSTS`.
   - Never expose raw object storage or internal database ports publicly.
