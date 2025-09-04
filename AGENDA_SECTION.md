# Agenda Section - Dashboard Documentation

## Overview

The Agenda section is a core feature of the Rolo dashboard that provides users with a comprehensive view of their scheduled tasks, reminders, and activities. It serves as a centralized task management interface that displays various types of agenda items in an organized, filterable format.

## Key Features

### 1. Time Range Filtering
The agenda section allows users to filter tasks by different time periods:

- **Today**: Shows tasks scheduled for the current day
- **Week**: Displays tasks for the next 7 days
- **Month**: Shows tasks for the next 30 days

Users can toggle between these time ranges by tapping on the time range selector at the top of the section.

### 2. Task Types Supported
The agenda section handles multiple types of tasks:

- **Email Tasks**: Follow-up emails, communication reminders
- **Payment Tasks**: Payment reminders, donation follow-ups
- **Event Tasks**: Meetings, appointments, scheduled events
- **Text Tasks**: General notes and reminders
- **Reminder Tasks**: Time-based notifications
- **Asset Tasks**: Document and file-related tasks
- **Checklist Tasks**: Multi-step task lists

### 3. Task Management Actions
Each agenda task supports the following actions:

- **Complete**: Mark tasks as finished
- **Skip**: Temporarily skip tasks for later
- **Delete**: Permanently remove tasks
- **Pin**: Pin important tasks to the top
- **Priority Toggle**: Mark tasks as high priority
- **Expand**: View detailed task information

### 4. Sorting and Organization
Tasks can be sorted by multiple criteria:

- **Date**: Chronological order
- **Kind**: Grouped by task type
- **Name (A → Z)**: Alphabetical ascending
- **Name (Z → A)**: Alphabetical descending

### 5. View Options
Users can customize their agenda view:

- **Priority First**: Show high-priority tasks at the top
- **Incomplete First**: Display unfinished tasks before completed ones
- **Compact View**: Condensed card layout for better overview
- **Show/Hide Completed**: Toggle visibility of completed tasks

## User Interface Components

### Header Section
- **Time Range Selector**: Dropdown to choose Today/Week/Month
- **Section Title**: "'s agenda" with expand/collapse functionality
- **View Controls**: 
  - Eye icon to show/hide completed tasks
  - Menu with sorting and view options
  - Chevron to expand/collapse the section

### Task Cards
Each task is displayed as a card with:

- **Profile Image**: Contact or task-specific icon
- **Task Name**: Primary identifier
- **Description**: Brief task summary
- **Date/Time**: When the task is scheduled
- **Priority Indicator**: Visual marker for high-priority items
- **Action Buttons**: Complete, skip, delete, pin options
- **Status Indicators**: Completed, overdue, or pending status

### Empty States
When no tasks are available, the section displays:

- **Empty State**: Encouraging message to add new tasks
- **Completion State**: Celebration message when all tasks are done
- **Dynamic Messages**: Rotating motivational text

## Task Data Structure

Each `AgendaTask` contains:

```swift
struct AgendaTask {
    let id: UUID
    var name: String
    var taskDescription: String
    var contentBody: String?
    var subject: String?
    var image: String
    let phone: String?
    let email: String?
    var priority: Bool
    var type: CardType
    var triggerDate: Date
    let actionDate: Date?
    var completed: Bool
    var hidden: Bool?
    var isSelected: Bool
    var isDeleted: Bool
    var isCompleting: Bool
    var shouldRemove: Bool
    var isPinned: Bool
    var isSkipped: Bool
    var actionCompletedOn: Date?
}
```

## Interaction Patterns

### Task Completion Flow
1. User taps the complete button on a task card
2. Task is marked as completed with timestamp
3. Task moves to completed section (if visible)
4. Completion banner appears with undo option
5. Task count updates in real-time

### Task Filtering Logic
1. **Time Range Filter**: Only shows tasks within selected period
2. **Visibility Filter**: Hides tasks older than 24.5 hours
3. **Status Filter**: Respects show/hide completed setting
4. **Priority Sorting**: Applies priority-first ordering if enabled

### Undo Functionality
- Users can undo recent actions (complete, delete, skip)
- Undo banner appears for 5 seconds
- Supports up to 3 undoable actions
- Actions are automatically finalized after timeout

## Performance Considerations

### Task Loading
- Tasks are filtered and sorted efficiently
- Lazy loading for large task lists
- Optimized date calculations for time ranges
- Cached sorting results for better performance

### Memory Management
- Removed tasks are filtered out immediately
- Completed tasks can be hidden to reduce memory usage
- Efficient state management for UI updates

## Accessibility Features

- **VoiceOver Support**: All interactive elements are properly labeled
- **Dynamic Type**: Text scales with system font size settings
- **High Contrast**: Supports high contrast mode
- **Reduced Motion**: Respects accessibility motion preferences

## Integration Points

### Dashboard Integration
- Part of the main dashboard view
- Integrates with other sections (Emails, Events, Campaigns)
- Shares state with the main dashboard view model

### Data Sources
- Connects to Supabase backend for task persistence
- Supports real-time updates via Firebase
- Integrates with contact management system

## Future Enhancements

### Planned Features
- **Recurring Tasks**: Support for repeating agenda items
- **Task Templates**: Pre-defined task structures
- **Bulk Actions**: Multi-select for batch operations
- **Advanced Filtering**: More granular filter options
- **Task Dependencies**: Link related tasks together

### Performance Improvements
- **Virtual Scrolling**: For very large task lists
- **Background Sync**: Offline task management
- **Smart Caching**: Predictive task loading

## Technical Implementation

### Key Components
- `DashboardView`: Main container view
- `AgendaCard`: Individual task card component
- `TimeRangeSelector`: Time period picker
- `HomeViewModel`: Business logic and state management

### State Management
- Uses SwiftUI's `@State` and `@StateObject` for local state
- Observable objects for data binding
- Proper state restoration and persistence

### Animation and Transitions
- Smooth expand/collapse animations
- Card transition effects
- Loading state animations
- Completion celebration animations

This agenda section provides users with a powerful, flexible task management interface that adapts to their workflow and preferences while maintaining excellent performance and user experience. 