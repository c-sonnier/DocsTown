# Plan 02: Authentication (GitHub OAuth)

## Goal
Implement GitHub OAuth sign-in so users can authenticate and begin voting immediately.

## Prerequisites
- Plan 00 (Project Setup)
- Plan 01 (Data Model — User model)

## Tasks

### 1. OmniAuth Configuration
- Install and configure `omniauth-github` gem
- Install `omniauth-rails_csrf_protection` gem (required for OmniAuth 2.x+ CSRF protection)
- Set up OAuth credentials in Rails credentials
- Configure OmniAuth initializer with GitHub strategy
- Set callback URL: `/auth/github/callback`

### 2. Current Attributes
Set up `Current` for request-scoped state (Rails convention):

```ruby
# app/models/current.rb
class Current < ActiveSupport::CurrentAttributes
  attribute :user
end
```

Set `Current.user` in a `before_action` on `ApplicationController`. This makes the current user available everywhere — models, jobs, mailers — not just controllers and views.

### 3. Sessions Controller
Create `SessionsController`:
- `create` — OmniAuth callback action
  - Find or create User from GitHub auth hash
  - Extract: `uid`, `info.nickname`, `info.image`, `info.email`
  - Set `session[:user_id]`
  - Set `Current.user`
  - Redirect to tasks index (or previous page)
- `destroy` — Sign out
  - Clear session
  - Redirect to root
- `failure` — OmniAuth failure handler
  - Flash error message
  - Redirect to root

### 4. Routes
```ruby
get "/auth/github/callback", to: "sessions#create"
get "/auth/failure", to: "sessions#failure"
delete "/logout", to: "sessions#destroy"
```

### 5. Authentication Helpers on ApplicationController
```ruby
class ApplicationController < ActionController::Base
  before_action :set_current_user

  private

  def set_current_user
    Current.user = User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def require_login
    redirect_to root_path, alert: "Please sign in" unless Current.user
  end

  def require_maintainer
    require_login
    redirect_to root_path, alert: "Not authorized" unless Current.user&.maintainer?
  end
end
```

### 6. Navigation Integration
- Show "Sign in with GitHub" button when logged out
- Show avatar, username, and "Sign out" link when logged in
- **Design reference:** See `STYLE_GUIDE.md` for button styles (primary "candy" button for sign-in CTA, nav styling) and `mockups/` for the nav bar pattern used across all authenticated pages

### 7. Tests
- Test OmniAuth callback with mock auth hash (OmniAuth test mode)
- Test user creation on first login
- Test user lookup on subsequent login
- Test session persistence and destruction
- Test require_login redirect behavior
- Test require_maintainer access control
- Test failure action renders gracefully

## Output
Working GitHub OAuth flow: sign in → session created → sign out. Protected routes redirect to sign-in.

## Estimated Complexity
Low-Medium — well-trodden path with OmniAuth, but need to handle edge cases.

## Notes
- OmniAuth test mode should be enabled in test environment for easy mock auth
- Consider storing the GitHub OAuth token if we need it for user-specific GitHub actions (not needed for MVP since PR submission uses a DocsTown service account)
