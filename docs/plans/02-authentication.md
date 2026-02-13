# Plan 02: Authentication (GitHub OAuth)

## Goal
Implement GitHub OAuth sign-in so users can authenticate and begin voting immediately.

## Prerequisites
- Plan 00 (Project Setup)
- Plan 01 (Data Model — User model)

## Tasks

### 1. OmniAuth Configuration
- Install and configure `omniauth-github` gem
- Set up OAuth credentials in Rails credentials
- Configure OmniAuth initializer with GitHub strategy
- Set callback URL: `/auth/github/callback`
- Handle CSRF protection with OmniAuth (Rails 8 considerations)

### 2. Sessions Controller
Create `SessionsController`:
- `create` — OmniAuth callback action
  - Find or create User from GitHub auth hash
  - Extract: `uid`, `info.nickname`, `info.image`, `info.email`
  - Set `session[:user_id]`
  - Redirect to tasks index (or previous page)
- `destroy` — Sign out
  - Clear session
  - Redirect to root

### 3. Routes
```ruby
get "/auth/github/callback", to: "sessions#create"
get "/auth/failure", to: "sessions#failure"
delete "/logout", to: "sessions#destroy"
```

### 4. Current User Helper
- `ApplicationController#current_user` — load user from session
- `ApplicationController#logged_in?` — boolean helper
- `ApplicationController#require_login` — before_action for protected routes
- Make `current_user` and `logged_in?` available as view helpers

### 5. Navigation Integration
- Show "Sign in with GitHub" button when logged out
- Show avatar, username, and "Sign out" link when logged in

### 6. Authorization Helpers
- `require_maintainer` before_action for admin routes
- Check `current_user.maintainer?` role

### 7. Tests
- Test OmniAuth callback with mock auth hash
- Test user creation on first login
- Test user lookup on subsequent login
- Test session persistence and destruction
- Test require_login redirect behavior
- Test require_maintainer access control

## Output
Working GitHub OAuth flow: sign in → session created → sign out. Protected routes redirect to sign-in.

## Estimated Complexity
Low-Medium — well-trodden path with OmniAuth, but need to handle edge cases.

## Notes
- OmniAuth test mode should be enabled in test environment for easy mock auth
- Consider storing the GitHub OAuth token if we need it for user-specific GitHub actions (not needed for MVP since PR submission uses a DocsTown service account)
