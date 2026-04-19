# Bookmark Manager

This is a Ruby on Rails application for managing bookmarks.

## Prerequisites

* **Ruby version:** 3.2.3 (see `.ruby-version`)
* **Rails version:** 8.1.3 (see `Gemfile`)
* **System dependencies:**
  * Node.js and Yarn (for frontend assets)
  * SQLite3 (development database)
  * Docker (optional, for containerized development/deployment)

## Getting Started

1. **Install dependencies:**
   ```bash
   bundle install
   ```

2. **Setup the database:**
   ```bash
   bin/rails db:setup
   ```

3. **Run the development server:**
   ```bash
   bin/dev
   ```

4. **Run the tests:**
   ```bash
   bin/rails test
   ```

## Development

* Use `bin/dev` to start the application with Tailwind CSS and JS watchers.
* The application uses SQLite for development and testing.

## Deployment

This project includes a `Dockerfile` and `kamal` configuration for deployment.
Refer to `.kamal/` and `config/deploy.yml` for more details.
