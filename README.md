# Still Monkey app

Still Monkey app is a focused, AI-powered learning app that turns any topic into short, swipeable lessons you can consume in minutes.

## Code map

- **Entry**: `StillMonkeyApp` → `ContentView` (root `NavigationStack` and navigation destinations).
- **Routing**: `ContentView` pushes `ReelsView` (Learn/Story feed), `PathCourseView`, and `PathLessonSessionView` based on internal `Route` cases.
- **State**: `TopicViewModel` drives topic text, content mode (Learn / Story / Path), reels feed, and generation; `PathCourseViewModel` owns the structured course, lesson progress, and path navigation.

## What It Offers

- **Learn mode**: Quickly understand a topic through concise, reel-style cards.
- **Story mode**: Explore the same topic as a calmer, narrative learning experience.
- **Path mode**: Follow a structured lesson path with quizzes and progression between lessons.

- **Smart suggestions**: Get ready-to-start topic ideas across Learn, Story, and Path.
- **Resume where you left off**: Recent sessions are saved locally so you can continue instantly.
- **Immersive reading**: Minimal UI controls help you stay focused while reading.

## Why It’s Useful

Still Monkey app helps you move from curiosity to clarity fast: pick a topic, choose a format that fits your mood, and keep momentum with lightweight progress and quick re-entry.

## Who It’s For

- **Students** who want quick explainers before or after deeper study.
- **Curious learners** who enjoy discovering new topics in short sessions.
- **Busy professionals** who want to learn in focused, bite-sized breaks.
