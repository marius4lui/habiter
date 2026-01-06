# App Lock

Stay focused by locking distracting apps until you complete your habits.

## How it works
App Lock integrates directly with your habit progress. It acts as a gatekeeper for your entertainment or social media apps.

!!! success "Motivation"
    You literally *cannot* open TikTok until you've done your 10 pushups!

## Setting up App Lock
1. Go to **Settings** > **App Lock**.
2. Grant the necessary **Usage Access** permissions (Android only).
3. Select the apps you want to restrict (e.g., Instagram, YouTube).
4. Set your **Unlock Condition** (e.g., "Complete all daily habits").

## visual flow
``` mermaid
graph LR
  A[User opens specific App] --> B{Habits Done?};
  B -- Yes --> C[App Opens Normally];
  B -- No --> D[Lock Screen Appears];
  D --> E[Redirect to Habiter];
```
