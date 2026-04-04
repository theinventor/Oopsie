# Ralph Agent Configuration

## Build Instructions

```bash
# Install dependencies
source ~/.rvm/scripts/rvm && rvm use ruby-4.0.2
bundle install
```

## Test Instructions

```bash
# Run tests
source ~/.rvm/scripts/rvm && rvm use ruby-4.0.2
bin/rails test
```

## Run Instructions

```bash
# Start the server (with Solid Queue and all processes)
source ~/.rvm/scripts/rvm && rvm use ruby-4.0.2
bin/dev
```

## Database

```bash
# Create and migrate database
bin/rails db:create db:migrate

# Run seeds
bin/rails db:seed
```

## Environment
- Ruby 4.0.2 via RVM
- Rails 8.1.3
- SQLite (default, no external DB needed)
- Solid Queue for background jobs (built into Rails 8.1)
- Use `bin/dev` to start all processes (web server + Solid Queue worker)
