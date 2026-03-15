# Go DB Application – Setup, Git Workflow, and API Behavior

## 1. Initializing the Go Module

```bash
go mod init go-k8s
```

Initializes a new Go module named `go-k8s` and creates:
- `go.mod` – module metadata and dependency list
- `go.sum` – checksums to ensure dependency integrity

---

## 2. Adding HTTP Router Dependency (Gorilla Mux)

```bash
go get -u github.com/gorilla/mux
```

Downloads and adds the Gorilla Mux router.
- `-u` updates to the latest compatible version
- Marked as `// indirect` until explicitly imported

---

## 3. Adding Database ORM (GORM + PostgreSQL)

```bash
go get -u gorm.io/gorm
go get -u gorm.io/driver/postgres
```

Adds:
- GORM ORM
- PostgreSQL driver
- Required transitive dependencies

---

## 4. go.mod vs go.sum

- `go.mod`: Declares module name, Go version, dependencies
- `go.sum`: Ensures reproducible builds and dependency integrity  
Both **must be committed**.

---

## 5. Git Status Before Pull

```bash
git status
```

- `go.mod` → tracked and modified
- `go-k8s` → untracked Go binary

---

## 6. Git Stash Behavior

```bash
git stash push -m "server local changes"
```

- Stashes **tracked files only**
- Untracked files are ignored

To include untracked files:
```bash
git stash push -u -m "include untracked"
```

---

## 7. Fetching Remote Changes

```bash
git fetch origin
git log --oneline HEAD..origin/main
git diff HEAD..origin/main
```

- Fetch downloads updates without modifying working tree

---

## 8. PostgreSQL DSN Fix

Incorrect:
```go
password=%s dbname=%s
```

Correct:
```go
password=%s dbname=%s
```

Correct ordering is required for authentication to succeed.

---

## 9. Merging Remote Branch

```bash
git merge origin/main
```

Fast-forward merge applied successfully.

---

## 10. Applying Stash

```bash
git stash apply stash@{0}
```

Restores tracked files only.

---

## 11. Go Binary (go-k8s)

- Compiled executable
- Should **not** be committed

Recommended `.gitignore`:
```gitignore
go-k8s
```

# PostgreSQL Environment Variable Setup for Go Application

This document explains how to configure environment variables required for connecting a Go application (using GORM + PostgreSQL) to a PostgreSQL database.

---

## 1. Why Environment Variables?

Environment variables are used to:
- Avoid hardcoding credentials in source code
- Support different environments (dev, test, prod)
- Improve security and portability

In production (VMs, Docker, Kubernetes), **environment variables are the standard approach**.

---

## 2. Required PostgreSQL Environment Variables

The application expects the following variables:

| Variable Name | Description | Example |
|--------------|------------|---------|
| `DB_HOST` | PostgreSQL server hostname or IP | `localhost` |
| `DB_PORT` | PostgreSQL port | `5432` |
| `DB_USER` | Database username | `postgres` |
| `DB_PASSWORD` | Database user password | `mypassword` |
| `DB_NAME` | Database name | `usersdb` |
| `DB_SSLMODE` | SSL mode for connection | `disable` |

---

## 3. Setting Environment Variables on Linux

### Temporary (Current Shell Only)

```bash
export DB_HOST=localhost
export DB_PORT=5432
export DB_USER=postgres
export DB_PASSWORD=postgres123
export DB_NAME=usersdb
export DB_SSLMODE=disable
```

Variables are cleared once the shell session ends.

---

### Persistent (User Level)

Add variables to `~/.bashrc` or `~/.bash_profile`:

```bash
export DB_HOST=localhost
export DB_PORT=5432
export DB_USER=postgres
export DB_PASSWORD=postgres123
export DB_NAME=usersdb
export DB_SSLMODE=disable
```

Apply changes:
```bash
source ~/.bashrc
```

---

## 4. Verifying Environment Variables

```bash
env | grep DB_
```

Expected output:
```text
DB_HOST=localhost
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=postgres123
DB_NAME=usersdb
DB_SSLMODE=disable
```

---

## 5. Using Environment Variables in Go Code

```go
dbHost := os.Getenv("DB_HOST")
dbPort := os.Getenv("DB_PORT")
dbUser := os.Getenv("DB_USER")
dbPassword := os.Getenv("DB_PASSWORD")
dbName := os.Getenv("DB_NAME")
sslMode := os.Getenv("DB_SSLMODE")
```

---

## 6. Building the PostgreSQL DSN (Correct Format)

```go
dsn := fmt.Sprintf(
  "host=%s user=%s password=%s dbname=%s port=%s sslmode=%s",
  dbHost,
  dbUser,
  dbPassword,
  dbName,
  dbPort,
  sslMode,
)
```

Incorrect ordering or missing fields will result in authentication or connection errors.

---

## 7. Common Connection Errors and Causes

| Error | Likely Cause |
|------|-------------|
| `password authentication failed` | Wrong username/password |
| `connection refused` | PostgreSQL not running or wrong port |
| `no such host` | Invalid DB_HOST |
| `database does not exist` | Wrong DB_NAME |
| `sslmode required` | SSL misconfiguration |

---

## 8. Security Best Practices

- ❌ Never commit credentials to Git
- ❌ Never hardcode passwords in Go code
- ✅ Use environment variables or secrets managers
- ✅ Use Kubernetes Secrets or Docker secrets in production

---

## 9. Kubernetes Example (Preview)

```yaml
env:
  - name: DB_HOST
    value: postgres-service
  - name: DB_PORT
    value: "5432"
  - name: DB_USER
    valueFrom:
      secretKeyRef:
        name: postgres-secret
        key: username
  - name: DB_PASSWORD
    valueFrom:
      secretKeyRef:
        name: postgres-secret
        key: password
  - name: DB_NAME
    value: usersdb
  - name: DB_SSLMODE
    value: disable
```

---

## 12. Gorilla Mux Routing Fix

Incorrect:
```go
/user{id}
```

Correct:
```go
/user/{id}
```

Curly braces are mandatory for path variables.

---

## 13. API Testing

Create user:
```bash
curl -X POST http://localhost:8080/user \
  -H "Content-Type: application/json" \
  -d '{"name":"Anuroop","email":"anu@example.com"}'
```

List users:
```bash
curl http://localhost:8080/users
```

Update user:
```bash
curl -X PUT http://localhost:8080/user/1 \
  -H "Content-Type: application/json" \
  -d '{"name":"Anuroop PS"}'
```

Delete user:
```bash
curl -X DELETE http://localhost:8080/user/1
```

---

## 14. Why `/users/1` Returns 404

No route defined for:
```go
/users/{id}
```

Only `/users` and `/user/{id}` exist.

---

## 15. Security Warning

Never commit GitHub tokens or secrets.

Use environment variables:
```bash
export GITHUB_TOKEN=xxxx
```

---

## 16. Best Practices

- Commit `go.mod` and `go.sum`
- Ignore binaries
- Validate routes
- Never store secrets in repos

